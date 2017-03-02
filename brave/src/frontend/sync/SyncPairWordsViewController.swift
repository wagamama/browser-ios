//
//  SyncPairWordsViewController.swift
//  Client
//
//  Created by James Mudgett on 2/26/17.
//  Copyright © 2017 Brave Software. All rights reserved.
//

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
        helpLabel.text = "Enter code words below."
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
        var codes: [String] = []
        for field in self.codewordsView.fields {
            codes.append(field.text ?? "")
        }
        // TODO: check codes.
    }
}
