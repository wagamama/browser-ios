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

            guard let deviceId = getDeviceIdAsJSArray() else {
                print("SyncLog: failed to get device id")
                return webCfg
            }
            var config = "var injected_deviceId = new Uint8Array(\(deviceId)); "

            if let seed = getSeedAsJSArray() {
                config += "var injected_seed = new Uint8Array(\(seed)); "
            } else {
                config += "var injected_seed = null; "
            }

            #if DEBUG
                config += "const injected_braveSyncConfig = {apiVersion: '0', serverUrl: 'https://sync-staging.brave.com', debug:true}"
            #else
                config += "const injected_braveSyncConfig = {apiVersion: '0', serverUrl: 'https://sync.brave.com'}"
            #endif

            userController.addUserScript(WKUserScript(source: config, injectionTime: .AtDocumentEnd, forMainFrameOnly: true))


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

    // return "[1,2,3,4,...,16]" for sending to javascript
    func getDeviceIdAsJSArray() -> String? {
        let prefName = "device-id-js-array"
        var key = NSUserDefaults.standardUserDefaults().stringForKey(prefName)
        if key == nil || key!.isEmpty {
            var uuidBytes = [UInt8](count: 16, repeatedValue: 0)
            guard let identifier = UIDevice.currentDevice().identifierForVendor else { return nil }
            identifier.getUUIDBytes(&uuidBytes)
            let data = NSData(bytes: &uuidBytes, length: 16)
            let dataAsArray = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(data.bytes), count: data.length))
            key = "\(dataAsArray)" // conveniently formats as [1,2,3,4...]
            NSUserDefaults.standardUserDefaults().setValue(key, forKey: prefName)
        }
        return key
    }

    func saveSeed(seed: String) {
        // SwiftKeychainWrapper
        print("TODO: save seed in keychain")
    }

    func getSeedAsJSArray() -> String? {
        // todo get from keychain
        return "[62, 109, 38, 113, 48, 33, 85, 86, 26, 37, 230, 142, 34, 79, 26, 231, 16, 126, 204, 5, 202, 59, 108, 187, 95, 211, 108, 181, 21, 188, 127, 148]"
    }
}

extension SyncWebView: WKScriptMessageHandler {
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        //print("😎 \(message.name) \(message.body)")
        guard let data = message.body as? [String: AnyObject], let messageName = data["message"] as? String else {
            assert(false) ;
            return
        }

        switch messageName {
        case "save-init-data" :
            if let seed = data["arg1"] as? String { // strange format "{ 0 = 23; 1 = 204; 10 = 151; }"
                print(seed)
                saveSeed(seed)
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
            webView.evaluateJavaScript("callbackList['fetch-sync-records'](null, ['0','1','2'], 0)",
                                       completionHandler: { (result, error) in
                print(result)
                print(error)
            })
            break
        case "send-sync-records":
            /* browser -> webview, sends this to the webview with the data that needs to be synced to the sync server.
            @param {string} categoryName, @param {Array.<Object>} records */
            break
        default:
            print("\(messageName) not handled yet")
        }
    }

}

