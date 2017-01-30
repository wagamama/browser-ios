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
    
    @NSManaged var domain: String?
    @NSManaged var visits: NSNumber?
    @NSManaged var topsite: NSNumber?
    @NSManaged var allOff: NSNumber?
    @NSManaged var adblockAndTp: NSNumber?
    @NSManaged var httpse: NSNumber?
    @NSManaged var noScript: NSNumber?
    @NSManaged var fpProtection: NSNumber?
    @NSManaged var safeBrowsing: NSNumber?
    @NSManaged var favicon: FaviconMO?
    @NSManaged var history: NSSet?
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
    }
    
}
