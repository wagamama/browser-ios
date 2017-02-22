//
//  Bookmark.swift
//  Client
//
//  Created by James Mudgett on 1/27/17.
//  Copyright © 2017 Brave. All rights reserved.
//

import UIKit
import CoreData
import Foundation

class Bookmark: NSManagedObject {
    
    @NSManaged var isFolder: Bool
    @NSManaged var title: String?
    @NSManaged var customTitle: String?
    @NSManaged var url: String?
    @NSManaged var visits: Int32
    @NSManaged var lastVisited: NSDate?
    @NSManaged var created: NSDate?
    @NSManaged var order: Int16
    @NSManaged var tags: [String]?
    @NSManaged var syncUUID: NSUUID?

    @NSManaged var parentFolder: Bookmark?
    @NSManaged var childFolders: NSSet?
    @NSManaged var domain: Domain?


    override func awakeFromInsert() {
        super.awakeFromInsert()
        created = NSDate()
        lastVisited = created
    }

    static var entityInfo: NSEntityDescription {
        return NSEntityDescription.entityForName("Bookmark", inManagedObjectContext: DataController.moc)!
    }

    class func frc(parentFolder parentFolder: Bookmark?) -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = Bookmark.entityInfo
        fetchRequest.fetchBatchSize = 20
        fetchRequest.fetchLimit = 200
        fetchRequest.sortDescriptors = [NSSortDescriptor(key:"order", ascending: false), NSSortDescriptor(key:"created", ascending: false)]
        if let parentFolder = parentFolder {
            fetchRequest.predicate = NSPredicate(format: "parentFolder == %@", parentFolder)
        }
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:DataController.moc, sectionNameKeyPath: nil, cacheName: nil)
    }

    class func add(url url: String?, title: String?, parentFolder:NSManagedObjectID? = nil, isFolder: Bool = false) {

        DataController.write {
            let bk = Bookmark(entity: Bookmark.entityInfo, insertIntoManagedObjectContext: DataController.moc)
            bk.url = url
            bk.title = title
            bk.isFolder = isFolder

            if let url = url, let nsurl = NSURL(string: url) {
                bk.domain = Domain.getOrCreateForUrl(nsurl)
            }
            if let id = parentFolder {
                bk.parentFolder = DataController.moc.objectWithID(id) as? Bookmark
            }
        }
    }
    
}
