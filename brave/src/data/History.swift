//
//  History.swift
//  Client
//
//  Created by James Mudgett on 1/29/17.
//  Copyright © 2017 Brave. All rights reserved.
//

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

    let Today = getDate(dayOffset: 0)
    let Yesterday = getDate(dayOffset: -1)
    let ThisWeek = getDate(dayOffset: -7)
    static let ThisMonth = getDate(dayOffset: -31)

    static var entityInfo: NSEntityDescription {
        return NSEntityDescription.entityForName("History", inManagedObjectContext: DataController.moc)!
    }

    class func add(title title: String, url: NSURL) {
        DataController.write {
            var item = History.getExisting(url)
            if item == nil {
                item = History(entity: History.entityInfo, insertIntoManagedObjectContext: DataController.moc)
                item!.domain = Domain.getOrCreateForUrl(url)
                item!.url = url.absoluteString
            }
            item?.title = title
            item?.domain?.visits += 1
            item?.visitedOn = NSDate()
            item?.sectionIdentifier = Strings.Today
        }
    }

    class func frc() -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = History.entityInfo
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

        if visitedOn?.compare(Today) == NSComparisonResult.OrderedDescending {
            sectionIdentifier = Strings.Today
        } else if visitedOn?.compare(Yesterday) == NSComparisonResult.OrderedDescending {
            sectionIdentifier = Strings.Yesterday
        } else if visitedOn?.compare(ThisWeek) == NSComparisonResult.OrderedDescending {
            sectionIdentifier = Strings.Last_week
        } else {
            sectionIdentifier = Strings.Last_month
        }
    }

    class func getExisting(url: NSURL) -> History? {
        guard let urlString = url.absoluteString else { return nil }
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = History.entityInfo
        fetchRequest.predicate = NSPredicate(format: "url == %@", urlString)
        var result: History? = nil
        do {
            let results = try DataController.moc.executeFetchRequest(fetchRequest) as? [History]
            if let item = results?.first {
                result = item
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return result
    }

}
