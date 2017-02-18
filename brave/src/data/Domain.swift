//
//  Domain.swift
//  Client
//
//  Created by James Mudgett on 1/29/17.
//  Copyright © 2017 Brave. All rights reserved.
//

import UIKit
import CoreData
import Foundation

class Domain: NSManagedObject {
    
    @NSManaged var url: String?
    @NSManaged var visits: Int32
    @NSManaged var topsite: Bool
    @NSManaged var favicon: FaviconMO?
    @NSManaged var history: NSSet?

    @NSManaged var shield_allOff: NSNumber?
    @NSManaged var shield_adblockAndTp: NSNumber?
    @NSManaged var shield_httpse: NSNumber?
    @NSManaged var shield_noScript: NSNumber?
    @NSManaged var shield_fpProtection: NSNumber?
    @NSManaged var shield_safeBrowsing: NSNumber?


    static var entityInfo: NSEntityDescription {
        return NSEntityDescription.entityForName("Domain", inManagedObjectContext: DataController.moc)!
    }

    override func awakeFromInsert() {
        super.awakeFromInsert()
    }

    class func getOrCreateForUrl(url: NSURL) -> Domain? {
        assert(!NSThread.isMainThread())

        let domainUrl = url.domainURL()
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = Domain.entityInfo
        fetchRequest.predicate = NSPredicate(format: "url == %@", domainUrl)
        var result: Domain? = nil
        do {
            let results = try DataController.moc.executeFetchRequest(fetchRequest) as? [Domain]
            if let item = results?.first {
                result = item
            } else {
                result = Domain(entity: Domain.entityInfo, insertIntoManagedObjectContext: DataController.moc)
                result?.url = domainUrl.absoluteString
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return result
    }
}
