import SwiftUI

/// SwiftUI presentation for the Top-Edge Snap Layout Picker flyout.
///
/// Renders 4 glassmorphic layout template cards with interactive slot highlighting.
/// Follows FlowSnap minimal design tokens (1px borders, Liquid Glass blur, accent focus).
public struct SnapLayoutPickerView: View {

    public let templates: [LayoutTemplate]
    public let hoveredSlotId: String?

    public init(
        templates: [LayoutTemplate] = LayoutTemplate.standardTemplates,
        hoveredSlotId: String? = nil
    ) {
        self.templates = templates
        self.hoveredSlotId = hoveredSlotId
    }

    public var body: some View {
        HStack(spacing: 12) {
            ForEach(templates) { template in
                TemplateCardView(template: template, hoveredSlotId: hoveredSlotId)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
        )
    }
}

/// Individual layout card displaying partitioned slots.
struct TemplateCardView: View {
    let template: LayoutTemplate
    let hoveredSlotId: String?

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Card base frame
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                        )

                    // Individual Slots
                    ForEach(template.slots) { slot in
                        let isHovered = (slot.id == hoveredSlotId)
                        let rect = slotRect(for: slot, in: geometry.size)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(isHovered ? Color.accentColor.opacity(0.45) : Color.primary.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .strokeBorder(
                                        isHovered ? Color.accentColor : Color.primary.opacity(0.18),
                                        lineWidth: isHovered ? 1.5 : 1
                                    )
                            )
                            .frame(width: rect.width, height: rect.height)
                            .offset(x: rect.minX, y: rect.minY)
                            .animation(.easeInOut(duration: 0.1), value: isHovered)
                    }
                }
            }
            .frame(width: 88, height: 56)

            Text(template.kind.rawValue)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 96)
    }

    private func slotRect(for slot: LayoutSlot, in size: CGSize) -> CGRect {
        let padding: CGFloat = 3
        let gap: CGFloat = 2
        let innerWidth = size.width - (padding * 2)
        let innerHeight = size.height - (padding * 2)

        let norm = slot.normalizedRect
        let x = padding + (norm.origin.x * innerWidth) + (norm.origin.x > 0 ? gap / 2.0 : 0)
        let y = padding + (norm.origin.y * innerHeight) + (norm.origin.y > 0 ? gap / 2.0 : 0)
        let w = (norm.width * innerWidth) - (norm.width < 1.0 ? gap / 2.0 : 0)
        let h = (norm.height * innerHeight) - (norm.height < 1.0 ? gap / 2.0 : 0)

        return CGRect(x: x, y: y, width: max(0, w), height: max(0, h))
    }
}
