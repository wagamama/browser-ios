//
//  SyncBookmark.swift
//
//  Created by Joel Reis on 3/23/17
//  Copyright (c) . All rights reserved.
//

import Foundation
import Shared

public final class SyncBookmark {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private struct SerializationKeys {
        static let isFolder = "isFolder"
        static let parentFolderObjectId = "parentFolderObjectId"
        static let site = "site"
    }
    
    // MARK: Properties
    public var isFolder: Bool? = false
    public var parentFolderObjectId: [Any]?
    public var site: SyncSite?
    
    // MARK: SwiftyJSON Initializers
    /// Initiates the instance based on the object.
    ///
    /// - parameter object: The object of either Dictionary or Array kind that was passed.
    /// - returns: An initialized instance of the class.
    public convenience init(object: [String: AnyObject]) {
        self.init(json: JSON(object))
    }
    
    /// Initiates the instance based on the JSON that was passed.
    ///
    /// - parameter json: JSON object from SwiftyJSON.
    public required init(json: JSON) {
        isFolder = json[SerializationKeys.isFolder].asBool
//        if let items = json[SerializationKeys.parentFolderObjectId].asArray { parentFolderObjectId = items.map { $0.whateverType } }
        site = SyncSite(json: json[SerializationKeys.site])
    }
    
    /// Generates description of the object in the form of a NSDictionary.
    ///
    /// - returns: A Key value pair containing all valid values in the object.
    public func dictionaryRepresentation() -> [String: AnyObject] {
        var dictionary: [String: AnyObject] = [:]
        dictionary[SerializationKeys.isFolder] = isFolder
//        if let value = parentFolderObjectId { dictionary[SerializationKeys.parentFolderObjectId] = value }
        if let value = site { dictionary[SerializationKeys.site] = value.dictionaryRepresentation() }
        return dictionary
    }
    
}
