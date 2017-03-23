//
//  SyncRoot.swift
//
//  Created by Joel Reis on 3/23/17
//  Copyright (c) . All rights reserved.
//

import Foundation
import Shared

public final class SyncRoot {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private struct SerializationKeys {
        static let objectId = "objectId"
        static let deviceId = "deviceId"
        static let action = "action"
        static let bookmark = "bookmark"
        static let objectData = "objectData"
    }
    
    // MARK: Properties
    public var objectId: [Int]?
    public var deviceId: [Int]?
    public var action: Int?
    public var bookmark: SyncBookmark?
    public var objectData: String?
    
//    lazy var objectIdDisplay: String? = {
//        return self.objectId?.map({ $0.description }).joinWithSeparator(",")
//    }()
    
    public convenience init() {
        self.init(json: nil)
    }
    
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
    public required init(json: JSON?) {
        // objectId can come in two different formats
        if let items = json?[SerializationKeys.objectId].asArray { objectId = items.map { $0.asInt ?? 0 } }
        if let items = json?[SerializationKeys.deviceId].asArray { deviceId = items.map { $0.asInt ?? 0 } }
        action = json?[SerializationKeys.action].asInt
        bookmark = SyncBookmark(json: json?[SerializationKeys.bookmark])
        objectData = json?[SerializationKeys.objectData].asString
    }
    
    /// Generates description of the object in the form of a NSDictionary.
    ///
    /// - returns: A Key value pair containing all valid values in the object.
    public func dictionaryRepresentation() -> [String: AnyObject] {
        var dictionary: [String: AnyObject] = [:]
        // Override to use string value instead of array, to be uniform to CD
        if let value = objectId { dictionary[SerializationKeys.objectId] = value }
        if let value = deviceId { dictionary[SerializationKeys.deviceId] = value }
        if let value = action { dictionary[SerializationKeys.action] = value }
        if let value = bookmark { dictionary[SerializationKeys.bookmark] = value.dictionaryRepresentation() }
        if let value = objectData { dictionary[SerializationKeys.objectData] = value }
        return dictionary
    }
}

extension SyncRoot {
    static func syncObject(rootJSON: [JSON]) -> [SyncRoot]? {
        return rootJSON.map { SyncRoot(json: $0) }
    }
    
    static func syncObject(data: [[String: AnyObject]]) -> [SyncRoot]? {
        return data.map { SyncRoot(object: $0) }
    }
}
