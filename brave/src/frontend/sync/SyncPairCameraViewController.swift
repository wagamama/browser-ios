/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

class SyncPairCameraViewController: UIViewController {
    
    var cameraView: SyncCameraView!
    var titleLabel: UILabel!
    var descriptionLabel: UILabel!
    var cameraAccessButton: UIButton!
    var enterWordsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.Pair
        view.backgroundColor = SyncBackgroundColor
        
        cameraView = SyncCameraView()
        cameraView.backgroundColor = UIColor.blackColor()
        cameraView.layer.cornerRadius = 4
        cameraView.layer.masksToBounds = true
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
        descriptionLabel.textAlignment = .Center
        descriptionLabel.text = "Using existing synced device open Brave Settings and navigate to “Devices & Settings”, tap ‘+’ to add a new device and reveal sync code."
        view.addSubview(descriptionLabel)
        
        cameraAccessButton = UIButton()
        cameraAccessButton.setTitle("Grant camera access", forState: .Normal)
        cameraAccessButton.titleLabel?.font = UIFont.systemFontOfSize(17, weight: UIFontWeightBold)
        cameraAccessButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        cameraAccessButton.backgroundColor = BraveUX.DefaultBlue
        cameraAccessButton.layer.cornerRadius = 8
        cameraAccessButton.addTarget(self, action: #selector(SEL_cameraAccess), forControlEvents: .TouchUpInside)
        view.addSubview(cameraAccessButton)
        
        enterWordsButton = UIButton()
        enterWordsButton.setTitle("Enter code words", forState: .Normal)
        enterWordsButton.titleLabel?.font = UIFont.systemFontOfSize(15, weight: UIFontWeightSemibold)
        enterWordsButton.setTitleColor(UIColor(rgb: 0x696969), forState: .Normal)
        enterWordsButton.addTarget(self, action: #selector(SEL_enterWords), forControlEvents: .TouchUpInside)
        view.addSubview(enterWordsButton)
        
        edgesForExtendedLayout = .None
        
        cameraView.snp_makeConstraints { (make) in
            make.top.equalTo(self.view).offset(24)
            make.size.equalTo(300)
            make.centerX.equalTo(self.view)
        }
        
        titleLabel.snp_makeConstraints { (make) in
            make.top.equalTo(self.cameraView.snp_bottom).offset(40)
            make.centerX.equalTo(self.view)
        }
        
        descriptionLabel.snp_makeConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp_bottom).offset(7)
            make.leftMargin.equalTo(30)
            make.rightMargin.equalTo(-30)
        }
        
        cameraAccessButton.snp_makeConstraints { (make) in
            make.bottom.equalTo(self.view.snp_bottom).offset(-60)
            make.leftMargin.equalTo(16)
            make.rightMargin.equalTo(-16)
            make.height.equalTo(50)
        }
        
        enterWordsButton.snp_makeConstraints { (make) in
            make.top.equalTo(self.cameraAccessButton.snp_bottom).offset(8)
            make.centerX.equalTo(self.view)
        }
    }
    
    func SEL_cameraAccess() {
        
    }
    
    func SEL_enterWords() {
        let view = SyncPairWordsViewController()
        navigationController?.pushViewController(view, animated: true)
    }
}

