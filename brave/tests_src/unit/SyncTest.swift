/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
@testable import Client
import Shared

class SyncTest: XCTestCase {
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

        let bm = "[{ action: 0," +
            "deviceId: [ 0 ]," +
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
        SyncWebView.singleton.sendSyncRecords([.bookmark], recordJson: bm)

        sleep(5)
        SyncWebView.singleton.fetch()

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
