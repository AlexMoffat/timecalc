/*
 * Copyright (c) 2017 Alex Moffat
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of mosquitto nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation

typealias RecognizerResult = (remainder: String, token: Token)?

protocol Recognizer {
    func tryToRecognize(_ s: String) -> RecognizerResult
}

class Recognizers {
    
    private static let matchingString = {(match: NSTextCheckingResult, s: String) -> String in String(s[s.startIndex ..< s.index(s.startIndex, offsetBy: match.range.length)])}
    
    private static let POSIX_LOCALE = Locale(identifier: "en_US_POSIX")
    
    static let formatterForTimeZone = {(format: String, zone: TimeZone?) -> DateFormatter in
        let fmt = DateFormatter()
        fmt.locale = POSIX_LOCALE
        fmt.dateFormat = format
        fmt.timeZone = zone
        return fmt
    }
    
    class Regex: Recognizer {
        
        let regexes: [NSRegularExpression]
        
        init(_ patterns: [String]) {
            self.regexes = patterns.map {p in try! NSRegularExpression(pattern: p, options: [])}
        }
        
        func tryToRecognize(_ s: String) -> RecognizerResult {
            for regex in regexes {
                if let match = regex.firstMatch(in: s, options: [NSRegularExpression.MatchingOptions.anchored], range: NSMakeRange(0, s.count)) {
                    if let token = createToken(regex, match, s) {
                        return (remainder: calculateRemainder(match, s), token: token)
                    }
                }
            }
            return nil
        }
        
        func createToken(_ regex: NSRegularExpression, _ match: NSTextCheckingResult, _ s: String) -> Token? {
            return nil
        }
        
        func calculateRemainder(_ match: NSTextCheckingResult, _ s: String) -> String {
            return String(s[s.index(s.startIndex, offsetBy:match.range.length)...])
        }
    }
    
    class Constant: Regex {
        let tokenGenerator: () -> Token
        
        init(_ pattern: String, _ tokenGenerator: @escaping () -> Token) {
            self.tokenGenerator = tokenGenerator
            super.init([pattern])
        }
        
        override func createToken(_ regex: NSRegularExpression, _ match: NSTextCheckingResult, _ s: String) -> Token? {
            return tokenGenerator()
        }
    }
    
    class Operator: Regex {
        
        init() {
            super.init(["([+*/@.-])[^0-9]"])
        }
        
        override func createToken(_ regex: NSRegularExpression, _ match: NSTextCheckingResult, _ s: String) -> Token? {
            return .Operator(String(s[s.startIndex ..< s.index(after: s.startIndex)]))
        }
        
        override func calculateRemainder(_ match: NSTextCheckingResult, _ s: String) -> String {
            return String(s[s.index(after: s.startIndex)...])
        }
    }
    
    class Duration: Regex {
        
        init() {
            // Allow up to eight digits so that you can have a complete day in milliseconds. This means that the
            // output of any <duration> . d can be parsed.
            super.init(["([1-9][0-9]{0,7})(d|h|m(?!s)|s|ms)"])
        }
        
        override func createToken(_ regex: NSRegularExpression, _ match: NSTextCheckingResult, _ s: String) -> Token? {
            if let value = Int(String(s[s.startIndex ..< s.index(s.startIndex, offsetBy: match.range(at: 1).length)])) {
                let units = String(s[s.index(s.startIndex, offsetBy: match.range(at: 1).length) ..< s.index(s.startIndex, offsetBy: match.range.length)])
                switch units {
                case "d":
                    return .MillisDuration(value*24*60*60*1000)
                case "h":
                    return .MillisDuration(value*60*60*1000)
                case "m":
                    return .MillisDuration(value*60*1000)
                case "s":
                    return .MillisDuration(value*1000)
                case "ms":
                    return .MillisDuration(value)
                default:
                    return nil;
                }
            } else {
                return nil
            }
        }
    }
    
    class Text: Regex {
        let tokenGenerator: (String) -> Token?
        
        init(_ pattern: String, _ tokenGenerator: @escaping (String) -> Token?) {
            self.tokenGenerator = tokenGenerator
            super.init([pattern])
        }
        
        override func createToken(_ regex: NSRegularExpression, _ match: NSTextCheckingResult, _ s: String) -> Token? {
            return tokenGenerator(matchingString(match, s))
        }
    }
    
    class Identifier: Text {
        
        init() {
            super.init("[a-zA-Z][0-9a-zA-Z]*", {s in .Identifier(s)})
        }
    }
    
    class Integer: Text {
        
        init() {
            super.init("-?[1-9]\\d{0,8}", {s in Int(s).map {i in .Int(i)}})
        }
    }
    
    class Unknown: Text {
        
        init() {
            super.init("\\S+", {s in .Unknown(s)})
        }
    }
    
    class QuotedString: Regex {
        
        init(_ pattern: String) {
            super.init([pattern])
        }
        
        override func createToken(_ regex: NSRegularExpression, _ match: NSTextCheckingResult, _ s: String) -> Token? {
            return .String(String(s[s.index(after: s.startIndex) ..< s.index(s.startIndex, offsetBy: match.range.length - 1)]))
        }
    }
    
    class Timestamp: Regex {
        
        let convertToSeconds: (Double) -> Double
        
        init(_ pattern: String, convertToSeconds: @escaping (Double) -> Double) {
            self.convertToSeconds = convertToSeconds;
            super.init([pattern])
        }
        
        override func createToken(_ regex: NSRegularExpression, _ match: NSTextCheckingResult, _ s: String) -> Token? {
            return Double(matchingString(match, s)).map {d in .DateTime(Date(timeIntervalSince1970: convertToSeconds(d)), true)}
        }
    }
    
    // Format patterns defined http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
    class Dates: Regex {
        typealias FormatterSpec = (String, includesTimeZone: Bool)
        typealias FormatterDefinition = (DateFormatter, includesTimeZone: Bool)
        
        let formatters: [FormatterDefinition]
        
        init(regularExpressions patterns: [String], dateFormats: [FormatterSpec]) {
            formatters = dateFormats.map {f in (formatterForTimeZone(f.0, TimeZone.current), includesTimeZone: f.includesTimeZone)}
            super.init(patterns)
        }
        
        init(regularExpressions patterns: [String], formatters: [FormatterDefinition]) {
            self.formatters = formatters
            super.init(patterns)
        }
        
        override func createToken(_ regex: NSRegularExpression, _ match: NSTextCheckingResult, _ s: String) -> Token? {
            let m = matchingString(match, s)
            for formatter in formatters {
                if let date = formatter.0.date(from: m) {
                    return .DateTime(date, formatter.includesTimeZone)
                }
            }
            return nil
        }
    }
    
    class SentryDates: Regex {
        
        let dateFormat = formatterForTimeZone("MMM dd yyyy hh:mm:ss a xxx", TimeZone.current)
        
        // Sentry date format         "Sep 29, 2017 2:00:23 PM UTC"
        // Another sentry date format "Feb. 5, 2018, 7:19:18 p.m. UTC"
        init() {
            super.init(["([JFMASOND][aepuco][nbrynlgptvc])\\.? (\\d{1,2}), (\\d{4}),? (\\d{1,2}:\\d{2}:\\d{2}) (?i:([ap]\\.?m\\.?)) (\\S{3})"])
        }
        
        override func createToken(_ regex: NSRegularExpression, _ match: NSTextCheckingResult, _ s: String) -> Token? {
            let m = matchingString(match, s)
            let reformattedDate = regex.stringByReplacingMatches(in: m, options: [], range: NSMakeRange(0, m.count), withTemplate: "$1 $2 $3 $4 $5 $6")
                .replacingOccurrences(of: "a.m.", with: "AM")
                .replacingOccurrences(of: "p.m.", with: "PM")
            if let date = dateFormat.date(from: reformattedDate) {
                return .DateTime(date, true)
            }
            return nil
        }
    }
    
    class KibanaDates: Regex {
        
        let removeOrdinalsLeadingMonth = try! NSRegularExpression(pattern: "([yhletr]\\s+[0-9]{1,2})((st)|(nd)|(rd)|(th))(\\s+\\d)", options: [])
        let dateFormat = formatterForTimeZone("MMM dd yyyy',' HH:mm:ss.SSS", TimeZone.current)
        
        // June 17th 2017, 12:00:03.000
        // TODO - Check assumption that timezone is current.
        init() {
            super.init(["(\\S+[yhletr]\\s+[0-9]{1,2})((st)|(nd)|(rd)|(th))(\\s+\\d{4}), \\d{2}:\\d{2}:\\d{2}\\.\\d{3}"])
        }
        
        override func createToken(_ regex: NSRegularExpression, _ match: NSTextCheckingResult, _ s: String) -> Token? {
            let m = matchingString(match, s)
            let reformattedDate = removeOrdinalsLeadingMonth.stringByReplacingMatches(in: m, options: [], range: NSMakeRange(0, m.count), withTemplate: "$1$7")
            if let date = dateFormat.date(from: reformattedDate) {
                return .DateTime(date, true)
            }
            return nil
        }
    }
    
    class BambooDates: Dates {
        
        // Date format that bamboo uses. Assumes UTC if no timezone.
        // "21-Jul-2017 03:02:26"
        // "20-Jul-2017 22:02:26 -05:00"
        // "21-Jul-2017 03:02:26 Z"
        // Bamboo "completed" date
        // 13 Feb 2018, 5:14:39 PM
        init() {
            super.init(regularExpressions: ["\\d{1,2}-[JFMASOND][aepuco][nbrynlgptvc][a-z]?-\\d{4} \\d{1,2}:\\d{2}:\\d{2}( (Z|([+-]\\d{2}:\\d{2})))?", "\\d{1,2} [JFMASOND][aepuco][nbrynlgptvc] \\d{4}, \\d{1,2}:\\d{2}:\\d{2} [AP]M"],
                       formatters: [(formatterForTimeZone("d-MMM-yyyy HH:mm:ss XXX", TimeZone.current), includesTimeZone: true),
                                    (formatterForTimeZone("d-MMM-yyyy HH:mm:ss", TimeZone.init(identifier: "UTC")), includesTimeZone: true),
                                    (formatterForTimeZone("dd MMM yyyy, hh:mm:ss a", TimeZone.current), includesTimeZone: false)])
        }
    }
    
    class DatesWithReformat: Dates {
        
        let template: String
        
        init(regularExpressions: [String], dateFormats: [FormatterSpec], template: String) {
            self.template = template
            super.init(regularExpressions: regularExpressions, dateFormats: dateFormats)
        }
        
        override func createToken(_ regex: NSRegularExpression, _ match: NSTextCheckingResult, _ s: String) -> Token? {
            let m = matchingString(match, s)
            let reformattedDate = regex.stringByReplacingMatches(in: m, options: [], range: NSMakeRange(0, m.count), withTemplate: template)
            for formatter in formatters {
                if let date = formatter.0.date(from: reformattedDate) {
                    return .DateTime(date, formatter.includesTimeZone)
                }
            }
            return nil
        }
    }
    
    class ISODates: DatesWithReformat {
        
        // Standard ISO format. TimeZone is optional.
        // 2017-06-17T17:00:03+00:00
        // 2017-06-17T19:00:03Z
        // 2017-08-15 17:28:34 +0000
        // 2017-08-15 17:28:34 Z
        
        init() {
            super.init(regularExpressions: ["(\\d{4}-\\d{2}-\\d{2})(?:T|\\s+)(\\d{2}:\\d{2}:\\d{2})\\s*([+-](\\d{4}|(\\d{2}:\\d{2})))", "(\\d{4}-\\d{2}-\\d{2})(?:T|\\s+)(\\d{2}:\\d{2}:\\d{2})(?:\\s*(Z))?"],
                       dateFormats: [("yyyy-MM-dd'T'HH:mm:ss XXXXX", includesTimeZone: true), ("yyyy-MM-dd'T'HH:mm:ss", includesTimeZone: false)],
                       template: "$1T$2 $3")
        }
    }
    
    class ISODatesWithMillis: DatesWithReformat {
        
        // Standard ISO format with milliseconds. May have timezone.
        // 2017-08-15T12:28:34.395-05:00
        // 2017-09-06T20:05:54.000Z git timestamp from version string.
        // 2017-08-15 17:28:34.456 +0000
        // 2018-02-07 20:05:36,501
        init() {
            super.init(regularExpressions: ["(\\d{4}-\\d{2}-\\d{2})(?:T|\\s+)(\\d{2}:\\d{2}:\\d{2})(?:\\.|,)(\\d{3})\\s*([+-](\\d{4}|(?:\\d{2}:\\d{2})))", "(\\d{4}-\\d{2}-\\d{2})(?:T|\\s+)(\\d{2}:\\d{2}:\\d{2})(?:\\.|,)(\\d{3})(?:\\s*(Z))?"],
                       dateFormats: [("yyyy-MM-dd'T'HH:mm:ss.SSS XXXXX", includesTimeZone: true), ("yyyy-MM-dd'T'HH:mm:ss.SSS", includesTimeZone: false)],
                       template: "$1T$2.$3 $4")
        }
    }
}
