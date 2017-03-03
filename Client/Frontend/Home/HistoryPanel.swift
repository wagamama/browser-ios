/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

import Shared
import Storage
import CoreData

private struct HistoryPanelUX {
    static let WelcomeScreenPadding: CGFloat = 15
    static let WelcomeScreenItemTextColor = UIColor.grayColor()
    static let WelcomeScreenItemWidth = 170
}

class HistoryPanel: SiteTableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    private lazy var emptyStateOverlayView: UIView = self.createEmptyStateOverview()
    private var kvoContext: UInt8 = 1
    var frc: NSFetchedResultsController? = nil

    init() {
        super.init(nibName: nil, bundle: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HistoryPanel.notificationReceived(_:)), name: NotificationFirefoxAccountChanged, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HistoryPanel.notificationReceived(_:)), name: NotificationPrivateDataClearedHistory, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HistoryPanel.notificationReceived(_:)), name: NotificationDynamicFontChanged, object: nil)
    }

    override func viewDidLoad() {
        frc = History.frc()
        frc!.delegate = self
        super.viewDidLoad()
        self.tableView.accessibilityIdentifier = "History List"

        reloadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationPrivateDataClearedHistory, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationDynamicFontChanged, object: nil)
    }

    func notificationReceived(notification: NSNotification) {
        switch notification.name {
        case NotificationDynamicFontChanged:
            if emptyStateOverlayView.superview != nil {
                emptyStateOverlayView.removeFromSuperview()
            }
            emptyStateOverlayView = createEmptyStateOverview()
            break
        default:
            // no need to do anything at all
            break
        }
    }

    override func reloadData() {
        guard let frc = frc else {
            return
        }
        DataController.saveContext()

        do {
            try frc.performFetch()
        } catch let error as NSError {
            print(error.description)
        }

        tableView.reloadData()
        updateEmptyPanelState()
    }

    private func updateEmptyPanelState() {
        if frc?.fetchedObjects?.count == 0 {
            if self.emptyStateOverlayView.superview == nil {
                self.tableView.addSubview(self.emptyStateOverlayView)
                self.emptyStateOverlayView.snp_makeConstraints { make -> Void in
                    make.edges.equalTo(self.tableView)
                    make.size.equalTo(self.view)
                }
            }
        } else {
            self.emptyStateOverlayView.removeFromSuperview()
        }
    }

    private func createEmptyStateOverview() -> UIView {
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.whiteColor()

        return overlayView
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    func configureCell(_cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let cell = _cell as? TwoLineTableViewCell else { return }
        let site = frc!.objectAtIndexPath(indexPath) as! History
        cell.backgroundColor = UIColor.clearColor()
        cell.setLines(site.title, detailText: site.url)
        cell.imageView!.image = FaviconFetcher.defaultFavicon
        if let faviconMO = site.domain?.favicon, let url = faviconMO.url {
            let favicon = Favicon(url: url, type: IconType(rawValue: Int(faviconMO.type)) ?? IconType.Guess)
            postAsyncToBackground {
                let best = getBestFavicon([favicon])
                postAsyncToMain {
                    cell.imageView!.setIcon(best, withPlaceholder: FaviconFetcher.defaultFavicon)
                }
            }
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        telemetry(action: "history item picked", props: nil)
        let site = frc?.objectAtIndexPath(indexPath) as! History

        if let u = site.url, let url = NSURL(string: u) {
            homePanelDelegate?.homePanel(self, didSelectURL: url)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // Minimum of 1 section
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let count = frc?.sections?.count ?? 0
        return count
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sections = frc?.sections else { return nil }
        return sections.indices ~= section ? sections[section].name : nil
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = frc?.sections else { return 0 }
        return sections.indices ~= section ? sections[section].numberOfObjects : 0
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            if let obj = self.frc?.objectAtIndexPath(indexPath) as? History {
                DataController.moc.deleteObject(obj)
                DataController.saveContext()
            }
        }
    }

    override func getLongPressUrl(forIndexPath indexPath: NSIndexPath) -> NSURL? {
        guard let obj = frc?.objectAtIndexPath(indexPath) as? History else { return nil }
        return obj.url != nil ? NSURL(string: obj.url!) : nil
    }
}

extension HistoryPanel : NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            let sectionIndexSet = NSIndexSet(index: sectionIndex)
            self.tableView.insertSections(sectionIndexSet, withRowAnimation: .Fade)
        case .Delete:
            let sectionIndexSet = NSIndexSet(index: sectionIndex)
            self.tableView.deleteSections(sectionIndexSet, withRowAnimation: .Fade)
        default: break;
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch (type) {
        case .Insert:
            if let indexPath = newIndexPath {
                tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        case .Delete:
            if let indexPath = indexPath {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        case .Update:
            if let indexPath = indexPath, let cell = tableView.cellForRowAtIndexPath(indexPath) {
                configureCell(cell, atIndexPath: indexPath)
            }
        case .Move:
            if let indexPath = indexPath {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }

            if let newIndexPath = newIndexPath {
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
            }
        }
        updateEmptyPanelState()
    }
}
