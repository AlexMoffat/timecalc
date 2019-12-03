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

// The remaining string to continue to try and recognize tokens in and the token that was recognized.
typealias RecognizerResult = (remainder: String, tokens: [Token])?

protocol Recognizer {
    // See if this recognizer can recognize a token at the start of the string.
    func tryToRecognize(_ s: String) -> RecognizerResult
}

class Recognizers {
    
    private static let matchingString = {(match: NSTextCheckingResult, s: String) -> String in String(s[s.startIndex ..< s.index(s.startIndex, offsetBy: match.range.length)])}
    
    private static let MONTH_PREFIX_PATTERN = "[JFMASOND][aepueco][nbrylgptvc]";
    
    // Try to match the start of a String against one or more regular expressions. Call createToken for the first
    // one that matches. If a token is created then strip the match from the start of the string.
    class Regex: Recognizer {
        
        let regexes: [NSRegularExpression]
        
        init(_ patterns: [String]) {
            self.regexes = patterns.map {p in try! NSRegularExpression(pattern: p, options: [])}
        }
        
        func tryToRecognize(_ s: String) -> RecognizerResult {
            for regex in regexes {
                if let match = regex.firstMatch(in: s, options: [NSRegularExpression.MatchingOptions.anchored], range: NSMakeRange(0, s.count)) {
                    if let token = createToken(regex, match, s) {
                        return (remainder: calculateRemainder(match, s), tokens: [token])
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
    
    // If the pattern is recognized the token from the tokenGenerator is returned.
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
            super.init(["([+*/@-])([^0-9]|$)"])
        }
        
        override func createToken(_ regex: NSRegularExpression, _ match: NSTextCheckingResult, _ s: String) -> Token? {
            return .Operator(String(s[s.startIndex ..< s.index(after: s.startIndex)]))
        }
        
        override func calculateRemainder(_ match: NSTextCheckingResult, _ s: String) -> String {
            return String(s[s.index(after: s.startIndex)...])
        }
    }
    
    class ChooseTimezone: Regex {
        
        init() {
            // Identify only TimeZone identifiers that include a /. Others are lexed as Identifiers. Both String and Identifier values following
            // an @ are correctly handled by the Executor.
            super.init(["(@\\s+)([A-Za-z]+(?:/[A-Za-z_]+){1,2})"])
        }
        
        override func tryToRecognize(_ s: String) -> RecognizerResult {
            for regex in regexes {
                if let match = regex.firstMatch(in: s, options: [NSRegularExpression.MatchingOptions.anchored], range: NSMakeRange(0, s.count)) {
                    return (remainder: calculateRemainder(match, s), tokens: [Token.Operator("@"), Token.String(String(s[s.index(s.startIndex, offsetBy: match.range(at: 1).length) ..< s.index(s.startIndex, offsetBy: match.range.length)]))])
                }
            }
            return nil
        }
    }
    
    class Duration: Regex {
        
        // Allow up to eight digits so that you can have a complete day in milliseconds. This means that the
        // output of any <duration> . d can be parsed.
        init() {
            super.init(["(-?[1-9][0-9]{0,7})(d|h|m(?!s)|s|ms)"])
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
    
    @available(OSX 10.13, *)
    class JavaDuration: Regex {
        
        init() {
            super.init(["(?<negate>[-+]?)[Pp](?:(?<days>[-+]?[0-9]+)[Dd])?([Tt](?:(?<hours>[-+]?[0-9]+)[Hh])?(?:(?<minutes>[-+]?[0-9]+)[Mm])?(?:(?<seconds>[-+]?[0-9]+)(?:[.,](?<millis>[0-9]{0,3}))?[Ss])?)?"])
        }
        
        override func createToken(_ regex: NSRegularExpression, _ match: NSTextCheckingResult, _ s: String) -> Token? {
            
            let negate = (match.range(withName: "negate").location != NSNotFound) ? s[Range(match.range(withName: "negate"), in: s)!] == "-" : false
            let secondsDuration =
                extractMatch("days", match, s) * (24 * 60 * 60) +
                    extractMatch("hours", match, s) * (60 * 60) +
                    extractMatch("minutes", match, s) * 60 +
                    extractMatch("seconds", match, s)
            let millis: Int
            if match.range(withName: "millis").location != NSNotFound {
                var millisString = s[Range(match.range(withName: "millis"), in: s)!]
                for _ in 0..<(3 - millisString.count) {
                    millisString = millisString + "0"
                }
                millis = Int(millisString)!
            } else {
                millis = 0
            }
            let millisDuration = secondsDuration * 1000 + millis
            if negate {
                return .MillisDuration(-1 * millisDuration)
            } else {
                return .MillisDuration(millisDuration)
            }
        }
        
        func extractMatch(_ name: String, _ match: NSTextCheckingResult, _ s: String) -> Int {
            return (match.range(withName: name).location != NSNotFound) ? Int(s[Range(match.range(withName: name), in: s)!])! : 0
        }
    }
    
    // Create a token using the text matched by the regular expression.
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
    
    class Comment: Text {
        
        init() {
            super.init("#[^\r\n]*", {s in .Comment(s)})
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
    
    // A regular expression that recognizes a sequence of digits and a way to convert that to a number of seconds.
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
    
    // Format patterns for date formats are defined by
    // http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
    
    // Try each of the date formats against each of the strings matched by the regular expressions.
    // The first format that converts the string into a date is used.
    class Dates: Regex {
        typealias FormatterSpec = (String, includesTimeZone: Bool)
        typealias FormatterDefinition = (DateFormatter, includesTimeZone: Bool)
        
        let formatters: [FormatterDefinition]
        
        init(regularExpressions patterns: [String], dateFormats: [FormatterSpec]) {
            formatters = dateFormats.map {f in (Common.formatterForTimeZone(f.0, TimeZone.current), includesTimeZone: f.includesTimeZone)}
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
    
    // Adds a reformatting step to the Dates class. The template is used to generate the string passed to the
    // date formatters. This lets you remove unwanted punctuation and perform other reordering.
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
                    let nanos = match.range(withName: "nanos")
                    if nanos.location == NSNotFound {
                        return .DateTime(date, formatter.includesTimeZone)
                    } else {
                        if let nanosValue = Range(nanos, in: m).map({r in m[r]}).flatMap({s in Int(String(s))}) {
                            return .DateTime(date.addingTimeInterval(TimeInterval(nanosValue) / 1000000), formatter.includesTimeZone)
                        } else {
                            return .DateTime(date, formatter.includesTimeZone)
                        }
                    }
                }
            }
            return nil
        }
    }
    
    class SentryDates: Regex {
        
        let dateFormat = Common.formatterForTimeZone("MMM dd yyyy hh:mm:ss a xxx", TimeZone.current)
        
        // Sentry date format         "Sep 29, 2017 2:00:23 PM UTC"
        // Another sentry date format "Feb. 5, 2018, 7:19:18 p.m. UTC"
        init() {
            super.init(["(\(MONTH_PREFIX_PATTERN))\\.? (\\d{1,2}), (\\d{4}),? (\\d{1,2}:\\d{2}:\\d{2}) (?i:([ap]\\.?m\\.?)) (\\S{3})"])
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
        let dateFormat = Common.formatterForTimeZone("MMM dd yyyy',' HH:mm:ss.SSS", TimeZone.current)
        
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
            super.init(regularExpressions: ["\\d{1,2}-\(MONTH_PREFIX_PATTERN)[a-z]?-\\d{4} \\d{1,2}:\\d{2}:\\d{2}( (Z|([+-]\\d{2}:\\d{2})))?", "\\d{1,2} [JFMASOND][aepuco][nbrynlgptvc] \\d{4}, \\d{1,2}:\\d{2}:\\d{2} [AP]M"],
                       formatters: [(Common.formatterForTimeZone("d-MMM-yyyy HH:mm:ss XXX", TimeZone.current), includesTimeZone: true),
                                    (Common.formatterForTimeZone("d-MMM-yyyy HH:mm:ss", TimeZone.init(identifier: "UTC")), includesTimeZone: true),
                                    (Common.formatterForTimeZone("dd MMM yyyy, hh:mm:ss a", TimeZone.current), includesTimeZone: false)])
        }
    }
    
    class FinatraAccessLogDates: Dates {
        // Finatra access logging filter
        // 14/Feb/2018:14:39:14 +0000
        init() {
            super.init(
                regularExpressions: ["\\d{2}/\(MONTH_PREFIX_PATTERN)/\\d{4}:\\d{2}:\\d{2}:\\d{2}\\s+[+-]\\d{4}"],
                dateFormats: [("dd/MMM/yyyy:HH:mm:ss XXX", includesTimeZone: true)])
        }
    }
    
    class JiraDates: Dates {
        // A date from jira
        // 06/Feb/18 8:38 AM
        init() {
            super.init(regularExpressions: ["\\d{2}/\(MONTH_PREFIX_PATTERN)/\\d{2} \\d{1,2}:\\d{2} [AP]M"],
                       dateFormats: [("dd/MMM/yy hh:mm a", includesTimeZone: false)])
        }
    }
    
    class PlainDates: Dates {
        // Just a date with no timezone
        // 2017-08-15
        init() {
            super.init(regularExpressions: ["\\d{4}-\\d{2}-\\d{2}"],
                       dateFormats: [("yyyy-MM-dd", includesTimeZone: false)])
        }
    }
    
    class FullMonthPlainDates: DatesWithReformat {
        // Just a date with no timezone
        // July 31, 2018
        init() {
            super.init(regularExpressions: ["(\(MONTH_PREFIX_PATTERN)\\S{0,6})\\s+(\\d{2}),?\\s+(\\d{4})"],
                       dateFormats: [("MMM dd yyyy", includesTimeZone: false)],
                       template: "$1 $2 $3")
        }
    }
    
    class TwitterDates: Dates {
        // Twitter API format
        // "Tue Sep 19 15:04:28 +0000 2017"
        // "EEE MMM dd HH:mm:ss ZZZ yyyy"
        init() {
            super.init(regularExpressions: ["[MTWFS]\\S{2} \(MONTH_PREFIX_PATTERN) \\d{1,2} \\d{2}:\\d{2}:\\d{2} [+-]\\d{4} \\d{4}"],
                       dateFormats: [("EEE MMM dd HH:mm:ss XXX yyyy", includesTimeZone: true)])
        }
    }
    
    class ISODates: DatesWithReformat {
        // Standard ISO format. TimeZone is optional.
        // 2017-06-17T17:00:03 -05:00
        // 2017-06-17T17:00:03+00:00
        // 2017-06-17T19:00:03Z
        // 2017-08-15 17:28:34 +0000
        // 2017-08-15 17:28:34 Z
        // Regexp groups 1 (year), 2 (separator), 3 (month) and 4 (day) with separator of either - or /
        let yearMonthDay = "(\\d{4})([-/])(\\d{2})\\2(\\d{2})"
        // T or a space
        let dateTimeSeparator = "(?:T|\\s+)"
        // Regexp group 5 (hours mintes and seconds)
        let hoursMinutesSeconds = "(\\d{2}:\\d{2}:\\d{2})"
        init() {
            super.init(regularExpressions: [
                yearMonthDay + dateTimeSeparator + hoursMinutesSeconds + "\\s*([+-](\\d{4}|(\\d{2}:\\d{2})))",
                yearMonthDay + dateTimeSeparator + hoursMinutesSeconds + "(?:\\s*(Z))?"],
                       dateFormats: [
                        ("yyyy-MM-dd'T'HH:mm:ss XXXXX", includesTimeZone: true),
                        ("yyyy-MM-dd'T'HH:mm:ss", includesTimeZone: false)],
                       template: "$1-$3-$4T$5 $6")
        }
    }
    
    class ISODatesWithMillis: DatesWithReformat {
        // Standard ISO format with milliseconds. May have timezone.
        // 2017-08-15T12:28:34.395-05:00
        // 2017-09-06T20:05:54.000Z git timestamp from version string.
        // 2017-08-15 17:28:34.456 +0000
        // 2018-02-07 20:05:36,501
        // Regexp groups 1 (year), 2 (separator), 3 (month) and 4 (day) with separator of either - or /
        let yearMonthDay = "(\\d{4})([-/])(\\d{2})\\2(\\d{2})"
        // T or a space
        let dateTimeSeparator = "(?:T|\\s+)"
        // Regexp group 5 (hours minutes and seconds)
        let hoursMinutesSeconds = "(\\d{2}:\\d{2}:\\d{2})"
        // Regexp group 6 (milliseconds) and nanos/7 (optional nanoseconds)
        let millis = "(?:\\.|,)(\\d{3})(?<nanos>\\d{3})?"
        init() {
            super.init(regularExpressions: [
                yearMonthDay + dateTimeSeparator + hoursMinutesSeconds + millis + "\\s*([+-](\\d{4}|(?:\\d{2}:\\d{2})))",
                yearMonthDay + dateTimeSeparator + hoursMinutesSeconds + millis + "(?:\\s*(Z))?"],
                       dateFormats: [
                        ("yyyy-MM-dd'T'HH:mm:ss.SSS XXXXX", includesTimeZone: true),
                        ("yyyy-MM-dd'T'HH:mm:ss.SSS", includesTimeZone: false)],
                       template: "$1-$3-$4T$5.$6 $8")
        }
    }
    
    class CookieExpiryDates: DatesWithReformat {
        // Cookie expiry date as it appeared in some logging messages
        // "Fri, 14 Feb 2020 14:39:13 UTC"
        // Similar but with dashes
        // "Thu, 31-Jan-2019 23:57:29 GMT"
        init() {
            super.init(regularExpressions: ["([MTWFS]\\S{2}),? (\\d{1,2})[ -](\(MONTH_PREFIX_PATTERN))[ -](\\d{4}) (\\d{2}:\\d{2}:\\d{2}) (\\S{3})"],
                       dateFormats: [("EEE dd MMM yyyy HH:mm:ss z", includesTimeZone: true)],
                       template: "$1 $2 $3 $4 $5 $6")
        }
    }
}
