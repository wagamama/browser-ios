/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import CoreData

// Follow the stack design from http://floriankugler.com/2013/04/02/the-concurrent-core-data-stack/
// workerMOC is-child-of mainThreadMOC is-child-of writeMOC
// Data flows up through the stack only (child-to-parent), the bottom being the `writeMOC` which is used only for saving to disk.
//
// Notice no merge notifications are needed using this method.

let CoreDataWriteQueue: dispatch_queue_t = dispatch_queue_create("BraveDataWriteQueue", DISPATCH_QUEUE_SERIAL)

class DataController: NSObject {
    static let shared = DataController()

    private var writeMOC: NSManagedObjectContext?
    private var mainThreadMOC: NSManagedObjectContext?
    private var workerMOC: NSManagedObjectContext? = nil

    static var moc: NSManagedObjectContext {
        get {
            if DataController.shared.mainThreadMOC == nil {
                fatalError("DataController: Access to .moc contained nil value. A db connection has not yet been instantiated.")
            }

            if NSThread.isMainThread() {
                return DataController.shared.mainThreadMOC!
            } else {
                assert(false)
            }
        }
    }
    
    private var managedObjectModel: NSManagedObjectModel!
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    
    private override init() {
        super.init()

       // TransformerUUID.setValueTransformer(transformer: NSValueTransformer?, forName name: String)

        guard let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        guard let mom = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        
        self.managedObjectModel = mom
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        if let docURL = urls.last {
            let storeURL = docURL.URLByAppendingPathComponent("Brave.sqlite")
            do {
                try self.persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
            }
            catch {
                fatalError("Error migrating store: \(error)")
            }
        }

        mainThreadContext()
    }

    private func writeContext() -> NSManagedObjectContext {
        if writeMOC == nil {
            writeMOC = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            writeMOC?.persistentStoreCoordinator = persistentStoreCoordinator
            writeMOC?.undoManager = nil
            writeMOC?.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        }
        return writeMOC!
    }

    func workerContext() -> NSManagedObjectContext {
        if workerMOC == nil {
            workerMOC = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            workerMOC!.parentContext = mainThreadMOC
            workerMOC!.undoManager = nil
            workerMOC!.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        }
        return workerMOC!
    }

    private func mainThreadContext() -> NSManagedObjectContext {
        if mainThreadMOC != nil {
            return mainThreadMOC!
        }

        mainThreadMOC = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        mainThreadMOC?.undoManager = nil
        mainThreadMOC?.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        mainThreadMOC?.parentContext = writeContext()
        return mainThreadMOC!
    }

    static func saveContext(context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()

                if context === DataController.shared.mainThreadMOC {
                    // Data has changed on main MOC. Let the existing worker threads continue as-is,
                    // but create a new workerMOC (which is a copy of main MOC data) for next time a worker is used.
                    // By design we only merge changes 'up' the stack from child-to-parent.
                    DataController.shared.workerMOC = nil
                    DataController.shared.workerMOC = DataController.shared.workerContext()
                }

                // ensure event loop complete, so that child-to-parent moc merge is complete (no cost, and docs are not clear on whether this is required)
                postAsyncToMain {
                    DataController.shared.writeMOC?.performBlock({
                        do {
                            try DataController.shared.writeMOC!.save()
                        } catch {
                            fatalError("Error saving DB to disk: \(error)")
                        }
                    })
                }
            } catch {
                fatalError("Error saving DB: \(error)")
            }
        }
    }
}
