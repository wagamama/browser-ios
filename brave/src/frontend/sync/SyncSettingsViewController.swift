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
        let footerView = InsetLabel(frame: CGRectMake(0, 5, tableView.frame.size.width, 60))
        footerView.leftInset = CGFloat(20)
        footerView.rightInset = CGFloat(45)
        footerView.numberOfLines = 0
        footerView.lineBreakMode = .ByWordWrapping
        footerView.font = UIFont.systemFontOfSize(13)
        footerView.textColor = UIColor(rgb: 0x696969)
        
        if section == 0 {
            footerView.text = "Changing settings will only affect data that this device shares with others."
        }
        
        return footerView
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 40
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        title = "Devices"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(SEL_addDevice))
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func generateSettings() -> [SettingSection] {
        let prefs = profile.prefs
        
        // TODO: move these prefKeys somewhere else
        let syncPrefBookmarks = "syncBookmarksKey"
        let syncPrefTabs = "syncTabsKey"
        let syncPrefHistory = "syncHistoryKey"
        
        settings += [
            SettingSection(title: NSAttributedString(string: Strings.SyncOnDevice.uppercaseString), children:
                [BoolSetting(prefs: prefs, prefKey: syncPrefBookmarks, defaultValue: true, titleText: Strings.Bookmarks),
                    BoolSetting(prefs: prefs, prefKey: syncPrefTabs, defaultValue: true, titleText: Strings.Tabs),
                    BoolSetting(prefs: prefs, prefKey: syncPrefHistory, defaultValue: true, titleText: Strings.History)]
            ),
            SettingSection(title: nil, children:
                [RemoveDeviceSetting(settings: self)]
            )
        ]
        return settings
    }
    
    func SEL_addDevice() {
        
    }
}
