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

protocol ExprNode: CustomStringConvertible {
}

struct NumberNode: ExprNode {
    let value: Int
    var description: String {
        return "NumberNode(\(value))"
    }
}

struct IdentifierNode: ExprNode {
    let value: String
    var description: String {
        return "IdentifierNode(\(value))"
    }
}

struct StringNode: ExprNode {
    let value: String
    var description: String {
        return "StringNode(\(value))"
    }
}

struct CommentNode: ExprNode {
    let value: String
    var description: String {
        return "CommentNode(\(value))"
    }
}

struct DateTimeNode: ExprNode {
    let value: Date
    let timezoneSpecified: Bool
    var description: String {
        return "DateTimeNode(\(value), \(timezoneSpecified))"
    }
}

struct DurationNode: ExprNode {
    let value: Int
    var description: String {
        return "DurationNode(\(value))"
    }
}

struct AssignmentNode: ExprNode {
    let variable: IdentifierNode
    let value: ExprNode
    var description: String {
        return "AssignmentNode(variable: \(variable), value: \(value))"
    }
}

struct BinaryOpNode: ExprNode {
    let op: String
    let lhs: ExprNode
    let rhs: ExprNode
    var description: String {
        return "BinaryOpNode(op: \(op), lhs: \(lhs), rhs: \(rhs))"
    }
}

struct LineNode: ExprNode {
    let lineNumber: Int
    let value: ExprNode?
    let error: ParseError?
    var description: String {
        return "LineNode(lineNumber: \(lineNumber), value: \(String(describing: value)), error: \(String(describing: error)))"
    }
}

enum ParseError: Error, CustomStringConvertible {
    case ExpectedCharacter(Character)
    case ExpectedComment
    case ExpectedDateTime
    case ExpectedDuration
    case ExpectedExpression
    case ExpectedIdentifier
    case ExpectedNewline
    case ExpectedNumber
    case ExpectedOperator
    case ExpectedString(String)
    case ExpectedStringValue
    case ExpectedToken
    case UndefinedOperator(String)

    var description: String {
        switch self {
        case let .ExpectedCharacter(c):
            return "Parser Expected character \(c)."
        case .ExpectedComment:
            return "Parser Expected a comment."
        case .ExpectedDateTime:
            return "Parser Expected a date time value."
        case .ExpectedDuration:
            return "Parser Expected a duration value."
        case .ExpectedExpression:
            return "Parser Expected an expression."
        case .ExpectedIdentifier:
            return "Parser Expected an identifier."
        case .ExpectedNewline:
            return "Parser Expected a newline."
        case .ExpectedNumber:
            return "Parser Expected a number."
        case .ExpectedOperator:
            return "Parser Expected an operator, one of + - * / @ ."
        case let .ExpectedString(s):
            return "Parser Expected the value \(s)."
        case .ExpectedStringValue:
            return "Parser Expected a string."
        case .ExpectedToken:
            return "Parser Expected to find a token."
        case let .UndefinedOperator(s):
            return "Parser Expected an operator, one of + - * / @ . but got \(s)."
        }
    }
}

let opPrecedence: [String: Int] = [
    ".": 10,
    "@": 20,
    "+": 30,
    "-": 30,
    "*": 40,
    "/": 40
]

class Parser {
    let tokens: [Token]
    var index = 0
    var lineNumber = 1
    
    init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    var tokensAvailable: Bool {
        return index < tokens.count
    }
    
    func peekCurrentToken() throws -> Token {
        if !tokensAvailable {
            throw ParseError.ExpectedToken
        }
        return tokens[index]
    }
    
    func popCurrentToken() throws -> Token {
        let nextToken = try peekCurrentToken()
        index += 1
        return nextToken
    }
    
    func getCurrentTokenPrecedence() throws -> Int {
        guard tokensAvailable else {
            return -1
        }
        guard case let Token.Operator(op) = try peekCurrentToken() else {
            return -1
        }
        guard let precedence = opPrecedence[op] else {
            throw ParseError.UndefinedOperator(op)
        }
        return precedence
    }
    
    func parseNumber() throws -> NumberNode {
        guard case let Token.Int(value) = try popCurrentToken() else {
            throw ParseError.ExpectedNumber
        }
        return NumberNode(value: value)
    }
    
    func parseVariable() throws -> IdentifierNode {
        guard case let Token.Identifier(value) = try popCurrentToken() else {
            throw ParseError.ExpectedIdentifier
        }
        return IdentifierNode(value: value)
    }
    
    func parseString() throws -> StringNode {
        guard case let Token.String(value) = try popCurrentToken() else {
            throw ParseError.ExpectedStringValue
        }
        return StringNode(value: value)
    }
    
    func parseDateTime() throws -> DateTimeNode {
        guard case let Token.DateTime(date, timezoneSpecified) = try popCurrentToken() else {
            throw ParseError.ExpectedDateTime
        }
        return DateTimeNode(value: date, timezoneSpecified: timezoneSpecified)
    }
    
    func parseDurations() throws -> DurationNode {
        guard case let Token.MillisDuration(value) = try popCurrentToken() else {
            throw ParseError.ExpectedDuration
        }
        var totalDuration = value
        while tokensAvailable, case let Token.MillisDuration(value) = try peekCurrentToken() {
            totalDuration += value
            _ = try popCurrentToken()
        }
        return DurationNode(value: totalDuration)
    }
    
    func parseParens() throws -> ExprNode {
        guard case Token.OpenParen = try popCurrentToken() else {
            throw ParseError.ExpectedCharacter("(")
        }
        
        let exp = try parseExpression()
        
        guard case Token.CloseParen = try popCurrentToken() else {
            throw ParseError.ExpectedCharacter(")")
        }
        
        return exp
    }
    
    func parsePrimary() throws -> ExprNode {
        switch (try peekCurrentToken()) {
        case .Int:
            return try parseNumber()
        case .String:
            return try parseString()
        case .Identifier:
            return try parseVariable()
        case .DateTime:
            return try parseDateTime()
        case .MillisDuration:
            return try parseDurations()
        case .OpenParen:
            return try parseParens()
        default:
            throw ParseError.ExpectedExpression
        }
    }
    
    func parseBinaryOp(node: ExprNode, exprPrecedence: Int = 0) throws -> ExprNode {
        var lhs = node
        while true {
            let tokenPrecedence = try getCurrentTokenPrecedence()
            if tokenPrecedence < exprPrecedence {
                return lhs
            }
            
            guard case let Token.Operator(op) = try popCurrentToken() else {
                throw ParseError.ExpectedOperator
            }
            
            var rhs = try parsePrimary()
            let nextPrecedence = try getCurrentTokenPrecedence()
            
            if tokenPrecedence < nextPrecedence {
                rhs = try parseBinaryOp(node: rhs, exprPrecedence: tokenPrecedence + 1)
            }
            lhs = BinaryOpNode(op: op, lhs: lhs, rhs: rhs)
        }
    }
    
    func parseExpression() throws -> ExprNode {
        let node = try parsePrimary()
        return try parseBinaryOp(node: node)
    }
    
    func parseAssignment() throws -> ExprNode {
        guard case Token.Let = try popCurrentToken() else {
            throw ParseError.ExpectedString("let")
        }
        
        let variable = try parseVariable()
        
        guard case Token.Assign = try popCurrentToken() else {
            throw ParseError.ExpectedCharacter("=")
        }
        
        let value = try parseExpression()
        
        return AssignmentNode(variable: variable, value: value)
    }
    
    func parseNewline(value: ExprNode? = nil) throws -> LineNode {
        guard case Token.Newline = try popCurrentToken() else {
            throw ParseError.ExpectedNewline
        }
        let currentLineNumber = lineNumber
        lineNumber += 1
        return LineNode(lineNumber: currentLineNumber, value: value, error: nil)
    }
    
    func parseComment() throws -> CommentNode {
        guard case let Token.Comment(value) = try popCurrentToken() else {
            throw ParseError.ExpectedComment
        }
        return CommentNode(value: value)
    }
    
    func parseLine() throws -> LineNode {
        let value: ExprNode
        switch (try peekCurrentToken()) {
        case .Newline:
            return try parseNewline()
        case .Comment:
            value = try parseComment()
        case .Let:
            value = try parseAssignment()
        default:
            value = try parseExpression()
        }
        if tokensAvailable {
            return try parseNewline(value: value)
        } else {
            return LineNode(lineNumber: lineNumber, value: value, error: nil)
        }
    }
    
    func skipToEndOfLine(error: ParseError) throws -> LineNode {
        while (tokensAvailable) {
            let token = try popCurrentToken()
            if token == Token.Newline {
                let currentLineNumber = lineNumber
                lineNumber += 1
                return LineNode(lineNumber: currentLineNumber, value: nil, error: error)
            }
        }
        return LineNode(lineNumber: lineNumber, value: nil, error: error)
    }
    
    // Main entry point.
    func parseDocument() throws -> [LineNode] {
        var lines = [LineNode]()
        while (tokensAvailable) {
            do {
                lines.append(try parseLine())
            } catch let error as ParseError {
                lines.append(try skipToEndOfLine(error: error))
            }
        }
        return lines
    }
}
