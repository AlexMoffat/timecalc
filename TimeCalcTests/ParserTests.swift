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
class ParserTests: XCTestCase {

    func testParser() {
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
        
        parseAndCompare(expected: "[LineNode(lineNumber: 1, value: Optional(BinaryOpNode(op: ., lhs: BinaryOpNode(op: @, lhs: BinaryOpNode(op: +, lhs: DateTimeNode(2017-06-17 11:00:03 +0000, true), rhs: DurationNode(7200000)), rhs: IdentifierNode(UTC)), rhs: IdentifierNode(day))), error: nil)]",
                        toParse: "2017-06-17T17:00:03+06:00 + 2h @ UTC . day")
        
        parseAndCompare(expected: "[LineNode(lineNumber: 1, value: Optional(BinaryOpNode(op: @, lhs: BinaryOpNode(op: -, lhs: DateTimeNode(2017-06-17 19:00:03 +0000, true), rhs: DurationNode(90000000)), rhs: StringNode(UTC))), error: nil)]",
                        toParse: "2017-06-17T19:00:03Z - 1d 1h @ 'UTC'")
        
        parseAndCompare(expected: "[LineNode(lineNumber: 1, value: Optional(BinaryOpNode(op: *, lhs: DurationNode(10800000), rhs: BinaryOpNode(op: +, lhs: NumberNode(2), rhs: NumberNode(1)))), error: nil)]", toParse: "3h * (2 + 1)")
        
        parseAndCompare(expected: "[LineNode(lineNumber: 1, value: Optional(DurationNode(1495000)), error: nil)]", toParse: "25m -5s")
        
        parseAndCompare(expected: "[LineNode(lineNumber: 1, value: nil, error: Optional(Parser Expected a newline.))]", toParse: "2 +")
        
        parseAndCompare(expected: "[LineNode(lineNumber: 1, value: Optional(DateTimeNode(2017-06-17 17:00:03 +0000, false)), error: nil), LineNode(lineNumber: 2, value: Optional(AssignmentNode(variable: IdentifierNode(x), value: NumberNode(10))), error: nil)]", toParse: "2017-06-17T12:00:03,340\nlet x = 10")
    }

    func parseAndCompare(expected: String, toParse: String) {
        XCTAssertEqual(expected, String(describing: try! Parser(tokens: Lexer().tokenize(toParse)).parseDocument()), toParse)
    }
}
