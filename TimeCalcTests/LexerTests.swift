//
//  LexerTests.swift
//  TextViewTests
//
//  Created by Alex Moffat on 7/5/17.
//  Copyright © 2017 Zanthan. All rights reserved.
//

import XCTest
@testable import TimeCalcTests

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
        compare([Token.Let], "let ");
        compare([Token.Assign], "= ")
        compare([Token.Int(12)], "12")
        compare([Token.Identifier("x")], "x")
        compare([Token.Identifier("dog")], "dog")
        compare([Token.String("dog")], "'dog'")
        compare([Token.String("dog")], "\"dog\"")
        compare([Token.Identifier("i1")], "i1")
        compare([Token.OpenParen, Token.Unknown("0a"), Token.CloseParen], "( 0a )")
        compare([Token.Int(3), Token.Operator("+"), Token.Int(5)], "3 +5")
        compare([Token.MillisDuration(3*60*60*1000), Token.MillisDuration(4*1000), Token.MillisDuration(342)], "3h 4s 342ms")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1497726003))], "2017-06-17T19:00:03Z")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1497718803))], "2017-06-17T17:00:03+00:00")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1497718803))], "June 17th 2017, 12:00:03.000")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1497718803))], "1497718803")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1497718803.876))], "1497718803876")
        compare([Token.DateTime(Date(timeIntervalSince1970: 1500606146))], "20-Jul-2017 22:02:26")
        compare([Token.Identifier("abc"), Token.Int(456)], "abc 456")
    }

    private func compare(_ tokens: [Token], _ s: String) {
        XCTAssertEqual(tokens, Lexer(input: s).tokenize())
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
