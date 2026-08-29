# Data Model: Top-Edge Snap Layout Picker (US-SNAP-007)

## 1. Domain Entities & Value Types

```swift
import CoreGraphics
import Foundation

public enum LayoutTemplateKind: String, Sendable, CaseIterable, Identifiable {
    case twoColumnEqual = "2-Column (50/50)"
    case twoColumnAsymmetric = "2-Column (70/30)"
    case threeColumnEqual = "3-Column (1/3)"
    case fourQuarters = "4-Quarters (2x2)"

    public var id: String { rawValue }
}

public struct LayoutSlot: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let target: SnapTarget
    public let normalizedRect: CGRect // (x, y, width, height) in 0.0...1.0

    public init(id: String, title: String, target: SnapTarget, normalizedRect: CGRect) {
        self.id = id
        self.title = title
        self.target = target
        self.normalizedRect = normalizedRect
    }
}

public struct LayoutTemplate: Identifiable, Sendable, Equatable {
    public let id: String
    public let kind: LayoutTemplateKind
    public let slots: [LayoutSlot]

    public init(kind: LayoutTemplateKind, slots: [LayoutSlot]) {
        self.id = kind.rawValue
        self.kind = kind
        self.slots = slots
    }

    public static let standardTemplates: [LayoutTemplate] = [
        LayoutTemplate(
            kind: .twoColumnEqual,
            slots: [
                LayoutSlot(id: "twoCol-left", title: "Left", target: .leftHalf, normalizedRect: CGRect(x: 0, y: 0, width: 0.5, height: 1.0)),
                LayoutSlot(id: "twoCol-right", title: "Right", target: .rightHalf, normalizedRect: CGRect(x: 0.5, y: 0, width: 0.5, height: 1.0))
            ]
        ),
        LayoutTemplate(
            kind: .twoColumnAsymmetric,
            slots: [
                LayoutSlot(id: "twoColAsym-left", title: "Left 70%", target: .leftTwoThirds, normalizedRect: CGRect(x: 0, y: 0, width: 0.7, height: 1.0)),
                LayoutSlot(id: "twoColAsym-right", title: "Right 30%", target: .rightOneThird, normalizedRect: CGRect(x: 0.7, y: 0, width: 0.3, height: 1.0))
            ]
        ),
        LayoutTemplate(
            kind: .threeColumnEqual,
            slots: [
                LayoutSlot(id: "threeCol-left", title: "Left 1/3", target: .leftThird, normalizedRect: CGRect(x: 0, y: 0, width: 0.3333, height: 1.0)),
                LayoutSlot(id: "threeCol-center", title: "Center 1/3", target: .centerThird, normalizedRect: CGRect(x: 0.3333, y: 0, width: 0.3334, height: 1.0)),
                LayoutSlot(id: "threeCol-right", title: "Right 1/3", target: .rightThird, normalizedRect: CGRect(x: 0.6667, y: 0, width: 0.3333, height: 1.0))
            ]
        ),
        LayoutTemplate(
            kind: .fourQuarters,
            slots: [
                LayoutSlot(id: "fourQ-tl", title: "Top-Left", target: .topLeft, normalizedRect: CGRect(x: 0, y: 0, width: 0.5, height: 0.5)),
                LayoutSlot(id: "fourQ-tr", title: "Top-Right", target: .topRight, normalizedRect: CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5)),
                LayoutSlot(id: "fourQ-bl", title: "Bottom-Left", target: .bottomLeft, normalizedRect: CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5)),
                LayoutSlot(id: "fourQ-br", title: "Bottom-Right", target: .bottomRight, normalizedRect: CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5))
            ]
        )
    ]
}
```
