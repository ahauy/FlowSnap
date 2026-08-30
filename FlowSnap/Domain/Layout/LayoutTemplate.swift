import CoreGraphics
import Foundation

/// Semantic kind of layout template in the Top-Edge Layout Picker.
public struct LayoutTemplateKind: Sendable, Equatable, Hashable, Identifiable, RawRepresentable {
    public let rawValue: String
    public var id: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let twoColumnEqual = LayoutTemplateKind(rawValue: "2-Column (50/50)")
    public static let twoColumnAsymmetric = LayoutTemplateKind(rawValue: "2-Column (70/30)")
    public static let threeColumnEqual = LayoutTemplateKind(rawValue: "3-Column (1/3)")
    public static let fourQuarters = LayoutTemplateKind(rawValue: "4-Quarters (2x2)")
}

/// A predefined multi-window layout grouping presented as a card in the layout picker.
public struct LayoutTemplate: Identifiable, Sendable, Equatable {
    public let id: String
    public let kind: LayoutTemplateKind
    public let slots: [LayoutSlot]

    public init(kind: LayoutTemplateKind, slots: [LayoutSlot]) {
        self.id = kind.rawValue
        self.kind = kind
        self.slots = slots
    }

    /// Dynamic layout templates customized for the user's preferred ratio.
    public static func templates(for ratio: LayoutRatio = .equal) -> [LayoutTemplate] {
        let asymKind: LayoutTemplateKind
        let asymSlots: [LayoutSlot]

        switch ratio {
        case .sixtyForty:
            asymKind = LayoutTemplateKind(rawValue: "2-Column (60/40)")
            asymSlots = [
                LayoutSlot(
                    id: "twoColAsym-left",
                    title: "Left (60%)",
                    target: .zone(.left60_40),
                    normalizedRect: CGRect(x: 0, y: 0, width: 0.6, height: 1.0)
                ),
                LayoutSlot(
                    id: "twoColAsym-right",
                    title: "Right (40%)",
                    target: .zone(.right40_60),
                    normalizedRect: CGRect(x: 0.6, y: 0, width: 0.4, height: 1.0)
                )
            ]
        case .eightyTwenty:
            asymKind = LayoutTemplateKind(rawValue: "2-Column (80/20)")
            asymSlots = [
                LayoutSlot(
                    id: "twoColAsym-left",
                    title: "Left (80%)",
                    target: .zone(.left80_20),
                    normalizedRect: CGRect(x: 0, y: 0, width: 0.8, height: 1.0)
                ),
                LayoutSlot(
                    id: "twoColAsym-right",
                    title: "Right (20%)",
                    target: .zone(.right20_80),
                    normalizedRect: CGRect(x: 0.8, y: 0, width: 0.2, height: 1.0)
                )
            ]
        default:
            asymKind = .twoColumnAsymmetric
            asymSlots = [
                LayoutSlot(
                    id: "twoColAsym-left",
                    title: "Left (70%)",
                    target: .left70_30,
                    normalizedRect: CGRect(x: 0, y: 0, width: 0.7, height: 1.0)
                ),
                LayoutSlot(
                    id: "twoColAsym-right",
                    title: "Right (30%)",
                    target: .rightOneThird,
                    normalizedRect: CGRect(x: 0.7, y: 0, width: 0.3, height: 1.0)
                )
            ]
        }

        return [
            LayoutTemplate(
                kind: .twoColumnEqual,
                slots: [
                    LayoutSlot(
                        id: "twoCol-left",
                        title: "Left Half (50%)",
                        target: .left50_50,
                        normalizedRect: CGRect(x: 0, y: 0, width: 0.5, height: 1.0)
                    ),
                    LayoutSlot(
                        id: "twoCol-right",
                        title: "Right Half (50%)",
                        target: .right50_50,
                        normalizedRect: CGRect(x: 0.5, y: 0, width: 0.5, height: 1.0)
                    )
                ]
            ),
            LayoutTemplate(
                kind: asymKind,
                slots: asymSlots
            ),
            LayoutTemplate(
                kind: .threeColumnEqual,
                slots: [
                    LayoutSlot(
                        id: "threeCol-left",
                        title: "Left 1/3",
                        target: .leftThird,
                        normalizedRect: CGRect(x: 0, y: 0, width: 1.0 / 3.0, height: 1.0)
                    ),
                    LayoutSlot(
                        id: "threeCol-center",
                        title: "Center 1/3",
                        target: .centerThird,
                        normalizedRect: CGRect(x: 1.0 / 3.0, y: 0, width: 1.0 / 3.0, height: 1.0)
                    ),
                    LayoutSlot(
                        id: "threeCol-right",
                        title: "Right 1/3",
                        target: .rightThird,
                        normalizedRect: CGRect(x: 2.0 / 3.0, y: 0, width: 1.0 / 3.0, height: 1.0)
                    )
                ]
            ),
            LayoutTemplate(
                kind: .fourQuarters,
                slots: [
                    LayoutSlot(
                        id: "fourQ-tl",
                        title: "Top-Left",
                        target: .topLeft,
                        normalizedRect: CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
                    ),
                    LayoutSlot(
                        id: "fourQ-tr",
                        title: "Top-Right",
                        target: .topRight,
                        normalizedRect: CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5)
                    ),
                    LayoutSlot(
                        id: "fourQ-bl",
                        title: "Bottom-Left",
                        target: .bottomLeft,
                        normalizedRect: CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5)
                    ),
                    LayoutSlot(
                        id: "fourQ-br",
                        title: "Bottom-Right",
                        target: .bottomRight,
                        normalizedRect: CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
                    )
                ]
            )
        ]
    }

    /// The 4 standard layout templates specified in BR-PICKER-003.
    public static var standardTemplates: [LayoutTemplate] {
        templates(for: .equal)
    }
}
