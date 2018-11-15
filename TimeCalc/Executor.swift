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

/**
 * Turn the output from the Parser, a list of LineNodes, into a list of Results that can be displayed.
 */

enum Value: CustomStringConvertible {
    case DateValue(value: Date, timezone: TimeZone)
    case DurationValue(value: Int)
    case IntValue(value: Int)
    // value is the name of the identifier, for example X
    case IdentifierValue(value: String)
    // an identifier that we have no value for in the environment, value is name of identifier, for example Y
    case UnresolvedIdentifierValue(value: String)
    case StringValue(value: String)
    case CommentValue(value: String)
    
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
        case let .UnresolvedIdentifierValue(i):
            return "UnresolvedIdentifierValue(\(i))"
        case let .StringValue(s):
            return "StringValue(\(s))"
        case let .CommentValue(s):
            return "CommentValue(\(s))"
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
        reservedValues["day"] = .StringValue(value: "day")
        reservedValues["ms"] = .StringValue(value: "ms")
        reservedValues["s"] = .StringValue(value: "s")
        reservedValues["m"] = .StringValue(value: "m")
        reservedValues["h"] = .StringValue(value: "h")
        reservedValues["d"] = .StringValue(value: "d")
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
                    return .Right(.UnresolvedIdentifierValue(value: i))
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
                return .Right(.UnresolvedIdentifierValue(value: i))
            }
        } else {
            return .Right(value)
        }
    }
    
    func valueFromEnvironment(_ stringValue: String) -> ResultValue {
        if let v = self[stringValue] {
            return .Right(v)
        } else {
            return .Right(.UnresolvedIdentifierValue(value: stringValue))
        }
    }
}

class Executor {
    
    static let DURATION_FORMAT_FAILED = "Could not format duration.";
    
    let intervalFormatter = MillisFormatter()
    
    static let SHORT_FORMAT =  "yyyy-MM-dd HH:mm:ss ZZZZZ"
    static let MEDIUM_FORMAT = "yyyy-MM-dd HH:mm:ss.SSS ZZZZZ"
    static let LONG_FORMAT =   "yyyy-MM-dd HH:mm:ss.SSS'MS' ZZZZZ"
    var usingDefaultFormats = true
    var shortFormat =  SHORT_FORMAT
    var mediumFormat = MEDIUM_FORMAT
    var longFormat =   LONG_FORMAT
    
    var effectiveTimeZone = TimeZone.current;
    
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
                return .Right(.StringValue(value: intervalFormatter.format(ms: ms)))
            case let .IntValue(i):
                return .Right(.StringValue(value: String(i)))
            case .IdentifierValue(_):
                return toString(environment.valueFromEnvironment(v))
            case let .UnresolvedIdentifierValue(i):
                return .Right(.StringValue(value: i))
            case .StringValue(_):
                return value
            case .CommentValue(_):
                return value
            }
        case .Left(_):
            return value
        }
    }
    
    func toValue(_ d: Date, _ ts: TimeZone) -> ResultValue {
        let ns = NSCalendar.current.component(.nanosecond, from: d)
        if ns == 0 {
            return .Right(.StringValue(value: Recognizers.formatterForTimeZone(shortFormat, ts).string(from: d)))
        } else {
            let micros: Int = Int(((Double(ns) / 1000).rounded()))
            let microsRemainder = Int(Double(micros).truncatingRemainder(dividingBy: 1000))
            if microsRemainder == 0 {
                return .Right(.StringValue(value: Recognizers.formatterForTimeZone(mediumFormat, ts).string(from: d)))
            } else {
                if usingDefaultFormats {
                    return .Right(.StringValue(value: Recognizers.formatterForTimeZone(longFormat, ts).string(from: d).replacingOccurrences(of: "MS", with: String(format: "%03d", microsRemainder))))
                } else {
                    return .Right(.StringValue(value: Recognizers.formatterForTimeZone(longFormat, ts).string(from: d)))
                }
            }
        }
    }
    
    func evaluateExpression(expr: ExprNode) -> ResultValue {
        switch expr {
        case let com as CommentNode:
            return .Right(.CommentValue(value: com.value))
        case let num as NumberNode:
            return .Right(.IntValue(value: num.value))
        case let str as StringNode:
            return .Right(.StringValue(value: str.value))
        case let str as IdentifierNode:
            return environment.valueFromEnvironment(str.value)
        case let dt as DateTimeNode:
            if (dt.timezoneSpecified) {
                return .Right(.DateValue(value: dt.value, timezone: TimeZone.current))
            } else {
                // If the timezone to use has been modified then adjust to current timezone. It was parsed as if
                // in current timezone but should have been parsed as if in effective timezone.
                if (effectiveTimeZone != TimeZone.current) {
                    let targetOffset = TimeInterval(effectiveTimeZone.secondsFromGMT(for: dt.value))
                    let localOffset = TimeInterval(TimeZone.current.secondsFromGMT(for: dt.value))
                    return .Right(.DateValue(value: dt.value.addingTimeInterval(localOffset - targetOffset), timezone: TimeZone.current))
                } else {
                    return .Right(.DateValue(value: dt.value, timezone: TimeZone.current))
                }
            }
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
                return .Left("\(expr.variable.value) is a reserved variable. You can not change its value.")
            }
            switch v {
            case let .StringValue(s) where expr.variable.value == "fmt":
                if s == "" {
                    usingDefaultFormats = true
                    shortFormat = Executor.SHORT_FORMAT
                    mediumFormat = Executor.MEDIUM_FORMAT
                    longFormat = Executor.LONG_FORMAT
                } else {
                    // TODO - Check that the format is valid.
                    usingDefaultFormats = false
                    shortFormat = s
                    mediumFormat = s
                    longFormat = s
                }
            case let .StringValue(s) where expr.variable.value == "tz":
                if s == "" {
                    effectiveTimeZone = TimeZone.current
                } else {
                    effectiveTimeZone = TimeZone.init(identifier: s) ?? (TimeZone.init(abbreviation: s) ?? TimeZone.current)
                }
            default:
                break
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
        guard case let .StringValue(ident) = rhs else {
            return .Left("RHS of extract component is not a string identifying a date or duration component. It is \(String(describing: rhs))")
        }
        switch v {
        case let .DateValue(date, zone):
            return extractComponent(date: date, zone: zone, ident: ident)
        case let .DurationValue(ms):
            return extractComponent(ms: ms, ident: ident)
        default:
            return .Left("LHS of extract component is not a date. It is \(String(describing: v))")
        }
    }
    
    func extractComponent(date: Date, zone: TimeZone, ident: String) -> ResultValue {
        switch ident {
        case "day":
            return .Right(.StringValue(value: Recognizers.formatterForTimeZone("EEEE", zone).string(from: date)))
        case "ms":
            return .Right(.StringValue(value: String(Int((date.timeIntervalSince1970 * 1000)))))
        case "s":
            return .Right(.StringValue(value: String(Int(date.timeIntervalSince1970))))
        default:
            return .Left("Can not extract component \(ident) from a date.")
        }
    }
    
    func extractComponent(ms: Int, ident: String) -> ResultValue {
        switch ident {
        case "ms", "s", "m", "h", "d":
            return .Right(.StringValue(value: intervalFormatter.format(ms: ms, withLargestUnit: ident)))
        default:
            return .Left("Can not extract component \(ident) from a duration.")
        }
    }
    
    func formatDuration(ms: Int, divisor: Int, unit: String) -> String {
        let units = ms / divisor
        let remainder = Int(ms % divisor)
        if (remainder == 0) {
            return String(format: "%d%@", units, unit)
        } else {
            return String(format: "%d%@ %dms", units, unit, remainder)
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
        var zone: TimeZone
        switch (rhs) {
        case .StringValue(let value), .UnresolvedIdentifierValue(let value):
            guard let maybeZone = TimeZone(identifier: value) ?? TimeZone(abbreviation: value) ?? nil else {
                return .Left("RHS of change timezone is not a valid timezone. \(value) is not recoginzed as a TimeZone identifier or abbreviation.")
            }
            zone = maybeZone
        default:
            return .Left("RHS of change timezone does not identify a timezone. It is \(String(describing: rhs))")
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
            case let (.IntValue(lv), .IntValue(rv)):
                return .Right(.IntValue(value: (lv - rv)))
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
