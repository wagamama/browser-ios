/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

class SyncAddDeviceViewController: UIViewController {
    
    var scrollView: UIScrollView!
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
        
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.whiteColor()
        containerView.layer.shadowColor = UIColor(rgb: 0xC8C7CC).CGColor
        containerView.layer.shadowRadius = 0
        containerView.layer.shadowOpacity = 1.0
        containerView.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        scrollView.addSubview(containerView)
        
        guard let syncSeed = Sync.shared.syncSeedArray else {
            // TODO: Pop and error
            return
        }
        
        let qrSyncSeed = Niceware.shared.joinBytes(fromCombinedBytes: syncSeed)
        if qrSyncSeed.isEmpty {
            // Error
            return
        }
        
        Niceware.shared.passphrase(fromBytes: syncSeed) { (words, error) in
            guard let words = words where error == nil else {
                return
            }

            self.barcodeView = SyncBarcodeView(data: qrSyncSeed)
            self.codewordsView = SyncCodewordsView(data: words)
            
            self.setupVisuals()
        }
    }
    
    func setupVisuals() {
        containerView.addSubview(barcodeView)
        
        codewordsView.hidden = true
        containerView.addSubview(codewordsView)
        
        modeControl = UISegmentedControl(items: [Strings.QRCode, Strings.CodeWords])
        modeControl.translatesAutoresizingMaskIntoConstraints = false
        modeControl.tintColor = BraveUX.DefaultBlue
        modeControl.selectedSegmentIndex = 0
        modeControl.addTarget(self, action: #selector(SEL_changeMode), forControlEvents: .ValueChanged)
        scrollView.addSubview(modeControl)
        
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFontOfSize(20, weight: UIFontWeightSemibold)
        titleLabel.textColor = UIColor.blackColor()
        titleLabel.text = Strings.SyncAddDevice
        scrollView.addSubview(titleLabel)
        
        descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = UIFont.systemFontOfSize(15, weight: UIFontWeightRegular)
        descriptionLabel.textColor = UIColor(rgb: 0x696969)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .ByWordWrapping
        descriptionLabel.textAlignment = .Center
        descriptionLabel.text = Strings.SyncAddDeviceDescription
        scrollView.addSubview(descriptionLabel)
        
        doneButton = UIButton(type: .RoundedRect)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle(Strings.Done, forState: .Normal)
        doneButton.titleLabel?.font = UIFont.systemFontOfSize(17, weight: UIFontWeightBold)
        doneButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        doneButton.backgroundColor = BraveUX.DefaultBlue
        doneButton.layer.cornerRadius = 8
        doneButton.addTarget(self, action: #selector(SEL_done), forControlEvents: .TouchUpInside)
        scrollView.addSubview(doneButton)
        
        edgesForExtendedLayout = .None
        
        scrollView.snp_makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
        containerView.snp_makeConstraints { (make) in
            make.top.equalTo(self.scrollView)
            make.width.equalTo(self.scrollView)
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
            make.edges.equalTo(self.containerView).inset(UIEdgeInsetsMake(64, 0, 0, 0))
        }
        
        titleLabel.snp_makeConstraints { (make) in
            make.top.equalTo(self.containerView.snp_bottom).offset(30)
            make.centerX.equalTo(self.scrollView)
        }
        
        descriptionLabel.snp_makeConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp_bottom).offset(7)
            make.leftMargin.equalTo(30)
            make.rightMargin.equalTo(-30)
        }
        
        doneButton.snp_makeConstraints { (make) in
            make.top.equalTo(self.descriptionLabel.snp_bottom).offset(30)
            make.centerX.equalTo(self.scrollView)
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.bottom.equalTo(-16)
            make.height.equalTo(50)
        }
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        
        if toInterfaceOrientation.isLandscape {
            
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
    
    func SEL_done() {
        // Re-activate pop gesture in case it was removed
        navigationController?.interactivePopGestureRecognizer?.enabled = true
        
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
}

