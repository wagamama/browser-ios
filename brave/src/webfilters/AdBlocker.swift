/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class AdblockNetworkDataFileLoader: NetworkDataFileLoader {
    var lang = "en"
}

typealias localeCode = String

class AdBlocker {
    static let singleton = AdBlocker()

    static let prefKey = "braveBlockAdsAndTracking"
    static let prefKeyDefaultValue = true
    static let prefKeyUseRegional = "braveAdblockUseRegional"
    static let prefKeyUseRegionalDefaultValue = true
    static let dataVersion = "2"

    var isNSPrefEnabled = true
    private var fifoCacheOfUrlsChecked = FifoDict()
    private var regionToS3FileName = [localeCode: String]()
    private var networkLoaders = [localeCode: AdblockNetworkDataFileLoader]()
    private lazy var abpFilterLibWrappers: [localeCode: ABPFilterLibWrapper] = { return ["en": ABPFilterLibWrapper()] }()
    private var currentLocaleCode: localeCode = "en"
    private var isRegionalAdblockEnabled: Bool? = nil
    private let wellTestedAdblockRegions = ["ru", "uk", "be", "hi"]

    private init() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AdBlocker.prefsChanged(_:)), name: NSUserDefaultsDidChangeNotification, object: nil)

        updateEnabledState()

        networkLoaders["en"] = getNetworkLoader(forLocale: "en", name: "ABPFilterParserData")

        currentLocaleCode = NSLocale.preferredLanguages()[0]

        let regional = try! NSString(contentsOfFile: NSBundle.mainBundle().pathForResource("adblock-regions", ofType: "txt")!, encoding: NSUTF8StringEncoding) as String
        regional.componentsSeparatedByString("\n").forEach {
            let parts = String($0).componentsSeparatedByString(",")
            if parts.count == 2 {
                regionToS3FileName[parts[0]] = parts[1] // looks like: "cs": "7CCB6921-7FDA"
            }
        }

        // data loading is triggered explicitly at end of startup
        updateRegionalAdblockEnabledState(newRegionsLoadImmediately: false)
    }

    private func getNetworkLoader(forLocale locale: localeCode, name: String) -> AdblockNetworkDataFileLoader {
        let dataUrl = NSURL(string: "https://s3.amazonaws.com/adblock-data/\(AdBlocker.dataVersion)/\(name).dat")!
        let dataFile = "abp-data-\(AdBlocker.dataVersion)-\(locale).dat"
        let loader = AdblockNetworkDataFileLoader(url: dataUrl, file: dataFile, localDirName: "abp-data")
        loader.lang = locale
        loader.delegate = self
        return loader
    }

    func startLoading() {
        print(networkLoaders)
        networkLoaders.forEach { $0.1.loadData() }
    }

    func isRegionalAdblockPossible() -> (hasRegionalFile: Bool, isDefaultSettingOn: Bool) {
        return (hasRegionalFile: currentLocaleCode != "en" && regionToS3FileName[currentLocaleCode] != nil,
                isDefaultSettingOn: isRegionalAdblockEnabled ?? false)
    }

    func updateEnabledState() {
        isNSPrefEnabled = BraveApp.getPrefs()?.boolForKey(AdBlocker.prefKey) ?? AdBlocker.prefKeyDefaultValue
    }

    private func updateRegionalAdblockEnabledState(newRegionsLoadImmediately startLoad: Bool) {
        isRegionalAdblockEnabled = BraveApp.getPrefs()?.boolForKey(AdBlocker.prefKeyUseRegional)
        if isRegionalAdblockEnabled == nil && wellTestedAdblockRegions.contains(currentLocaleCode) {
            // in this case it is only enabled by default for well tested regions (leave set to nil otherwise)
            isRegionalAdblockEnabled = true
        }

        if currentLocaleCode != "en" && (isRegionalAdblockEnabled ?? false) {
            if let file = regionToS3FileName[currentLocaleCode] {
                if networkLoaders[currentLocaleCode] == nil {
                    networkLoaders[currentLocaleCode] = getNetworkLoader(forLocale: currentLocaleCode, name: file)
                    abpFilterLibWrappers[currentLocaleCode] = ABPFilterLibWrapper()
                    if startLoad {
                        networkLoaders[currentLocaleCode]!.loadData()
                    }
                }
            } else {
                NSLog("No custom adblock file for \(currentLocaleCode)")
            }
        }
    }

    @objc func prefsChanged(info: NSNotification) {
        updateEnabledState()

        updateRegionalAdblockEnabledState(newRegionsLoadImmediately: true)
    }

    // We can add whitelisting logic here for puzzling adblock problems
    private func isWhitelistedUrl(url: String?, forMainDocDomain domain: String) -> Bool {
        guard let url = url else { return false }
        // https://github.com/brave/browser-ios/issues/89
        if domain.contains("yahoo") && url.contains("s.yimg.com/zz/combo") {
            return true
        }

        // issue 385
        if domain.contains("m.jpost.com") {
            return true
        }

        return false
    }

    func setForbesCookie() {
        let cookieName = "forbes bypass"
        let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        let existing = storage.cookiesForURL(NSURL(string: "http://www.forbes.com")!)
        if let existing = existing {
            for c in existing {
                if c.name == cookieName {
                    return
                }
            }
        }

        var dict: [String:AnyObject] = [:]
        dict[NSHTTPCookiePath] = "/"
        dict[NSHTTPCookieName] = cookieName
        dict[NSHTTPCookieValue] = "forbes_ab=true; welcomeAd=true; adblock_session=Off; dailyWelcomeCookie=true"
        dict[NSHTTPCookieDomain] = "www.forbes.com"

        let components: NSDateComponents = NSDateComponents()
        components.setValue(1, forComponent: NSCalendarUnit.Month);
        dict[NSHTTPCookieExpires] = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: NSDate(), options: NSCalendarOptions(rawValue: 0))

        let newCookie = NSHTTPCookie(properties: dict)
        if let c = newCookie {
            storage.setCookie(c)
        }
    }

    class RedirectLoopGuard {
        let timeWindow: NSTimeInterval // seconds
        let maxRedirects: Int
        var startTime = NSDate()
        var redirects = 0

        init(timeWindow: NSTimeInterval, maxRedirects: Int) {
            self.timeWindow = timeWindow
            self.maxRedirects = maxRedirects
        }

        func isLooping() -> Bool {
            return redirects > maxRedirects
        }

        func increment() {
            let time = NSDate()
            if time.timeIntervalSinceDate(startTime) > timeWindow {
                startTime = time
                redirects = 0
            }
            redirects += 1
        }
    }

    // In the valid case, 4-5x we see 'forbes/welcome' page in succession (URLProtocol can call more than once for an URL, this is well documented)
    // Set the window as 10x in 10sec, after that stop forwarding the page.
    var forbesRedirectGuard = RedirectLoopGuard(timeWindow: 10.0, maxRedirects: 10)

    func shouldBlock(request: NSURLRequest) -> Bool {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard let url = request.URL else {
            return false
        }

        if url.host?.contains("forbes.com") ?? false {
            setForbesCookie()

            if url.absoluteString?.contains("/forbes/welcome") ?? false {
                forbesRedirectGuard.increment()
                if !forbesRedirectGuard.isLooping() {
                    postAsyncToMain(0.5) {
                        /* For some reason, even with the cookie set, I can't get past the welcome page, until I manually load a page on forbes. So if a do a google search for a subpage on forbes, I can click on that and get to forbes, and from that point on, I no longer see the welcome page. This hack seems to work perfectly for duplicating that behaviour. */
                        BraveApp.getCurrentWebView()?.loadRequest(NSURLRequest(URL: NSURL(string: "http://www.forbes.com")!))
                    }
                }
            }
        }


        if request.mainDocumentURL?.absoluteString?.startsWith(WebServer.sharedInstance.base) ?? false {
            return false
        }

        var mainDocDomain = request.mainDocumentURL?.host ?? ""
        mainDocDomain = stripLocalhostWebServer(mainDocDomain)

        if isWhitelistedUrl(url.absoluteString, forMainDocDomain: mainDocDomain) {
            return false
        }

        if !mainDocDomain.isEmpty && url.absoluteString?.contains(mainDocDomain) ?? false {
            return false // ignore top level doc
        }

        // A cache entry is like: fifoOfCachedUrlChunks[0]["www.microsoft.com_http://some.url"] = true/false for blocking
        let key = "\(mainDocDomain)_" + stripLocalhostWebServer(url.absoluteString)

        if let checkedItem = fifoCacheOfUrlsChecked.getItem(key) {
            if checkedItem === NSNull() {
                return false
            } else {
                return checkedItem as! Bool
            }
        }

        var isBlocked = false
        for (_, adblocker) in abpFilterLibWrappers {
            isBlocked = adblocker.isBlockedConsideringType(url.absoluteString,
                                                           mainDocumentUrl: mainDocDomain,
                                                           acceptHTTPHeader:request.valueForHTTPHeaderField("Accept"))

            if isBlocked {
                break
            }
        }
        fifoCacheOfUrlsChecked.addItem(key, value: isBlocked)

        #if LOG_AD_BLOCK
            if isBlocked {
                print("blocked \(url.absoluteString)")
            }
        #endif

        return isBlocked
    }
}

extension AdBlocker: NetworkDataFileLoaderDelegate {

    func fileLoader(loader: NetworkDataFileLoader, setDataFile data: NSData?) {
        guard let loader = loader as? AdblockNetworkDataFileLoader, adblocker = abpFilterLibWrappers[loader.lang] else {
            assert(false)
            return
        }
        adblocker.setDataFile(data)
    }

    func fileLoaderHasDataFile(loader: NetworkDataFileLoader) -> Bool {
        guard let loader = loader as? AdblockNetworkDataFileLoader, adblocker = abpFilterLibWrappers[loader.lang] else {
            assert(false)
            return false
        }
        return adblocker.hasDataFile()
    }

    func fileLoaderDelegateWillHandleInitialRead(loader: NetworkDataFileLoader) -> Bool {
        return false
    }
}
