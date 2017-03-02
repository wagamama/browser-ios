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
        containerView.layer.shadowColor = UIColor(rgb: 0xC8C7CC).CGColor
        containerView.layer.shadowRadius = 0
        containerView.layer.shadowOpacity = 1.0
        containerView.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        view.addSubview(containerView)
        
        barcodeView = SyncBarcodeView(data: "Hello world program created by someone")
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
        descriptionLabel.textAlignment = .Center
        descriptionLabel.text = "Using a second device navigate to Brave Settings > Sync. Capture the QR Code (above) with second device, or enter code words if no camera is available."
        view.addSubview(descriptionLabel)
        
        doneButton = UIButton()
        doneButton.setTitle("Done", forState: .Normal)
        doneButton.titleLabel?.font = UIFont.systemFontOfSize(17, weight: UIFontWeightBold)
        doneButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        doneButton.backgroundColor = BraveUX.DefaultBlue
        doneButton.layer.cornerRadius = 8
        view.addSubview(doneButton)
        
        edgesForExtendedLayout = .None
        
        containerView.snp_makeConstraints { (make) in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.height.equalTo(295)
        }
        
        modeControl.snp_makeConstraints { (make) in
            make.top.equalTo(self.containerView.snp_top).offset(10)
            make.left.equalTo(8)
            make.right.equalTo(-8)
        }
        
        barcodeView.snp_makeConstraints { (make) in
            make.top.equalTo(65)
            make.centerX.equalTo(self.containerView)
            make.size.equalTo(BarcodeSize)
        }
        
        codewordsView.snp_makeConstraints { (make) in
            make.edges.equalTo(self.containerView).inset(UIEdgeInsetsMake(44, 0, 0, 0))
        }
        
        titleLabel.snp_makeConstraints { (make) in
            make.top.equalTo(self.containerView.snp_bottom).offset(40)
            make.centerX.equalTo(self.view)
        }
        
        descriptionLabel.snp_makeConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp_bottom).offset(7)
            make.leftMargin.equalTo(30)
            make.rightMargin.equalTo(-30)
        }
        
        doneButton.snp_makeConstraints { (make) in
            make.bottom.equalTo(self.view.snp_bottom).offset(-60)
            make.leftMargin.equalTo(16)
            make.rightMargin.equalTo(-16)
            make.height.equalTo(50)
        }
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        
        if toInterfaceOrientation == .LandscapeLeft || toInterfaceOrientation == .LandscapeRight {
            
        }
        else {
            
        }
        
        self.view.setNeedsUpdateConstraints()
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

