/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
@testable import Client
import Shared

class JSInjectorTest: XCTestCase {

    var injector = JSInjector()
    
    // General usecase
    func testJSDictToNativeArrayWithValidDataIntResult() {
        // [String:Int] -> Int
        let validInput = [ "2" : 2, "9" : 9, "5" : 5, "0" : 0, "1" : 1, "4" : 4, "6" : 6, "8" : 8, "7" : 7, "3" : 3 ]
        let expected = Array(0..<validInput.count)
        
        let result = injector.javascriptDictionaryAsNativeArray(validInput)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(validInput.count, result!.count)
        XCTAssertEqual(result!, expected)
    }
    
    // Validating that works for any value.type
    func testJSDictToNativeArrayWithValidDataStringResult() {
        // [String:String] -> String
        let validInput = [ "2" : "two", "9" : "nine", "5" : "five", "0" : "zero", "1" : "one", "4" : "four", "6" : "six", "8" : "eight", "7" : "seven", "3" : "three" ]
        let expected = [ "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" ];
        
        let result = injector.javascriptDictionaryAsNativeArray(validInput)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(validInput.count, result!.count)
        XCTAssertEqual(result!, expected)
    }
    
    // If dictionary is missing a string index, validate func dose not fail silently
    func testJSDictToNativeArrayWithMissingIndex() {
        // Missing index 4
        let invalidInput = [ "2" : 2, "9" : 9, "5" : 5, "0" : 0, "1" : 1, /*"4" : 4, */"6" : 6, "8" : 8, "7" : 7, "3" : 3 ]
        
        let result = injector.javascriptDictionaryAsNativeArray(invalidInput)
        XCTAssertNil(result, "js dict to native array with missing index did not return nil")

    }
}
