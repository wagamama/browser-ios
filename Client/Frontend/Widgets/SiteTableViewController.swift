/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

struct SiteTableViewControllerUX {
    static let HeaderHeight = CGFloat(25)
    static let RowHeight = CGFloat(58)
    static let HeaderBorderColor = UIColor(rgb: 0xCFD5D9).colorWithAlphaComponent(0.8)
    static let HeaderTextColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor(rgb: 0x232323)
    static let HeaderBackgroundColor = UIColor(rgb: 0xECF0F3).colorWithAlphaComponent(0.3)
    static let HeaderFont = UIFont.systemFontOfSize(12, weight: UIFontWeightMedium)
    static let HeaderTextMargin = CGFloat(10)
}

class SiteTableViewHeader : UITableViewHeaderFooterView {
    // I can't get drawRect to play nicely with the glass background. As a fallback
    // we just use views for the top and bottom borders.
    let topBorder = UIView()
    let bottomBorder = UIView()
    let titleLabel = UILabel()

    override var textLabel: UILabel? {
        return titleLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        topBorder.backgroundColor = UIColor.whiteColor()
        bottomBorder.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        contentView.backgroundColor = UIColor.whiteColor()

        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
        titleLabel.textColor = SiteTableViewControllerUX.HeaderTextColor
        titleLabel.textAlignment = .Left

        addSubview(topBorder)
        addSubview(bottomBorder)
        contentView.addSubview(titleLabel)

        topBorder.snp_makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).offset(-0.5)
            make.height.equalTo(0.5)
        }

        bottomBorder.snp_makeConstraints { make in
            make.left.right.bottom.equalTo(self)
            make.height.equalTo(0.5)
        }

        // A table view will initialize the header with CGSizeZero before applying the actual size. Hence, the label's constraints
        // must not impose a minimum width on the content view.
        titleLabel.snp_makeConstraints { make in
            make.left.equalTo(contentView).offset(SiteTableViewControllerUX.HeaderTextMargin).priority(999)
            make.right.equalTo(contentView).offset(-SiteTableViewControllerUX.HeaderTextMargin).priority(999)
            make.centerY.equalTo(contentView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/**
 * Provides base shared functionality for site rows and headers.
 */
class SiteTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let DefaultCellIdentifier = "DefaultCellIdentifier"
    private let CellIdentifier = "CellIdentifier"
    private let HeaderIdentifier = "HeaderIdentifier"
    var iconForSiteId = [Int : Favicon]()

    var tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: DefaultCellIdentifier)
        tableView.registerClass(HistoryTableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        tableView.registerClass(SiteTableViewHeader.self, forHeaderFooterViewReuseIdentifier: HeaderIdentifier)
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.OnDrag
        tableView.backgroundColor = UIConstants.PanelBackgroundColor
        tableView.separatorColor = UIConstants.SeparatorColor
        tableView.accessibilityIdentifier = "SiteTable"

        tableView.cellLayoutMarginsFollowReadableWidth = false

        // Set an empty footer to prevent empty cells from appearing in the list.
        tableView.tableFooterView = UIView()
    }

    deinit {
        // The view might outlive this view controller thanks to animations;
        // explicitly nil out its references to us to avoid crashes. Bug 1218826.
        tableView.dataSource = nil
        tableView.delegate = nil
    }

    func reloadData() {
        self.tableView.reloadData()
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath: indexPath)
        if self.tableView(tableView, hasFullWidthSeparatorForRowAtIndexPath: indexPath) {
            cell.separatorInset = UIEdgeInsetsZero
        }
        
        if tableView.editing == false {
            cell.gestureRecognizers?.forEach { cell.removeGestureRecognizer($0) }
            let lp = UILongPressGestureRecognizer(target: self, action: #selector(longPressOnCell))
            cell.addGestureRecognizer(lp)
        }
        return cell
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterViewWithIdentifier(HeaderIdentifier)
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return SiteTableViewControllerUX.HeaderHeight
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return SiteTableViewControllerUX.RowHeight
    }

    func tableView(tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    func getLongPressUrl(forIndexPath indexPath: NSIndexPath) -> NSURL? {
        print("override in subclass for long press behaviour")
        return nil
    }

    @objc func longPressOnCell(gesture: UILongPressGestureRecognizer) {
        if tableView.editing { //disable context menu on editing mode
            return
        }
        
        if gesture.state != .Began {
            return
        }
        guard let cell = gesture.view as? UITableViewCell, let indexPath = tableView.indexPathForCell(cell) else { return }

        let tappedElement = ContextMenuHelper.Elements(link: getLongPressUrl(forIndexPath: indexPath), image: nil)
        var p = getApp().window!.convertPoint(cell.center, fromView:cell.superview!)
        p.x += cell.frame.width * 0.33
        getApp().browserViewController.showContextMenu(elements: tappedElement, touchPoint: p)
    }
}
