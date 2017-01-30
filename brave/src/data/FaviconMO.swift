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

class FaviconMO: NSManagedObject {
    
    @NSManaged var url: String?
    @NSManaged var width: NSNumber?
    @NSManaged var height: NSNumber?
    @NSManaged var bookmark: Bookmark?
    @NSManaged var domain: Domain?
    @NSManaged var tab: Tab?
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
    }
    
}
