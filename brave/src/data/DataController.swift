//
//  DataController.swift
//  Client
//
//  Created by James Mudgett on 1/24/17.
//  Copyright © 2017 Brave. All rights reserved.
//

import UIKit
import CoreData

let CoreDataWriteQueue: dispatch_queue_t = dispatch_queue_create("BraveDataWriteQueue", DISPATCH_QUEUE_SERIAL)

class DataController: NSObject {
    static let shared = DataController()
    
    private var _managedObjectContext: NSManagedObjectContext? = nil
    private var managedObjectContext: NSManagedObjectContext? {
        get {
            if NSThread.isMainThread() {
                return mainThreadContext()
            }
            else {
                return writeContext()
            }
        }
        set(value) {
            _managedObjectContext = value
        }
    }
    private var writeObjectContext: NSManagedObjectContext?

    static var moc: NSManagedObjectContext {
        get {
            if DataController.shared.managedObjectContext == nil {
                fatalError("DataController: Access to .moc contained nil value. A db connection has not yet been instantiated.")
            }
            
            return DataController.shared.managedObjectContext!
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
    }
    
    // Create new from "ManagedObject"
    static func new(model: String) -> NSManagedObject {
        return NSEntityDescription.insertNewObjectForEntityForName(model, inManagedObjectContext: DataController.moc)
    }
    
    static func saveContext() {
        guard let managedObjectContext: NSManagedObjectContext = DataController.shared.managedObjectContext else {
            return
        }
        
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            }
            catch {
                fatalError("Error saving DB: \(error)")
            }
        }
    }
    
    // DataController.write {...} closure execute data updates before context save.
    static func write(closure: ()->Void) {
        dispatch_async(CoreDataWriteQueue) {
            closure()
            DataController.saveContext()
        }
    }

    // Ensure not to pass NSManagedObjects between closure and completionOnMain
    static func asyncAccess(closure: ()->Void, completionOnMain: (() -> Void)? = nil) {
        dispatch_async(CoreDataWriteQueue) {
            closure()
            postAsyncToMain {
                completionOnMain?()
            }
        }
    }

    private func mainThreadContext() -> NSManagedObjectContext {
        if _managedObjectContext != nil {
            return _managedObjectContext!
        }

        // do not set a persistent store for main thread context.
        // The parent of the main context is the writeContext, and when the main context is saved
        // the mainThreadContextDidSave

        managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext?.undoManager = nil
        managedObjectContext?.mergePolicy = NSErrorMergePolicy
        managedObjectContext?.parentContext = writeContext()

        // when main context is saved, we need to propagate the changes to our insertion thread's context
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(mainThreadContextDidSaveInMem(_:)), name: NSManagedObjectContextDidSaveNotification, object: managedObjectContext!)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(bgContextDidSaveToDisk(_:)), name: NSManagedObjectContextDidSaveNotification, object: writeContext())

        return managedObjectContext!
    }

    @objc private func bgContextDidSaveToDisk(notification: NSNotification) {
        assert(!NSThread.isMainThread())
        postAsyncToMain {
            self.managedObjectContext?.mergeChangesFromContextDidSaveNotification(notification)
        }
    }

    @objc private func mainThreadContextDidSaveInMem(notification: NSNotification) {
        assert(NSThread.isMainThread())
        dispatch_async(CoreDataWriteQueue, {
            self.writeObjectContext?.mergeChangesFromContextDidSaveNotification(notification)
            DataController.saveContext()
        })
    }
    
    private func writeContext() -> NSManagedObjectContext {
        // This will only ever be called from a dispatch thread.
        if writeObjectContext == nil {
            writeObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            writeObjectContext?.persistentStoreCoordinator = persistentStoreCoordinator
            writeObjectContext?.undoManager = nil
            writeObjectContext?.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        }
        return writeObjectContext!
    }
    
    // To be called only from the main thread.
    @objc private func mergeSaveNotification(notification: NSNotification) {
        managedObjectContext?.mergeChangesFromContextDidSaveNotification(notification)
    }
}
