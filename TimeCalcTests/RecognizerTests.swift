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

class RecognizerTests: XCTestCase {

    func testISODatesWithMillis() {
        let recognizer = Recognizers.ISODatesWithMillis()
        
        cmp(recognizer, "2017-08-15 12:28:34.395 -0500", 1502818114.395, includesTimeZone: true)
        
        cmp(recognizer, "2017-06-17 12:00:03.340 -07:00", 1497726003.340, includesTimeZone: true)
        
        cmp(recognizer, "2017-06-17T12:00:03,340 -07:00", 1497726003.340, includesTimeZone: true)
        
        cmp(recognizer, "2017-06-17T12:00:03,340", 1497718803.340, includesTimeZone: false)
    }
    
    func testSentryDates() {
        let recognizer = Recognizers.SentryDates()
        
        cmp(recognizer, "Sep 29, 2017 2:00:23 PM UTC", 1506693623, includesTimeZone: true)
    }
    
    
    @available(OSX 10.13, *)
    func testJavaDurations() {
        let recognizer = Recognizers.JavaDuration()
        
        cmp(recognizer, "P2D", 2 * 24 * 60 * 60 * 1000)
        
        cmp(recognizer, "PT5.302s", 5 * 1000 + 302)
        
        cmp(recognizer, "PT2H1M10,4S", ((2 * 60 + 1) * 60 + 10) * 1000 + 400)
        
        cmp(recognizer, "-PT2S", -2000)
        
        cmp(recognizer, "PT-2S", -2000)
        
        cmp(recognizer, "PT1M-2S", 58000)
    }
    
    private func cmp(_ recognizer: Recognizer, _ dateAsString: String, _ dateAsDouble: Double, includesTimeZone: Bool) {
        let result = recognizer.tryToRecognize(dateAsString)
        XCTAssertFalse(result == nil, "Did not recognize " + dateAsString)
        if result != nil {
            XCTAssertEqual("", result?.remainder, "Did not consume all \"" + dateAsString + "\" - remainder " + (result?.remainder)!)
            XCTAssertEqual(Token.DateTime(Date(timeIntervalSince1970: dateAsDouble), includesTimeZone), result?.tokens[0], "Did not correctly parse " + dateAsString)
        }
    }
    
    private func cmp(_ recognizer: Recognizer, _ durationAsString: String, _ durationAsNum: Int) {
        let result = recognizer.tryToRecognize(durationAsString)
        XCTAssertFalse(result == nil, "Did not recognize " + durationAsString)
        if result != nil {
            XCTAssertEqual("", result?.remainder, "Did not consume all \"" + durationAsString + "\" - remainder " + (result?.remainder)!)
            XCTAssertEqual(Token.MillisDuration(durationAsNum), result?.tokens[0], "Did not correctly parse " + durationAsString)
        }
        
    }

}
