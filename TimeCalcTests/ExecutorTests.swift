//
//  ExecutorTests.swift
//  TextViewTests
//
//  Created by Alex Moffat on 7/18/17.
//  Copyright © 2017 Zanthan. All rights reserved.
//

import XCTest
@testable import TimeCalcTests

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
        checkSuccess(toParse: "let x = 2d", expected: "2d")
        checkSuccess(toParse: "1497718803 + 2h @ 'UTC'", expected: "2017-06-17T19:00:03Z")
        checkSuccess(toParse: "2017-06-17T19:00:03Z - 1d 1h @ 'UTC'", expected: "2017-06-16T18:00:03Z")
        checkSuccess(toParse: "2017-06-17T19:00:03Z - 2017-06-16T18:00:03Z", expected: "1d 1h")
        checkSuccess(toParse: "2d + 1497718803", expected: "2017-06-19T12:00:03-05:00")
        checkFailure(toParse: "2 +", expected: "Parser Expected to find a token.")
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
