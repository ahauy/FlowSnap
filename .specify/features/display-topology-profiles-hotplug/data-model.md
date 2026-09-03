# Data Model: Display Topology Profiles & Hot-Plug Rebalancer (US-DISP-016)

## 1. Domain Entities & Value Objects

### 1.1 `TopologyFingerprint`

```swift
public struct TopologyFingerprint: RawRepresentable, Codable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: String
    public let displayCount: Int
    public let displayDescriptions: [String]

    public init(rawValue: String, displayCount: Int, displayDescriptions: [String]) {
        self.rawValue = rawValue
        self.displayCount = displayCount
        self.displayDescriptions = displayDescriptions
    }

    public init?(rawValue: String) {
        self.rawValue = rawValue
        self.displayCount = 0
        self.displayDescriptions = []
    }

    public var description: String {
        "\(rawValue.prefix(12))... (\(displayCount) displays)"
    }
}
```

### 1.2 `DisplayTopologyProfile`

```swift
public struct DisplayTopologyProfile: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let fingerprint: TopologyFingerprint
    public var name: String
    public let capturedAt: Date
    public var windowPlacements: [String: WindowPlacement] // bundleID -> placement
    public var displayIndexMap: [String: Int]              // bundleID -> displayIndex

    public init(
        id: UUID = UUID(),
        fingerprint: TopologyFingerprint,
        name: String? = nil,
        capturedAt: Date = Date(),
        windowPlacements: [String: WindowPlacement] = [:],
        displayIndexMap: [String: Int] = [:]
    ) {
        self.id = id
        self.fingerprint = fingerprint
        self.name = name ?? "Setup with \(fingerprint.displayCount) displays"
        self.capturedAt = capturedAt
        self.windowPlacements = windowPlacements
        self.displayIndexMap = displayIndexMap
    }
}
```

### 1.3 `FrameClampingHelper`

```swift
public enum FrameClampingHelper: Sendable {
    public static let defaultTitleBarSafeHeight: CGFloat = 36.0

    /// Pure geometric function clamping `windowFrame` safely inside `visibleFrame`.
    public static func clamp(
        windowFrame: CGRect,
        inside visibleFrame: CGRect,
        titleBarHeight: CGFloat = defaultTitleBarSafeHeight
    ) -> CGRect {
        var width = windowFrame.width
        var height = windowFrame.height

        // Downscale proportionally if larger than visible bounds
        if width > visibleFrame.width || height > visibleFrame.height {
            let scaleX = visibleFrame.width / width
            let scaleY = visibleFrame.height / height
            let scale = min(scaleX, scaleY)
            width = max(200, width * scale)
            height = max(200, height * scale)
        }

        // Clamp origin X
        var originX = max(visibleFrame.minX, windowFrame.minX)
        if originX + width > visibleFrame.maxX {
            originX = visibleFrame.maxX - width
        }

        // Clamp origin Y (guaranteeing title bar below top edge)
        var originY = max(visibleFrame.minY, windowFrame.minY)
        if originY + height > visibleFrame.maxY {
            originY = visibleFrame.maxY - height
        }

        return CGRect(x: originX, y: originY, width: width, height: height)
    }
}
```

## 2. Storage & Persistence

Profiles are stored either in `UserDefaults` (`PreferencesStore`) under key `"com.flowsnap.topologyProfiles"` as serialized JSON data, or in `~/Library/Application Support/FlowSnap/topology_profiles.json`.
