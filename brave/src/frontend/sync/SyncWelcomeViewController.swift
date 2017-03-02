/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

let SyncBackgroundColor = UIColor(rgb: 0xF8F8F8)

class SyncWelcomeViewController: UIViewController {
    
    var graphic: UIImageView!
    var bg: UIImageView!
    var titleLabel: UILabel!
    var descriptionLabel: UILabel!
    var newToSyncButton: UIButton!
    var existingUserButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.Sync
        view.backgroundColor = SyncBackgroundColor
        
        bg = UIImageView(image: UIImage(named: "sync-gradient"))
        bg.contentMode = .ScaleAspectFill
        view.addSubview(bg)
        
        graphic = UIImageView(image: UIImage(named: "sync-art"))
        graphic.contentMode = .Center
        view.addSubview(graphic)
        
        titleLabel = UILabel()
        titleLabel.font = UIFont.systemFontOfSize(20, weight: UIFontWeightSemibold)
        titleLabel.textColor = UIColor.blackColor()
        titleLabel.text = "Brave Sync"
        view.addSubview(titleLabel)
        
        descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFontOfSize(15, weight: UIFontWeightRegular)
        descriptionLabel.textColor = UIColor(rgb: 0x696969)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .ByWordWrapping
        descriptionLabel.textAlignment = .Center
        descriptionLabel.text = "Sync browser data between your devices securely using Brave Sync, no account creation required. Tap below to get started."
        view.addSubview(descriptionLabel)
        
        newToSyncButton = UIButton()
        newToSyncButton.setTitle("I am new to sync", forState: .Normal)
        newToSyncButton.titleLabel?.font = UIFont.systemFontOfSize(17, weight: UIFontWeightBold)
        newToSyncButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        newToSyncButton.backgroundColor = BraveUX.DefaultBlue
        newToSyncButton.layer.cornerRadius = 8
        newToSyncButton.addTarget(self, action: #selector(SEL_newToSync), forControlEvents: .TouchUpInside)
        view.addSubview(newToSyncButton)
        
        existingUserButton = UIButton()
        existingUserButton.setTitle("Scan or enter code", forState: .Normal)
        existingUserButton.titleLabel?.font = UIFont.systemFontOfSize(15, weight: UIFontWeightSemibold)
        existingUserButton.setTitleColor(UIColor(rgb: 0x696969), forState: .Normal)
        existingUserButton.addTarget(self, action: #selector(SEL_existingUser), forControlEvents: .TouchUpInside)
        view.addSubview(existingUserButton)
        
        edgesForExtendedLayout = .None
        
        bg.snp_makeConstraints { (make) in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
        }
        
        graphic.snp_makeConstraints { (make) in
            make.edges.equalTo(self.bg).inset(UIEdgeInsetsMake(0, 19, 0, 0))
        }
        
        titleLabel.snp_makeConstraints { (make) in
            make.top.equalTo(self.bg.snp_bottom).offset(40)
            make.centerX.equalTo(self.view)
        }
        
        descriptionLabel.snp_makeConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp_bottom).offset(7)
            make.leftMargin.equalTo(30)
            make.rightMargin.equalTo(-30)
        }
        
        newToSyncButton.snp_makeConstraints { (make) in
            make.bottom.equalTo(self.view.snp_bottom).offset(-60)
            make.leftMargin.equalTo(16)
            make.rightMargin.equalTo(-16)
            make.height.equalTo(50)
        }
        
        existingUserButton.snp_makeConstraints { (make) in
            make.top.equalTo(self.newToSyncButton.snp_bottom).offset(8)
            make.centerX.equalTo(self.view)
        }
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        
        if toInterfaceOrientation.isLandscape {
            graphic.snp_remakeConstraints(closure: { (make) in
                make.top.equalTo(-300)
                make.centerX.equalTo(self.view)
            })
            
            titleLabel.snp_remakeConstraints(closure: { (make) in
                make.centerY.equalTo(self.view).offset(-60)
                make.centerX.equalTo(self.view)
            })
        }
        else {
            graphic.snp_remakeConstraints(closure: { (make) in
                make.edges.equalTo(self.bg).inset(UIEdgeInsetsMake(0, 19, 0, 0))
            })
            
            titleLabel.snp_remakeConstraints(closure: { (make) in
                make.top.equalTo(self.bg.snp_bottom).offset(40)
                make.centerX.equalTo(self.view)
            })
        }
        
        self.view.setNeedsUpdateConstraints()
    }
    
    func SEL_newToSync() {
        let view = SyncAddDeviceViewController()
        navigationController?.pushViewController(view, animated: true)
    }
    
    func SEL_existingUser() {
        let view = SyncPairCameraViewController()
        navigationController?.pushViewController(view, animated: true)
    }
    
}
