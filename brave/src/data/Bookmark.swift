/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */


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
    @NSManaged var syncUUID: String?

    @NSManaged var parentFolder: Bookmark?
    @NSManaged var children: Set<Bookmark>?
    @NSManaged var domain: Domain?

    // To trigger fetchedResultsController to update, change this value.
    // For instance, when a favicon is set on a domain, to notify any bookmarks or history items that
    // are displayed in a table and waiting for a favicon, you can change markDirty, and the favicon will update
    @NSManaged var markDirty: Int16

    override func awakeFromInsert() {
        super.awakeFromInsert()
        created = NSDate()
        lastVisited = created
    }

    static func entity(context:NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entityForName("Bookmark", inManagedObjectContext: context)!
    }

    class func frc(parentFolder parentFolder: Bookmark?) -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = Bookmark.entity(DataController.moc)
        fetchRequest.fetchBatchSize = 20
        fetchRequest.fetchLimit = 200
        fetchRequest.sortDescriptors = [NSSortDescriptor(key:"order", ascending: true), NSSortDescriptor(key:"created", ascending: false)]
        if let parentFolder = parentFolder {
            fetchRequest.predicate = NSPredicate(format: "parentFolder == %@", parentFolder)
        } else {
            fetchRequest.predicate = NSPredicate(format: "parentFolder == nil")
        }

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:DataController.moc, sectionNameKeyPath: nil, cacheName: nil)
    }

    class func add(url url: NSURL?,
                       title: String?,
                       customTitle: String?,
                       // Optionals
                       syncUUID: String? = nil,
                       created: UInt? = nil,
                       lastAccessed: UInt? = nil,
                       parentFolder:NSManagedObjectID? = nil,
                       isFolder: Bool = false,
                       save: Bool = true) -> Bookmark? {
        
        if url?.absoluteString?.startsWith(WebServer.sharedInstance.base) ?? false {
            return nil
        }
        
        let bk = Bookmark(entity: Bookmark.entity(DataController.moc), insertIntoManagedObjectContext: DataController.moc)
        bk.url = url?.absoluteString
        bk.title = title
        bk.customTitle = customTitle // TODO: Check against empty titles
        bk.isFolder = isFolder
        
        if let created = created {
            bk.created = NSDate(timeIntervalSince1970:(Double(created) / 1000.0))
        } else {
            bk.created = NSDate()
        }
        
        if let visited = lastAccessed {
            bk.lastVisited = NSDate(timeIntervalSince1970:(Double(visited) / 1000.0))
        } else {
            bk.lastVisited = NSDate()
        }

        if let syncUUID = syncUUID {
            bk.syncUUID = syncUUID.stringByReplacingOccurrencesOfString(" ", withString: "")
        } else {
            // Need async creation of UUID
        }

        if let url = url {
            bk.domain = Domain.getOrCreateForUrl(url, context: DataController.moc)
        }
        if let id = parentFolder {
            bk.parentFolder = DataController.moc.objectWithID(id) as? Bookmark
        }

        if save {
            DataController.saveContext()
        }
        
        return bk
    }

    class func contains(url url: NSURL, completionOnMain completion: ((Bool)->Void)) {
        var found = false
        let context = DataController.shared.workerContext()
        context.performBlock {
            if let count = get(forUrl: url, countOnly: true, context: context) as? Int {
                found = count > 0
            }
            postAsyncToMain {
                completion(found)
            }
        }
    }

    private static func get(forUrl url: NSURL, countOnly: Bool = false, context: NSManagedObjectContext) -> AnyObject? {
        guard let str = url.absoluteDisplayString() else { return nil }
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = Bookmark.entity(context)
        fetchRequest.predicate = NSPredicate(format: "url == %@", str)
        do {
            if countOnly {
                let count = try context.countForFetchRequest(fetchRequest)
                return count
            }
            let results = try context.executeFetchRequest(fetchRequest)
            if let bm = results.first {
                return bm as? Bookmark
            } else {
                return nil
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return nil
    }
    
    static func get(intSyncUUIDs intSyncUUIDs: [[Int]]?) -> [Bookmark]? {

        let uuids = intSyncUUIDs?.map { $0.description }
        return get(syncUUIDs: uuids)
    }
    
    static func get(syncUUIDs syncUUIDs: [String]?) -> [Bookmark]? {
        
        guard var syncUUIDs = syncUUIDs else {
            return nil
        }
        
        syncUUIDs = syncUUIDs.map { $0.stringByReplacingOccurrencesOfString(" ", withString: "") }
        
        // TODO: filter a unique set of syncUUIDs

        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = Bookmark.entity(DataController.moc)
        fetchRequest.predicate = NSPredicate(format: "syncUUID IN %@", syncUUIDs)
        
        if let results = try? DataController.moc.executeFetchRequest(fetchRequest) as? [Bookmark] {
            return results
        }
        
        return nil
    }

    static func getFolders(bookmark: Bookmark?) -> [Bookmark] {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = Bookmark.entity(DataController.moc)
        if let parent = bookmark?.parentFolder {
            fetchRequest.predicate = NSPredicate(format: "isFolder == true and parentFolder == %@", parent)
        } else {
            fetchRequest.predicate = NSPredicate(format: "isFolder == true and parentFolder.@count = 0")
        }
        do {
            if let results = try DataController.moc.executeFetchRequest(fetchRequest) as? [Bookmark] {
                return results
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return [Bookmark]()
    }

    class func remove(forUrl url: NSURL, save: Bool = true) -> Bool {
        if let bm = get(forUrl: url, context: DataController.moc) as? Bookmark {
            DataController.moc.deleteObject(bm)
            if save {
                DataController.saveContext()
            }
            return true
        }
        return false
    }

    class func frecencyQuery(context: NSManagedObjectContext) -> [Bookmark] {
        assert(!NSThread.isMainThread())

        let fetchRequest = NSFetchRequest()
        fetchRequest.fetchLimit = 5
        fetchRequest.entity = Bookmark.entity(context)
        fetchRequest.predicate = NSPredicate(format: "lastVisited > %@", History.ThisWeek)

        do {
            if let results = try context.executeFetchRequest(fetchRequest) as? [Bookmark] {
                return results
            }
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return [Bookmark]()
    }

}
