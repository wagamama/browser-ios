//
//  Tab.swift
//  Client
//
//  Created by James Mudgett on 1/30/17.
//  Copyright © 2017 Brave. All rights reserved.
//

import UIKit
import CoreData
import Foundation

class Tab: NSManagedObject {
    
    @NSManaged var title: String?
    @NSManaged var url: String?
    @NSManaged var order: NSNumber?
    @NSManaged var closedOn: NSDate?
    @NSManaged var privacy: NSNumber?
    @NSManaged var favicon: FaviconMO?
    @NSManaged var history: NSSet?
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
    }
    
}
