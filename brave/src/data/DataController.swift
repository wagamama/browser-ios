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
    static let singleton = DataController()
    
    private var _managedObjectContext: NSManagedObjectContext? = nil
    var managedObjectContext: NSManagedObjectContext? {
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
    var writeObjectContext: NSManagedObjectContext?
    var writeSemaphore: dispatch_semaphore_t?
    
    static var moc: NSManagedObjectContext {
        get {
            return DataController.singleton.managedObjectContext!
        }
    }
    
    private var managedObjectModel: NSManagedObjectModel!
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    
    private override init() {
        super.init()
        
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
    
    // Writes could still be executed on main thread, but recommended to use DataController.write {...}
    static func saveContext() {
        guard let managedObjectContext: NSManagedObjectContext = DataController.singleton.managedObjectContext else {
            return
        }
        
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            }
            catch {
                fatalError("Error migrating store: \(error)")
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
    
    func mainThreadContext() -> NSManagedObjectContext {
        if _managedObjectContext != nil {
            return _managedObjectContext!
        }
        
        if let coordinator: NSPersistentStoreCoordinator = self.persistentStoreCoordinator {
            managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            managedObjectContext?.persistentStoreCoordinator = coordinator
            managedObjectContext?.undoManager = nil
            managedObjectContext?.mergePolicy = NSErrorMergePolicy
            
            // when main context is saved, we need to propagate the changes to our insertion thread's context
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(mainThreadContextDidSave(_:)), name: NSManagedObjectContextDidSaveNotification, object: managedObjectContext!)
        }
        
        return managedObjectContext!
    }
    
    func mainThreadContextDidSave(notification: NSNotification) {
        // This notification will always be received on the main thread.
        // Need to tell insertion context to merge in changes that occurred on the main thread's context.
        if writeObjectContext != nil {
            dispatch_async(CoreDataWriteQueue, {
                self.writeObjectContext?.mergeChangesFromContextDidSaveNotification(notification)
            })
        }
    }
    
    func writeContext() -> NSManagedObjectContext {
        // This will only ever be called from a dispatch thread.
        if writeObjectContext == nil {
            writeObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            writeObjectContext?.persistentStoreCoordinator = persistentStoreCoordinator
            writeObjectContext?.undoManager = nil
            writeObjectContext?.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(writeContextDidSave(_:)), name: NSManagedObjectContextDidSaveNotification, object: writeObjectContext!)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(writeContextWillSave(_:)), name: NSManagedObjectContextWillSaveNotification, object: writeObjectContext!)
            
        }
        return writeObjectContext!
    }
    
    // To be called only from the main thread.
    func mergeSaveNotification(notification: NSNotification) {
        managedObjectContext?.mergeChangesFromContextDidSaveNotification(notification)
    }
    
    func waitForSaveToBegin() {
        // To be called only from the main thread.
        if writeSemaphore != nil {
            dispatch_semaphore_wait(writeSemaphore!, DISPATCH_TIME_FOREVER)
            writeSemaphore = nil
        }
    }
    
    func writeContextWillSave(notification: NSNotification) {
        let context: NSManagedObjectContext = notification.object as! NSManagedObjectContext
        if context.deletedObjects.count > 0 {
            if writeSemaphore == nil {
                writeSemaphore = dispatch_semaphore_create(0)
            }
            
            self.performSelectorOnMainThread(#selector(waitForSaveToBegin), withObject: nil, waitUntilDone: false)
        }
    }
    
    func writeContextDidSave(notification: NSNotification) {
        // This notification will always be received on a dispatch thread.
        // Need to tell main thread's context to merge in changes that occurred on the background thread's context.
        
        // If we are resetting CoreData, managedObjectContext will be nil, and we'll be blocking on main thread, so don't try to synchronously merge.
        
        if writeSemaphore != nil {
            dispatch_semaphore_signal(writeSemaphore!)
        }
        
        if managedObjectContext != nil {
            self.performSelectorOnMainThread(#selector(mergeSaveNotification(_:)), withObject: notification, waitUntilDone: true)
        }
    }
}
