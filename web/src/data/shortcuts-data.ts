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
  keys: string[];
  displayString: string;
  description: string;
  badge?: string;
}

export const shortcutCategories: ShortcutCategoryDef[] = [
  { key: "all", label: "Tất cả" },
  { key: "window", label: "Cửa sổ" },
  { key: "display", label: "Màn hình" },
  { key: "workspace", label: "Workspace" },
  { key: "utility", label: "Tiện ích" },
];

export const shortcutsCatalog: ShortcutDefinition[] = [
  // Cửa sổ (Window & Snap)
  {
    id: "snap-left",
    action: "Snap Nửa Trái (50%)",
    category: "window",
    keys: ["⌃", "⌥", "←"],
    displayString: "⌃⌥←",
    description: "Chia cửa sổ vào 50% bên trái màn hình hiện tại",
    badge: "Cơ bản",
  },
  {
    id: "snap-right",
    action: "Snap Nửa Phải (50%)",
    category: "window",
    keys: ["⌃", "⌥", "→"],
    displayString: "⌃⌥→",
    description: "Chia cửa sổ vào 50% bên phải màn hình hiện tại",
    badge: "Cơ bản",
  },
  {
    id: "snap-maximize",
    action: "Phóng To Toàn Màn Hình",
    category: "window",
    keys: ["⌃", "⌥", "↑"],
    displayString: "⌃⌥↑",
    description:
      "Mở rộng chiếm 100% không gian làm việc khả dụng (trừ Dock/Menu Bar)",
  },
  {
    id: "snap-restore",
    action: "Khôi Phục Vị Trí Cũ",
    category: "window",
    keys: ["⌃", "⌥", "↓"],
    displayString: "⌃⌥↓",
    description:
      "Đưa cửa sổ về lại kích thước và tọa độ ban đầu trước khi snap",
  },
  {
    id: "snap-quarters",
    action: "Snap 4 Góc (25%)",
    category: "window",
    keys: ["⌃", "⌥", "1..4"],
    displayString: "⌃⌥1..4",
    description:
      "Xếp cửa sổ vào 1 trong 4 góc màn hình (1: Top-Left, 2: Top-Right, 3: Bottom-Left, 4: Bottom-Right)",
  },
  {
    id: "pin-always-on-top",
    action: "Ghim Luôn Trên Cùng",
    category: "window",
    keys: ["⌃", "⌥", "P"],
    displayString: "⌃⌥P",
    description:
      "Ghim cửa sổ luôn nổi lên trên các ứng dụng khác (Always-on-Top)",
    badge: "Mới",
  },

  // Màn hình (Multi-Display)
  {
    id: "throw-next-display",
    action: "Ném Sang Màn Hình Kế Tiếp",
    category: "display",
    keys: ["⌃", "⌥", "⇧", "→"],
    displayString: "⌃⌥⇧→",
    description:
      "Chuyển cửa sổ sang màn hình bên phải và tự co giãn tỷ lệ khung hình",
    badge: "Đa màn hình",
  },
  {
    id: "throw-prev-display",
    action: "Ném Sang Màn Hình Trước",
    category: "display",
    keys: ["⌃", "⌥", "⇧", "←"],
    displayString: "⌃⌥⇧←",
    description:
      "Chuyển cửa sổ sang màn hình bên trái và tự co giãn tỷ lệ khung hình",
    badge: "Đa màn hình",
  },
  {
    id: "migrate-workspace-display",
    action: "Di Chuyển Trọn Gói Workspace",
    category: "display",
    keys: ["⌃", "⌥", "⇧", "⌘", "→"],
    displayString: "⌃⌥⇧⌘→",
    description:
      "Chuyển toàn bộ nhóm cửa sổ đang làm việc sang màn hình khác đồng thời",
  },

  // Workspace (Workspaces & Presets)
  {
    id: "preset-coding",
    action: "Bố Cục Lập Trình (Coding Flow)",
    category: "workspace",
    keys: ["⌃", "⌥", "⌘", "1"],
    displayString: "⌃⌥⌘1",
    description:
      "Khôi phục bộ 3 cửa sổ: VS Code (60%), Chrome DevTools (25%), Terminal (15%)",
    badge: "Preset",
  },
  {
    id: "preset-research",
    action: "Bố Cục Nghiên Cứu & Viết Lách",
    category: "workspace",
    keys: ["⌃", "⌥", "⌘", "2"],
    displayString: "⌃⌥⌘2",
    description:
      "Khôi phục bố cục tài liệu: Arc Browser (70%) + Notion / Notes (30%)",
    badge: "Preset",
  },
  {
    id: "snapshot-save",
    action: "Lưu Nhanh Bố Cục Workspace",
    category: "workspace",
    keys: ["⌃", "⌥", "⌘", "S"],
    displayString: "⌃⌥⌘S",
    description:
      "Chụp ảnh không gian làm việc hiện tại và lưu vào danh sách Workspace cá nhân",
  },

  // Tiện ích (Utilities & Focus)
  {
    id: "toggle-scratchpad",
    action: "Triệu Hồi Quake Scratchpad",
    category: "utility",
    keys: ["⌥", "Space"],
    displayString: "⌥Space",
    description:
      "Bật/tắt nhanh cửa sổ ghi chú hoặc terminal nổi; nhấn lại hoặc ESC để ẩn",
    badge: "Đột phá",
  },
  {
    id: "universal-fullscreen-escape",
    action: "Thoát Toàn Màn Hình Tức Thì",
    category: "utility",
    keys: ["⌃", "⌘", "F"],
    displayString: "⌃⌘F",
    description:
      "Thoát Fullscreen đa tầng hỗ trợ cả app macOS Native lẫn Electron",
  },
  {
    id: "open-settings",
    action: "Mở Cài Đặt FlowSnap",
    category: "utility",
    keys: ["⌃", "⌥", ","],
    displayString: "⌃⌥,",
    description:
      "Mở cửa sổ cấu hình phím tắt, khoảng hở viền (Gaps), và khởi động cùng macOS",
  },
];
