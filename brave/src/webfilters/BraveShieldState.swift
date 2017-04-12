import Foundation
import Deferred
import Shared
import Storage

// These override the setting in the prefs
public struct BraveShieldState {

    public static func set(forDomain domain: String, state: (BraveShieldState.Shield, Bool?)) {
        BraveShieldState.setInMemoryforDomain(domain, setState: state)

        if PrivateBrowsing.singleton.isOn {
            return
        }

        let context = DataController.shared.workerContext()
        context.performBlock {
            Domain.setBraveShield(forDomain: domain, state: state, context: context)
        }
    }

    public enum Shield : String {
        case AllOff = "all_off"
        case AdblockAndTp = "adblock_and_tp"
        case HTTPSE = "httpse"
        case SafeBrowsing = "safebrowsing"
        case FpProtection = "fp_protection"
        case NoScript = "noscript"
    }

    private var state = [Shield:Bool]()

    typealias DomainKey = String
    static var perNormalizedDomain = [DomainKey: BraveShieldState]()

    public static func setInMemoryforDomain(domain: String, setState state:(BraveShieldState.Shield, Bool?)) {
        var shields = perNormalizedDomain[domain]
        if shields == nil {
            if state.1 == nil {
                return
            }
            shields = BraveShieldState()
        }

        shields!.setState(state.0, on: state.1)
        perNormalizedDomain[domain] = shields!
    }

    static func getStateForDomain(domain: String) -> BraveShieldState? {
        return perNormalizedDomain[domain]
    }

    public init(jsonStateFromDbRow: String) {
        let js = JSON(string: jsonStateFromDbRow)
        for (k,v) in (js.asDictionary ?? [:]) {
            if let key = Shield(rawValue: k) {
                setState(key, on: v.asBool)
            } else {
                assert(false, "db has bad brave shield state")
            }
        }
    }

    public init() {
    }

    public init(orig: BraveShieldState) {
        self.state = orig.state // Dict value type is copied
    }

    func toJsonString() -> String? {
        var _state = [String: Bool]()
        for (k, v) in state {
            _state[k.rawValue] = v
        }
        return JSON(_state).toString()
    }

    mutating func setState(key: Shield, on: Bool?) {
        if let on = on {
            state[key] = on
        } else {
            state.removeValueForKey(key)
        }
    }

    func isAllOff() -> Bool {
        return state[.AllOff] ?? false
    }

    func isNotSet() -> Bool {
        return state.count < 1
    }

    func isOnAdBlockAndTp() -> Bool? {
        return state[.AdblockAndTp] ?? nil
    }

    func isOnHTTPSE() -> Bool? {
        return state[.HTTPSE] ?? nil
    }

    func isOnSafeBrowsing() -> Bool? {
        return state[.SafeBrowsing] ?? nil
    }

    func isOnScriptBlocking() -> Bool? {
        return state[.NoScript] ?? nil
    }

    func isOnFingerprintProtection() -> Bool? {
        return state[.FpProtection] ?? nil
    }

    mutating func setStateFromPerPageShield(pageState: BraveShieldState?) {
        setState(.NoScript, on: pageState?.isOnScriptBlocking() ?? (BraveApp.getPrefs()?.boolForKey(kPrefKeyNoScriptOn) ?? false))
        setState(.AdblockAndTp, on: pageState?.isOnAdBlockAndTp() ?? AdBlocker.singleton.isNSPrefEnabled)
        setState(.SafeBrowsing, on: pageState?.isOnSafeBrowsing() ?? SafeBrowsing.singleton.isNSPrefEnabled)
        setState(.HTTPSE, on: pageState?.isOnHTTPSE() ?? HttpsEverywhere.singleton.isNSPrefEnabled)
        setState(.FpProtection, on: pageState?.isOnFingerprintProtection() ?? (BraveApp.getPrefs()?.boolForKey(kPrefKeyFingerprintProtection) ?? false))
    }
}

public class BraveGlobalShieldStats {
    static let singleton = BraveGlobalShieldStats()
    static let DidUpdateNotification = "BraveGlobalShieldStatsDidUpdate"
    
    private let prefs = NSUserDefaults.standardUserDefaults()
    
    var adblock: Int = 0 {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(BraveGlobalShieldStats.DidUpdateNotification, object: nil)
        }
    }

    var trackingProtection: Int = 0 {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(BraveGlobalShieldStats.DidUpdateNotification, object: nil)
        }
    }

    var httpse: Int = 0 {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(BraveGlobalShieldStats.DidUpdateNotification, object: nil)
        }
    }
    
    var safeBrowsing: Int = 0 {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(BraveGlobalShieldStats.DidUpdateNotification, object: nil)
        }
    }
    
    var fpProtection: Int = 0 {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(BraveGlobalShieldStats.DidUpdateNotification, object: nil)
        }
    }
    

    enum Shield: String {
        case Adblock = "adblock"
        case TrackingProtection = "tracking_protection"
        case HTTPSE = "httpse"
        case SafeBrowsing = "safebrowsing"
        case FpProtection = "fp_protection"
    }
    
    private init() {
        adblock += prefs.integerForKey(Shield.Adblock.rawValue)
        trackingProtection += prefs.integerForKey(Shield.TrackingProtection.rawValue)
        httpse += prefs.integerForKey(Shield.HTTPSE.rawValue)
        safeBrowsing += prefs.integerForKey(Shield.SafeBrowsing.rawValue)
        fpProtection += prefs.integerForKey(Shield.FpProtection.rawValue)
    }

    var bgSaveTask: UIBackgroundTaskIdentifier?

    public func save() {
        if let t = bgSaveTask where t != UIBackgroundTaskInvalid {
            return
        }
        
        bgSaveTask = UIApplication.sharedApplication().beginBackgroundTaskWithName("brave-global-stats-save", expirationHandler: {
            if let task = self.bgSaveTask {
                UIApplication.sharedApplication().endBackgroundTask(task)
            }
            self.bgSaveTask = UIBackgroundTaskInvalid
        })
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            self.prefs.setInteger(self.adblock, forKey: Shield.Adblock.rawValue)
            self.prefs.setInteger(self.trackingProtection, forKey: Shield.TrackingProtection.rawValue)
            self.prefs.setInteger(self.httpse, forKey: Shield.HTTPSE.rawValue)
            self.prefs.setInteger(self.safeBrowsing, forKey: Shield.SafeBrowsing.rawValue)
            self.prefs.setInteger(self.fpProtection, forKey: Shield.FpProtection.rawValue)
            self.prefs.synchronize()

            if let task = self.bgSaveTask {
                UIApplication.sharedApplication().endBackgroundTask(task)
            }
            self.bgSaveTask = UIBackgroundTaskInvalid
        }
    }
}
