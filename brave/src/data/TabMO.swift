import UIKit
import CoreData
import Foundation

typealias SavedTab = (title: String, url: String, isSelected: Bool, order: Int16, screenshot: UIImage?, history: [String], historyIndex: Int16)

extension TabManager {
    class func tabsToRestore() -> [TabMO] {
        return TabMO.getAll(DataController.moc)
    }

    func preserveTabs() {
        print("preserveTabs()")
        var _tabs = [SavedTab]()
        var i = 0
        for tab in tabs.internalTabList {
            if tab.isPrivate || tab.url?.absoluteString == nil {
                continue
            }

            var urls = [String]()
            var currentPage = 0
            if let currentItem = tab.webView?.backForwardList.currentItem {
                // Freshly created web views won't have any history entries at all.

                let backList = tab.webView?.backForwardList.backList ?? []
                let forwardList = tab.webView?.backForwardList.forwardList ?? []
                urls += (backList + [currentItem] + forwardList).map { $0.URL.absoluteString ?? "" }
                currentPage = -forwardList.count
            }

            _tabs.append((tab.title ?? "", tab.url!.absoluteString!, self.selectedTab === tab, Int16(i), tab.screenshot.image, urls, Int16(currentPage)))
            i += 1
        }

        let context = DataController.shared.workerContext()
        context.performBlock {
            var savedTabs = [String: TabMO]()
            TabMO.getAll(context).forEach { savedTabs[$0.url ?? ""] = $0 }
            for t in _tabs {
                var mo = savedTabs[t.url]
                if mo == nil {
                    mo = TabMO.add(t, context: context)
                } else {
                    savedTabs[t.url] = nil
                }
            }

            savedTabs.values.forEach {
                context.deleteObject($0)
            }

            DataController.saveContext(context)
        }
    }

    func restoreTabs() {
        var tabToSelect: Browser?
        let savedTabs = TabMO.getAll(DataController.moc)
        for savedTab in savedTabs {
            guard let tab = addTab(nil, configuration: nil, zombie: true, isPrivate: false) else { return }
            tab.setScreenshot(savedTab.screenshotImage)
            if savedTab.isSelected {
                tabToSelect = tab
            }
            tab.lastTitle = savedTab.title
            if let w = tab.webView {
                let data = SavedTab(title: savedTab.title ?? "", url: savedTab.url ?? "", isSelected: savedTab.isSelected, order: savedTab.order, screenshot: nil, history:savedTab.urlHistorySnapshot as! [String], historyIndex: savedTab.urlHistoryCurrentIndex)
                tab.restore(w, restorationData: data)
            }
        }
        if tabToSelect == nil {
            tabToSelect = tabs.displayedTabsForCurrentPrivateMode.first
        }

        // Only tell our delegates that we restored tabs if we actually restored a tab(s)
        if savedTabs.count > 0 {
            delegates.forEach { $0.value?.tabManagerDidRestoreTabs(self) }
        }

        if let tab = tabToSelect {
            selectTab(tab)
        }

        if selectedTab == nil {
            addTabAndSelect()
        }
    }
}

class TabMO: NSManagedObject {
    
    @NSManaged var title: String?
    @NSManaged var url: String?
    @NSManaged var order: Int16
    @NSManaged var urlHistorySnapshot: NSArray? // array of strings for urls
    @NSManaged var urlHistoryCurrentIndex: Int16
    @NSManaged var screenshot: NSData?
    @NSManaged var isSelected: Bool

    var screenshotImage: UIImage?

    override func awakeFromInsert() {
        super.awakeFromInsert()

        if let data = screenshot {
            screenshotImage = UIImage(data: data)
        }
    }

    static func entity(context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entityForName("TabMO", inManagedObjectContext: context)!
    }

    class func add(tabInfo: SavedTab, context: NSManagedObjectContext) -> TabMO {
        let tab = TabMO(entity: TabMO.entity(context), insertIntoManagedObjectContext: context)
        if let s = tabInfo.screenshot {
            tab.screenshot = UIImageJPEGRepresentation(s, 1)
        }
        tab.url = tabInfo.url
        tab.order = tabInfo.order
        tab.title = tabInfo.title
        tab.urlHistorySnapshot = tabInfo.history
        tab.urlHistoryCurrentIndex = tabInfo.historyIndex
        tab.isSelected = tabInfo.isSelected
        return tab
    }

    class func getAll(context: NSManagedObjectContext) -> [TabMO] {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = TabMO.entity(context)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        do {
            return try context.executeFetchRequest(fetchRequest) as? [TabMO] ?? [TabMO]()
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return [TabMO]()
    }
}
