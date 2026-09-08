# Data Model: Distribution Hub, 1-Click Terminal Copy, DMG & Privacy Manifesto (US-WEB-028)

## 1. Domain Entities & TypeScript Contracts

To ensure clean separation of concerns and type-safety, all distribution data will reside in `web/src/data/distribution-data.ts`.

```typescript
export type InstallTabId = "curl" | "brew";

export interface ReleaseMetadata {
  readonly version: string; // e.g. "v1.3.1"
  readonly releaseDate: string; // e.g. "September 2026"
  readonly dmgUrl: string; // Direct download URL to FlowSnap.dmg
  readonly releasesPageUrl: string; // GitHub releases repository URL
  readonly binaryArch: string; // "Universal (Apple Silicon & Intel)"
  readonly minMacOS: string; // "macOS 14.0+ (Sonoma & Sequoia)"
  readonly fileSize: string; // "~14.2 MB"
  readonly license: string; // "MIT License (100% Free & Open Source)"
  readonly sha256: string; // Sample SHA-256 checksum for verification
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
```

## 2. Default Static Data Definition (`web/src/data/distribution-data.ts`)

```typescript
export const RELEASE_METADATA: ReleaseMetadata = {
  version: "v1.3.1",
  releaseDate: "September 2026",
  dmgUrl:
    "https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg",
  releasesPageUrl: "https://github.com/ahauy/FlowSnap/releases",
  binaryArch: "Universal (Apple Silicon & Intel)",
  minMacOS: "macOS 14.0+ (Sonoma & Sequoia)",
  fileSize: "~14.2 MB",
  license: "MIT (100% Free & Open Source)",
  sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
};

export const TERMINAL_TABS: readonly TerminalTabItem[] = [
  {
    id: "curl",
    label: "cURL",
    command:
      "curl -fsSL https://raw.githubusercontent.com/ahauy/FlowSnap/main/install.sh | bash",
    description:
      "Tải và cài đặt tự động bản Universal DMG mới nhất vào /Applications",
    defaultActive: true,
  },
  {
    id: "brew",
    label: "Homebrew",
    command: "brew install --cask ahauy/tap/flowsnap",
    description:
      "Cài đặt và quản lý phiên bản qua Homebrew Cask tap chính thức",
    defaultActive: false,
  },
];

export const PRIVACY_PILLARS: readonly PrivacyPillarItem[] = [
  {
    id: "offline",
    title: "100% Hoạt động Offline",
    badge: "Zero Network Outbound",
    icon: "offline",
    description:
      "FlowSnap hoạt động hoàn toàn cục bộ trên máy của bạn mà không kết nối với bất kỳ máy chủ nào.",
    details: [
      "Không yêu cầu đăng ký tài khoản hay đăng nhập",
      "Không gửi dữ liệu cấu hình hoặc bố cục ra bên ngoài",
      "Hoạt động hoàn hảo ngay cả khi ngắt toàn bộ Internet",
    ],
  },
  {
    id: "telemetry",
    title: "Zero Telemetry & Tracking",
    badge: "No Tracking SDKs",
    icon: "shield",
    description:
      "Tuyệt đối không thu thập dữ liệu phân tích hành vi hay thông tin cá nhân của người dùng.",
    details: [
      "Không tích hợp Google Analytics, Sentry hay Mixpanel",
      "Không lưu cookie hay fingerprint máy tính",
      "Mã nguồn minh bạch 100% để cộng đồng tự do kiểm toán",
    ],
  },
  {
    id: "accessibility",
    title: "Quyền Trợ Năng Minh Bạch",
    badge: "AXUIElement Only",
    icon: "lock",
    description:
      "Quyền Accessibility (AX) chỉ được dùng để tính toán và điều hướng tọa độ cửa sổ.",
    details: [
      "Chỉ thao tác kích thước (size) và vị trí (position) cửa sổ",
      "Cam kết Zero Keylogging: Không bao giờ theo dõi nội dung gõ phím",
      "Không can thiệp vào bộ nhớ hoặc dữ liệu của ứng dụng khác",
    ],
  },
];

export const GATEKEEPER_DATA: GatekeeperGuideData = {
  title: 'Gặp cảnh báo "Unidentified Developer" từ macOS Gatekeeper?',
  summary:
    "Vì FlowSnap là phần mềm mã nguồn mở cộng đồng phi thương mại (không mua chứng chỉ Apple Developer $99/năm), macOS sẽ gán cờ cách ly (quarantine) lần đầu mở app.",
  command: "xattr -cr /Applications/FlowSnap.app",
  steps: [
    {
      stepNumber: 1,
      title: "Kéo FlowSnap vào thư mục Applications",
      instruction:
        "Mở tệp FlowSnap.dmg vừa tải và kéo biểu tượng FlowSnap vào thư mục /Applications như bình thường.",
    },
    {
      stepNumber: 2,
      title: "Mở Terminal và chạy lệnh gỡ cờ cách ly",
      instruction:
        "Sao chép và dán câu lệnh bên dưới vào Terminal rồi nhấn Enter để xóa thuộc tính com.apple.quarantine.",
    },
    {
      stepNumber: 3,
      title: "Mở ứng dụng và cấp quyền Trợ năng",
      instruction:
        "Khởi chạy FlowSnap từ Launchpad hoặc Spotlight, sau đó cấp quyền Trợ năng (Accessibility) khi được hỏi để bắt đầu tận hưởng snap mượt mà.",
    },
  ],
};
```
