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
    func uniqueBytes(count byteCount: Int, completion: (([Int]?, NSError?) -> Void)?) {
        // TODO: Add byteCount validation (e.g. must be even)
        executeBlockOnReady {
            self.nicewareWebView.evaluateJavaScript("JSON.stringify(niceware.passphraseToBytes(niceware.generatePassphrase(\(byteCount))))") { (result, error) in
                
                // TODO: Accross all of these functions
                //  Should abstract logic
                //  Make sure completion block is executed via defer, to guarantee it has been run
                
                guard let result = result else {
                    return
                }
                
                guard let nativeResult = NSJSONSerialization.swiftObject(withJSON: result) as? [String: AnyObject] else {
                    return
                }
                
                guard let bytes = nativeResult["data"] as? [Int] else {
                    return
                }
                
                completion?(bytes, error)
            }
        }
    }
    
    /// Takes hex values and returns associated English words
    /// fromBytes: Array of hex strings (no "0x" prefix) : ["00", "ee", "4a", "42"]
    /// returns (via completion): Array of words from niceware that map to those hex values : ["administrational", "experimental"]
    // TODO: Massage data a bit more for completion block
    func passphrase(fromBytes bytes: [Int], completion: (([String]?, NSError?) -> Void)?) {
        
        executeBlockOnReady {
            
            let input = "new Uint8Array(\(bytes))"
            let jsToExecute = "JSON.stringify(niceware.bytesToPassphrase(\(input)));"
            
            self.nicewareWebView.evaluateJavaScript(jsToExecute, completionHandler: {
                (result, error) in
                    
                guard let result = result else {
                    return
                }
                
                guard let nativeResult = NSJSONSerialization.swiftObject(withJSON: result) as? [String: AnyObject] else {
                    return
                }
                
                guard let words = nativeResult["data"] as? [String] else {
                    return
                }
                
                completion?(words, error)
            })
        }
    }
    
    /// Takes joined string of unique hex bytes (e.g. from QR code) and returns
    func passphrase(fromJoinedBytes bytes: String, completion: (([String]?, NSError?) -> Void)?) {
        if let split = splitBytes(fromJoinedBytes: bytes) {
            return passphrase(fromBytes: split, completion: completion)
        }
        // TODO: Create real error
        completion?(nil, nil)
    }
    
    /// Takes a joined string of unique hex bytes (e.g. from QR code) and splits up the hex values
    /// fromJoinedBytes: a single string of hex data (even # of chars required): 897a6f0219fd2950
    /// return: integer values split into 8 bit groupings [0x98, 0x7a, 0x6f, ...]
    func splitBytes(fromJoinedBytes bytes: String) -> [Int]? {
        var chars = bytes.characters.map { String($0) }
        
        if chars.count % 2 == 1 {
            // Must be an even array
            return nil
        }
        
        var result = [Int]()
        while !chars.isEmpty {
            let hex = chars[0...1].reduce("", combine: +)
            guard let integer = Int(hex, radix: 16) else {
                // bad error
                return nil
            }
            result.append(integer)
            chars.removeFirst(2) // According to docs this returns removed result, behavior is different (at least for Swift 2.3)
        }
        return result.isEmpty ? nil : result
    }
    
    /// Takes English words and returns associated bytes (2 bytes per word)
    /// fromPassphrase: An array of words : ["administrational", "experimental"]
    /// returns (via completion): Array of integer values : [0x00, 0xee, 0x4a, 0x42]
    func bytes(fromPassphrase passphrase: Array<String>, completion: (([Int]?, NSError?) -> Void)?) {
        // TODO: Add some keyword validation
        executeBlockOnReady {
            
            let jsToExecute = "JSON.stringify(niceware.passphraseToBytes(\(passphrase)));"
            
            self.nicewareWebView.evaluateJavaScript(jsToExecute, completionHandler: {
                (result, error) in
                
                guard let nativeResult = NSJSONSerialization.swiftObject(withJSON: result) as? [String: AnyObject] else {
                    return
                }
                
                guard let bytes = nativeResult["data"] as? [Int] else {
                    return
                }
                
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
