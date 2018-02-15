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

class MillisFormatterTest: XCTestCase {

    var formatter = MillisFormatter()

    func testFormatter() {
        
        XCTAssertEqual("1d", formatter.format(ms: 24 * 60 * 60 * 1000))
        
        XCTAssertEqual("2d 3h", formatter.format(ms: (2 * 24 + 3) * 60 * 60 * 1000))
        
        XCTAssertEqual("2d 10m", formatter.format(ms: (2 * 24 * 60 + 10) * 60 * 1000))
        
        XCTAssertEqual("1d 10m 15ms", formatter.format(ms: (24 * 60 + 10) * 60 * 1000 + 15))
        
        XCTAssertEqual("1d 10m 45s 15ms", formatter.format(ms: ((24 * 60 + 10) * 60 + 45) * 1000 + 15))
        
        XCTAssertEqual("2h 25s", formatter.format(ms: (2 * 60 * 60 + 25) * 1000))
        
        XCTAssertEqual("-10m -5s", formatter.format(ms: -(10 * 60 + 5) * 1000))
        
        XCTAssertEqual("51h", formatter.format(ms: (2 * 24 + 3) * 60 * 60 * 1000, withLargestUnit: "h"))
        
        XCTAssertEqual("24h 10m 45s 15ms", formatter.format(ms: ((24 * 60 + 10) * 60 + 45) * 1000 + 15, withLargestUnit: "h"))
        
        XCTAssertEqual("1450m 45s 15ms", formatter.format(ms: ((24 * 60 + 10) * 60 + 45) * 1000 + 15, withLargestUnit: "m"))
    }
}
