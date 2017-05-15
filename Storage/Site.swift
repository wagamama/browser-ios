/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

public protocol Identifiable: Equatable {
    var id: Int? { get set }
}

public func ==<T>(lhs: T, rhs: T) -> Bool where T: Identifiable {
    return lhs.id == rhs.id
}

public enum IconType: Int {
    public func isPreferredTo (_ other: IconType) -> Bool {
        return rank > other.rank
    }

    fileprivate var rank: Int {
        switch self {
        case .appleIconPrecomposed:
            return 5
        case .appleIcon:
            return 4
        case .icon:
            return 3
        case .local:
            return 2
        case .guess:
            return 1
        case .noneFound:
            return 0
        }
    }

    case icon = 0
    case appleIcon = 1
    case appleIconPrecomposed = 2
    case guess = 3
    case local = 4
    case noneFound = 5
}

open class Favicon: NSObject, Identifiable, NSCoding {
    open var id: Int? = nil

    open let url: String
    open let date: Date
    open var width: Int?
    open var height: Int?
    open let type: IconType

    public init(url: String, date: Date = Date(), type: IconType) {
        self.url = url
        self.date = date
        self.type = type
    }
    
    required public init?(coder: NSCoder) {
        self.id = Int(coder.decodeInt64(forKey: "id"))
        self.url = coder.decodeObject(forKey: "url") as? String ?? ""
        self.date = coder.decodeObject(forKey: "date") as? Date ?? Date()
        self.width = Int(coder.decodeInt64(forKey: "width"))
        self.height = Int(coder.decodeInt64(forKey: "height"))
        self.type = IconType(rawValue: Int(coder.decodeInt64(forKey: "type"))) ?? .noneFound
    }
    
    open func encode(with coder: NSCoder) {
        if let id = id {
            coder.encode(Int64(id), forKey: "id")
        }
        coder.encode(url, forKey: "url")
        coder.encode(date, forKey: "date")
        if let width = width {
            coder.encode(Int64(width), forKey: "width")
        }
        
        if let height = height {
            coder.encode(Int64(height), forKey: "height")
        }
        
        coder.encode(Int64(type.rawValue), forKey: "type")
    }
}

// TODO: Site shouldn't have all of these optional decorators. Include those in the
// cursor results, perhaps as a tuple.
open class Site: Identifiable, Hashable {
    open var id: Int? = nil
    var guid: String? = nil

    open var tileURL: URL {
        return URL(string: url)?.domainURL() ?? URL(string: "about:blank")!
    }

    open let url: String
    open let title: String
     // Sites may have multiple favicons. We'll return the largest.
    open var icon: Favicon?
    open var latestVisit: Visit?
    open let bookmarked: Bool?

    public convenience init(url: String, title: String) {
        self.init(url: url, title: title, bookmarked: false)
    }

    public init(url: String, title: String, bookmarked: Bool?) {
        self.url = url
        self.title = title
        self.bookmarked = bookmarked
    }
    
    // This hash is a bit limited in scope, but contains enough data to make a unique distinction.
    //  If modified, verify usage elsewhere, as places may rely on the hash only including these two elements.
    open var hashValue: Int {
        return 31 &* self.url.hash &+ self.title.hash
    }
}
