/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared
import XCGLogger

private let log = Logger.browserLogger

@objc
protocol BrowserToolbarProtocol {
    weak var browserToolbarDelegate: BrowserToolbarDelegate? { get set }
    var shareButton: UIButton { get }
    var forwardButton: UIButton { get }
    var backButton: UIButton { get }
    var addTabButton: UIButton { get }
    var actionButtons: [UIButton] { get }

    func updateBackStatus(canGoBack: Bool)
    func updateForwardStatus(canGoForward: Bool)
    func updateReloadStatus(isLoading: Bool)
    func updatePageStatus(isWebPage isWebPage: Bool)
}

@objc
protocol BrowserToolbarDelegate: class {
    func browserToolbarDidPressBack(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressForward(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressBookmark(browserToolbar: BrowserToolbarProtocol, button: UIButton)
    func browserToolbarDidPressShare(browserToolbar: BrowserToolbarProtocol, button: UIButton)
}

@objc
public class BrowserToolbarHelper: NSObject {
    let toolbar: BrowserToolbarProtocol

    var buttonTintColor = BraveUX.ActionButtonTintColor { // TODO see if setting it here can be avoided
        didSet {
            setTintColor(buttonTintColor, forButtons: toolbar.actionButtons)
        }
    }

    private func setTintColor(color: UIColor, forButtons buttons: [UIButton]) {
      buttons.forEach { $0.tintColor = UIColor.greenColor() }
    }

    init(toolbar: BrowserToolbarProtocol) {
        self.toolbar = toolbar
        super.init()

        toolbar.backButton.setImage(UIImage(named: "back"), forState: .Normal)
        toolbar.backButton.accessibilityLabel = Strings.Back
        toolbar.backButton.addTarget(self, action: #selector(BrowserToolbarHelper.SELdidClickBack), forControlEvents: UIControlEvents.TouchUpInside)

        toolbar.forwardButton.setImage(UIImage(named: "forward"), forState: .Normal)
        toolbar.forwardButton.accessibilityLabel = Strings.Forward
        toolbar.forwardButton.addTarget(self, action: #selector(BrowserToolbarHelper.SELdidClickForward), forControlEvents: UIControlEvents.TouchUpInside)

        toolbar.shareButton.setImage(UIImage(named: "send"), forState: .Normal)
        toolbar.shareButton.accessibilityLabel = Strings.Share
        toolbar.shareButton.addTarget(self, action: #selector(BrowserToolbarHelper.SELdidClickShare), forControlEvents: UIControlEvents.TouchUpInside)
        
        toolbar.addTabButton.setImage(UIImage(named: "add"), forState: .Normal)
        toolbar.addTabButton.accessibilityLabel = Strings.Add_Tab
        toolbar.addTabButton.addTarget(self, action: #selector(BrowserToolbarHelper.SELdidClickAddTab), forControlEvents: UIControlEvents.TouchUpInside)

        setTintColor(buttonTintColor, forButtons: toolbar.actionButtons)
    }

    func SELdidClickBack() {
        toolbar.browserToolbarDelegate?.browserToolbarDidPressBack(toolbar, button: toolbar.backButton)
    }

    func SELdidClickShare() {
        toolbar.browserToolbarDelegate?.browserToolbarDidPressShare(toolbar, button: toolbar.shareButton)
    }

    func SELdidClickForward() {
        toolbar.browserToolbarDelegate?.browserToolbarDidPressForward(toolbar, button: toolbar.forwardButton)
    }
    
    func SELdidClickAddTab() {
        telemetry(action: "add tab", props: ["bottomToolbar": "true"])
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let isPrivate = PrivateBrowsing.singleton.isOn
        if isPrivate {
            app.tabManager.addTabAndSelect(nil, configuration: nil, isPrivate: true)
        } else {
            app.tabManager.addTabAndSelect()
        }
        app.browserViewController.urlBar.browserLocationViewDidTapLocation(app.browserViewController.urlBar.locationView)
    }
}

class BrowserToolbar: Toolbar, BrowserToolbarProtocol {
    weak var browserToolbarDelegate: BrowserToolbarDelegate?

    let shareButton = UIButton()
    let forwardButton = UIButton()
    let backButton = UIButton()
    let addTabButton = UIButton()
    
    lazy var actionButtons: [UIButton] = {
        return [self.shareButton, self.forwardButton, self.backButton, self.addTabButton]
    }()

    var stopReloadButton: UIButton {
        get {
            return getApp().browserViewController.urlBar.locationView.stopReloadButton
        }
    }

    var helper: BrowserToolbarHelper?

    static var Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.buttonTintColor = UIConstants.PrivateModeActionButtonTintColor
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.buttonTintColor = UIColor.darkGrayColor()
        themes[Theme.NormalMode] = theme

        return themes
    }()

    // This has to be here since init() calls it
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.helper = BrowserToolbarHelper(toolbar: self)

        addButtons(actionButtons)

        accessibilityNavigationStyle = .Combined
        accessibilityLabel = Strings.Navigation_Toolbar
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateBackStatus(canGoBack: Bool) {
        backButton.enabled = canGoBack
    }

    func updateForwardStatus(canGoForward: Bool) {
        forwardButton.enabled = canGoForward
    }

    func updateReloadStatus(isLoading: Bool) {
        getApp().browserViewController.urlBar.locationView.stopReloadButtonIsLoading(isLoading)
    }

    func updatePageStatus(isWebPage isWebPage: Bool) {
        stopReloadButton.enabled = isWebPage
        shareButton.enabled = isWebPage
    }

    override func drawRect(rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            drawLine(context, start: CGPoint(x: 0, y: 0), end: CGPoint(x: frame.width, y: 0))
        }
    }

    private func drawLine(context: CGContextRef, start: CGPoint, end: CGPoint) {
        CGContextSetStrokeColorWithColor(context, UIColor.blackColor().colorWithAlphaComponent(0.05).CGColor)
        CGContextSetLineWidth(context, 2)
        CGContextMoveToPoint(context, start.x, start.y)
        CGContextAddLineToPoint(context, end.x, end.y)
        CGContextStrokePath(context)
    }
}

// MARK: UIAppearance
extension BrowserToolbar {
    dynamic var actionButtonTintColor: UIColor? {
        get { return helper?.buttonTintColor }
        set {
            guard let value = newValue else { return }
            helper?.buttonTintColor = value
        }
    }
}

extension BrowserToolbar: Themeable {
    func applyTheme(themeName: String) {
        guard let theme = BrowserToolbar.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }
        actionButtonTintColor = theme.buttonTintColor!
    }
}
