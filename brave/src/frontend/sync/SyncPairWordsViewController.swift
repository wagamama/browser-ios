/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

class SyncPairWordsViewController: UIViewController {
    
    var containerView: UIView!
    var helpLabel: UILabel!
    var codewordsView: SyncCodewordsView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.Pair
        view.backgroundColor = SyncBackgroundColor
        
        containerView = UIView()
        containerView.backgroundColor = UIColor.whiteColor()
        containerView.layer.shadowColor = UIColor(rgb: 0xC8C7CC).CGColor
        containerView.layer.shadowRadius = 0
        containerView.layer.shadowOpacity = 1.0
        containerView.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        view.addSubview(containerView)
        
        codewordsView = SyncCodewordsView(data: [])
        codewordsView.doneKeyCallback = {
            self.checkCodes()
        }
        containerView.addSubview(codewordsView)
        
        helpLabel = UILabel()
        helpLabel.font = UIFont.systemFontOfSize(15, weight: UIFontWeightRegular)
        helpLabel.textColor = UIColor(rgb: 0x696969)
        helpLabel.text = Strings.EnterCodeWordsBelow
        view.addSubview(helpLabel)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(SEL_done))
        
        edgesForExtendedLayout = .None
        
        containerView.snp_makeConstraints { (make) in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.height.equalTo(295)
        }
        
        helpLabel.snp_makeConstraints { (make) in
            make.top.equalTo(self.containerView.snp_top).offset(10)
            make.centerX.equalTo(self.view)
        }
        
        codewordsView.snp_makeConstraints { (make) in
            make.edges.equalTo(self.containerView).inset(UIEdgeInsetsMake(44, 0, 0, 0))
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Focus on first input field.
        codewordsView.fields[0].becomeFirstResponder()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    func SEL_done() {
        checkCodes()
    }
    
    func checkCodes() {
        debugPrint("check codes")
        
        func alert(title title: String? = nil, message: String? = nil) {
            let title = title ?? "Unable to Connect"
            let message = message ?? "Unable to connect with entered words. Please check the entered words and try again."
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "ok", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        let codes = self.codewordsView.codeWords()
        
        Niceware.shared.bytes(fromPassphrase: codes) { (result, error) in
            if result?.count == 0 || error != nil {
                var errorText = error?.userInfo["WKJavaScriptExceptionMessage"] as? String
                if let er = errorText where er.contains("Invalid word") {
                    errorText = er + "\n Please recheck spelling"
                }
                alert(title: nil, message: errorText)
                return
            }
            
            Sync.shared.initializeSync(result)
        }
    }
}
