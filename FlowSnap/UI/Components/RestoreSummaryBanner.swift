import SwiftUI

/// Non-blocking banner displaying the outcome of a workspace or preset restore operation.
///
/// Features:
/// - Distinct visual states for full success vs partial skips (FR-PRESET-007, spec §4.5)
/// - Plain-language headlines and per-app failure breakdown
/// - Compact mode for Menu Bar popover and expanded mode for Settings tabs
/// - Conforms to Apple HIG and native macOS desktop aesthetics
public struct RestoreSummaryBanner: View {

    public let summary: RestoreSummary
    public let isCompact: Bool
    public let onDismiss: (() -> Void)?

    public init(
        summary: RestoreSummary,
        isCompact: Bool = false,
        onDismiss: (() -> Void)? = nil
    ) {
        self.summary = summary
        self.isCompact = isCompact
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(alignment: .top, spacing: isCompact ? 6 : 8) {
            statusIcon

            VStack(alignment: .leading, spacing: isCompact ? 1 : 3) {
                Text(summary.headline)
                    .font(.system(size: isCompact ? 10 : 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if !isCompact && !summary.details.isEmpty {
                    ForEach(summary.details, id: \.self) { detail in
                        Text(detail)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 4)

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: isCompact ? 8 : 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Dismiss summary")
            }
        }
        .padding(isCompact ? 6 : 10)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 5 : 7)
                .fill((summary.isFullSuccess ? Color.green : Color.orange).opacity(0.08))
                .stroke((summary.isFullSuccess ? Color.green : Color.orange).opacity(0.25), lineWidth: 1)
        )
    }

    private var statusIcon: some View {
        Image(systemName: summary.isFullSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            .font(.system(size: isCompact ? 10 : 12))
            .foregroundStyle(summary.isFullSuccess ? Color.green : Color.orange)
    }
}
