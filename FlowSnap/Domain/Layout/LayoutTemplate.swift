import CoreGraphics
import Foundation

/// Semantic kind of layout template in the Top-Edge Layout Picker.
public enum LayoutTemplateKind: String, Sendable, CaseIterable, Identifiable {
    case twoColumnEqual = "2-Column (50/50)"
    case twoColumnAsymmetric = "2-Column (70/30)"
    case threeColumnEqual = "3-Column (1/3)"
    case fourQuarters = "4-Quarters (2x2)"

    public var id: String { rawValue }
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

    /// The 4 standard layout templates specified in BR-PICKER-003.
    public static let standardTemplates: [LayoutTemplate] = [
        LayoutTemplate(
            kind: .twoColumnEqual,
            slots: [
                LayoutSlot(
                    id: "twoCol-left",
                    title: "Left Half (50%)",
                    target: .leftHalf,
                    normalizedRect: CGRect(x: 0, y: 0, width: 0.5, height: 1.0)
                ),
                LayoutSlot(
                    id: "twoCol-right",
                    title: "Right Half (50%)",
                    target: .rightHalf,
                    normalizedRect: CGRect(x: 0.5, y: 0, width: 0.5, height: 1.0)
                )
            ]
        ),
        LayoutTemplate(
            kind: .twoColumnAsymmetric,
            slots: [
                LayoutSlot(
                    id: "twoColAsym-left",
                    title: "Left (70%)",
                    target: .leftTwoThirds,
                    normalizedRect: CGRect(x: 0, y: 0, width: 0.7, height: 1.0)
                ),
                LayoutSlot(
                    id: "twoColAsym-right",
                    title: "Right (30%)",
                    target: .rightOneThird,
                    normalizedRect: CGRect(x: 0.7, y: 0, width: 0.3, height: 1.0)
                )
            ]
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
