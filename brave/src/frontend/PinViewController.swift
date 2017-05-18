/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Foundation

struct PinUX {
    private static let ButtonSize: CGSize = CGSize(width: 80, height: 80)
    private static let DefaultBackgroundColor = UIColor.clearColor()
    private static let SelectedBackgroundColor = UIColor(rgb: 0x696969)
    private static let DefaultBorderWidth: CGFloat = 1.0
    private static let SelectedBorderWidth: CGFloat = 0.0
    private static let DefaultBorderColor = UIColor(rgb: 0x696969).CGColor
    private static let IndicatorSize: CGSize = CGSize(width: 14, height: 14)
}

protocol PinViewControllerDelegate {
}

class PinViewController: UIViewController {
    
    var delegate: PinViewControllerDelegate?
    var pinView: PinLockView!
    
    override func loadView() {
        super.loadView()
        
        pinView = PinLockView(message: "Enter New Pin")
        pinView.codeCallback = { code in
            debugPrint("entered code: \(code)")
        }
        view.addSubview(pinView)
        
        edgesForExtendedLayout = .None
        
        pinView.snp_makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
        title = "Set Pin"
        view.backgroundColor = UIColor.whiteColor()
    }
    
}

class PinLockView: UIView {
    var buttons: [PinButton] = []
    
    var codeCallback: ((code: String) -> Void)?
    
    var messageLabel: UILabel!
    var pinIndicatorView: PinIndicatorView!
    var deleteButton: UIButton!
    
    convenience init(message: String) {
        self.init()
        
        messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = UIFont.systemFontOfSize(16, weight: UIFontWeightMedium)
        messageLabel.textColor = PinUX.SelectedBackgroundColor
        messageLabel.sizeToFit()
        addSubview(messageLabel)
        
        pinIndicatorView = PinIndicatorView(size: 4)
        pinIndicatorView.sizeToFit()
        addSubview(pinIndicatorView)
        
        for i in 1...10 {
            let button = PinButton()
            button.tag = i
            button.titleLabel.text = i > 9 ? "0" : "\(i)"
            addSubview(button)
            buttons.append(button)
        }
        
        deleteButton = UIButton()
        deleteButton.titleLabel?.font = UIFont.systemFontOfSize(16, weight: UIFontWeightMedium)
        deleteButton.setTitle("Delete", forState: .Normal)
        deleteButton.setTitleColor(PinUX.SelectedBackgroundColor, forState: .Normal)
        deleteButton.sizeToFit()
        addSubview(deleteButton)
    }
    
    override func layoutSubviews() {
        var messageLabelFrame = messageLabel.frame
        messageLabelFrame.origin.x = (UIScreen.mainScreen().bounds.width - CGRectGetWidth(messageLabelFrame)) / 2
        messageLabelFrame.origin.y = 30
        messageLabel.frame = messageLabelFrame
        
        var indicatorViewFrame = pinIndicatorView.frame
        indicatorViewFrame.origin.x = (UIScreen.mainScreen().bounds.width - CGRectGetWidth(indicatorViewFrame)) / 2
        indicatorViewFrame.origin.y = CGRectGetMaxY(messageLabelFrame) + 18
        pinIndicatorView.frame = indicatorViewFrame
        
        let spaceX: CGFloat = (min(UIScreen.mainScreen().bounds.width, 375) - PinUX.ButtonSize.width * 3) / 4
        let spaceY: CGFloat = spaceX
        var x: CGFloat = 0
        var y: CGFloat = CGRectGetMaxY(indicatorViewFrame) + 40
        let w: CGFloat = PinUX.ButtonSize.width
        let h: CGFloat = PinUX.ButtonSize.height
        for i in 0..<buttons.count {
            x = x + spaceX
            if x + w > UIScreen.mainScreen().bounds.width {
                x = spaceX
                y = y + h + spaceY
            }
            if i == buttons.count - 1 {
                // Center last.
                x = (UIScreen.mainScreen().bounds.width - w) / 2
            }
            // debugPrint("w \(w) x \(x) y\(y)")
            
            let button = buttons[i]
            var buttonFrame = button.frame
            buttonFrame.origin.x = x
            buttonFrame.origin.y = y
            buttonFrame.size.width = w
            buttonFrame.size.height = h
            button.frame = buttonFrame
            
            x = x + w
        }
        
        let button0 = viewWithTag(10)
        let button9 = viewWithTag(9)
        var deleteButtonFrame = deleteButton.frame
        deleteButtonFrame.center = CGPoint(x: CGRectGetMidX(button9!.frame ?? CGRectZero), y: CGRectGetMidY(button0!.frame ?? CGRectZero))
        deleteButton.frame = deleteButtonFrame
    }
    
    override func sizeToFit() {
        let button = buttons[buttons.count - 1]
        var f = frame
        f.size.width = UIScreen.mainScreen().bounds.width
        f.size.height = CGRectGetMaxY(button.frame)
        frame = f
    }
}

class PinIndicatorView: UIView {
    var indicators: [UIView] = []
    
    var defaultColor: UIColor!
    
    convenience init(size: Int) {
        self.init()
        
        defaultColor = PinUX.SelectedBackgroundColor
        
        for i in 0..<size {
            let view = UIView()
            view.tag = i
            view.layer.cornerRadius = PinUX.IndicatorSize.width / 2
            view.layer.masksToBounds = true
            view.layer.borderWidth = 1
            view.layer.borderColor = defaultColor.CGColor
            addSubview(view)
            indicators.append(view)
        }
        
        setNeedsDisplay()
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        let spaceX: CGFloat = 10
        var x: CGFloat = 0
        for i in 0..<indicators.count {
            let view = indicators[i]
            var viewFrame = view.frame
            viewFrame.origin.x = x
            viewFrame.origin.y = 0
            viewFrame.size.width = PinUX.IndicatorSize.width
            viewFrame.size.height = PinUX.IndicatorSize.height
            view.frame = viewFrame
            
            x = x + PinUX.IndicatorSize.width + spaceX
        }
    }
    
    override func sizeToFit() {
        let view = indicators[indicators.count - 1]
        var f = frame
        f.size.width = CGRectGetMaxX(view.frame)
        f.size.height = CGRectGetMaxY(view.frame)
        frame = f
    }
}

class PinButton: UIControl {
    var titleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.masksToBounds = true
        layer.borderWidth = PinUX.DefaultBorderWidth
        layer.borderColor = PinUX.DefaultBorderColor
        backgroundColor = UIColor.clearColor()
        
        titleLabel = UILabel(frame: frame)
        titleLabel.userInteractionEnabled = false
        titleLabel.textAlignment = .Center
        titleLabel.font = UIFont.systemFontOfSize(30, weight: UIFontWeightMedium)
        titleLabel.textColor = PinUX.SelectedBackgroundColor
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
                    self.backgroundColor = PinUX.SelectedBackgroundColor
                    self.titleLabel.textColor = UIColor.whiteColor()
                })
            }
            else {
                UIView.animateWithDuration(0.1, animations: {
                    self.backgroundColor = UIColor.clearColor()
                    self.titleLabel.textColor = PinUX.SelectedBackgroundColor
                })
            }
        }
    }
    
    override func layoutSubviews() {
        titleLabel.frame = bounds
        layer.cornerRadius = CGRectGetHeight(frame) / 2.0
    }
    
    override func sizeToFit() {
        super.sizeToFit()
        
        var frame: CGRect = self.frame
        frame.size.width = PinUX.ButtonSize.width
        frame.size.height = PinUX.ButtonSize.height
        self.frame = frame
    }
}
