//
//  RecognizerTests.swift
//  TimeCalcTests
//
//  Created by Alex Moffat on 2/14/18.
//  Copyright © 2018 Zanthan. All rights reserved.
//

import XCTest
@testable import TimeCalc

class RecognizerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

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
    
    private func cmp(_ recognizer: Recognizer, _ dateAsString: String, _ dateAsDouble: Double, includesTimeZone: Bool) {
        let result = recognizer.tryToRecognize(dateAsString)
        XCTAssertFalse(result == nil, "Did not recognize " + dateAsString)
        if result != nil {
        XCTAssertEqual("", result?.remainder, "Did not consume all \"" + dateAsString + "\" - remainder " + (result?.remainder)!)
        XCTAssertEqual(Token.DateTime(Date(timeIntervalSince1970: dateAsDouble), includesTimeZone), result?.token, "Did not correctly parse " + dateAsString)
        }
    }

}
