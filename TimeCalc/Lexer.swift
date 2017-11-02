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

public enum Token {
    case Whitespace
    case Newline
    case Let
    case Assign
    case OpenParen
    case CloseParen
    case Operator(String)
    case MillisDuration(Int)
    case DateTime(Date)
    case Identifier(String)
    case Int(Int)
    case String(String)
    case Unknown(String)
}

extension Token: Equatable {
    public static func ==(lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case (.Whitespace, .Whitespace) : return true
        case (.Newline, .Newline) : return true
        case (.Let, .Let) : return true
        case (.Assign, .Assign) : return true
        case (.OpenParen, .OpenParen) : return true
        case (.CloseParen, .CloseParen) : return true
        case let (.Operator(l), .Operator(r)) : return l == r
        case let (.MillisDuration(l), .MillisDuration(r)) : return l == r
        case let (.DateTime(l), .DateTime(r)) : return l == r
        case let (.Identifier(l), .Identifier(r)) : return l == r
        case let (.Int(l), .Int(r)) : return l == r
        case let (.String(l), .String(r)) : return l == r
        case let (.Unknown(l), .Unknown(r)) : return l == r
        default : return false
        }
    }
}

// Take a regular expression match and the complete string the match was found in and return a token if one can be built.
typealias TokenGenerator = (NSTextCheckingResult, String) -> Token?

let POSIX_LOCALE = Locale(identifier: "en_US_POSIX")

let formatterForTimeZone = {(zone: TimeZone?, format: String) -> DateFormatter in
    let fmt = DateFormatter()
    fmt.locale = POSIX_LOCALE
    fmt.dateFormat = format
    fmt.timeZone = zone
    return fmt
}

// Map from a regular expression to the generator to try if the expression matches. The first matching expression
// with a generator that returns a token is used.
// Format patterns defined http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
let tokenGenerators: [(NSRegularExpression, TokenGenerator)] = {() -> [(NSRegularExpression, TokenGenerator)] in
    
    let match = {(r: NSTextCheckingResult, s: String) -> String in (s as NSString).substring(with: r.range(at: 1))}
    
    let toDuration: TokenGenerator = {r, s in
        if let value = Int((s as NSString).substring(with: r.range(at: 2))) {
            let units = (s as NSString).substring(with: r.range(at: 3))
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
            return .Unknown(match(r,s))
        }
    }
    
    // Standard iso format.
    let isoDateFormat = formatterForTimeZone(TimeZone.current, "yyyy-MM-dd'T'HH:mm:ssZZZZZ")
    let isoDateFormatNoZone = formatterForTimeZone(TimeZone.current, "yyyy-MM-dd'T'HH:mm:ss")
    let toDateFromISO: TokenGenerator = {r, s in
        let v = match(r, s)
        return isoDateFormat.date(from: v).map({d in .DateTime(d)}) ?? isoDateFormatNoZone.date(from: v).map({d in .DateTime(d)})
    }
    
    // Standard iso format with milliseconds.
    let isoDateFormatWithMillis = formatterForTimeZone(TimeZone.current, "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ")
    let isoDateFormatWithMillisNoZone = formatterForTimeZone(TimeZone.current, "yyyy-MM-dd'T'HH:mm:ss.SSS")
    let toDateFromISOWithMillis: TokenGenerator = {r, s in
        let v = match(r, s)
        return isoDateFormatWithMillis.date(from: v).map({d in .DateTime(d)}) ?? isoDateFormatWithMillisNoZone.date(from: v).map({d in .DateTime(d)})
    }
    
    // ISO format but with spaces between date, time and timezone.
    let isoDateFormatWithSpaces = formatterForTimeZone(TimeZone.current, "yyyy-MM-dd HH:mm:ss ZZZ")
    let isoDateFormatWithSpacesNoZone = formatterForTimeZone(TimeZone.current, "yyyy-MM-dd HH:mm:ss")
    let toDateFromISOWithSpaces: TokenGenerator = {r, s in
        isoDateFormatWithSpaces.date(from: match(r, s)).map({d in .DateTime(d)}) ?? isoDateFormatWithSpacesNoZone.date(from: match(r, s)).map({d in .DateTime(d)})
    }
    
    // ISO format with milliseconds but with spaces between date, time and timezone 
    let isoDateFormatWithSpacesAndMillis = formatterForTimeZone(TimeZone.current, "yyyy-MM-dd HH:mm:ss.SSS ZZZ")
    let toDateFromISOWithSpacesAndMillis: TokenGenerator = {r, s in
        isoDateFormatWithSpacesAndMillis.date(from: match(r, s)).map({d in .DateTime(d)})
    }
    
    // Just a date
    let justADateFormat = formatterForTimeZone(TimeZone.current, "yyyy-MM-dd")
    let justADate: TokenGenerator = {r, s in
        justADateFormat.date(from: match(r, s)).map({d in .DateTime(d)})
    }
    
    // Date format kibana uses.
    let kibanaDateFormat = formatterForTimeZone(TimeZone.current, "MMM dd yyyy',' HH:mm:ss.SSS")
    let removeOrdinalsLeadingMonth = try! NSRegularExpression(pattern: "([yhletr]\\s+[0-9]{1,2})((st)|(nd)|(rd)|(th))(\\s+\\d)", options: [])
    let toDateFromKibana: TokenGenerator = {r, s in
        let mutable = NSMutableString(string: match(r, s))
        if removeOrdinalsLeadingMonth.replaceMatches(in: mutable, options: [], range: NSMakeRange(0, mutable.length), withTemplate: "$1$7") > 0 {
            return kibanaDateFormat.date(from: mutable as String).map({d in .DateTime(d)})
        } else {
            return nil
        }
    }
    
    // Date format that bamboo uses.
    let bambooDateFormat = formatterForTimeZone(TimeZone.current, "d-MMM-yyyy HH:mm:ss")
    let toDateFromBamboo: TokenGenerator = {r, s in
        bambooDateFormat.date(from: match(r, s)).map({d in .DateTime(d)})
    }
    
    let twitterDateFormat = formatterForTimeZone(TimeZone.current, "EEE MMM dd HH:mm:ss ZZZ yyyy")
    let toDateFromTwitter: TokenGenerator = {r, s in
        twitterDateFormat.date(from: match(r, s)).map({d in .DateTime(d)})
    }
    
    // Sentry date format "Sep 29, 2017 2:00:23 PM UTC"
    let sentryDateFormat = formatterForTimeZone(TimeZone.current, "MMM dd, yyyy hh:mm:ss a zzz")
    let toDateFromSentry: TokenGenerator = {r, s in
        sentryDateFormat.date(from: match(r, s)).map({d in .DateTime(d)})
    }
    
    let toString: TokenGenerator = {r, s in
        let theMatch = match(r, s)
        let start = theMatch.index(theMatch.startIndex, offsetBy: 1)
        let end = theMatch.index(theMatch.endIndex, offsetBy: -1)
        return .String(String(theMatch[start ..< end]))
    }

    // Order matters here. You want longer matches for dates etc to come first.
    let tokenDefinitions: [(String, TokenGenerator)] = [
        
        ("([ \t]+)",      {_,_  in .Whitespace}),
        ("(#[^\r\n]*)",   {_,_  in .Whitespace}),
        ("(\r?\n)",       {_,_  in .Newline}),
        ("(let)",         {_,_  in .Let}),
        ("(=)",           {_,_  in .Assign}),
        ("(\\()",         {_,_  in .OpenParen}),
        ("(\\))",         {_,_  in .CloseParen}),
        ("([+*/@.-])[^0-9]",      {r, s in .Operator(match(r, s))}),
        ("(([1-9][0-9]{0,3})(d|h|m(?!s)|s|ms))", toDuration),
        // 2017-08-15T12:28:34.395-05:00
        ("(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}[+-]\\d{2}:\\d{2})", toDateFromISOWithMillis),
        // 2017-09-06T20:05:54.000Z git timestamp from version string.
        ("(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z?)", toDateFromISOWithMillis),
        // 2017-06-17T17:00:03+00:00
        ("(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}[+-]\\d{2}:\\d{2})", toDateFromISO),
        // 2017-06-17T19:00:03Z
        ("(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z?)", toDateFromISO),
        // 2017-08-15 17:28:34.456 +0000
        ("(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}\\.\\d{3} [+-](\\d{4}|(\\d{2}:\\d{2})))", toDateFromISOWithSpacesAndMillis),
        // 2017-08-15 17:28:34 +0000 (zone is optional)
        ("(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}(\\s+[+-]\\d{4})?)", toDateFromISOWithSpaces),
        // 2017-08-15
        ("(\\d{4}-\\d{2}-\\d{2})", justADate),
        // "Tue Sep 19 15:04:28 +0000 2017" twitter api format
        // "EEE MMM dd HH:mm:ss ZZZ yyyy"
        ("([MTWFS]\\S{2} [JFMASOND]\\S{2} \\d{1,2} \\d{2}:\\d{2}:\\d{2} [+-]\\d{4} \\d{4})", toDateFromTwitter),
        // Sentry date format "Sep 29, 2017 2:00:23 PM UTC"
        ("([JFMASOND]\\S{2} \\d{1,2}, \\d{4} \\d{1,2}:\\d{2}:\\d{2} ((AM)|(PM)) \\S{3})", toDateFromSentry),
        // June 17th 2017, 12:00:03.000
        ("((\\S+[yhletr]\\s+[0-9]{1,2})((st)|(nd)|(rd)|(th))(\\s+\\d{4}), \\d{2}:\\d{2}:\\d{2}\\.\\d{3})", toDateFromKibana),
        // 20-Jul-2017 22:02:26
        ("(\\d{1,2}-[JFMASOND][aepuco][nbrynlgptvc][a-z]?-\\d{4} \\d{1,2}:\\d{2}:\\d{2})", toDateFromBamboo),
        // 1504742693764001 (cassandra cli timestamp) microseconds
        ("(\\d{16})", {r, s in Double(match(r, s)).map({d in .DateTime(Date(timeIntervalSince1970: (d / 1000000)))})}),
        // 1499212382123 (date in milliseconds)
        ("(\\d{13})", {r, s in Double(match(r, s)).map({d in .DateTime(Date(timeIntervalSince1970: (d / 1000)))})}),
        // 1499212382 (date in seconds)
        ("(\\d{10})", {r, s in Double(match(r, s)).map({d in .DateTime(Date(timeIntervalSince1970: d))})}),
        ("(\"([^\"\r\n]*)\")", toString),
        ("('([^'\r\n]*)')", toString),
        ("([a-zA-Z][0-9a-zA-Z]*)", {r, s in .Identifier(match(r, s))}),
        ("(-?[1-9]\\d{0,8})", {r, s in Int(match(r, s)).map({i in .Int(i)})}),
        ("(\\S+)", {r, s in .Unknown(match(r, s))})
        
    ]
    
    let rgx = {(p: (String, TokenGenerator)) -> (NSRegularExpression, TokenGenerator) in
        return (try! NSRegularExpression(pattern: "^\(p.0)", options: []), p.1)
    }
    
    return tokenDefinitions.map(rgx)
}()


class Lexer {
    let input: String
    
    init(input: String) {
        self.input = input
    }
    
    public func tokenize() -> [Token] {
        var tokens = [Token]()
        var content = input
        
        while (content.count > 0) {
            var matched = false
            
            for (pattern, generator) in tokenGenerators {
                if let match = pattern.firstMatch(in: content, options: [], range: NSMakeRange(0, content.count)) {
                    if let t = generator(match, content) {
                        if t != .Whitespace {
                            tokens.append(t)
                        }
                        content = String(content[content.index(content.startIndex, offsetBy:match.range(at: 1).length)...])
                        matched = true
                        break
                    }
                }
            }
            
            if !matched {
                let index = content.index(content.startIndex, offsetBy: 1)
                tokens.append(.Unknown(String(content[..<index])))
                content = String(content[index...])
            }
        }
        return tokens
    }
}
