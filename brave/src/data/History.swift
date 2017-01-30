//
//  History.swift
//  Client
//
//  Created by James Mudgett on 1/29/17.
//  Copyright © 2017 Brave. All rights reserved.
//

import UIKit
import CoreData
import Foundation

class History: NSManagedObject {

    @NSManaged var title: String?
    @NSManaged var url: String?
    @NSManaged var visitedOn: NSDate?
    @NSManaged var domain: Domain?
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        visitedOn = NSDate()
    }
    
}
