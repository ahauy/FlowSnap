import SwiftUI

/// Non-blocking banner displaying the outcome of a workspace or preset restore operation.
///
/// Features:
/// - Distinct visual states for full success vs partial restore outcomes (FR-PRESET-007, spec §4.5)
/// - Explicit placed/failed/unverifiable/skipped counters and reason groups
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

            VStack(alignment: .leading, spacing: isCompact ? 1 : 5) {
                Text(summary.headline)
                    .font(.system(size: isCompact ? 10 : 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if !isCompact {
                    summaryCounts

                    issueGroup(title: "Failed", issues: summary.failed)
                    issueGroup(title: "Unverifiable", issues: summary.unverifiable)
                    issueGroup(title: "Not presented", issues: summary.movedButNotPresented)
                    issueGroup(title: "Skipped", issues: summary.skipped)
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
                .accessibilityLabel("Dismiss summary")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("restore-summary-banner")
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
            .accessibilityHidden(true)
    }

    /// Counters are rendered independently from `headline` so a partial pass
    /// remains scannable even when it contains several issue reasons. In compact
    /// mode the existing single-line headline is retained for the Menu Bar.
    private var summaryCounts: some View {
        HStack(spacing: 8) {
            countLabel("Placed", value: summary.placedCount, tint: .green)

            if summary.failedCount > 0 {
                countLabel("Failed", value: summary.failedCount, tint: .red)
            }
            if summary.unverifiableCount > 0 {
                countLabel("Unverifiable", value: summary.unverifiableCount, tint: .orange)
            }
            if summary.movedButNotPresentedCount > 0 {
                countLabel("Not presented", value: summary.movedButNotPresentedCount, tint: .orange)
            }
            if summary.skippedCount > 0 {
                countLabel("Skipped", value: summary.skippedCount, tint: Color.secondary)
            }
        }
        .font(.system(size: 10, weight: .medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Restore summary counts")
    }

    private func countLabel(_ title: LocalizedStringKey, value: Int, tint: Color) -> some View {
        HStack(spacing: 2) {
            Text(title)
            Text("\(value)")
        }
        .foregroundStyle(tint)
    }

    @ViewBuilder
    private func issueGroup(title: LocalizedStringKey, issues: [RestoreIssue]) -> some View {
        if !issues.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 2) {
                    Text(title)
                    Text("(\(issues.count))")
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

                ForEach(issues) { issue in
                    Text("• \(issue.displayReason)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(issue.displayReason)
                }
            }
        }
    }
}
