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
    
    /// Used to retrive unique bytes for UUIDs (e.g. bookmarks), that will map well with niceware
    /// count: The number of unique bytes desired
    /// returns (via completion): Array of unique bytes
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
    
    /// Takes hex values and returns associated English words
    /// fromBytes: Array of hex strings (no "0x" prefix) : ["00", "ee", "4a", "42"]
    /// returns (via completion): Array of words from niceware that map to those hex values : ["administrational", "experimental"]
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
    
    /// Takes a joined string of unique hex bytes (e.g. from QR code) and splits up the hex values
    /// fromJoinedBytes: a single string of hex data (even # of chars required): 897a6f0219fd2950
    /// return: hex values split into 8 bit groupings ["98", "7a", "6f", ...]
    func splitBytes(fromJoinedBytes bytes: String) -> [String]? {
        var chars = bytes.characters.map { String($0) }
        
        if chars.count % 2 == 1 {
            // Must be an even array
            return nil
        }
        
        var result = [String]()
        while !chars.isEmpty {
            result.append(chars[0...1].reduce("", combine: +))
            chars.removeFirst(2) // According to docs thsi returns removed result, behavior is different (at least for Swift 2.3)
        }
        return result.isEmpty ? nil : result
    }
    
    /// Takes English words and returns associated bytes (2 bytes per word)
    /// fromPassphrase: An array of words : ["administrational", "experimental"]
    /// returns (via completion): Array of integer values : [00, ee, 4a, 42]
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
