# Data Model & Schema Specification: Bento Grid & Shortcuts (US-WEB-027)

## 1. TypeScript Interfaces

```typescript
// web/src/data/bento-features.ts

export type BentoCardSpan = "hero" | "standard";

export interface BentoFeatureItem {
  id: string;
  title: string;
  badge: string;
  description: string;
  highlights: string[];
  span: BentoCardSpan; // 'hero' (2 columns on desktop) | 'standard' (1 column)
  illustrationId:
    | "top-edge"
    | "collinear-2d"
    | "current-space"
    | "workspaces"
    | "scratchpad"
    | "multi-monitor";
}

// web/src/data/metrics-proof.ts

export interface MetricProofItem {
  id: string;
  value: string;
  label: string;
  sublabel: string;
  icon: "concurrency" | "shield" | "check" | "speed" | "fps";
}

// web/src/data/shortcuts.ts

export type ShortcutCategoryKey =
  "all" | "window" | "display" | "workspace" | "utility";

export interface ShortcutCategoryDef {
  key: ShortcutCategoryKey;
  label: string;
}

export interface ShortcutDefinition {
  id: string;
  action: string;
  category: ShortcutCategoryKey;
  keys: string[]; // e.g. ["⌃", "⌥", "←"]
  displayString: string; // e.g. "⌃⌥←"
  description: string;
  badge?: string;
}
```

---

## 2. Static Data Fixtures Catalog

### A. 6 Feature Pillars Data (`bentoFeatures`)

1. **`top-edge-picker`**:
   - `title`: "Top-Edge Snap Layout Picker"
   - `badge`: "Windows 11-Style on Mac"
   - `span`: "hero"
   - `description`: "Kéo cửa sổ chạm mép trên màn hình để mở khay chọn bố cục trực quan: 50/50, 70/30, 3 cột và 4 góc."
   - `highlights`: ["Trượt xuống mượt mà", "Xem trước kính mờ", "Thả vào ô là snap"]
2. **`collinear-2d`**:
   - `title`: "Adaptive Collinear 2D Resize"
   - `badge`: "Tiling Precision"
   - `span`: "standard"
   - `description`: "Kéo đường phân cách chung hoặc ngã ba/ngã tư để cùng lúc resize 2 đến 4 cửa sổ liền kề mượt mà ở 60 FPS."
   - `highlights`: ["T-Junction & Crosshair", "Đồng bộ đa cửa sổ"]
3. **`current-space`**:
   - `title`: "Current Space Preservation"
   - `badge`: "Flow Continuity"
   - `span`: "standard"
   - `description`: "Mở ứng dụng mới luôn xuất hiện ngay tại Space hiện tại. Chấm dứt hiện tượng macOS tự văng sang Space khác."
   - `highlights`: ["Zero Private API", "Không gián đoạn mạch tập trung"]
4. **`workspaces-presets`**:
   - `title`: "Intent-Based Workspaces & Presets"
   - `badge`: "Multi-App Harmony"
   - `span`: "standard"
   - `description`: "Lưu và khôi phục toàn bộ bố cục nhiều cửa sổ (Coding, Research, Writing) theo ý định chỉ bằng 1 phím tắt."
   - `highlights`: ["Preset Coding & Research", "Khôi phục đa màn hình"]
5. **`quake-scratchpad`**:
   - `title`: "Quake-Style Quick Scratchpad"
   - `badge`: "Instant Summon (⌥Space)"
   - `span`: "hero"
   - `description`: "Nhấn ⌥Space để triệu hồi cửa sổ tiện ích (Terminal, Notes, Finder) nổi lên trên cùng. Thoát nhanh bằng ESC mà không co nhỏ ứng dụng đang làm việc 1 pixel nào."
   - `highlights`: ["Triệu hồi < 50ms", "Tự ẩn khi click ra ngoài", "Giữ nguyên 100% app nền"]
6. **`multi-monitor`**:
   - `title`: "Display-Aware Multi-Monitor Topology"
   - `badge`: "Coordinate Inversion Math"
   - `span`: "standard"
   - `description`: "Ném cửa sổ xuyên màn hình (⌃⌥⇧→), tự co giãn tỷ lệ giữa màn hình Retina và màn 4K với toán học đảo trục Y chuẩn xác."
   - `highlights`: ["Ném cửa sổ 1 chạm", "Bảo toàn tỷ lệ khung hình"]

### B. 5 Verifiable Metrics Data (`metricsProof`)

1. `{ value: "Swift 6", label: "Strict Concurrency", sublabel: "100% Actor Isolation & Zero Data Races", icon: "concurrency" }`
2. `{ value: "0", label: "Private APIs", sublabel: "100% Public AppKit & Accessibility (AXUIElement)", icon: "shield" }`
3. `{ value: "470+", label: "Automated Tests", sublabel: "100% Math & Geometry Code Coverage", icon: "check" }`
4. `{ value: "< 1ms", label: "Snap Math", sublabel: "Zero Disk I/O In-Memory Coordinate Engine", icon: "speed" }`
5. `{ value: "60 FPS", label: "Divider Dragging", sublabel: "16.6ms Throttled Fluid Multi-Window Resizing", icon: "fps" }`

### C. 15 Interactive Shortcuts Catalog (`shortcutsCatalog`)

- **Cửa sổ (Window)**:
  - `⌃⌥←`: Snap Trái 50%
  - `⌃⌥→`: Snap Phải 50%
  - `⌃⌥↑`: Maximize (Toàn màn hình khả dụng)
  - `⌃⌥↓`: Khôi phục vị trí ban đầu (Restore)
  - `⌃⌥1 / 2 / 3 / 4`: Snap 4 góc màn hình
  - `⌃⌥P`: Ghim cửa sổ luôn trên cùng (Always-on-Top)
- **Màn hình (Display)**:
  - `⌃⌥⇧→`: Ném cửa sổ sang màn hình kế tiếp (Next Display)
  - `⌃⌥⇧←`: Ném cửa sổ sang màn hình trước (Prev Display)
  - `⌃⌥⇧⌘→`: Di chuyển toàn bộ Workspace sang màn hình khác
- **Workspace (Workspaces & Presets)**:
  - `⌃⌥⌘1`: Khôi phục Preset Coding (VS Code + Browser + Terminal)
  - `⌃⌥⌘2`: Khôi phục Preset Research & Writing
  - `⌃⌥⌘S`: Lưu nhanh ảnh chụp Workspace hiện tại
- **Tiện ích (Utilities)**:
  - `⌥Space`: Bật/tắt Quake Quick Scratchpad
  - `⌃⌘F`: Thoát Fullscreen tức thì (Universal Escape)
  - `⌃⌥,`: Mở nhanh Cửa sổ Cài đặt FlowSnap
