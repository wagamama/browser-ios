/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit

class Niceware: NSObject {

    static let shared = Niceware()
    
    private let nicewareWebView = WKWebView(frame: CGRectZero, configuration: Niceware.webConfig)
    /// Whehter or not niceware is ready to be used
    private var isNicewareReady = false
    /// The number of attempts that has been delayed, waiting for niceware to be ready
    private var readyDelayAttempts = 0

    
    override init() {
        super.init()
        // Load HTML and await for response, to verify the webpage is loaded to receive niceware commands
        self.nicewareWebView.navigationDelegate = self;
        // Must load HTML for delegate method to fire
        self.nicewareWebView.loadHTMLString("<body>TEST</body>", baseURL: nil)
    }
    
    private class var webConfig:WKWebViewConfiguration {
        let webCfg = WKWebViewConfiguration()
        webCfg.userContentController = WKUserContentController()
        webCfg.userContentController.addUserScript(WKUserScript(source: Sync.getScript("niceware"), injectionTime: .AtDocumentEnd, forMainFrameOnly: true))
        return webCfg
    }
    
    // TODO: Massage data a bit more for completion block
    func passphrase(fromBytes bytes: Array<String>, completion: ((AnyObject?, NSError?) -> Void)?) {
        
        if !self.isNicewareReady && readyDelayAttempts < 2 {
            // If delay attempts exceeds limit, and still not ready, evaluateJS will just throw errors in the completion block
            readyDelayAttempts += 1
            
            // Perform delayed attempt
            // TODO: Update with Swift 3 syntax
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.5) * Int64(NSEC_PER_SEC)), dispatch_get_main_queue(), {
                self.passphrase(fromBytes: bytes, completion: completion)
            })
            
            return;
        }
        
        
        let input = "new Uint8Array([73, 206, 112, 84, 16, 109, 201, 101, 153, 50, 112, 98, 52, 236, 203, 60, 125, 53, 53, 220, 146, 159, 46, 244, 108, 121, 60, 5, 128, 71, 3, 56])"
        let jsToExecute = "niceware.bytesToPassphrase(\(input));"
        
        self.nicewareWebView.evaluateJavaScript(jsToExecute, completionHandler: {
            (result, error) in
                
            print(result)
            if error != nil {
                print(error)
            }
            
            completion?(result, error)
        })
            
    }
    
    func bytes(fromPassphrase: Array<String>) -> Array<String> {
        return [""]
    }
}


extension Niceware: WKNavigationDelegate {
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        self.isNicewareReady = true
    }

}
