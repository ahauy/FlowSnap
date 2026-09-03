import CoreFoundation
import Foundation

/// Infrastructure implementation of `StageManagerDetecting` reading the preference
/// domain `com.apple.WindowManager` key `GloballyEnabled`.
///
/// Traces to: US-WORK-017, BR-SMA-001, ASM-SMA-003.
public final class StageManagerDetector: StageManagerDetecting, @unchecked Sendable {
    private let suiteName: String
    private let key: String
    private let userDefaults: UserDefaults?

    public init(
        suiteName: String = "com.apple.WindowManager",
        key: String = "GloballyEnabled",
        userDefaults: UserDefaults? = nil
    ) {
        self.suiteName = suiteName
        self.key = key
        self.userDefaults = userDefaults ?? UserDefaults(suiteName: suiteName)
    }

    public var isStageManagerEnabled: Bool {
        // Read directly from CFPreferences to bypass cached daemon values
        if let val = CFPreferencesCopyAppValue(key as CFString, suiteName as CFString) {
            if let boolVal = val as? Bool {
                return boolVal
            }
            if let numVal = val as? NSNumber {
                return numVal.boolValue
            }
        }
        return userDefaults?.bool(forKey: key) ?? false
    }
}
