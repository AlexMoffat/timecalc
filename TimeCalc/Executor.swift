//
//  Executor.swift
//  TextViewTests
//
//  Created by Alex Moffat on 7/15/17.
//  Copyright © 2017 Zanthan. All rights reserved.
//

import Foundation

enum Value: CustomStringConvertible {
    case DateValue(value: Date, timezone: TimeZone)
    case DurationValue(value: Int)
    case IntValue(value: Int)
    case IdentifierValue(value: String)
    case StringValue(value: String)
    
    var description: String {
        switch self {
        case let .DateValue(d, t):
            return "DateValue(\(d), \(t))"
        case let .DurationValue(d):
            return "DurationValue(\(d))"
        case let .IntValue(i):
            return "IntValue(\(i))"
        case let.IdentifierValue(i):
            return "IdentifierValue(\(i))"
        case let .StringValue(s):
            return "StringValue(\(s))"
        }
    }
}

typealias ErrorMessage = String

enum Either<L, R> {
    case Left(L)
    case Right(R)
}

typealias ResultValue = Either<ErrorMessage, Value>

struct Result {
    let lineNumber: Int
    let value: ResultValue
}

class Environment {
    var reservedValues = [String: Value]()
    var values = [String: Value]()
    
    init() {
        reservedValues["now"] = .DateValue(value: Date(), timezone: TimeZone.current)
        reservedValues["day"] = .IdentifierValue(value: "day")
        reservedValues["ms"] = .IdentifierValue(value: "ms")
        reservedValues["s"] = .IdentifierValue(value: "s")
    }
    
    subscript(index: String) -> Value? {
        get {
            return reservedValues[index] ?? values[index]
        }
        set(newValue) {
            values[index] = newValue
        }
    }
    
    func isReserved(_ index: String) -> Bool {
        return reservedValues[index] != nil
    }
    
    func valueFromEnvironment(_ resultValue: ResultValue) -> ResultValue {
        if case let .Right(value) = resultValue {
            if case let .IdentifierValue(i) = value {
                if let v = self[i] {
                    return .Right(v)
                } else {
                    return .Left("\(String(describing: value)) is an undefined identifier. It has no value.")
                }
            } else {
                return .Right(value)
            }
        } else {
            return resultValue
        }
    }
    
    func valueFromEnvironment(_ value: Value) -> ResultValue {
        if case let .IdentifierValue(i) = value {
            if let v = self[i] {
                return .Right(v)
            } else {
                return .Left("\(String(describing: value)) is an undefined identifier. It has no value.")
            }
        } else {
            return .Right(value)
        }
    }
    
    func valueFromEnvironment(_ stringValue: String) -> ResultValue {
        if let v = self[stringValue] {
            return .Right(v)
        } else {
            return .Left("\(stringValue) is an undefined identifier. It has no value.")
        }
    }
}

class Executor {
    
    let intervalFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()
    
    
    static let SHORT_FORMAT =  "yyyy-MM-dd HH:mm:ss ZZZZZ"
    static let MEDIUM_FORMAT = "yyyy-MM-dd HH:mm:ss.SSS ZZZZZ"
    static let LONG_FORMAT =   "yyyy-MM-dd HH:mm:ss.SSSSSS ZZZZZ"
    var shortFormat =  SHORT_FORMAT
    var mediumFormat = MEDIUM_FORMAT
    var longFormat =   LONG_FORMAT
    
    var environment = Environment()
    var lines: [LineNode]
    
    init(lines: [LineNode]) {
        self.lines = lines
    }
    
    func evaluate() -> [Result] {
        var results = [Result]()
        for line in lines {
            results.append(evaluateLine(line: line))
        }
        
        return results;
    }
    
    func evaluateLine(line: LineNode) -> Result {
        if let expr = line.value {
            return Result(lineNumber: line.lineNumber, value: toString(evaluateExpression(expr: expr)))
        } else if let err = line.error {
            return Result(lineNumber: line.lineNumber, value: .Left(String(describing: err)))
        } else {
            return Result(lineNumber: line.lineNumber, value: .Right(.StringValue(value: "")))
        }
    }
    
    func toString(_ value: ResultValue) -> ResultValue {
        switch value {
        case let .Right(v):
            switch v {
            case let .DateValue(d):
                return toValue(d.value, d.timezone)
            case let .DurationValue(ms):
                return .Right(.StringValue(value: intervalFormatter.string(from: Double(ms) / 1000) ?? "Could not format duration."))
            case let .IntValue(i):
                return .Right(.StringValue(value: String(i)))
            case .IdentifierValue(_):
                return toString(environment.valueFromEnvironment(v))
            case .StringValue(_):
                return value
            }
        case .Left(_):
            return value
        }
    }
    
    func toValue(_ d: Date, _ ts: TimeZone) -> ResultValue {
        let ns = NSCalendar.current.component(.nanosecond, from: d)
        if ns == 0 {
            return .Right(.StringValue(value: formatterForTimeZone(ts, shortFormat).string(from: d)))
        } else {
            let micros: Int = Int(floor(Double(ns / 1000)))
            let millis: Int = Int(floor(Double(micros / 1000)))
            let microsRemainder = micros - (millis * 1000)
            if microsRemainder == 0 {
                return .Right(.StringValue(value: formatterForTimeZone(ts, mediumFormat).string(from: d)))
            } else {
                return .Right(.StringValue(value: formatterForTimeZone(ts, longFormat).string(from: d)))
            }
        }
    }
    
    func evaluateExpression(expr: ExprNode) -> ResultValue {
        switch expr {
        case let num as NumberNode:
            return .Right(.IntValue(value: num.value))
        case let str as StringNode:
            return .Right(.StringValue(value: str.value))
        case let str as IdentifierNode:
            return environment.valueFromEnvironment(str.value)
        case let dt as DateTimeNode:
            return .Right(.DateValue(value: dt.value, timezone: TimeZone.current))
        case let d as DurationNode:
            return .Right(.DurationValue(value: d.value))
        case let assignment as AssignmentNode:
            return evaluateAssignment(expr: assignment)
        case let bop as BinaryOpNode:
            return evaluateBinaryOp(expr: bop)
        default:
            return .Left("Unknown type of expression.")
        }
    }
    
    func evaluateAssignment(expr: AssignmentNode) -> ResultValue {
        let value = environment.valueFromEnvironment(evaluateExpression(expr: expr.value))
        switch value {
        case let .Right(v):
            if environment.isReserved(expr.variable.value) {
                return .Left("\(expr.variable.value) is a reserved identifier. You can not change its value.")
            }
            if case .StringValue(let s) = v, expr.variable.value == "fmt" {
                if s == "" {
                    shortFormat = Executor.SHORT_FORMAT
                    mediumFormat = Executor.MEDIUM_FORMAT
                    longFormat = Executor.LONG_FORMAT
                } else {
                    // TODO - Check that the format is valid.
                    shortFormat = s
                    mediumFormat = s
                    longFormat = s
                }
            }
            environment[expr.variable.value] = v
            return value
        case .Left(_):
            return value
        }
    }
    
    func evaluateBinaryOp(expr: BinaryOpNode) -> ResultValue {
        let lhs = evaluateExpression(expr: expr.lhs)
        guard case let .Right(lhsValue) = lhs else {
            return lhs
        }
        let rhs = evaluateExpression(expr: expr.rhs)
        guard case let .Right(rhsValue) = rhs else {
            return rhs
        }
        
        switch expr.op {
        case ".":
            return extractComponent(lhs: lhsValue, rhs: rhsValue)
        case "@":
            return changeTimezone(lhs: lhsValue, rhs: rhsValue)
        case "+":
            return add(lhs: lhsValue, rhs: rhsValue)
        case "-":
            return subtract(lhs: lhsValue, rhs: rhsValue)
        case "*":
            return multiply(lhs: lhsValue, rhs: rhsValue)
        case "/":
            return divide(lhs: lhsValue, rhs: rhsValue)
        default:
            return .Left("Unknown operator \(expr.op)")
        }
    }
    
    func extractComponent(lhs: Value, rhs: Value) -> ResultValue {
        let lhsValue = environment.valueFromEnvironment(lhs)
        guard case let .Right(v) = lhsValue else {
            return lhsValue
        }
        guard case let .DateValue(date, zone) = v else {
            return .Left("LHS of extract component is not a date. It is \(String(describing: v))")
        }
        guard case let .IdentifierValue(ident) = rhs else {
            return .Left("RHS of extract component is not an identifier. It is \(String(describing: rhs))")
        }
        switch ident {
        case "day":
            return .Right(.StringValue(value: formatterForTimeZone(zone, "EEEE").string(from: date)))
        case "ms":
            return .Right(.StringValue(value: String(Int((date.timeIntervalSince1970 * 1000)))))
        case "s":
            return .Right(.StringValue(value: String(Int(date.timeIntervalSince1970))))
        default:
            return .Left("Can not extract component \(ident) from a date.")
        }
    }
    
    func changeTimezone(lhs: Value, rhs: Value) -> ResultValue {
        let lhsValue = environment.valueFromEnvironment(lhs)
        guard case let .Right(v) = lhsValue else {
            return lhsValue
        }
        guard case let .DateValue(date, _) = v else {
            return .Left("LHS of change timezone is not a date. It is \(String(describing: v))")
        }
        guard case let .StringValue(ident) = rhs else {
            return .Left("RHS of change timezone is not an identifier. It is \(String(describing: rhs))")
        }
        guard let zone = TimeZone(abbreviation: ident) ?? TimeZone(identifier: ident) ?? nil else {
            return .Left("RHS of change timezone is not a valid timezone. It is \(String(describing: rhs))")
        }
        return ResultValue.Right(.DateValue(value: date, timezone: zone))
    }
    
    func add(lhs: Value, rhs:Value) -> ResultValue {
        return withResolvedIdentifiers(lhs: lhs, rhs: rhs) {(left, right) in
            switch (left, right) {
            case let (.DateValue(lv), .DurationValue(rv)):
                return .Right(.DateValue(value: lv.value.addingTimeInterval(Double(rv) / 1000), timezone: lv.timezone))
            case let (.DurationValue(lv), .DateValue(rv)):
                return .Right(.DateValue(value: rv.value.addingTimeInterval(Double(lv) / 1000), timezone: rv.timezone))
            case let (.DurationValue(lv), .DurationValue(rv)):
                return .Right(.DurationValue(value: (lv + rv)))
            case let (.IntValue(lv), .IntValue(rv)):
                return .Right(.IntValue(value: (lv + rv)))
            default:
                return .Left("Unable to add \(left) to \(right)")
            }
        }
    }
    
    func subtract(lhs: Value, rhs:Value) -> ResultValue {
        return withResolvedIdentifiers(lhs: lhs, rhs: rhs) {(left, right) in
            switch (left, right) {
            case let (.DateValue(lv), .DurationValue(rv)):
                return .Right(.DateValue(value: lv.value.addingTimeInterval(Double(rv) / -1000), timezone: lv.timezone))
            case let (.DateValue(lv), .DateValue(rv)):
                return .Right(.DurationValue(value: Int((lv.value.timeIntervalSince1970 * 1000) - (rv.value.timeIntervalSince1970 * 1000))))
            case let (.DurationValue(lv), .DurationValue(rv)):
                return .Right(.DurationValue(value: (lv - rv)))
            default:
                return .Left("Unable to subtract \(right) from \(left)")
            }
        }
    }
    
    func multiply(lhs: Value, rhs:Value) -> ResultValue {
        return withResolvedIdentifiers(lhs: lhs, rhs: rhs) {(left, right) in
            switch (left, right) {
            case let (.DurationValue(lv), .IntValue(rv)):
                return .Right(.DurationValue(value: (lv * rv)))
            case let (.IntValue(lv), .DurationValue(rv)):
                return .Right(.DurationValue(value: (lv * rv)))
            case let (.IntValue(lv), .IntValue(rv)):
                return .Right(.IntValue(value: (lv * rv)))
            default:
                return .Left("Unable to multiply \(left) by \(right)")
            }
        }
    }
    
    func divide(lhs: Value, rhs:Value) -> ResultValue {
        return withResolvedIdentifiers(lhs: lhs, rhs: rhs) {(left, right) in
            switch (left, right) {
            case let (.DurationValue(lv), .IntValue(rv)):
                return .Right(.DurationValue(value: (lv / rv)))
            case let (.IntValue(lv), .IntValue(rv)):
                return .Right(.IntValue(value: (lv / rv)))
            default:
                return .Left("Unable to divide \(left) by \(right)")
            }
        }
    }
    
    func withResolvedIdentifiers(lhs: Value, rhs: Value, _ fcn: (Value, Value) -> ResultValue) -> ResultValue {
        let lhsValue = environment.valueFromEnvironment(lhs)
        guard case let .Right(left) = lhsValue else {
            return lhsValue
        }
        let rhsValue = environment.valueFromEnvironment(rhs)
        guard case let .Right(right) = rhsValue else {
            return rhsValue
        }
        return fcn(left, right)
    }
}
