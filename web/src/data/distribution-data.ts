export type InstallTabId = "curl" | "brew";

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
  readonly title: string;
  readonly summary: string;
  readonly command: string;
  readonly steps: readonly {
    readonly stepNumber: number;
    readonly title: string;
    readonly instruction: string;
  }[];
}

export const RELEASE_METADATA: ReleaseMetadata = {
  version: "v1.3.1",
  releaseDate: "September 2026",
  dmgUrl:
    "https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg",
  releasesPageUrl: "https://github.com/ahauy/FlowSnap/releases",
  binaryArch: "Universal Binary (Apple Silicon & Intel)",
  minMacOS: "macOS 14.0+ (Sonoma & Sequoia)",
  fileSize: "~14.2 MB",
  license: "MIT Open Source",
  sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
};

export const TERMINAL_TABS: readonly TerminalTabItem[] = [
  {
    id: "curl",
    label: "cURL",
    command:
      "curl -fsSL https://raw.githubusercontent.com/ahauy/FlowSnap/main/install.sh | bash",
    description:
      "Automatically download and install the latest Universal DMG into /Applications",
    defaultActive: true,
  },
  {
    id: "brew",
    label: "Homebrew",
    command: "brew install --cask ahauy/tap/flowsnap",
    description:
      "Install and manage updates via the official Homebrew Cask tap",
    defaultActive: false,
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
  title: 'Encountered macOS Gatekeeper "Unidentified Developer" Warning?',
  summary:
    "Because FlowSnap is an open-source community utility without Apple Developer Program signing, macOS applies a quarantine flag on first launch.",
  command: "xattr -cr /Applications/FlowSnap.app",
  steps: [
    {
      stepNumber: 1,
      title: "Drag FlowSnap to Applications",
      instruction:
        "Open the downloaded FlowSnap.dmg and drag the FlowSnap icon into your /Applications directory as usual.",
    },
    {
      stepNumber: 2,
      title: "Remove quarantine attribute via Terminal",
      instruction:
        "Copy and paste the command below into Terminal, then press Enter to remove the com.apple.quarantine attribute.",
    },
    {
      stepNumber: 3,
      title: "Launch and grant Accessibility permissions",
      instruction:
        "Open FlowSnap from Spotlight or Launchpad, then grant Accessibility access when prompted to enable window snapping.",
    },
  ],
};
