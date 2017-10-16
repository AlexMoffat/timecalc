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

class ExecutorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        checkSuccess(toParse: "2 + 3", expected: "5")
        checkSuccess(toParse: "2 + -3", expected: "-1")
        checkSuccess(toParse: "let x = 2d", expected: "2d")
        checkSuccess(toParse: "1497718803 + 2h @ 'UTC'", expected: "2017-06-17 19:00:03 Z")
        checkSuccess(toParse: "1497718803765 + 2h @ 'UTC'", expected: "2017-06-17 19:00:03.765 Z")
        checkSuccess(toParse: "2017-06-17T19:00:03Z - 1d 1h @ 'UTC'", expected: "2017-06-16 18:00:03 Z")
        checkSuccess(toParse: "2017-06-17T19:00:03Z - 2017-06-16T18:00:03Z", expected: "1d 1h")
        checkSuccess(toParse: "2d + 1497718803", expected: "2017-06-19 12:00:03 -05:00")
        checkFailure(toParse: "2 +", expected: "Parser Expected a newline.")
    }

    func checkSuccess(toParse: String, expected: String) {
        let results = try! Executor(lines: Parser(tokens: Lexer(input: toParse).tokenize()).parseDocument()).evaluate()
        XCTAssertEqual(1, results.count, "Need one result.")
        guard case let .Right(.StringValue(s)) = results[0].value else {
            XCTFail("Result is not string " + String(describing: results) + " Expected " + expected)
            return
        }
        XCTAssertEqual(expected, s, "Results are " + String(describing: results))
    }
    
    func checkFailure(toParse: String, expected: String) {
        let results = try! Executor(lines: Parser(tokens: Lexer(input: toParse).tokenize()).parseDocument()).evaluate()
        XCTAssertEqual(1, results.count, "Need one result.")
        guard case let .Left(s) = results[0].value else {
            XCTFail("Result is not error " + String(describing: results) + " Expected " + expected)
            return
        }
        XCTAssertEqual(expected, s, "Results are " + String(describing: results))
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
