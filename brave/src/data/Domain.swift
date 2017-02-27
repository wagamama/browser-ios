/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import UIKit
import CoreData
import Foundation

class Domain: NSManagedObject {
    
    @NSManaged var url: String?
    @NSManaged var visits: Int32
    @NSManaged var topsite: Bool
    @NSManaged var blockedFromTopSites: Bool // don't show ever on top sites
    @NSManaged var favicon: FaviconMO?

    @NSManaged var shield_allOff: NSNumber?
    @NSManaged var shield_adblockAndTp: NSNumber?
    @NSManaged var shield_httpse: NSNumber?
    @NSManaged var shield_noScript: NSNumber?
    @NSManaged var shield_fpProtection: NSNumber?
    @NSManaged var shield_safeBrowsing: NSNumber?

    @NSManaged var historyItems: NSSet?
    @NSManaged var bookmarks: NSSet?

    static func entity(context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entityForName("Domain", inManagedObjectContext: context)!
    }

    override func awakeFromInsert() {
        super.awakeFromInsert()
    }

    class func getOrCreateForUrl(url: NSURL, context: NSManagedObjectContext) -> Domain? {
        guard let domainUrl = url.normalizedHost() else { return nil }

        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = Domain.entity(context)
        fetchRequest.predicate = NSPredicate(format: "url == %@", domainUrl)
        var result: Domain? = nil
        do {
            let results = try context.executeFetchRequest(fetchRequest) as? [Domain]
            if let item = results?.first {
                result = item
            } else {
                print("👽 Creating Domain \(domainUrl)")
                result = Domain(entity: Domain.entity(context), insertIntoManagedObjectContext: context)
                result?.url = domainUrl
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return result
    }

    class func blockFromTopSites(url: NSURL, context: NSManagedObjectContext) {
        if let domain = getOrCreateForUrl(url, context: context) {
            domain.blockedFromTopSites = true
            DataController.saveContext(context)
        }
    }

    class func blockedTopSites(context: NSManagedObjectContext) -> [Domain] {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = Domain.entity(context)
        fetchRequest.predicate = NSPredicate(format: "blockedFromTopSites == %@", NSNumber(bool: true))
        do {
            if let results = try context.executeFetchRequest(fetchRequest) as? [Domain] {
                return results
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return [Domain]()
    }

    class func topSitesQuery(limit limit: Int, context: NSManagedObjectContext) -> [Domain] {
        assert(!NSThread.isMainThread())

        let minVisits = 5

        let fetchRequest = NSFetchRequest()
        fetchRequest.fetchLimit = limit
        fetchRequest.entity = Domain.entity(context)
        fetchRequest.predicate = NSPredicate(format: "visits > %i AND blockedFromTopSites != %@", minVisits, NSNumber(bool: true))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "visits", ascending: false)]
        do {
            if let results = try context.executeFetchRequest(fetchRequest) as? [Domain] {
                return results
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return [Domain]()
    }

    
}
