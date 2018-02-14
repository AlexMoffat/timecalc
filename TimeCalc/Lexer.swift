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
    // True if timezone specified in format used to parse date
    case DateTime(Date, Bool)
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

class Lexer {
    
    let recongizers: [Recognizer] = [
        Recognizers.Constant("[ \t]+",    {.Whitespace}),
        Recognizers.Constant("#[^\r\n]*", {.Whitespace}),
        Recognizers.Constant("\r?\n",     {.Newline}),
        Recognizers.Constant("let",       {.Let}),
        Recognizers.Constant("=",         {.Assign}),
        Recognizers.Constant("\\(",       {.OpenParen}),
        Recognizers.Constant("\\)",       {.CloseParen}),
        
        // Operators like + - @ and .
        Recognizers.Operator(),
        
        // Durations. For example 2d 4h 10s is 2 days, 4 hours and 10 seconds. Each space separated item is a separate duration.
        Recognizers.Duration(),
        
        Recognizers.ISODatesWithMillis(),
        
        Recognizers.ISODates(),
        
        // Finatra access logging filter
        // 14/Feb/2018:14:39:14 +0000
        Recognizers.Dates(
            regularExpressions: ["\\d{2}/[JFMASOND][aepuco][nbrynlgptvc]/\\d{4}:\\d{2}:\\d{2}:\\d{2}\\s+[+-]\\d{4}"],
            dateFormats: [("dd/MMM/yyyy:HH:mm:ss XXX", includesTimeZone: true)]),
        
        // A date from jira
        // 06/Feb/18 8:38 AM
        Recognizers.Dates(
            regularExpressions: ["\\d{2}/[JFMASOND][aepuco][nbrynlgptvc]/\\d{2} \\d{1,2}:\\d{2} [AP]M"],
            dateFormats: [("dd/MMM/yy hh:mm a", includesTimeZone: false)]),
        
        // Just a date with no timezone
        // 2017-08-15
        Recognizers.Dates(regularExpressions: ["\\d{4}-\\d{2}-\\d{2}"], dateFormats: [("yyyy-MM-dd", includesTimeZone: false)]),
        
        // Twitter API format
        // "Tue Sep 19 15:04:28 +0000 2017"
        // "EEE MMM dd HH:mm:ss ZZZ yyyy"
        Recognizers.Dates(
            regularExpressions: ["[MTWFS]\\S{2} [JFMASOND]\\S{2} \\d{1,2} \\d{2}:\\d{2}:\\d{2} [+-]\\d{4} \\d{4}"],
            dateFormats: [("EEE MMM dd HH:mm:ss XXX yyyy", includesTimeZone: true)]),
        
        // Cookie expiry date as it appeared in some logging messages
        // "Fri, 14 Feb 2020 14:39:13 UTC"
        // Similar but with dashes
        // "Thu, 31-Jan-2019 23:57:29 GMT"
        Recognizers.DatesWithReformat(
            regularExpressions: ["([MTWFS]\\S{2}),? (\\d{1,2})[ -]([JFMASOND][aepuco][nbrynlgptvc])[ -](\\d{4}) (\\d{2}:\\d{2}:\\d{2}) (\\S{3})"],
            dateFormats: [("EEE dd MMM yyyy HH:mm:ss z", includesTimeZone: true)],
            template: "$1 $2 $3 $4 $5 $6"),
        
        // Sentry
        // "Sep 29, 2017 2:00:23 PM UTC"
        // "Feb. 5, 2018, 7:19:18 p.m. UTC"
        Recognizers.SentryDates(),
        
        // Kibana
        // June 17th 2017, 12:00:03.000
        Recognizers.KibanaDates(),
        
        // Bamboo
        // 20-Jul-2017 22:02:26
        Recognizers.BambooDates(),
        
        // 1504742693764001 (cassandra cli timestamp) microseconds. These are in UTC
        Recognizers.Timestamp("\\d{16}", convertToSeconds: {d in d / 1000000}),
        // 1499212382123 (date in milliseconds) microseconds. These are in UTC
        Recognizers.Timestamp("\\d{13}", convertToSeconds: {d in d / 1000}),
        // 1499212382.123 (date in seconds with optional fraction. Mainly to support jackson serialization of java Interval)
        Recognizers.Timestamp("\\d{10}(\\.\\d{1,9})?", convertToSeconds: {d in d}),
        
        Recognizers.QuotedString("\"([^\"\r\n]*)\""),
        Recognizers.QuotedString("'([^'\r\n]*)'"),
        Recognizers.Identifier(),
        Recognizers.Integer(),
        Recognizers.Unknown()
    ]
    
    public func tokenize(_ input: String) -> [Token] {
        var tokens = [Token]()
        var remaining = input
        
        while (remaining.count > 0) {
            var matched = false
            
            for recognizer in recongizers {
                if let result = recognizer.tryToRecognize(remaining) {
                    if result.token != .Whitespace {
                        tokens.append(result.token)
                    }
                    remaining = result.remainder
                    matched = true
                    break
                }
            }
            
            if !matched {
                let index = remaining.index(after: remaining.startIndex)
                tokens.append(.Unknown(String(remaining[..<index])))
                remaining = String(remaining[index...])
            }
        }
        
        return tokens
    }
}
