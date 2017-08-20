//
//  ParserTests.swift
//  TextViewTests
//
//  Created by Alex Moffat on 7/14/17.
//  Copyright © 2017 Zanthan. All rights reserved.
//

import XCTest
@testable import TimeCalc

class ParserTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        parseAndCompare(expected: "[LineNode(lineNumber: 1, value: Optional(IdentifierNode(x)), error: nil)]",
                        toParse:  "x")
        
        parseAndCompare(expected: "[LineNode(lineNumber: 1, value: Optional(IdentifierNode(x)), error: nil), LineNode(lineNumber: 2, value: nil, error: nil), LineNode(lineNumber: 3, value: Optional(IdentifierNode(y)), error: nil)]",
                        toParse:  "x\n\ny")
        
        parseAndCompare(expected: "[LineNode(lineNumber: 1, value: Optional(NumberNode(12)), error: nil)]",
                        toParse:  "12")

        parseAndCompare(expected: "[LineNode(lineNumber: 1, value: nil, error: nil), " +
            "LineNode(lineNumber: 2, value: Optional(IdentifierNode(now)), error: nil)]",
                        toParse: "\n now ")
        
        parseAndCompare(expected: "[LineNode(lineNumber: 1, value: Optional(BinaryOpNode(op: +, lhs: NumberNode(10), rhs: NumberNode(4))), error: nil), " +
            "LineNode(lineNumber: 2, value: Optional(DurationNode(266400000)), error: nil)]",
                        toParse: "10 + 4\n3d 2h\n")
        
        parseAndCompare(expected: "[LineNode(lineNumber: 1, value: Optional(BinaryOpNode(op: ., lhs: BinaryOpNode(op: @, lhs: BinaryOpNode(op: +, lhs: DateTimeNode(2017-06-17 11:00:03 +0000), rhs: DurationNode(7200000)), rhs: IdentifierNode(UTC)), rhs: IdentifierNode(day))), error: nil)]",
                        toParse: "2017-06-17T17:00:03+06:00 + 2h @ UTC . day")
        
        parseAndCompare(expected: "[LineNode(lineNumber: 1, value: Optional(BinaryOpNode(op: @, lhs: BinaryOpNode(op: -, lhs: DateTimeNode(2017-06-17 19:00:03 +0000), rhs: DurationNode(90000000)), rhs: StringNode(UTC))), error: nil)]",
                        toParse: "2017-06-17T19:00:03Z - 1d 1h @ 'UTC'")
        
        parseAndCompare(expected: "[LineNode(lineNumber: 1, value: Optional(BinaryOpNode(op: *, lhs: DurationNode(10800000), rhs: BinaryOpNode(op: +, lhs: NumberNode(2), rhs: NumberNode(1)))), error: nil)]", toParse: "3h * (2 + 1)")
        
        parseAndCompare(expected: "[LineNode(lineNumber: 1, value: nil, error: Optional(Parser Expected to find a token.))]", toParse: "2 +")
    }

    func parseAndCompare(expected: String, toParse: String) {
        XCTAssertEqual(expected, String(describing: try! Parser(tokens: Lexer(input: toParse).tokenize()).parseDocument()))
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
