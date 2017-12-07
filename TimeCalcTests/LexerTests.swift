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

class LexerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        compare([Token.Newline], "  \n");
        compare([Token.Newline], "# a comment  \n");
        compare([Token.Let], "let ");
        compare([Token.Assign], "= ")
        compare([Token.Int(12)], "12")
        compare([Token.Int(-2)], "-2")
        compare([Token.Identifier("x")], "x")
        compare([Token.Identifier("dog")], "dog")
        compare([Token.String("dog")], "'dog'")
        compare([Token.String("dog")], "\"dog\"")
        compare([Token.String("")], "''")
        compare([Token.String("")], "\"\"")
        compare([Token.Identifier("i1")], "i1")
        compare([Token.OpenParen, Token.Unknown("0a"), Token.CloseParen], "( 0a )")
        compare([Token.Int(3), Token.Operator("+"), Token.Int(5)], "3 + 5")
        compare([Token.Int(3), Token.Operator("-"), Token.Int(-5)], "3 - -5")
        compare([Token.MillisDuration(3*60*60*1000), Token.MillisDuration(4*1000), Token.MillisDuration(342)], "3h 4s 342ms")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1504414800))], "2017-09-03")
        // Lexer - Standard iso format.
        compare([Token.DateTime(Date(timeIntervalSince1970: 1497744003))], "2017-06-17T19:00:03")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1497744003))], "2017-06-17T19:00:03-05:00")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1497726003))], "2017-06-17T19:00:03Z")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1497718803))], "2017-06-17T17:00:03+00:00")
        // Lexer - Standard iso format with milliseconds.
        compare([Token.DateTime(Date(timeIntervalSince1970: 1504728354.045))],"2017-09-06T20:05:54.045Z")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1504746354.045))],"2017-09-06T20:05:54.045")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1504746354.045))],"2017-09-06T20:05:54.045-05:00")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1502818114.395))],"2017-08-15T12:28:34.395-05:00")
        // Lexer - Date format kibana uses.
        compare([Token.DateTime(Date(timeIntervalSince1970: 1497718803))], "June 17th 2017, 12:00:03.000")
        // Lexer - Twitter API format
        compare([Token.DateTime(Date(timeIntervalSince1970: 1505833468))], "Tue Sep 19 15:04:28 +0000 2017")
        // Lexer - Sentry date format "Sep 29, 2017 2:00:23 PM UTC"
        compare([Token.DateTime(Date(timeIntervalSince1970: 1506693623))], "Sep 29, 2017 2:00:23 PM UTC")
        // Lexer - Date format that bamboo uses.
        compare([Token.DateTime(Date(timeIntervalSince1970: 1500606146))], "20-Jul-2017 22:02:26")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1500606146))], "20-Jul-2017 22:02:26 -05:00")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1500606146))], "21-Jul-2017 03:02:26 Z")
        // Lexer - ISO format but with spaces between date, time and timezone.
        compare([Token.DateTime(Date(timeIntervalSince1970: 1502818114))], "2017-08-15 17:28:34 +0000")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1505686719))], "2017-09-17 17:18:39")
        // Lexer - ISO format with milliseconds but with spaces between date, time and timezone 
        compare([Token.DateTime(Date(timeIntervalSince1970: 1502818114.395))], "2017-08-15 12:28:34.395 -0500")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1497726003.340))], "2017-06-17 12:00:03.340 -07:00")
        // Lexer - Seconds
        compare([Token.DateTime(Date(timeIntervalSince1970: 1497718803))], "1497718803")
        // Lexer - Seconds with fraction mainly to support java interval serialized with jackson
        compare([Token.DateTime(Date(timeIntervalSince1970: 1502713067.720000000))], "1502713067.720000000")
        // Lexer - milliseconds
        compare([Token.DateTime(Date(timeIntervalSince1970: 1497718803.876))], "1497718803876")
        // Lexer - microseconds
        compare([Token.DateTime(Date(timeIntervalSince1970: 1504742693.764001))], "1504742693764001")
        compare([Token.Identifier("abc"), Token.Int(456)], "abc 456")
    }

    private func compare(_ tokens: [Token], _ s: String) {
        XCTAssertEqual(tokens, Lexer(input: s).tokenize(), s)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
