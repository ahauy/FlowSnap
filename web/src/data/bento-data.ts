export type BentoCardSpan = "hero" | "standard";

export interface BentoFeatureItem {
  id: string;
  title: string;
  badge: string;
  description: string;
  highlights: string[];
  span: BentoCardSpan;
  illustrationId:
    | "top-edge"
    | "collinear-2d"
    | "current-space"
    | "workspaces"
    | "scratchpad"
    | "multi-monitor";
}

export const bentoFeatures: BentoFeatureItem[] = [
  {
    id: "top-edge-picker",
    title: "Top-Edge Snap Layout Picker",
    badge: "Windows 11-Style on Mac",
    description:
      "Kéo cửa sổ chạm mép trên cùng màn hình để mở khay chọn bố cục trực quan: 50/50, 70/30, 3 cột ngang và 4 góc. Thả vào ô bất kỳ để snap tức thì.",
    highlights: [
      "Trượt xuống mượt mà",
      "Xem trước kính mờ Liquid Glass",
      "4 mẫu bố cục thông minh",
    ],
    span: "hero",
    illustrationId: "top-edge",
  },
  {
    id: "collinear-2d",
    title: "Adaptive Collinear 2D Resize",
    badge: "Tiling Precision",
    description:
      "Kéo đường phân cách chung hoặc ngã ba/ngã tư để đồng thời co giãn 2 đến 4 cửa sổ liền kề mượt mà ở 60 FPS mà không phá vỡ cấu trúc layout.",
    highlights: [
      "Điểm giao chữ T & dấu cộng",
      "Giữ nhịp 60 FPS không giật lag",
    ],
    span: "standard",
    illustrationId: "collinear-2d",
  },
  {
    id: "current-space",
    title: "Current Space Preservation",
    badge: "Flow Continuity",
    description:
      "Mở ứng dụng mới luôn xuất hiện tại không gian làm việc hiện tại. Chấm dứt vĩnh viễn ức chế bị macOS tự văng sang Desktop Space khác.",
    highlights: ["100% Public APIs", "Bảo toàn mạch tập trung tuyệt đối"],
    span: "standard",
    illustrationId: "current-space",
  },
  {
    id: "workspaces-presets",
    title: "Intent-Based Workspaces & Presets",
    badge: "Multi-App Harmony",
    description:
      "Lưu và khôi phục trọn gói không gian làm việc (Coding, Research, Writing) theo tỷ lệ phần trăm độc lập kích thước màn hình chỉ với 1 phím tắt.",
    highlights: ["Preset Coding & Research", "Khôi phục đa màn hình mượt mà"],
    span: "standard",
    illustrationId: "workspaces",
  },
  {
    id: "quake-scratchpad",
    title: "Quake-Style Quick Scratchpad",
    badge: "Instant Summon (⌥Space)",
    description:
      "Triệu hồi cửa sổ tiện ích (Terminal, Notes, Finder) nổi lên trước mặt người dùng trong < 50ms. Thoát nhanh bằng phím ESC mà không co nhỏ ứng dụng đang làm việc 1 pixel nào.",
    highlights: [
      "Triệu hồi tức thì < 50ms",
      "Tự ẩn khi click ra ngoài",
      "Zero-shrink ứng dụng nền",
    ],
    span: "hero",
    illustrationId: "scratchpad",
  },
  {
    id: "multi-monitor",
    title: "Display-Aware Multi-Monitor Topology",
    badge: "Coordinate Inversion Math",
    description:
      "Ném cửa sổ xuyên màn hình bằng phím tắt (⌃⌥⇧→), tự co giãn tỷ lệ giữa màn hình Retina và màn 4K với toán học đảo trục tọa độ chuẩn xác 100%.",
    highlights: [
      "Ném cửa sổ 1 chạm",
      "Bảo toàn tỷ lệ khung hình giữa 4K & Retina",
    ],
    span: "standard",
    illustrationId: "multi-monitor",
  },
];
