/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import UIKit
import CoreData
import Foundation
import Shared

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
    
    /// Should not be set directly, due to specific formatting required, use `syncUUID` instead
    /// CD does not allow (easily) searching on transformable properties, could use binary, but would still require tranformtion
    //  syncUUID should never change
    @NSManaged var syncDisplayUUID: String?
    @NSManaged var syncParentDisplayUUID: String?

    @NSManaged var parentFolder: Bookmark?
    @NSManaged var children: Set<Bookmark>?
    @NSManaged var domain: Domain?

    // To trigger fetchedResultsController to update, change this value.
    // For instance, when a favicon is set on a domain, to notify any bookmarks or history items that
    // are displayed in a table and waiting for a favicon, you can change markDirty, and the favicon will update
    @NSManaged var markDirty: Int16

    // Is conveted to better store in CD
    var syncUUID: [Int]? {
        get { return syncUUID(fromString: syncDisplayUUID) }
        set(value) { syncDisplayUUID = Bookmark.syncDisplay(fromUUID: value) }
    }
    
    var syncParentUUID: [Int]? {
        get { return syncUUID(fromString: syncParentDisplayUUID) }
        set(value) {
            // Save actual instance variable
            syncParentDisplayUUID = Bookmark.syncDisplay(fromUUID: value)

            // Attach parent, only works if parent exists.
            let parent = Bookmark.get(parentSyncUUID: value)
            parentFolder = parent
        }
    }
    
    var displayTitle: String? {
        if let custom = customTitle where !custom.isEmpty {
            return customTitle
        }
        
        if let t = title where !t.isEmpty {
            return title
        }
        
        // Want to return nil so less checking on frontend
        return nil
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        created = NSDate()
        lastVisited = created
    }
    
    // TODO: This entire method needs to go, to fragile with strings
    // TODO: Better use of `deviceId`
    // TODO: Use `action` enum
    func asSyncBookmark(deviceId deviceId: String, action: Int) -> JSON {
        
        // TODO: Could convert to 'actual' SyncBookmark record if handled objectId properly
        
        let unixCreated = Int((created?.timeIntervalSince1970 ?? 0) * 1000)
        let unixAccessed = Int((lastVisited?.timeIntervalSince1970 ?? 0) * 1000)
        
        let site = [
            "creationTime": unixCreated,
            "customTitle": customTitle ?? "",
            "favicon": domain?.favicon?.url ?? "",
            "lastAccessedTime": unixAccessed,
            "location": url ?? "",
            "title": title ?? ""
        ]
        
        let nativeObject: [String: AnyObject] = [
            "objectData": "bookmark",
            "deviceId": [0], // TODO: Actually set
            "objectId": syncUUID ?? "null",
            "action": action,
            "bookmark": [
                "isFolder": Int(isFolder),
//                "parentFolderObjectId": "undefined", // TODO: Fix
                "site": site
            ]
        ]
        
        return JSON(nativeObject)
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

    class func add(rootObject root: SyncRoot, save: Bool = false) -> Bookmark? {
        let bookmark = root.bookmark
        let site = bookmark?.site
        let url = NSURL(string: site?.location ?? "")
        
        if url?.absoluteString?.startsWith(WebServer.sharedInstance.base) ?? false {
            return nil
        }
        
        let bk = Bookmark(entity: Bookmark.entity(DataController.moc), insertIntoManagedObjectContext: DataController.moc)
        bk.url = url?.absoluteString
        bk.title = site?.title
        bk.customTitle = site?.customTitle // TODO: Check against empty titles
        bk.isFolder = bookmark?.isFolder ?? false
        
        if let created = site?.creationTime {
            bk.created = NSDate(timeIntervalSince1970:(Double(created) / 1000.0))
        } else {
            bk.created = NSDate()
        }
        
        if let visited = site?.lastAccessedTime {
            bk.lastVisited = NSDate(timeIntervalSince1970:(Double(visited) / 1000.0))
        } else {
            bk.lastVisited = NSDate()
        }
        
        if let url = url {
            bk.domain = Domain.getOrCreateForUrl(url, context: DataController.moc)
        }
        
        if let parentFolderObjectId = bookmark?.parentFolderObjectId {
            bk.syncParentUUID = parentFolderObjectId
        }
        
        bk.syncUUID = root.objectId
        
        if bk.syncUUID == nil {
            // Need async creation of UUID
            Niceware.shared.uniqueBytes(count: 16) {
                (result, error) in
                
                bk.syncUUID = result
                
                if save {
                    DataController.saveContext()
                }
                
                if Sync.shared.isInSyncGroup {
                    Sync.shared.sendSyncRecords(.bookmark, bookmarks: [bk])
                }
            }
        } else if save {
            // If no syncUUI is available, it will be saved after id is set
            DataController.saveContext()
        }
        
        return bk
    }
    
    // TODO: DELETE
    class func add(url url: String?,
                       title: String?,
                       parentFolder:Bookmark? = nil,
                       isFolder:Bool = false) -> Bookmark? {
        
        let site = SyncSite()
        site.title = title
        site.location = url
        
        let bookmark = SyncBookmark()
        bookmark.isFolder = isFolder
        bookmark.parentFolderObjectId = isFolder ? parentFolder?.syncUUID : parentFolder?.syncParentUUID
        bookmark.site = site
        
        let root = SyncRoot()
        root.bookmark = bookmark
        
        return self.add(rootObject: root)
    }
    
    // TODO: Migration syncUUIDS still needs to be solved
    // Should only ever be used for migration from old db
    class func addForMigration(url url: String?, title: String, customTitle: String, parentFolder: NSManagedObjectID?, isFolder: Bool?) -> Bookmark? {
        // isFolder = true
        
        let site = SyncSite()
        site.title = title
        site.customTitle = customTitle
        site.location = url
        
        let bookmark = SyncBookmark()
        bookmark.isFolder = isFolder
//        bookmark.parentFolderObjectId = [parentFolder]
        bookmark.site = site
        
        let root = SyncRoot()
        root.bookmark = bookmark
        
        return self.add(rootObject: root, save: true)
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
    
    
    /// UUID -> DisplayUUID
    private static func syncDisplay(fromUUID uuid: [Int]?) -> String? {
        return uuid?.map{ $0.description }.joinWithSeparator(",")
    }
    
    /// DisplayUUID -> UUID
    private func syncUUID(fromString string: String?) -> [Int]? {
        return string?.componentsSeparatedByString(",").map { Int($0) }.flatMap { $0 }
    }
}

// Getters
extension Bookmark {
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
    
    private static func get(predicate predicate: NSPredicate?) -> [Bookmark]? {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = Bookmark.entity(DataController.moc)
        fetchRequest.predicate = predicate
        
        do {
            return try DataController.moc.executeFetchRequest(fetchRequest) as? [Bookmark]
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        
        return nil
    }
    
    static func get(syncUUIDs syncUUIDs: [[Int]]?) -> [Bookmark]? {
        
        guard let syncUUIDs = syncUUIDs else {
            return nil
        }
        
        // TODO: filter a unique set of syncUUIDs
        
        let searchableUUIDs = syncUUIDs.map { Bookmark.syncDisplay(fromUUID: $0) }.flatMap { $0 }
        return get(predicate: NSPredicate(format: "syncDisplayUUID IN %@", searchableUUIDs ))
    }
    
    static func get(parentSyncUUID parentUUID: [Int]?) -> Bookmark? {
        guard let searchableUUID = Bookmark.syncDisplay(fromUUID: parentUUID) else {
            return nil
        }
        
        return get(predicate: NSPredicate(format: "syncDisplayUUID == %@", searchableUUID))?.first
    }
    
    static func getFolders(bookmark: Bookmark?) -> [Bookmark] {
    
        var predicate: NSPredicate?
        if let parent = bookmark?.parentFolder {
            predicate = NSPredicate(format: "isFolder == true and parentFolder == %@", parent)
        } else {
            predicate = NSPredicate(format: "isFolder == true and parentFolder.@count = 0")
        }
        
        return get(predicate: predicate) ?? [Bookmark]()
    }
    
    static func getAllBookmarks() -> [Bookmark] {
        return get(predicate: nil) ?? [Bookmark]()
    }
}

// Removals
extension Bookmark {
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
    
    class func remove(bookmark bookmark: Bookmark, save: Bool = true) {
        DataController.moc.deleteObject(bookmark)
        if save {
            DataController.saveContext()
        }
    }
}

