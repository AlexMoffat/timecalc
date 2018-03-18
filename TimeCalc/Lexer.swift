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

public enum Token: Equatable {
    case Whitespace
    case Comment(String)
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

@available(OSX 10.13, *)
class Lexer {
    
    // Recognizers need to be ordered here so that if recognizer A recognizes the prefix of a pattern recognized by B
    // B comes before A in the list.
    let recongizers: [Recognizer] = [
        Recognizers.Constant("[ \t]+",    {.Whitespace}),
        Recognizers.Comment(),
        Recognizers.Constant("\r?\n",     {.Newline}),
        Recognizers.Constant("let",       {.Let}),
        Recognizers.Constant("=",         {.Assign}),
        Recognizers.Constant("\\(",       {.OpenParen}),
        Recognizers.Constant("\\)",       {.CloseParen}),
        
        // Operators like + - @ and .
        Recognizers.Operator(),
        
        // Durations. For example 2d 4h 10s is 2 days, 4 hours and 10 seconds. Each space separated item is a separate duration.
        Recognizers.Duration(),
        
        Recognizers.JavaDuration(),
        
        // Standard ISO format with milliseconds. May have timezone.
        // 2017-08-15T12:28:34.395-05:00
        // 2017-09-06T20:05:54.000Z git timestamp from version string.
        // 2017-08-15 17:28:34.456 +0000
        // 2018-02-07 20:05:36,501
        Recognizers.ISODatesWithMillis(),
        
        // Standard ISO format. TimeZone is optional.
        // 2017-06-17T17:00:03+00:00
        // 2017-06-17T19:00:03Z
        // 2017-08-15 17:28:34 +0000
        // 2017-08-15 17:28:34 Z
        Recognizers.ISODates(),
        
        // Finatra access logging filter
        // 14/Feb/2018:14:39:14 +0000
        Recognizers.FinatraAccessLogDates(),
        
        // A date from jira
        // 06/Feb/18 8:38 AM
        Recognizers.JiraDates(),
        
        // Twitter API format
        // "Tue Sep 19 15:04:28 +0000 2017"
        // "EEE MMM dd HH:mm:ss ZZZ yyyy"
        Recognizers.TwitterDates(),
        
        // Cookie expiry date as it appeared in some logging messages
        // "Fri, 14 Feb 2020 14:39:13 UTC"
        // Similar but with dashes
        // "Thu, 31-Jan-2019 23:57:29 GMT"
        Recognizers.CookieExpiryDates(),
        
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
        
        // Just a date with no timezone
        // 2017-08-15
        Recognizers.PlainDates(),
        
        // Date with month first
        // July 31 2018 or June 25, 2018
        Recognizers.FullMonthPlainDates(),
        
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
