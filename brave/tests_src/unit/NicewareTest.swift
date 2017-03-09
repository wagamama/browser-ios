/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class NicewareTest: XCTestCase {
    
    func testNewByteSeed() {
        
    }
    
    func testNewPassphrase() {
        
    }
    
    func testPassphraseToByte() {
        
    }
    
    func testByteToPassphrase() {
        let niceware = Niceware()
        
        let expect = self.expectationWithDescription("byteToPassphrase attempt")
        niceware.passphrase(fromBytes: ["00", "ee", "4a", "42", "3a", "a3", "a3", "0f", "59", "5f", "c2", "00", "fa", "6a", "d9", "c9", "63", "38", "bb", "02", "0c", "37", "5b", "92", "98", "e7", "68", "79", "84", "ba", "e1", "9f"]) { (result, error) in
            XCTAssertNil(error, "byteToPassphrase contained error")
            XCTAssertNotNil(result, "byteToPassphrase result was nil")
            
            guard let resultWithStrings = result as? [String] else {
                XCTAssert(false, "byteToPassphrase cast to [String] failed")
                return
            }
            
            XCTAssertEqual(resultWithStrings, ["administrational","experimental","disconnection","plane","gigaton","savaging","wheaten","suez","herman","retina","bailment","gorier","overmodestly","idealism","mesa","theurgy",])
            
            expect.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(4) { error in
            XCTAssertNil(error, "Niceware error with `passphrase`")
        }
    }
    
}
