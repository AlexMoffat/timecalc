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
 * Format a value in milliseconds as a number of days, hours, minutes, seconds and milliseconds. You can choose the larges unit to
 * use, for example you can have a format with a largest unit of minutes. Zero values are not output, so 2d 10m not 2d 0h 10m.
 */
class MillisFormatter {
    
    typealias Unit = (millis: Int, suffix: String)
    
    static let units = [
        (millis: 24 * 60 * 60 * 1000, suffix: "d"),
        (millis:      60 * 60 * 1000, suffix: "h"),
        (millis:           60 * 1000, suffix: "m"),
        (millis:                1000, suffix: "s"),
        (millis:                   1, suffix: "ms")
    ]
    
    func format(ms: Int, withLargestUnit: String = "d") -> String {
        let sign = ms < 0 ? "-" : ""
        var remainingValue = abs(ms)
        var values = [String]()
        var format = false
        
        for unit in MillisFormatter.units {
            if !format && withLargestUnit == unit.suffix {
                format = true
            }
            if format && remainingValue >= unit.millis {
                values.append(sign + String(remainingValue / unit.millis) + unit.suffix)
                remainingValue = remainingValue % unit.millis
            }
        }
        
        assert(remainingValue == 0)
        
        return values.joined(separator: " ")
    }
}
