/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger
import Deferred

private let log = Logger.browserLogger

private let URLBeforePathRegex = try! NSRegularExpression(pattern: "^https?://([^/]+)/", options: [])

// TODO: Swift currently requires that classes extending generic classes must also be generic.
// This is a workaround until that requirement is fixed.
typealias SearchLoader = _SearchLoader<AnyObject, AnyObject>

/**
 * Shared data source for the SearchViewController and the URLBar domain completion.
 * Since both of these use the same SQL query, we can perform the query once and dispatch the results.
 */
class _SearchLoader<UnusedA, UnusedB>: Loader<[Site], SearchViewController> {
    private let profile: Profile
    private let urlBar: URLBarView
    private var inProgress: Cancellable? = nil

    init(profile: Profile, urlBar: URLBarView) {
        self.profile = profile
        self.urlBar = urlBar
        super.init()
    }

    private lazy var topDomains: [String] = {
        let filePath = NSBundle.mainBundle().pathForResource("topdomains", ofType: "txt")
        return try! String(contentsOfFile: filePath!).componentsSeparatedByString("\n")
    }()

    // TODO: This is not a proper frecency query, it just gets sites from the past week
    private func getSitesByFrecency(containing containing: String? = nil) -> Deferred<[Site]> {
        let result = Deferred<[Site]>()

        let context = DataController.shared.workerContext()
        context.performBlock {
            
            let history: [WebsitePresentable] = History.frecencyQuery(context, containing: containing)
            let bookmarks: [WebsitePresentable] = Bookmark.frecencyQuery(context, containing: containing)
            
            // History must come before bookmarks, since later items replace existing ones, and want bookmarks to replace history entries
            let uniqueSites = Set<Site>( (history + bookmarks).map { Site(url: $0.url ?? "", title: $0.title ?? "", bookmarked: $0 is Bookmark) } )
            result.fill(Array(uniqueSites))
        }
        return result
    }

    var query: String = "" {
        didSet {
            if query.isEmpty {
                self.load([Site]())
                return
            }

            if let inProgress = inProgress {
                inProgress.cancel()
                self.inProgress = nil
            }

            let deferred = getSitesByFrecency(containing: query)
            inProgress = deferred as? Cancellable

            deferred.uponQueue(dispatch_get_main_queue()) { result in
                self.inProgress = nil

                // First, see if the query matches any URLs from the user's search history.
                self.load(result)
                for site in result {
                    if let completion = self.completionForURL(site.url) {
                        self.urlBar.setAutocompleteSuggestion(completion)
                        return
                    }
                }

                // If there are no search history matches, try matching one of the Alexa top domains.
                for domain in self.topDomains {
                    if let completion = self.completionForDomain(domain) {
                        self.urlBar.setAutocompleteSuggestion(completion)
                        return
                    }
                }
            }

        }
    }

    private func completionForURL(url: String) -> String? {
        // Extract the pre-path substring from the URL. This should be more efficient than parsing via
        // NSURL since we need to only look at the beginning of the string.
        // Note that we won't match non-HTTP(S) URLs.
        guard let match = URLBeforePathRegex.firstMatchInString(url, options: NSMatchingOptions(), range: NSRange(location: 0, length: url.characters.count)) else {
            return nil
        }

        // If the pre-path component (including the scheme) starts with the query, just use it as is.
        let prePathURL = (url as NSString).substringWithRange(match.rangeAtIndex(0))
        if prePathURL.startsWith(query) {
            return prePathURL
        }

        // Otherwise, find and use any matching domain.
        // To simplify the search, prepend a ".", and search the string for ".query".
        // For example, for http://en.m.wikipedia.org, domainWithDotPrefix will be ".en.m.wikipedia.org".
        // This allows us to use the "." as a separator, so we can match "en", "m", "wikipedia", and "org",
        let domain = (url as NSString).substringWithRange(match.rangeAtIndex(1))
        return completionForDomain(domain)
    }

    private func completionForDomain(domain: String) -> String? {
        let domainWithDotPrefix: String = ".\(domain)"
        if let range = domainWithDotPrefix.rangeOfString(".\(query)", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) {
            // We don't actually want to match the top-level domain ("com", "org", etc.) by itself, so
            // so make sure the result includes at least one ".".
            let matchedDomain: String = domainWithDotPrefix.substringFromIndex(range.startIndex.advancedBy(1))
            if matchedDomain.contains(".") {
                return matchedDomain + "/"
            }
        }

        return nil
    }
}
