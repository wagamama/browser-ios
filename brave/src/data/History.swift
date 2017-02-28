/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import CoreData
import Shared

private func getDate(dayOffset dayOffset: Int) -> NSDate {
    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    let nowComponents = calendar.components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: NSDate())
    let today = calendar.dateFromComponents(nowComponents)!
    return calendar.dateByAddingUnit(NSCalendarUnit.Day, value: dayOffset, toDate: today, options: [])!
}

private var ignoredSchemes = ["about"]

public func isIgnoredURL(url: NSURL) -> Bool {
    guard let scheme = url.scheme else { return false }

    if let _ = ignoredSchemes.indexOf(scheme) {
        return true
    }

    if url.host == "localhost" {
        return true
    }

    return false
}

public func isIgnoredURL(url: String) -> Bool {
    if let url = NSURL(string: url) {
        return isIgnoredURL(url)
    }

    return false
}

class History: NSManagedObject {

    @NSManaged var title: String?
    @NSManaged var url: String?
    @NSManaged var visitedOn: NSDate?
    @NSManaged var syncUUID: NSUUID?
    @NSManaged var domain: Domain?
    @NSManaged var sectionIdentifier: String?

    // To trigger fetchedResultsController to update, easiest method is change this value
    // For instance, when a favicon is set on a domain, to notify any bookmarks or history items that
    // are displayed in a table and waiting for a favicon, you can change markDirty, and the favicon will update
    @NSManaged var markDirty: Int16
    
    static let Today = getDate(dayOffset: 0)
    static let Yesterday = getDate(dayOffset: -1)
    static let ThisWeek = getDate(dayOffset: -7)
    static let ThisMonth = getDate(dayOffset: -31)

    static func entity(context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entityForName("History", inManagedObjectContext: context)!
    }

    class func add(title title: String, url: NSURL) {
        let context = DataController.shared.workerContext()
        context.performBlock {
            var item = History.getExisting(url, context: context)
            if item == nil {
                item = History(entity: History.entity(context), insertIntoManagedObjectContext: context)
                item!.domain = Domain.getOrCreateForUrl(url, context: context)
                item!.url = url.absoluteString
            }
            item?.title = title
            item?.domain?.visits += 1
            item?.visitedOn = NSDate()
            item?.sectionIdentifier = Strings.Today

            DataController.saveContext(context)
        }
    }

    class func frc() -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = History.entity(DataController.moc)
        fetchRequest.fetchBatchSize = 20
        fetchRequest.fetchLimit = 200
        fetchRequest.sortDescriptors = [NSSortDescriptor(key:"visitedOn", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "visitedOn >= %@", History.ThisMonth)

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:DataController.moc, sectionNameKeyPath: "sectionIdentifier", cacheName: nil)
    }

    override func awakeFromFetch() {
        if sectionIdentifier != nil {
            return
        }

        if visitedOn?.compare(History.Today) == NSComparisonResult.OrderedDescending {
            sectionIdentifier = Strings.Today
        } else if visitedOn?.compare(History.Yesterday) == NSComparisonResult.OrderedDescending {
            sectionIdentifier = Strings.Yesterday
        } else if visitedOn?.compare(History.ThisWeek) == NSComparisonResult.OrderedDescending {
            sectionIdentifier = Strings.Last_week
        } else {
            sectionIdentifier = Strings.Last_month
        }
    }

    class func getExisting(url: NSURL, context: NSManagedObjectContext) -> History? {
        assert(!NSThread.isMainThread())

        guard let urlString = url.absoluteString else { return nil }
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = History.entity(context)
        fetchRequest.predicate = NSPredicate(format: "url == %@", urlString)
        var result: History? = nil
        do {
            let results = try context.executeFetchRequest(fetchRequest) as? [History]
            if let item = results?.first {
                result = item
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return result
    }

    class func frecencyQuery(context: NSManagedObjectContext) -> [History] {
        assert(!NSThread.isMainThread())

        let fetchRequest = NSFetchRequest()
        fetchRequest.fetchLimit = 100
        fetchRequest.entity = History.entity(context)
        fetchRequest.predicate = NSPredicate(format: "visitedOn > %@", History.ThisWeek)

        do {
            if let results = try context.executeFetchRequest(fetchRequest) as? [History] {
                return results
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return [History]()
    }
    
    class func deleteAll(completionOnMain: ()->()) {
        let context = DataController.shared.workerContext()
        context.performBlock {
            let fetchRequest = NSFetchRequest()
            fetchRequest.entity = History.entity(context)
            fetchRequest.includesPropertyValues = false
            do {
                let results = try context.executeFetchRequest(fetchRequest)
                for result in results {
                    context.deleteObject(result as! NSManagedObject)
                }

            } catch {
                let fetchError = error as NSError
                print(fetchError)
            }

            DataController.saveContext(context)

            Domain.deleteNonBookmarked {
                completionOnMain()
            }
        }
    }

}
