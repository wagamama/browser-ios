//
//  SyncAddDeviceViewController.swift
//  Client
//
//  Created by James Mudgett on 2/26/17.
//  Copyright © 2017 Brave Software. All rights reserved.
//

import UIKit
import Shared

class SyncAddDeviceViewController: UIViewController {
    
    var containerView: UIView!
    var barcodeView: SyncBarcodeView!
    var codewordsView: SyncCodewordsView!
    var modeControl: UISegmentedControl!
    var titleLabel: UILabel!
    var descriptionLabel: UILabel!
    var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.Sync
        view.backgroundColor = SyncBackgroundColor
        
        containerView = UIView()
        containerView.backgroundColor = UIColor.whiteColor()
        view.addSubview(containerView)
        
        barcodeView = SyncBarcodeView()
        containerView.addSubview(barcodeView)
        
        codewordsView = SyncCodewordsView()
        containerView.addSubview(codewordsView)
        
        modeControl = UISegmentedControl(items: ["QR Code", "Code Words"])
        modeControl.tintColor = BraveUX.DefaultBlue
        modeControl.selectedSegmentIndex = 0
        modeControl.addTarget(self, action: #selector(SEL_changeMode), forControlEvents: .ValueChanged)
        view.addSubview(modeControl)
        
        titleLabel = UILabel()
        titleLabel.font = UIFont.systemFontOfSize(20, weight: UIFontWeightSemibold)
        titleLabel.textColor = UIColor.blackColor()
        titleLabel.text = "Add Device"
        view.addSubview(titleLabel)
        
        descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFontOfSize(15, weight: UIFontWeightRegular)
        descriptionLabel.textColor = UIColor(rgb: 0x696969)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .ByWordWrapping
        descriptionLabel.text = "Using a second device navigate to Brave Settings > Sync. Capture the QR Code (above) with second device, or enter code words if no camera is available."
        view.addSubview(descriptionLabel)
        
        doneButton = UIButton()
        doneButton.setTitle("Done", forState: .Normal)
        doneButton.titleLabel?.font = UIFont.systemFontOfSize(17, weight: UIFontWeightBold)
        doneButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        doneButton.backgroundColor = BraveUX.DefaultBlue
        doneButton.layer.cornerRadius = 8
        view.addSubview(doneButton)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    func SEL_changeMode() {
        barcodeView.hidden = (modeControl.selectedSegmentIndex == 1)
        codewordsView.hidden = (modeControl.selectedSegmentIndex == 0)
    }
}

