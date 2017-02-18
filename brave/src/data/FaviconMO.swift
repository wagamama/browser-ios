//
//  Favicon.swift
//  Client
//
//  Created by James Mudgett on 1/29/17.
//  Copyright © 2017 Brave. All rights reserved.
//

import UIKit
import CoreData
import Foundation
import Storage

class FaviconMO: NSManagedObject {
    
    @NSManaged var url: String?
    @NSManaged var width: Int16
    @NSManaged var height: Int16
    @NSManaged var type: Int16
    @NSManaged var domain: Domain?

    static var entityInfo: NSEntityDescription {
        return NSEntityDescription.entityForName("Favicon", inManagedObjectContext: DataController.moc)!
    }

    class func get(forFaviconUrl urlString: String) -> FaviconMO? {
        assert(!NSThread.isMainThread())

        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = FaviconMO.entityInfo
        fetchRequest.predicate = NSPredicate(format: "url == %@", urlString)
        var result: FaviconMO? = nil
        do {
            let results = try DataController.moc.executeFetchRequest(fetchRequest) as? [FaviconMO]
            if let item = results?.first {
                result = item
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return result
    }

    class func add(favicon favicon: Favicon, forSiteUrl siteUrl: NSURL) {
        DataController.write {
            let domainUrl = siteUrl.domainURL()
            var item = FaviconMO.get(forFaviconUrl: favicon.url)
            if item == nil {
                item = FaviconMO(entity: FaviconMO.entityInfo, insertIntoManagedObjectContext: DataController.moc)
                item!.url = favicon.url
            }
            if item?.domain == nil {
                item!.domain = Domain.getOrCreateForUrl(domainUrl)
            }
            let w = Int16(favicon.width ?? 0)
            let h = Int16(favicon.height ?? 0)
            let t = Int16(favicon.type.rawValue ?? 0)

            if w != item!.width && w > 0 {
                item!.width = w
            }

            if h != item!.height && h > 0 {
                item!.height = h
            }

            if t != item!.type {
                item!.type = t
            }
        }
    }


}
