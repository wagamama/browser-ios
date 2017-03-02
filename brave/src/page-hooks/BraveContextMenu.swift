/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Using suggestions from: http://www.icab.de/blog/2010/07/11/customize-the-contextual-menu-of-uiwebview/

let kNotificationMainWindowTapAndHold = "kNotificationMainWindowTapAndHold"

class BraveContextMenu {
    private var tapLocation = CGPointZero
    private var tappedElement: ContextMenuHelper.Elements?

    private var timer1_cancelDefaultMenu = NSTimer()
    private var timer2_showMenuIfStillPressed = NSTimer()

    static let initialDelayToCancelBuiltinMenu = 0.25 // seconds, must be <0.3 or built-in menu can't be cancelled
    static let totalDelayToShowContextMenu = 0.85 - initialDelayToCancelBuiltinMenu // 850 is copied from Safari

    private let fingerMovedTolerance = Float(5.0)

    private func reset() {
        timer1_cancelDefaultMenu.invalidate()
        timer2_showMenuIfStillPressed.invalidate()
        tappedElement = nil
        tapLocation = CGPointZero
    }

    private func isActive() -> Bool {
        return tapLocation != CGPointZero && (timer1_cancelDefaultMenu.valid || timer2_showMenuIfStillPressed.valid)
    }

    private func isBrowserTopmostAndNoPanelsOpen() ->  Bool {
        guard let top = getApp().rootViewController.visibleViewController as? BraveTopViewController else {
            return false
        }

        return top.mainSidePanel.view.hidden && top.rightSidePanel.view.hidden
    }

    private func fingerMovedTooFar(touch: UITouch, window: UIView) -> Bool {
        let p1 = touch.locationInView(window)
        let p2 = tapLocation
        let distance = hypotf(Float(p1.x) - Float(p2.x), Float(p1.y) - Float(p2.y))
        return distance > fingerMovedTolerance
    }

    func sendEvent(event: UIEvent, window: UIWindow) {
        if !isBrowserTopmostAndNoPanelsOpen() {
            reset()
            return
        }

        guard let braveWebView = BraveApp.getCurrentWebView() else { return }

        if let touches = event.touchesForWindow(window), let touch = touches.first where touches.count == 1 {
            braveWebView.lastTappedTime = NSDate()
            switch touch.phase {
            case .Began:  // A finger touched the screen
                reset()
                guard let touchView = event.allTouches()?.first?.view where touchView.isDescendantOfView(braveWebView) else {
                    return
                }

                tapLocation = touch.locationInView(window)
                timer1_cancelDefaultMenu = NSTimer.scheduledTimerWithTimeInterval(BraveContextMenu.initialDelayToCancelBuiltinMenu, target: self, selector: #selector(BraveContextMenu.cancelDefaultMenuAndFindTappedItem), userInfo: nil, repeats: false)
            case .Moved, .Stationary:
                if isActive() && fingerMovedTooFar(touch, window: window) {
                    // my test for this: tap with edge of finger, then roll to opposite edge while holding finger down, is 5-10 px of movement; Should still show context menu, don't want this to trigger a reset()
                    reset()
                }
            case .Ended, .Cancelled:
                if isActive() {
                    if let url = tappedElement?.link where !fingerMovedTooFar(touch, window: window) {
                        BraveApp.getCurrentWebView()?.loadRequest(NSURLRequest(URL: url))
                    }

                    reset()
                }
            }
        } else {
            reset()
        }
    }

    @objc func showContextMenu() {
        func showContextMenuForElement(tappedElement:  ContextMenuHelper.Elements) {
            let info = ["point": NSValue(CGPoint: tapLocation)]
            NSNotificationCenter.defaultCenter().postNotificationName(kNotificationMainWindowTapAndHold, object: self, userInfo: info)
            guard let bvc = getApp().browserViewController else { return }
            if bvc.urlBar.inSearchMode {
                return
            }
            bvc.showContextMenu(elements: tappedElement, touchPoint: tapLocation)
            reset()
        }


        if let tappedElement = tappedElement {
            showContextMenuForElement(tappedElement)
        }
    }

    // This is called 2x, once at .25 seconds to ensure the native context menu is cancelled,
    // then again at .5 seconds to show our context menu. (This code was borne of frustration, not ideal flow)
    @objc func cancelDefaultMenuAndFindTappedItem() {
        if !isBrowserTopmostAndNoPanelsOpen() {
            reset()
            return
        }

        guard let webView = BraveApp.getCurrentWebView() else { return }

        let hit: (url: String?, image: String?, urlTarget: String?)?

        if [".jpg", ".png", ".gif"].filter({ webView.URL?.absoluteString?.endsWith($0) ?? false }).count > 0 {
            // web view is just showing an image
            hit = (url:nil, image:webView.URL!.absoluteString, urlTarget:nil)
        } else {
            hit = ElementAtPoint().getHit(tapLocation)
        }
        if hit == nil {
            // No link or image found, not for this class to handle
            reset()
            return
        }

        tappedElement = ContextMenuHelper.Elements(link: hit!.url != nil ? NSURL(string: hit!.url!) : nil, image: hit!.image != nil ? NSURL(string: hit!.image!) : nil)

        func blockOtherGestures(views: [UIView]?) {
            guard let views = views else { return }
            for view in views {
                if let gestures = view.gestureRecognizers as [UIGestureRecognizer]! {
                    for gesture in gestures {
                        if gesture is UILongPressGestureRecognizer {
                            // toggling gets the gesture to ignore this long press
                            gesture.enabled = false
                            gesture.enabled = true
                        }
                    }
                }
            }
        }
        
        blockOtherGestures(BraveApp.getCurrentWebView()?.scrollView.subviews)

        timer2_showMenuIfStillPressed = NSTimer.scheduledTimerWithTimeInterval(BraveContextMenu.totalDelayToShowContextMenu, target: self, selector: #selector(BraveContextMenu.showContextMenu), userInfo: nil, repeats: false)
    }
}
