//
//  SyncSettingsViewController.swift
//  Client
//
//  Created by James Mudgett on 2/26/17.
//  Copyright © 2017 Brave Software. All rights reserved.
//

import UIKit
import Shared

class SyncSettingsViewController: AppSettingsTableViewController {
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = InsetLabel(frame: CGRectMake(0, 0, tableView.frame.size.width, 40))
        footerView.leftInset = CGFloat(20)
        footerView.rightInset = CGFloat(10)
        footerView.numberOfLines = 0
        footerView.font = UIFont.boldSystemFontOfSize(13)
        return footerView
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    override func generateSettings() -> [SettingSection] {
        settings += [
            SettingSection(title: NSAttributedString(string: Strings.Sync.uppercaseString), children:
                [SyncDevicesSetting(settings: self)]
            )
        ]
        return settings
    }
}
