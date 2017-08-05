//
//  Lexer.swift
//  TextViewTests
//
//  Created by Alex Moffat on 7/3/17.
//  Copyright © 2017 Zanthan. All rights reserved.
//

import Foundation

public enum Token {
    case Whitespace
    case Newline
    case Let
    case Assign
    case OpenParen
    case CloseParen
    case Operator(String)
    case MillisDuration(Int)
    case DateTime(Date)
    case Identifier(String)
    case Int(Int)
    case String(String)
    case Unknown(String)
}

extension Token: Equatable {
    public static func ==(lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case (.Whitespace, .Whitespace) : return true
        case (.Newline, .Newline) : return true
        case (.Let, .Let) : return true
        case (.Assign, .Assign) : return true
        case (.OpenParen, .OpenParen) : return true
        case (.CloseParen, .CloseParen) : return true
        case let (.Operator(l), .Operator(r)) : return l == r
        case let (.MillisDuration(l), .MillisDuration(r)) : return l == r
        case let (.DateTime(l), .DateTime(r)) : return l == r
        case let (.Identifier(l), .Identifier(r)) : return l == r
        case let (.Int(l), .Int(r)) : return l == r
        case let (.Unknown(l), .Unknown(r)) : return l == r
        case let (.String(l), .String(r)) : return l == r
        default : return false
        }
    }
}

typealias TokenGenerator = (NSTextCheckingResult, String) -> Token?

let POSIX_LOCALE = Locale(identifier: "en_US_POSIX")

let formatterForTimeZone = {(zone: TimeZone?, format: String) -> DateFormatter in
    let fmt = DateFormatter()
    fmt.locale = POSIX_LOCALE
    fmt.dateFormat = format
    fmt.timeZone = zone
    return fmt
}

let tokenGenerators: [(NSRegularExpression, TokenGenerator)] = {() -> [(NSRegularExpression, TokenGenerator)] in
    
    let match = {(r: NSTextCheckingResult, s: String) -> String in (s as NSString).substring(with: r.range)}
    
    let toDuration: TokenGenerator = {r, s in
        if let value = Int((s as NSString).substring(with: r.rangeAt(1))) {
            let units = (s as NSString).substring(with: r.rangeAt(2))
            switch units {
            case "d":
                return .MillisDuration(value*24*60*60*1000)
            case "h":
                return .MillisDuration(value*60*60*1000)
            case "m":
                return .MillisDuration(value*60*1000)
            case "s":
                return .MillisDuration(value*1000)
            case "ms":
                return .MillisDuration(value)
            default:
                return nil;
            }
        } else {
            return .Unknown(match(r,s))
        }
    }
    
    let isoDateFormat = formatterForTimeZone(TimeZone.current, "yyyy-MM-dd'T'HH:mm:ssZZZZZ")
    
    let toDateFromISO: TokenGenerator = {r, s in
        isoDateFormat.date(from: match(r, s)).map({d in .DateTime(d)})
    }
    
    let kibanaDateFormat = formatterForTimeZone(TimeZone.current, "MMM dd yyyy',' HH:mm:ss.SSS")
    let removeOrdinalsLeadingMonth = try! NSRegularExpression(pattern: "([yhletr]\\s+[0-9]{1,2})((st)|(nd)|(rd)|(th))(\\s+\\d)", options: [])
    let toDateFromKibana: TokenGenerator = {r, s in
        let mutable = NSMutableString(string: match(r, s))
        if removeOrdinalsLeadingMonth.replaceMatches(in: mutable, options: [], range: NSMakeRange(0, mutable.length), withTemplate: "$1$7") > 0 {
            return kibanaDateFormat.date(from: mutable as String).map({d in .DateTime(d)})
        } else {
            return nil
        }
    }
    
    let bambooDateFormat = formatterForTimeZone(TimeZone.current, "d-MMM-yyyy HH:mm:ss")
    let toDateFromBamboo: TokenGenerator = {r, s in
        bambooDateFormat.date(from: match(r, s)).map({d in .DateTime(d)})
    }
    
    let toString: TokenGenerator = {r, s in
        let theMatch = match(r, s)
        let start = theMatch.index(theMatch.startIndex, offsetBy: 1)
        let end = theMatch.index(theMatch.endIndex, offsetBy: -1)
        return .String(theMatch.substring(with: start ..< end))
    }

    let tokenDefinitions: [(String, TokenGenerator)] = [
        
        ("[ \t]+",        {_ in .Whitespace}),
        ("\r?\n",     {_ in .Newline}),
        ("let",         {_ in .Let}),
        ("=",           {_ in .Assign}),
        ("\\(",         {_ in .OpenParen}),
        ("\\)",         {_ in .CloseParen}),
        ("[+*/@.-]",      {r, s in .Operator(match(r, s))}),
        ("([1-9][0-9]{0,3})(d|h|m(?!s)|s|ms)", toDuration),
        // 2017-06-17T17:00:03+00:00
        ("\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}[+-]\\d{2}:\\d{2}", toDateFromISO),
        // 2017-06-17T19:00:03Z
        ("\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z", toDateFromISO),
        // June 17th 2017, 12:00:03.000
        ("(\\S+[yhletr]\\s+[0-9]{1,2})((st)|(nd)|(rd)|(th))(\\s+\\d{4}), \\d{2}:\\d{2}:\\d{2}\\.\\d{3}", toDateFromKibana),
        // 20-Jul-2017 22:02:26
        ("\\d{1,2}-[JFMASOND][aepuco][nbrynlgptvc][a-z]?-\\d{4} \\d{1,2}:\\d{2}:\\d{2}", toDateFromBamboo),
        // 1499212382123 (date in milliseconds)
        ("\\d{13}", {r, s in Double(match(r, s)).map({d in .DateTime(Date(timeIntervalSince1970: (d / 1000)))})}),
        // 1499212382 (date in seconds)
        ("\\d{10}", {r, s in Double(match(r, s)).map({d in .DateTime(Date(timeIntervalSince1970: d))})}),
        ("\"([^\"\r\n]+)\"", toString),
        ("'([^'\r\n]+)'", toString),
        ("[a-zA-Z][0-9a-zA-Z]*", {r, s in .Identifier(match(r, s))}),
        ("[1-9]\\d{0,3}", {r, s in Int(match(r, s)).map({i in .Int(i)})}),
        ("\\S+", {r, s in .Unknown(match(r, s))})
        
    ]
    
    let rgx = {(p: (String, TokenGenerator)) -> (NSRegularExpression, TokenGenerator) in
        return (try! NSRegularExpression(pattern: "^\(p.0)", options: []), p.1)
    }
    
    return tokenDefinitions.map(rgx)
}()


class Lexer {
    let input: String
    
    init(input: String) {
        self.input = input
    }
    
    public func tokenize() -> [Token] {
        var tokens = [Token]()
        var content = input
        
        while (content.characters.count > 0) {
            var matched = false
            
            for (pattern, generator) in tokenGenerators {
                if let match = pattern.firstMatch(in: content, options: [], range: NSMakeRange(0, content.characters.count)) {
                    if let t = generator(match, content) {
                        if t != .Whitespace {
                            tokens.append(t)
                        }
                        content = content.substring(from: content.index(content.startIndex, offsetBy:match.range.length))
                        matched = true
                        break
                    }
                }
            }
            
            if !matched {
                let index = content.index(content.startIndex, offsetBy: 1)
                tokens.append(.Unknown(content.substring(to: index)))
                content = content.substring(from: index)
            }
        }
        return tokens
    }
}