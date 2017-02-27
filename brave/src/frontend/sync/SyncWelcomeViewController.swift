//
//  SyncWelcomeViewController.swift
//  Client
//
//  Created by James Mudgett on 2/23/17.
//  Copyright © 2017 Brave Software. All rights reserved.
//

import UIKit
import Shared

let SyncBackgroundColor = UIColor(rgb: 0xF8F8F8)

class SyncWelcomeViewController: UIViewController {
    
    var graphic: UIImageView!
    var bg: UIImageView!
    var titleLabel: UILabel!
    var descriptionLabel: UILabel!
    var newToSyncButton: SyncButton!
    var existingUserButton: SyncButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.Sync
        view.backgroundColor = SyncBackgroundColor
        
        bg = UIImageView(image: UIImage(named: "sync-gradient"))
        view.addSubview(bg)
        
        graphic = UIImageView(image: UIImage(named: "sync-art"))
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
        descriptionLabel.text = "Sync browser data between your devices securely using Brave Sync, no account creation required. Tap below to get started."
        view.addSubview(descriptionLabel)
        
        newToSyncButton = SyncButton()
        newToSyncButton.titleLabel.text = "I am new to sync"
        view.addSubview(newToSyncButton)
        
        existingUserButton = SyncButton()
        existingUserButton.titleLabel.text = "I have an existing sync code"
        view.addSubview(existingUserButton)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
}

class SyncButton: UIControl {
    
    private let Padding: CGFloat = 11.0
    
    var titleLabel: UILabel!
    var highlightColor: UIColor?
    var _color: UIColor = BraveUX.DefaultBlue
    var color: UIColor {
        get {
            return _color
        }
        set {
            _color = newValue
            backgroundColor = _color
        }
    }
    
    var _textColor: UIColor = UIColor.whiteColor()
    var textColor: UIColor {
        get {
            return _textColor
        }
        set {
            _textColor = newValue
            titleLabel.textColor = _textColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.masksToBounds = true
        backgroundColor = UIColor.clearColor()
        
        titleLabel = UILabel(frame: frame)
        titleLabel.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        titleLabel.userInteractionEnabled = false
        titleLabel.textAlignment = .Center
        titleLabel.font = UIFont.systemFontOfSize(17, weight: UIFontWeightBold)
        titleLabel.textColor = textColor
        titleLabel.backgroundColor = UIColor.clearColor()
        addSubview(titleLabel)
        setNeedsDisplay()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)!
    }
    
    override var highlighted: Bool {
        didSet {
            if (highlighted) {
                UIView.animateWithDuration(0.1, animations: {
                    self.backgroundColor = self.highlightColor ?? BraveUX.DefaultBlue.colorWithAlphaComponent(0.8)
                })
            }
            else {
                UIView.animateWithDuration(0.1, animations: {
                    self.backgroundColor = self.color
                })
            }
        }
    }
    
    override func layoutSubviews() {
        titleLabel.frame = bounds
        
        layer.cornerRadius = 8
    }
    
    override func sizeToFit() {
        super.sizeToFit()
        
        let size: CGSize = titleLabel.sizeThatFits(CGSizeMake(CGFloat.max, CGFloat.max))
        var frame: CGRect = self.frame
        frame.size.width = size.width + Padding * 4.0
        frame.size.height = size.height + Padding * 2.0
        self.frame = frame
    }
}
