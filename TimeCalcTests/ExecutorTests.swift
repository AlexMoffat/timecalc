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
class ExecutorTests: XCTestCase {
    
    
    func testOne() {
        checkSuccess(toParse: #"1569784566412 as 'MM-dd'"#, expected: "09-29")
        checkSuccess(toParse: #"1569784566412 as "MM-dd""#, expected: "09-29")
    }
    
    func xtestExecutor() {
        checkSuccess(toParse: "2 + 3", expected: "5")
        checkSuccess(toParse: "2 + -3", expected: "-1")
        checkSuccess(toParse: "70 - 43", expected: "27")
        checkSuccess(toParse: "let x = 2d", expected: "2d")
        checkSuccess(toParse: "1497718803 + 2h @ 'UTC'", expected: "2017-06-17 19:00:03 Z")
        checkSuccess(toParse: "1497718803765 + 2h @ 'UTC'", expected: "2017-06-17 19:00:03.765 Z")
        checkSuccess(toParse: "2017-06-17T19:00:03", expected: "2017-06-17 19:00:03 -05:00")
        checkSuccess(toParse: "2017-06-17T19:00:03Z", expected: "2017-06-17 14:00:03 -05:00")
        checkSuccess(toParse: "let tz = 'UTC'\n2017-06-17T19:00:03", expecteds: ["UTC", "2017-06-17 14:00:03 -05:00"])
        checkSuccess(toParse: "2017-06-17T19:00:03Z - 1d 1h @ 'UTC'", expected: "2017-06-16 18:00:03 Z")
        checkSuccess(toParse: "2017-06-17T19:00:03Z - 1d 1h @ UTC", expected: "2017-06-16 18:00:03 Z")
        checkSuccess(toParse: "2017-06-17T19:00:03Z @ America/Chicago", expected: "2017-06-17 14:00:03 -05:00")
        checkFailure(toParse: "2017-06-17T19:00:03Z @ XXX", expected: "RHS of change timezone is not a valid timezone. XXX is not recoginzed as a TimeZone identifier or abbreviation.")
        checkSuccess(toParse: "let x = 'America/Chicago'\n2017-06-17T19:00:03Z @ x", expecteds: ["America/Chicago", "2017-06-17 14:00:03 -05:00"])
        checkSuccess(toParse: "2017-06-17T19:00:03Z - 2017-06-16T18:00:03Z", expected: "1d 1h")
        checkSuccess(toParse: "2d + 1497718803", expected: "2017-06-19 12:00:03 -05:00")
        checkSuccess(toParse: "(2017-08-17T17:00:03+00:00 - 2017-08-15 17:28:34 +0000) as m", expected: "2851m 29s")
        checkSuccess(toParse: "2851m 29000ms", expected: "1d 23h 31m 29s");
        checkSuccess(toParse: "(2017-08-17T17:00:03+00:00 - 2017-08-15 17:28:34 +0000) as h", expected: "47h 31m 29s")
        checkSuccess(toParse: "47h 1889000ms", expected: "1d 23h 31m 29s");
        checkSuccess(toParse: "(2017-08-17T17:00:03+00:00 - 2017-08-15 17:28:34 +0000) as d", expected: "1d 23h 31m 29s")
        checkSuccess(toParse: "1d 84689000ms", expected: "1d 23h 31m 29s");
        checkSuccess(toParse: "84689000ms", expected: "23h 31m 29s");
        checkSuccess(toParse: "1889000ms", expected: "31m 29s");
        checkSuccess(toParse: "29000ms", expected: "29s");
        checkFailure(toParse: "2 +", expected: "Parser Expected to find a token.")
        checkSuccess(toParse: "2019-10-24 as \"yyyy\"", expected: "2019")
        checkSuccess(toParse: "2019-10-24 as yyyy", expected: "2019")
        checkSuccess(toParse: #"1569784566412 as 'MM-dd'"#, expected: "09-29")
        checkSuccess(toParse: #"1569784566412 as "MM-dd""#, expected: "09-29")
        checkSuccess(toParse: #"1569784566412 as “MM-dd”"#, expected: "09-29") // unicode curly quote
        checkSuccess(toParse: #"(2019-10-24T21:12:04Z @ UTC) as "'v'_yyyyMMdd_HHmm""#, expected: "v_20191024_2112")
        checkSuccess(toParse: #"2019-10-24T21:12:04Z @ UTC as "'v'_yyyyMMdd_HHmm""#, expected: "v_20191024_2112")
    }

    func checkSuccess(toParse: String, expected: String) {
        let results = try! Executor(lines: Parser(tokens: Lexer().tokenize(toParse)).parseDocument()).evaluate()
        XCTAssertEqual(1, results.count, "Need one result.")
        guard case let .Right(.StringValue(s)) = results[0].value else {
            XCTFail("Result is not string " + String(describing: results) + " Expected " + expected)
            return
        }
        XCTAssertEqual(expected, s, "Results are " + String(describing: results))
    }
    
    func checkSuccess(toParse: String, expecteds: [String]) {
        let results = try! Executor(lines: Parser(tokens: Lexer().tokenize(toParse)).parseDocument()).evaluate()
        XCTAssertEqual(expecteds.count, results.count, "Need \(expecteds.count) results.")
        for i in 0 ..< expecteds.count  {
            guard case let .Right(.StringValue(s)) = results[i].value else {
                XCTFail("Result is not string " + String(describing: results) + " Expected " + expecteds[i])
                return
            }
            XCTAssertEqual(expecteds[i], s, "Results are " + String(describing: results) + " from " + toParse)
        }
    }
    
    func checkFailure(toParse: String, expected: String) {
        let results = try! Executor(lines: Parser(tokens: Lexer().tokenize(toParse)).parseDocument()).evaluate()
        XCTAssertEqual(1, results.count, "Need one result.")
        guard case let .Left(s) = results[0].value else {
            XCTFail("Result is not error " + String(describing: results) + " Expected " + expected)
            return
        }
        XCTAssertEqual(expected, s, "Results are " + String(describing: results))
    }
}
