import SwiftUI

/// Visual interactive grid of miniature screen cards representing window snap zones.
///
/// Shares visual design tokens (1px hairline borders, continuous corner radii, accent focus)
/// with `SnapLayoutPickerView` for a cohesive user experience across FlowSnap surfaces.
///
/// Traces to: REQ-MENU-007, US-SNAP-005.
public struct VisualSnapGridView: View {

    public let isEnabled: Bool
    public let onSelect: (MenuBarAction) -> Void

    @State private var hoveredAction: MenuBarAction?

    public init(
        isEnabled: Bool = true,
        onSelect: @escaping (MenuBarAction) -> Void
    ) {
        self.isEnabled = isEnabled
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Section Header & Active Action Feedback
            HStack {
                Text("QUICK SNAP")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)

                Spacer()

                if let action = hoveredAction {
                    HStack(spacing: 4) {
                        Text(action.rawValue)
                            .font(.system(size: 9, weight: .medium))
                        Text(action.shortcutBadge)
                            .font(.system(size: 8, weight: .regular, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    Text("Click slot to snap")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
            }
            .animation(.easeInOut(duration: 0.12), value: hoveredAction)

            // 2x2 Interactive Canvas Grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                // Card 1: Halves (Left / Right)
                visualCard(
                    title: "Halves",
                    slots: [
                        SlotConfig(action: .leftHalf, rect: CGRect(x: 0, y: 0, width: 0.5, height: 1.0)),
                        SlotConfig(action: .rightHalf, rect: CGRect(x: 0.5, y: 0, width: 0.5, height: 1.0))
                    ]
                )

                // Card 2: Top / Bottom
                visualCard(
                    title: "Top / Bottom",
                    slots: [
                        SlotConfig(action: .topHalf, rect: CGRect(x: 0, y: 0, width: 1.0, height: 0.5)),
                        SlotConfig(action: .bottomHalf, rect: CGRect(x: 0, y: 0.5, width: 1.0, height: 0.5))
                    ]
                )

                // Card 3: 4-Quarters (2x2)
                visualCard(
                    title: "Quarters",
                    slots: [
                        SlotConfig(action: .topLeft, rect: CGRect(x: 0, y: 0, width: 0.5, height: 0.5)),
                        SlotConfig(action: .topRight, rect: CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5)),
                        SlotConfig(action: .bottomLeft, rect: CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5)),
                        SlotConfig(action: .bottomRight, rect: CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5))
                    ]
                )

                // Card 4: Maximize & Restore
                visualCard(
                    title: "Maximize / Restore",
                    slots: [
                        SlotConfig(action: .maximize, rect: CGRect(x: 0, y: 0, width: 0.68, height: 1.0), icon: "arrow.up.left.and.arrow.down.right"),
                        SlotConfig(action: .restore, rect: CGRect(x: 0.68, y: 0, width: 0.32, height: 1.0), icon: "arrow.counterclockwise")
                    ]
                )
            }
            .opacity(isEnabled ? 1.0 : 0.45)
            .disabled(!isEnabled)
        }
    }

    // MARK: - Card Component

    private func visualCard(title: String, slots: [SlotConfig]) -> some View {
        VStack(spacing: 3) {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Screen bezel frame
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                        )

                    // Clickable Partition Slots
                    ForEach(slots) { slot in
                        let isHovered = (slot.action == hoveredAction)
                        let rect = calculateRect(for: slot.rect, in: geometry.size)

                        Button {
                            onSelect(slot.action)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                    .fill(isHovered ? Color.accentColor.opacity(0.40) : Color.primary.opacity(0.07))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                            .strokeBorder(
                                                isHovered ? Color.accentColor : Color.primary.opacity(0.16),
                                                lineWidth: isHovered ? 1.2 : 0.8
                                            )
                                    )

                                if let icon = slot.icon {
                                    Image(systemName: icon)
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundStyle(isHovered ? Color.accentColor : .secondary)
                                }
                            }
                            .frame(width: rect.width, height: rect.height)
                        }
                        .buttonStyle(.plain)
                        .offset(x: rect.minX, y: rect.minY)
                        .onHover { isHovering in
                            if isHovering {
                                hoveredAction = slot.action
                            } else if hoveredAction == slot.action {
                                hoveredAction = nil
                            }
                        }
                        .animation(.easeInOut(duration: 0.1), value: isHovered)
                    }
                }
            }
            .frame(height: 48)

            Text(title)
                .font(.system(size: 8.5, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }

    private func calculateRect(for norm: CGRect, in size: CGSize) -> CGRect {
        let padding: CGFloat = 3
        let gap: CGFloat = 2
        let innerWidth = size.width - (padding * 2)
        let innerHeight = size.height - (padding * 2)

        let x = padding + (norm.origin.x * innerWidth) + (norm.origin.x > 0 ? gap / 2.0 : 0)
        let y = padding + (norm.origin.y * innerHeight) + (norm.origin.y > 0 ? gap / 2.0 : 0)
        let w = (norm.width * innerWidth) - (norm.width < 1.0 ? gap / 2.0 : 0)
        let h = (norm.height * innerHeight) - (norm.height < 1.0 ? gap / 2.0 : 0)

        return CGRect(x: x, y: y, width: max(0, w), height: max(0, h))
    }
}

private struct SlotConfig: Identifiable {
    let action: MenuBarAction
    let rect: CGRect
    var icon: String? = nil

    var id: String { action.rawValue }
}
