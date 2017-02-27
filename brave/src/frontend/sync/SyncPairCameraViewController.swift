//
//  SyncPairCameraViewController.swift
//  Client
//
//  Created by James Mudgett on 2/26/17.
//  Copyright © 2017 Brave Software. All rights reserved.
//

import UIKit
import Shared

class SyncPairCameraViewController: UIViewController {
    
    var cameraView: SyncCameraView!
    var titleLabel: UILabel!
    var descriptionLabel: UILabel!
    var cameraAccessButton: SyncButton!
    var enterWordsButton: SyncButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.Sync
        view.backgroundColor = SyncBackgroundColor
        
        cameraView = SyncCameraView()
        view.addSubview(cameraView)
        
        titleLabel = UILabel()
        titleLabel.font = UIFont.systemFontOfSize(20, weight: UIFontWeightSemibold)
        titleLabel.textColor = UIColor.blackColor()
        titleLabel.text = "Sync to device"
        view.addSubview(titleLabel)
        
        descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFontOfSize(15, weight: UIFontWeightRegular)
        descriptionLabel.textColor = UIColor(rgb: 0x696969)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .ByWordWrapping
        descriptionLabel.text = "Using existing synced device open Brave Settings and navigate to “Devices & Settings”, tap ‘+’ to add a new device and reveal sync code."
        view.addSubview(descriptionLabel)
        
        cameraAccessButton = SyncButton()
        cameraAccessButton.titleLabel.text = "Grant camera access"
        view.addSubview(cameraAccessButton)
        
        enterWordsButton = SyncButton()
        enterWordsButton.titleLabel.text = "Enter code words"
        view.addSubview(enterWordsButton)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
}

