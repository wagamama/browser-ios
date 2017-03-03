/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
@testable import Client
import Shared

class SyncTest: XCTestCase {
    
    func testByteToPassphrase() {
        let niceware = Niceware()
        
        let expect = self.expectationWithDescription("byteToPassphrase attempt")
        niceware.passphrase(fromBytes: [""]) { (result, error) in
            XCTAssertNil(error, "byteToPassphrase contained error")
            expect.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(4) { error in
            XCTAssertNil(error, "Niceware error with `passphrase`")
        }
    }
    
    func testSync() {
        expectationForNotification(NotificationSyncReady, object: nil, handler:nil)
        var isOk = true
        waitForExpectationsWithTimeout(20) { (error:NSError?) -> Void in
            if let _ = error {
                isOk = false
                XCTAssert(false, "load data failed")
            }
        }

        if !isOk {
            return
        }

        var bm = "[{ action: \(SyncActions.delete.rawValue),"
        bm += "deviceId: [ 0 ]," +
            "objectId: [ 171, 177, 210, 122, 73, 79, 129, 2, 30, 151, 125, 139, 226, 96, 92, 144 ]," +
            "bookmark:" +
              "{ site:" +
                "{ location: 'https://www.google.com/'," +
                "title: 'Google'," +
                "customTitle: ''," +
                "lastAccessedTime: 1486066976216," +
                "creationTime: 0 }," +
                "isFolder: false," +
                "parentFolderObjectId: undefined } }]"
        Sync.singleton.sendSyncRecords([.bookmark], recordJson: bm)

        sleep(5)
        Sync.singleton.fetch()

        // Wait for something that doesn't arrive for now, replace this
        expectationForNotification("never arriving 🤡", object: nil, handler:nil)
        waitForExpectationsWithTimeout(20) { (error:NSError?) -> Void in
            if let _ = error {
                isOk = false
                XCTAssert(false, "error")
            }
        }

    }

}
