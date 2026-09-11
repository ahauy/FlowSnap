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
      "Drag any window to the top edge to reveal an intuitive layout picker: 50/50, 70/30, 3-column, and 4-corner grids. Drop into any zone for instant snapping.",
    highlights: [
      "Smooth slide-in physics",
      "Liquid Glass translucent HUD",
      "4 smart layout templates",
    ],
    span: "hero",
    illustrationId: "top-edge",
  },
  {
    id: "collinear-2d",
    title: "Adaptive Collinear 2D Resize",
    badge: "Tiling Precision",
    description:
      "Drag shared divider borders or crosshair intersections to simultaneously resize 2 to 4 adjacent windows at 60 FPS without breaking layout symmetry.",
    highlights: [
      "T-junction & crosshair snapping",
      "Rock-solid 60 FPS fluidity",
    ],
    span: "standard",
    illustrationId: "collinear-2d",
  },
  {
    id: "current-space",
    title: "Current Space Preservation",
    badge: "Flow Continuity",
    description:
      "Newly launched apps appear strictly in your current active workspace. Permanently ends macOS from jarringly jumping to another virtual desktop space.",
    highlights: ["100% Public APIs", "Zero workspace disruption"],
    span: "standard",
    illustrationId: "current-space",
  },
  {
    id: "workspaces-presets",
    title: "Intent-Based Workspaces & Presets",
    badge: "Multi-App Harmony",
    description:
      "Save and restore full application workspace groups (Coding, Research, Writing) mapped by screen-independent percentages with a single keystroke.",
    highlights: ["Coding & Research Presets", "Seamless multi-display restore"],
    span: "hero",
    illustrationId: "workspaces",
  },
  {
    id: "quake-scratchpad",
    title: "Quake-Style Quick Scratchpad",
    badge: "Instant Summon (⌥Space)",
    description:
      "Summon a dedicated utility window (Terminal, Notes, Finder) floating in front in < 50ms. Dismiss quickly with ESC without shrinking underlying windows by 1 pixel.",
    highlights: [
      "Instant < 50ms summon",
      "Auto-dismiss on outside click",
      "Zero-shrink background apps",
    ],
    span: "hero",
    illustrationId: "scratchpad",
  },
  {
    id: "multi-monitor",
    title: "Display-Aware Multi-Monitor Topology",
    badge: "Multi-Display Topology",
    description:
      "Throw windows across screens with dedicated hotkeys (⌃⌥⇧→), automatically scaling proportions between Retina displays and 4K monitors with pixel-perfect math.",
    highlights: [
      "1-touch display throw",
      "Preserves aspect ratio across 4K & Retina",
    ],
    span: "standard",
    illustrationId: "multi-monitor",
  },
];
