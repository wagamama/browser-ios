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

class SyncWebView: UIViewController {
    var webView: WKWebView!

    var webConfig:WKWebViewConfiguration {
        get {
            let webCfg = WKWebViewConfiguration()
            let userController = WKUserContentController()

            userController.addScriptMessageHandler(self, name: "syncToIOS_on")
            userController.addScriptMessageHandler(self, name: "syncToIOS_send")

            ["fetch", "ios-sync", "bundle"].forEach() {
                userController.addUserScript(WKUserScript(source: getScript($0), injectionTime: .AtDocumentEnd, forMainFrameOnly: true))
            }

            webCfg.userContentController = userController
            return webCfg
        }
    }

    func getScript(name:String) -> String {
        let filePath = NSBundle.mainBundle().pathForResource(name, ofType:"js")
        return try! String(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.frame = CGRectMake(20, 20, 300, 300)
        webView = WKWebView(frame: view.frame, configuration: webConfig)
        //webView.navigationDelegate = self
        view.addSubview(webView)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        webView.loadHTMLString("<body>TEST</body>", baseURL: nil)
    }

    func webView(webView: WKWebView, didFinish navigation: WKNavigation!) {
        print(#function)
    }

    let prefNameId = "device-id-js-array"
    let prefNameSeed = "seed-js-array"

    var syncDeviceId: String {
        get {
            let val = NSUserDefaults.standardUserDefaults().stringForKey(prefNameId)
            return val == nil || val!.isEmpty ? "null" : "new Uint8Array(\(val!))"
        }
        set(value) {
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: prefNameId)
        }
    }

    var syncSeed: String {
        get {
            let val = NSUserDefaults.standardUserDefaults().stringForKey(prefNameSeed)
            return val == nil || val!.isEmpty ? "null" : "new Uint8Array(\(val!))"
        }
        set(value) {
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: prefNameSeed)
        }
    }

//    func getInitData() {
//        var config =
//            "var injected_deviceId = \(syncDeviceId); " +
//            "var injected_seed = \(syncSeed); "
//
//        #if DEBUG
//            config += "const injected_braveSyncConfig = {apiVersion: '0', serverUrl: 'https://sync-staging.brave.com', debug:true}"
//        #else
//            config += "const injected_braveSyncConfig = {apiVersion: '0', serverUrl: 'https://sync.brave.com'}"
//        #endif
//
//        webView.evaluateJavaScript(config,
//                                   completionHandler: { (result, error) in
//                                    print(result);print(error) })
//
//    }
}

extension SyncWebView: WKScriptMessageHandler {
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        print("😎 \(message.name) \(message.body)")
        guard let data = message.body as? [String: AnyObject], let messageName = data["message"] as? String else {
            assert(false) ;
            return
        }

        /*
         resolve-sync-records not handled yet
         delete-sync-user not handled yet
         delete-sync-category not handled yet
         delete-sync-site-settings not handled yet
         */
        switch messageName {
        case "get-init-data":
            //getInitData()
            break
        case "got-init-data":
//            if (cb) {
//                initCb = cb
//            }
//            // native has injected these varibles into the js context, or from 'save-init-data'
//            initCb(null, injected_seed, injected_deviceId, injected_braveSyncConfig)
//        } else {
            let args = "(null, \(syncSeed), \(syncDeviceId), {apiVersion: '0', serverUrl: 'https://sync-staging.brave.com', debug:true})"
            print(args)
            webView.evaluateJavaScript("callbackList['got-init-data']\(args)",
                                       completionHandler: { (result, error) in
                                        print(result)
                                        print(error)
            })


        case "save-init-data" :
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
        case "sync-debug":
            print("Sync Debug: \(data)")
        case "sync-ready":
            break
        case "fetch-sync-records":
            /*  browser -> webview: sent to fetch sync records after a given start time from the sync server.
            @param Array.<string> categoryNames, @param {number} startAt (in seconds) **/
            webView.evaluateJavaScript("callbackList['fetch-sync-records'](null, ['BOOKMARKS'], 0)",
                                       completionHandler: { (result, error) in
                print(result)
                print(error)
            })
        case "send-sync-records":
            /* browser -> webview, sends this to the webview with the data that needs to be synced to the sync server.
            @param {string} categoryName, @param {Array.<Object>} records */
            webView.evaluateJavaScript("callbackList['send-sync-records'](null, ['BOOKMARKS'], 0)",
                                       completionHandler: { (result, error) in
                print(result)
                print(error)
            })
        default:
            print("\(messageName) not handled yet")
        }
    }

}

