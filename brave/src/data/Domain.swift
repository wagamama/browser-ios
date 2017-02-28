/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import UIKit
import CoreData
import Foundation

class Domain: NSManagedObject {
    
    @NSManaged var url: String?
    @NSManaged var visits: Int32
    @NSManaged var topsite: Bool // not currently used. Should be used once proper frecency code is in.
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
        let domainUrl = url.normalizedHost() 

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

    class func setBraveShield(forDomain domainString: String, state: (BraveShieldState.Shield, Bool?), context: NSManagedObjectContext) {
        guard let url = NSURL(string: domainString) else { return }
        let domain = Domain.getOrCreateForUrl(url, context: context)
        let shield = state.0
        switch (shield) {
            case .AllOff: domain?.shield_allOff = state.1
            case .AdblockAndTp: domain?.shield_adblockAndTp = state.1
            case .HTTPSE: domain?.shield_httpse = state.1
            case .SafeBrowsing: domain?.shield_safeBrowsing = state.1
            case .FpProtection: domain?.shield_fpProtection = state.1
            case .NoScript: domain?.shield_noScript = state.1
        }
        DataController.saveContext(context)
    }

    class func loadShieldsIntoMemory(completionOnMain: ()->()) {
        BraveShieldState.perNormalizedDomain.removeAll()

        let context = DataController.shared.workerContext()
        context.performBlock {
            let fetchRequest = NSFetchRequest()
            fetchRequest.entity = Domain.entity(context)
            do {
                let results = try context.executeFetchRequest(fetchRequest)
                for obj in results {
                    let domain = obj as! Domain
                    guard let url = domain.url else { continue }

                    print(url)
                    if let shield = domain.shield_allOff {
                        BraveShieldState.setInMemoryforDomain(url, setState: (.AllOff, shield.boolValue))
                    }
                    if let shield = domain.shield_adblockAndTp {
                        BraveShieldState.setInMemoryforDomain(url, setState: (.AdblockAndTp, shield.boolValue))
                    }
                    if let shield = domain.shield_safeBrowsing {
                        BraveShieldState.setInMemoryforDomain(url, setState: (.SafeBrowsing, shield.boolValue))
                    }
                    if let shield = domain.shield_httpse {
                        BraveShieldState.setInMemoryforDomain(url, setState: (.HTTPSE, shield.boolValue))
                    }
                    if let shield = domain.shield_fpProtection {
                        BraveShieldState.setInMemoryforDomain(url, setState: (.FpProtection, shield.boolValue))
                    }
                    if let shield = domain.shield_noScript {
                        BraveShieldState.setInMemoryforDomain(url, setState: (.NoScript, shield.boolValue))
                    }
                }
            } catch {
                let fetchError = error as NSError
                print(fetchError)
            }

            postAsyncToMain {
                completionOnMain()
            }
        }
    }

    class func deleteNonBookmarked(completionOnMain: ()->()) {
        let context = DataController.shared.workerContext()
        context.performBlock {
            let fetchRequest = NSFetchRequest()
            fetchRequest.entity = Domain.entity(context)
            fetchRequest.predicate = NSPredicate(format: "bookmarks.@count == 0")
            do {
                let results = try context.executeFetchRequest(fetchRequest)
                for obj in results {
                    // Cascading delete on favicon, it will also get deleted
                    context.deleteObject(obj as! NSManagedObject)
                }
            } catch {
                let fetchError = error as NSError
                print(fetchError)
            }

            DataController.saveContext(context)
            postAsyncToMain {
                completionOnMain()
            }
        }
    }
}
