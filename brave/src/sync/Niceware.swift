/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit

class Niceware: JSInjector {

    static let shared = Niceware()
    
    private let nicewareWebView = WKWebView(frame: CGRectZero, configuration: Niceware.webConfig)
    /// Whehter or not niceware is ready to be used
    private var isNicewareReady = false
    
    override init() {
        super.init()
        
        // Overriding javascript check for this subclass
        self.isJavascriptReadyCheck = { return self.isNicewareReady }
        
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
    
    func uniqueBytes(count byteCount: Int, completion: ((AnyObject?, NSError?) -> Void)?) {
        // TODO: Add byteCount validation (e.g. must be even)
        executeBlockOnReady {
            self.nicewareWebView.evaluateJavaScript("niceware.passphraseToBytes(niceware.generatePassphrase(\(byteCount)))") { (one, error) in
                print(one)
                print(error)
                completion?(one, error)
            }
        }
    }
    
    /// This requires native hex strings
    // TODO: Massage data a bit more for completion block
    func passphrase(fromBytes bytes: Array<String>, completion: ((AnyObject?, NSError?) -> Void)?) {
        
        executeBlockOnReady {
            
            let intBytes = bytes.map({ Int($0, radix: 16) ?? 0 })
            let input = "new Uint8Array(\(intBytes))"
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
    }
    
    // TODO: Add docs
    func bytes(fromPassphrase passphrase: Array<String>, completion: (([Int]?, NSError?) -> Void)?) {
        // TODO: Add some keyword validation
        executeBlockOnReady {
            
            let jsToExecute = "niceware.passphraseToBytes(\(passphrase));"
            
            self.nicewareWebView.evaluateJavaScript(jsToExecute, completionHandler: {
                (result, error) in
                
                // Result comes in the format [Index(String): Value(Int)]
                //  Since dictionary is unordered, index must be pulled via string values
                guard let nativeResult = result as? [String:Int] else {
                    completion?(nil, nil)
                    return
                }
                
                let bytes = self.javascriptDictionaryAsNativeArray(nativeResult)
                
                completion?(bytes, error)
            })
        }
    }
}

extension Niceware: WKNavigationDelegate {
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        self.isNicewareReady = true
    }
}
