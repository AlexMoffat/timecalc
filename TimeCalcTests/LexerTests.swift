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

import XCTest
@testable import TimeCalc

@available(OSX 10.13, *)
class LexerTests: XCTestCase {

    var lexer: Lexer = Lexer()
    
    func testLexer() {
        cmp([Token.Newline], "  \n");
        cmp([Token.Comment("# a comment  "), Token.Newline], "  # a comment  \n");
        cmp([Token.Let], "let ");
        cmp([Token.Assign], "= ")
        cmp([Token.Int(12)], "12")
        cmp([Token.Int(-2)], "-2")
        cmp([Token.Identifier("x")], "x")
        cmp([Token.Identifier("dog")], "dog")
        cmp([Token.String("dog")], "'dog'")
        cmp([Token.String("cat")], "\"cat\"")
        cmp([Token.String("")], "''")
        cmp([Token.String("")], "\"\"")
        cmp([Token.Identifier("i1")], "i1")
        cmp([Token.OpenParen, Token.Unknown("0a"), Token.CloseParen], "( 0a )")
        cmp([Token.Int(3), Token.Operator("+"), Token.Int(5)], "3 + 5")
        cmp([Token.Int(2), Token.Operator("+")], "2 + ")
        cmp([Token.Int(2), Token.Operator("+")], "2 +")
        cmp([Token.Int(3), Token.Operator("-"), Token.Int(-5)], "3 - -5")
        cmp([Token.Int(3), Token.Operator("-"), Token.Identifier("Z")], "3 -Z")
        cmp([Token.Int(5), Token.Operator("-"), Token.Identifier("Z")], "5 - Z")
        
        // Lexer - Timezones
        cmp([Token.Operator("@"), Token.Identifier("UTC")], "@ UTC")
        cmp([Token.Operator("@"), Token.String("UTC")], "@ \"UTC\"")
        cmp([Token.Operator("@"), Token.String("UTC")], "@ 'UTC'")
        cmp([Token.Operator("@"), Token.String("America/Los_Angeles")], "@   America/Los_Angeles")
        cmp([Token.Operator("@"), Token.String("America/Kentucky/Monticello"), Token.Int(15)], "@ America/Kentucky/Monticello 15")
        
        // Lexer - Duration
        cmp([Token.MillisDuration(3*60*60*1000), Token.MillisDuration(4*1000), Token.MillisDuration(342), Token.Identifier("aa")], "3h 4s 342ms aa")
        cmp([Token.MillisDuration(25*60*1000), Token.MillisDuration(-5*1000)], "25m -5s")
        
        // Lexer - Standard iso format with milliseconds.
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1504728354.045), true)],"2017-09-06T20:05:54.045Z")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1504746354.045), false)],"2017-09-06T20:05:54.045")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1504746354.045), true)],"2017-09-06T20:05:54.045-05:00")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1502818114.395), true)],"2017-08-15T12:28:34.395-05:00")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1502818114.395), true)],"2017-08-15T12:28:34,395-05:00")
        // Lexer - ISO format with milliseconds but with spaces between date, time and timezone
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1502818114.395), true)], "2017-08-15 12:28:34.395 -0500")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1497726003.340), true)], "2017-06-17 12:00:03.340 -07:00")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1497726003.340), true), Token.Newline], "2017-06-17T12:00:03,340 -07:00\n")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1497718803.340), false), Token.Newline], "2017-06-17T12:00:03,340\n")
        
        // Lexer - Standard iso format.
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1497744003), false)], "2017-06-17T19:00:03")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1497744003), true)], "2017-06-17T19:00:03-05:00")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1497726003), true)], "2017-06-17T19:00:03Z")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1497718803), true)], "2017-06-17T17:00:03+00:00")
        // Lexer - ISO format but with spaces between date, time and timezone.
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1502818114), true)], "2017-08-15 17:28:34 +0000")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1502818114), true)], "2017-08-15 17:28:34 Z")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1505686719), false)], "2017-09-17 17:18:39")
        
        // Lexer - Just a date
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1504414800), false)], "2017-09-03")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1533013200), false)], "July 31, 2018")
        
        // Lexer - Date format kibana uses.
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1497718803), true)], "June 17th 2017, 12:00:03.000")
        
        // Lexer - Twitter API format
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1505833468), true)], "Tue Sep 19 15:04:28 +0000 2017")
        
        // Lexer - Cookie expires date
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1581691153), true)], "Fri, 14 Feb 2020 14:39:13 UTC")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1548979049), true)], "Thu, 31-Jan-2019 23:57:29 GMT")
        
        // Lexer - Sentry date format "Sep 29, 2017 2:00:23 PM UTC"
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1506693623), true)], "Sep 29, 2017 2:00:23 PM UTC")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1506650423), true)], "Sep 29, 2017 2:00:23 AM UTC")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1517858358), true)], "Feb. 5, 2018, 7:19:18 p.m. UTC")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1519072439), true)], "Feb 19, 2018 8:33:59 PM UTC")
        
        // Lexer - Date format that bamboo uses. Assumes UTC if no timezone.
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1500606146), true)], "21-Jul-2017 03:02:26")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1500606146), true)], "20-Jul-2017 22:02:26 -05:00")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1500606146), true)], "21-Jul-2017 03:02:26 Z")
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1506650423), false)], "28 Sep 2017, 9:00:23 PM")
        
        // Lexer - Finatra access logging filter
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1518619154), true)], "14/Feb/2018:14:39:14 +0000")
        
        // Lexer - A date from jira
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1517927880), false)], "06/Feb/18 8:38 AM")
        
        // Lexer - Java duration
        // PT7776000S
        cmp([Token.MillisDuration(7776000 * 1000)], "PT7776000S")
        // PT2H3M
        cmp([Token.MillisDuration((2 * 60 + 3) * 60 * 1000)], "PT2H3M")
        // P1DT10S
        cmp([Token.MillisDuration((24 * 60 * 60 + 10) * 1000)], "P1DT10S")
        
        // Lexer - Seconds
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1497718803), true)], "1497718803")
        // Lexer - Seconds with fraction mainly to support java interval serialized with jackson
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1502713067.720000000), true)], "1502713067.720000000")
        // Lexer - milliseconds
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1497718803.876), true)], "1497718803876")
        // Lexer - microseconds
        cmp([Token.DateTime(Date(timeIntervalSince1970: 1504742693.764001), true)], "1504742693764001")
        
        cmp([Token.Identifier("abc"), Token.Int(456)], "abc 456")
    }
    
    private func cmp(_ tokens: [Token], _ s: String) {
        XCTAssertEqual(tokens, lexer.tokenize(s), s)
    }
}
