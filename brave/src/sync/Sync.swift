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

class Sync: JSInjector {
    static let singleton = Sync()

    /// This must be public so it can be added into the view hierarchy 
    var webView: WKWebView!

    var isSyncFullyInitialized = (syncReady: Bool, fetchReady: Bool, sendRecordsReady: Bool, resolveRecordsReady: Bool, deleteUserReady: Bool, deleteSiteSettingsReady: Bool, deleteCategoryReady: Bool)(false, false, false, false, false, false, false)

    // TODO: Move to a better place
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
        
        // TODO: Remove - currently for sync testing
//        syncSeed = nil
        
        self.isJavascriptReadyCheck = checkIsSyncReady
        self.maximumDelayAttempts = 15
        self.delayLengthInSeconds = Int64(3.0)
        
        webView = WKWebView(frame: CGRectMake(30, 30, 300, 500), configuration: webConfig)
        // Attempt sync setup
        initializeSync()
    }
    
    /// Sets up sync to actually start pulling/pushing data. This method can only be called once
    /// seed (optional): The user seed, in the form of string hex values. Must be even number : ["00", "ee", "4a", "42"]
    /// Notice:: seed will be ignored if the keychain already has one, a user must disconnect from existing sync group prior to joining a new one
    func initializeSync(seed: [Int]? = nil) {
        
        if let joinedSeed = seed where joinedSeed.count > 0 {
            // Always attempt seed write, setter prevents bad overwrites
            syncSeed = "\(joinedSeed)"
        }
        
        // Autoload sync if already connected to a sync group, otherwise just wait for user initiation
        if let _ = syncSeed {
            self.webView.loadHTMLString("<body>TEST</body>", baseURL: nil)
        }
    }
    
    func initializeNewSyncGroup() {
        if syncSeed != nil {
            // Error, to setup new sync group, must have no seed
            return
        }
        
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

    private var syncDeviceId: String? {
        get {
            return jsArray(userDefaultKey: prefNameId)
        }
        set(value) {
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: prefNameId)
        }
    }
    
    /// Seed as 16 unique words
    var seedAsPassphrase: Array<String> {
        return [""]
    }
    
    /// Seed byte array, 2 indeces for each word
    var seedAsBytes: String {
        return ""
    }

    // TODO: Move to keychain
    private var syncSeed: String? {
        get {
            return jsArray(userDefaultKey: prefNameSeed)
        }
        set(value) {
            if syncSeed != nil && value != nil {
                // Error, cannot replace sync seed with another seed
                //  must set syncSeed to ni prior to replacing it
                return
            }
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: prefNameSeed)
        }
    }
    
    private func jsArray(userDefaultKey key: String) -> String? {
        if let val = NSUserDefaults.standardUserDefaults().stringForKey(key) {
            return "new Uint8Array(\(val))"
        }
        
        return nil
    }

    func checkIsSyncReady() -> Bool {
        struct Static {
            static var isReady = false
        }
        
        print("******")
        print(isSyncFullyInitialized.0, isSyncFullyInitialized.1, isSyncFullyInitialized.2, isSyncFullyInitialized.3, isSyncFullyInitialized.4, isSyncFullyInitialized.5, isSyncFullyInitialized.6)
        
        if Static.isReady {
            return true
        }

        let mirror = Mirror(reflecting: isSyncFullyInitialized)
        let ready = mirror.children.reduce(true) { $0 && $1.1 as! Bool }
        if ready {
            Static.isReady = true
            NSNotificationCenter.defaultCenter().postNotificationName(NotificationSyncReady, object: nil)
            
            // TODO: Start fetch recusive
            self.fetch()
        }
        return ready
    }
 }

// MARK: Native-initiated Message category
extension Sync {
    func sendSyncRecords(recordType: SyncRecordType, recordJson: String) {
        
        executeBlockOnReady() {
            /* browser -> webview, sends this to the webview with the data that needs to be synced to the sync server.
             @param {string} categoryName, @param {Array.<Object>} records */
//            let arg1 = recordType.reduce("[") { $0 + "'\($1.rawValue)'," } + "]"
            let evaluate = "callbackList['send-sync-records'](null, 'BOOKMARKS',\(recordJson))"
            print(evaluate)
            self.webView.evaluateJavaScript(evaluate,
                                       completionHandler: { (result, error) in
                                        print(result)
                                        if error != nil {
                                            print(error)
                                        }
            })
        }
    }

    func gotInitData() {
        let args = "(null, \(syncSeed ?? "null"), \(syncDeviceId ?? "null"), {apiVersion: '\(apiVersion)', serverUrl: '\(serverUrl)', debug:\(isDebug)})"
        print(args)
        webView.evaluateJavaScript("callbackList['got-init-data']\(args)",
                                   completionHandler: { (result, error) in
//                                    print(result)
//                                    if error != nil {
//                                        print(error)
//                                    }
        })
    }
    
    /// Makes call to sync to fetch new records, instead of just returning records, sync sends `get-existing-objects` message
    func fetch(completion: (NSError? -> Void)? = nil) {
        /*  browser -> webview: sent to fetch sync records after a given start time from the sync server.
         @param Array.<string> categoryNames, @param {number} startAt (in seconds) **/
        
        executeBlockOnReady() {
            self.webView.evaluateJavaScript("callbackList['fetch-sync-records'](null, ['BOOKMARKS'], 0)",
                                       completionHandler: { (result, error) in
                                        // Process merging
                                        
                                        
                                        print(error)
                                        completion?(error)
            })
        }
    }

    func resolvedSyncRecords(data: [String: AnyObject]) {
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
        guard let objects = data["arg2"] as? [[String: AnyObject]] else { return }
        /* Top level keys: "bookmark", "action","objectId", "objectData:bookmark","deviceId" */
        
        // Root "AnyObject" here should either be [String:AnyObject] or the string literal "null"
        var matchedBookmarks = [[AnyObject]]()
        for var fetchedBookmark in objects {
            guard let fetchedId = (fetchedBookmark["objectId"] as? [Int])?.description.withoutSpaces else {
                continue
            }
            
            // Pulls bookmarks individually from CD to verify duplicates do not get added
            let bookmarks = Bookmark.get(syncUUIDs: [fetchedId])
            
            // TODO: Validate count, should never be more than one!
            
            var singleBookmark = bookmarks?.first
            if singleBookmark == nil {
                // Add, not found

                if (fetchedBookmark["objectData"] as? String) == "bookmark",
                    let bookmark = fetchedBookmark["bookmark"] as? [String: AnyObject],
                    let site = bookmark["site"] as? [String: AnyObject] {
                    
                    let location = NSURL(string: (site["location"] as? String) ?? "")
                    
                    singleBookmark = Bookmark.add(url: location, title: site["title"] as? String, customTitle: site["customTitle"] as? String, syncUUID: fetchedId, created: site["creationTime"] as? UInt, lastAccessed: site["lastAccessedTime"] as? UInt, parentFolder: nil, isFolder: bookmark["isFolder"] as? Bool ?? false, save: true)
                    print("(url: \(location), title: \(site["title"] as? String), customTitle: \(site["customTitle"] as? String), syncUUID: \(fetchedId), created: \(site["creationTime"] as? UInt), lastAccessed: \(site["lastAccessedTime"] as? UInt), parentFolder: nil, isFolder: \(bookmark["isFolder"] as? Bool ?? false), save: true)")
                }
                
            }
            
            guard let bm = singleBookmark?.asSyncBookmark(deviceId: syncDeviceId ?? "0", action: 0) else {
                return
            }
            
            matchedBookmarks.append([fetchedBookmark, bm])
        }
        
        guard let serializedData = NSJSONSerialization.jsObject(withNative: matchedBookmarks) else {
            // Huge error
            return
        }
        
        let jsonParser = "JSON.parse(\"\(serializedData)\")"
        print(jsonParser)
        
        
        self.webView.evaluateJavaScript("callbackList['resolve-sync-records'](null, ['BOOKMARKS'], \(jsonParser))",
            completionHandler: { (result, error) in
                print(error)
        })
    }

    func saveInitData(data: [String: AnyObject]) {
        if let seedDict = data["arg1"] as? [String: Int] {
            
            // TODO: Use js util converter
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
        
        guard
            let data = NSJSONSerialization.swiftObject(withJSON: message.body),
            let messageName = data["message"] as? String else {
                
            assert(false)
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
            // TODO: Should just return records, and immediately call resolve-sync-records
            getExistingObjects(data)
        case "resolved-sync-records":
            resolvedSyncRecords(data)
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

