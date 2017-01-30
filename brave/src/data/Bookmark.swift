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
    
    @NSManaged var id: NSNumber?
    @NSManaged var parentId: String?
    @NSManaged var title: String?
    @NSManaged var customTitle: String?
    @NSManaged var url: String?
    @NSManaged var visits: NSNumber?
    @NSManaged var lastVisited: NSDate?
    @NSManaged var order: NSNumber?
    @NSManaged var tags: [String]?
    @NSManaged var favIcon: FaviconMO?
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        lastVisited = NSDate()
    }
    
}
