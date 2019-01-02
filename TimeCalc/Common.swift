//
//  Common.swift
//  TimeCalc
//
//  Created by Alex Moffat on 12/8/18.
//  Copyright © 2018 Zanthan. All rights reserved.
//

import Foundation

class Common {
    
    private static let POSIX_LOCALE = Locale(identifier: "en_US_POSIX")
    
    private static let SHORT_FORMAT =  "yyyy-MM-dd HH:mm:ss ZZZZZ"
    private static let MEDIUM_FORMAT = "yyyy-MM-dd HH:mm:ss.SSS ZZZZZ"
    private static let LONG_FORMAT =   "yyyy-MM-dd HH:mm:ss.SSS'MS' ZZZZZ"
    
    static let formatterForTimeZone = {(format: String, zone: TimeZone?) -> DateFormatter in
        let fmt = DateFormatter()
        fmt.locale = POSIX_LOCALE
        fmt.dateFormat = format
        fmt.timeZone = zone
        return fmt
    }
    
    static func toValue(_ d: Date) -> String {
        let ts = TimeZone.current
        let ns = NSCalendar.current.component(.nanosecond, from: d)
        if ns == 0 {
            return Common.formatterForTimeZone(SHORT_FORMAT, ts).string(from: d)
        } else {
            let micros: Int = Int(((Double(ns) / 1000).rounded()))
            let microsRemainder = Int(Double(micros).truncatingRemainder(dividingBy: 1000))
            if microsRemainder == 0 {
                return Common.formatterForTimeZone(MEDIUM_FORMAT, ts).string(from: d)
            } else {
                return Common.formatterForTimeZone(LONG_FORMAT, ts).string(from: d)
                    .replacingOccurrences(of: "MS", with: String(format: "%03d", microsRemainder))
            }
        }
    }
}
