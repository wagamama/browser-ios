import UIKit
import WebKit

/*
 var http = new XMLHttpRequest();
 var url = "https://sync-staging.brave.com/abcdefg/credentials";
 var params = "";
 http.open("POST", url, true);
 http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
 http.onreadystatechange = function() {
     if(http.readyState == 4 && http.status == 200) {
         alert(http.responseText);
     }
 }
 http.send(params);
 */

class SyncWebView: UIViewController {
    var webView: WKWebView!

    var webConfig:WKWebViewConfiguration {
        get {
            let webCfg = WKWebViewConfiguration()
            let userController = WKUserContentController()

            var config = "var injected_seed = new Uint8Array([243, 203, 185, 143, 101, 184, 134, 109, 69, 166, 218, 58, 63, 155, 158, 17, 31, 184, 175, 52, 73, 80, 190, 47, 45, 12, 59, 64, 130, 13, 146, 248]); " +
                        "var injected_deviceId = new Uint8Array([1,2,3,4]); "
            #if DEBUG
                config += "const injected_braveSyncConfig = {apiVersion: '0', serverUrl: 'https://sync-staging.brave.com', debug:true}"
            #else
                config += "const injected_braveSyncConfig = {apiVersion: '0', serverUrl: 'https://sync.brave.com'}"
            #endif

            userController.addUserScript(WKUserScript(source: config, injectionTime: .AtDocumentEnd, forMainFrameOnly: true))

            userController.addScriptMessageHandler(self, name: "syncToIOS")

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
}

extension SyncWebView: WKScriptMessageHandler {
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        print("😎 \(message.body)")
        guard let data = message.body as? [String: AnyObject] else { assert(false) ; return }
        print(data)
    }

}

