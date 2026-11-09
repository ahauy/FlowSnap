export type InstallTabId = "curl";

export interface ReleaseMetadata {
  readonly version: string;
  readonly releaseDate: string;
  readonly dmgUrl: string;
  readonly releasesPageUrl: string;
  readonly binaryArch: string;
  readonly minMacOS: string;
  readonly fileSize: string;
  readonly license: string;
  readonly sha256: string;
}

export interface TerminalTabItem {
  readonly id: InstallTabId;
  readonly label: string;
  readonly command: string;
  readonly description: string;
  readonly defaultActive?: boolean;
  /** Source a visitor can read before running the command. Absent means the
   *  command has no same-origin script to audit, so the UI must not imply one. */
  readonly scriptUrl?: string;
}

export interface PrivacyPillarItem {
  readonly id: string;
  readonly title: string;
  readonly badge: string;
  readonly icon: "offline" | "shield" | "lock";
  readonly description: string;
  readonly details: readonly string[];
}

export interface GatekeeperGuideData {
  readonly command: string;
}

export const RELEASE_METADATA: ReleaseMetadata = {
  version: "v1.3.1",
  releaseDate: "September 2026",
  dmgUrl:
    "https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg",
  releasesPageUrl: "https://github.com/ahauy/FlowSnap/releases",
  binaryArch: "Universal Binary (Apple Silicon & Intel)",
  minMacOS: "macOS 14.0+ (Sonoma & Sequoia)",
  fileSize: "~3.3 MB",
  license: "MIT Open Source",
  sha256: "d31f1a0d9973b3951a2775d776e65959d2b8dae144614b9216c5e517f8f4bf1f",
};

export const TERMINAL_TABS: readonly TerminalTabItem[] = [
  {
    id: "curl",
    label: "cURL",
    command:
      '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ahauy/FlowSnap/main/scripts/install.sh)"',
    description:
      "Automatically download and install the latest Universal DMG into /Applications",
    scriptUrl: "https://github.com/ahauy/FlowSnap/blob/main/scripts/install.sh",
    defaultActive: true,
  },
];

export const PRIVACY_PILLARS: readonly PrivacyPillarItem[] = [
  {
    id: "offline",
    title: "100% Offline Operation",
    badge: "Zero Network Outbound",
    icon: "offline",
    description:
      "FlowSnap operates entirely on your local machine without opening external network sockets or phoning home.",
    details: [
      "No account creation, login, or cloud licensing required",
      "Zero telemetry, layout data, or telemetry transmissions",
      "Fully functional even with network interfaces disconnected",
    ],
  },
  {
    id: "telemetry",
    title: "Zero Telemetry & Tracking",
    badge: "No Tracking SDKs",
    icon: "shield",
    description:
      "We strictly collect zero analytics, behavioral event telemetry, or personal identifiable information.",
    details: [
      "Zero Google Analytics, Mixpanel, or Sentry SDKs bundled",
      "No cookies, local fingerprinting, or hardware serial tracking",
      "100% open-source codebase for full community auditability",
    ],
  },
  {
    id: "accessibility",
    title: "Transparent Accessibility Permissions",
    badge: "AXUIElement Only",
    icon: "lock",
    description:
      "Accessibility (AX) privileges are used strictly for querying window coordinates and geometric resizing.",
    details: [
      "Mutates only window frame bounds (size) and position (origin)",
      "Zero Keylogging guarantee: never reads keyboard input outside hotkeys",
      "Never inspects application content, text payloads, or window data",
    ],
  },
];

export const GATEKEEPER_DATA: GatekeeperGuideData = {
  command: "xattr -cr /Applications/FlowSnap.app",
};
