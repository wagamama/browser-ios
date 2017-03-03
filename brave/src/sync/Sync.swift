/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit

/*
 module.exports.categories = {
 BOOKMARKS: '0',
 HISTORY_SITES: '1',
 PREFERENCES: '2'
 }

 module.exports.actions = {
 CREATE: 0,
 UPDATE: 1,
 DELETE: 2
 }
 */

let NotificationSyncReady = "NotificationSyncReady"

enum SyncRecordType : String {
    case bookmark = "BOOKMARKS"
    case history = "HISTORY_SITES"
    case prefs = "PREFERENCES"
}

enum SyncActions: Int {
    case create = 0
    case update = 1
    case delete = 2

}

class Sync: NSObject {
    static let singleton = Sync()

    private var webView: WKWebView!

    var isSyncFullyInitialized = (syncReady: Bool, fetchReady: Bool, sendRecordsReady: Bool, resolveRecordsReady: Bool, deleteUserReady: Bool, deleteSiteSettingsReady: Bool, deleteCategoryReady: Bool)(false, false, false, false, false, false, false)

    private let prefNameId = "device-id-js-array"
    private let prefNameSeed = "seed-js-array"
    #if DEBUG
    private let isDebug = true
    private let serverUrl = "https://sync-staging.brave.com"
    #else
    private let isDebug = false
    private let serverUrl = "https://sync.brave.com"
    #endif

    private let apiVersion = 0

    private var webConfig:WKWebViewConfiguration {
        let webCfg = WKWebViewConfiguration()
        let userController = WKUserContentController()

        userController.addScriptMessageHandler(self, name: "syncToIOS_on")
        userController.addScriptMessageHandler(self, name: "syncToIOS_send")

        // ios-sync must be called before bundle, since it auto-runs
        ["fetch", "ios-sync", "bundle"].forEach() {
            userController.addUserScript(WKUserScript(source: Sync.getScript($0), injectionTime: .AtDocumentEnd, forMainFrameOnly: true))
        }

        webCfg.userContentController = userController
        return webCfg
    }
    
    override init() {
        super.init()
        webView = WKWebView(frame: CGRectZero, configuration: webConfig)
        self.webView.loadHTMLString("<body>TEST</body>", baseURL: nil)
    }

    class func getScript(name:String) -> String {
        // TODO: Add unwrapping warnings
        // TODO: Place in helper location
        let filePath = NSBundle.mainBundle().pathForResource(name, ofType:"js")
        return try! String(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding)
    }

    private func webView(webView: WKWebView, didFinish navigation: WKNavigation!) {
        print(#function)
    }

    private var syncDeviceId: String {
        get {
            let val = NSUserDefaults.standardUserDefaults().stringForKey(prefNameId)
            return val == nil || val!.isEmpty ? "null" : "new Uint8Array(\(val!))"
        }
        set(value) {
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: prefNameId)
        }
    }

    // TODO: Move to keychain
    private var syncSeed: String {
        get {
            let val = NSUserDefaults.standardUserDefaults().stringForKey(prefNameSeed)
            return val == nil || val!.isEmpty ? "null" : "new Uint8Array(\(val!))"
        }
        set(value) {
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: prefNameSeed)
        }
    }

    private func checkIsSyncReady() -> Bool {
        struct Static {
            static var isReady = false
        }
        if Static.isReady {
            return true
        }

        let mirror = Mirror(reflecting: isSyncFullyInitialized)
        let ready = mirror.children.reduce(true) { $0 && $1.1 as! Bool }
        if ready {
            NSNotificationCenter.defaultCenter().postNotificationName(NotificationSyncReady, object: nil)
            Static.isReady = true
        }
        return ready
    }
 }

// MARK: Native-initiated Message category
extension Sync {
    func sendSyncRecords(recordType: [SyncRecordType], recordJson: String) {
        /* browser -> webview, sends this to the webview with the data that needs to be synced to the sync server.
         @param {string} categoryName, @param {Array.<Object>} records */
        let arg1 = recordType.reduce("[") { $0 + "'\($1.rawValue)'," } + "]"
        webView.evaluateJavaScript("callbackList['send-sync-records'](null, \(arg1),\(recordJson))",
                                   completionHandler: { (result, error) in
//                                    print(result)
//                                    if error != nil {
//                                        print(error)
//                                    }
        })
    }

    func gotInitData() {
        let args = "(null, \(syncSeed), \(syncDeviceId), {apiVersion: '\(apiVersion)', serverUrl: '\(serverUrl)', debug:\(isDebug)})"
        print(args)
        webView.evaluateJavaScript("callbackList['got-init-data']\(args)",
                                   completionHandler: { (result, error) in
//                                    print(result)
//                                    if error != nil {
//                                        print(error)
//                                    }
        })
    }
    func fetch() {
        /*  browser -> webview: sent to fetch sync records after a given start time from the sync server.
         @param Array.<string> categoryNames, @param {number} startAt (in seconds) **/
        webView.evaluateJavaScript("callbackList['fetch-sync-records'](null, ['BOOKMARKS'], 0)",
                                   completionHandler: { (result, error) in
//                                    print(result)
//                                    if error != nil {
//                                        print(error)
//                                    }
        })
    }

    func resolveSyncRecords(data: [String: AnyObject]) {
        print("not implemented: resolveSyncRecords() \(data)")
    }

    func deleteSyncUser(data: [String: AnyObject]) {
        print("not implemented: deleteSyncUser() \(data)")
    }

    func deleteSyncCategory(data: [String: AnyObject]) {
        print("not implemented: deleteSyncCategory() \(data)")
    }

    func deleteSyncSiteSettings(data: [String: AnyObject]) {
        print("not implemented: delete sync site settings \(data)")
    }

}

// MARK: Server To Native Message category
extension Sync {

    func getExistingObjects(data: [String: AnyObject]) {
        guard let typeName = data["arg1"] as? String,
            let objects = data["arg2"] as? [[String: AnyObject]] else { return }
        /*▿ Top level keys: "bookmark", "action","objectId", "objectData:bookmark","deviceId" */
        for item in objects {
            if item["objectData"] as? String == "bookmark" {
                print("parse a bookmark")
            }
        }
    }

    func saveInitData(data: [String: AnyObject]) {
        if let seedDict = data["arg1"] as? [String: Int] {
            var seedArray = [Int](count: 32, repeatedValue: 0)
            for (k, v) in seedDict {
                if let k = Int(k) where k < 32 {
                    seedArray[k] = v
                }
            }
            syncSeed = "\(seedArray)"

            if let idDict = data["arg2"] as? [String: Int] {
                if let id = idDict["0"] {
                    syncDeviceId = "[\(id)]"
                    print(id)
                }
            }
        } else {
            print("Seed expected.")
        }
    }

}

extension Sync: WKScriptMessageHandler {
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        //print("😎 \(message.name) \(message.body)")
        guard let data = message.body as? [String: AnyObject], let messageName = data["message"] as? String else {
            assert(false) ;
            return
        }

        switch messageName {
        case "get-init-data":
//            getInitData()
            break
        case "got-init-data":
            gotInitData()
        case "save-init-data" :
            saveInitData(data)
        case "get-existing-objects":
            getExistingObjects(data)
        case "sync-debug":
            print("---- Sync Debug: \(data)")
        case "sync-ready":
            isSyncFullyInitialized.syncReady = true
        case "fetch-sync-records":
            isSyncFullyInitialized.fetchReady = true
        case "send-sync-records":
            isSyncFullyInitialized.sendRecordsReady = true
        case "resolve-sync-records":
            isSyncFullyInitialized.resolveRecordsReady = true
        case "delete-sync-user":
            isSyncFullyInitialized.deleteUserReady = true
        case "delete-sync-site-settings":
            isSyncFullyInitialized.deleteSiteSettingsReady = true
        case "delete-sync-category":
            isSyncFullyInitialized.deleteCategoryReady = true
        default:
            print("\(messageName) not handled yet")
        }

        checkIsSyncReady()
    }
}

