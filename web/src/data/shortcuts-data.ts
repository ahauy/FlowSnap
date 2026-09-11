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
  { key: "all", label: "All" },
  { key: "window", label: "Window" },
  { key: "display", label: "Display" },
  { key: "workspace", label: "Workspace" },
  { key: "utility", label: "Utility" },
];

export const shortcutsCatalog: ShortcutDefinition[] = [
  // Window & Snap
  {
    id: "snap-left",
    action: "Snap Left Half (50%)",
    category: "window",
    keys: ["⌃", "⌥", "←"],
    displayString: "⌃⌥←",
    description: "Snap focused window to the left 50% of the active display",
    badge: "Basic",
  },
  {
    id: "snap-right",
    action: "Snap Right Half (50%)",
    category: "window",
    keys: ["⌃", "⌥", "→"],
    displayString: "⌃⌥→",
    description: "Snap focused window to the right 50% of the active display",
    badge: "Basic",
  },
  {
    id: "snap-maximize",
    action: "Maximize Window (100%)",
    category: "window",
    keys: ["⌃", "⌥", "↑"],
    displayString: "⌃⌥↑",
    description:
      "Expand window to 100% usable workspace (respecting Dock & Menu Bar)",
  },
  {
    id: "snap-restore",
    action: "Restore Previous Geometry",
    category: "window",
    keys: ["⌃", "⌥", "↓"],
    displayString: "⌃⌥↓",
    description:
      "Revert window back to its pre-snap coordinates and dimensions",
  },
  {
    id: "snap-quarters",
    action: "Snap 4 Corners (25%)",
    category: "window",
    keys: ["⌃", "⌥", "1..4"],
    displayString: "⌃⌥1..4",
    description:
      "Tile window into one of 4 corners (1: Top-Left, 2: Top-Right, 3: Bottom-Left, 4: Bottom-Right)",
  },
  {
    id: "pin-always-on-top",
    action: "Pin Always-on-Top",
    category: "window",
    keys: ["⌃", "⌥", "P"],
    displayString: "⌃⌥P",
    description: "Float window above all other applications (Floating Overlay)",
    badge: "New",
  },

  // Multi-Display
  {
    id: "throw-next-display",
    action: "Throw to Next Display",
    category: "display",
    keys: ["⌃", "⌥", "⇧", "→"],
    displayString: "⌃⌥⇧→",
    description:
      "Move window to right adjacent screen with proportional scaling",
    badge: "Multi-Screen",
  },
  {
    id: "throw-prev-display",
    action: "Throw to Previous Display",
    category: "display",
    keys: ["⌃", "⌥", "⇧", "←"],
    displayString: "⌃⌥⇧←",
    description:
      "Move window to left adjacent screen with proportional scaling",
    badge: "Multi-Screen",
  },
  {
    id: "migrate-workspace-display",
    action: "Migrate Entire Workspace",
    category: "display",
    keys: ["⌃", "⌥", "⇧", "⌘", "→"],
    displayString: "⌃⌥⇧⌘→",
    description:
      "Move all windows in the current group to another display simultaneously",
  },

  // Workspaces & Presets
  {
    id: "preset-coding",
    action: "Coding Layout Preset",
    category: "workspace",
    keys: ["⌃", "⌥", "⌘", "1"],
    displayString: "⌃⌥⌘1",
    description:
      "Restore 3-window layout: VS Code (60%), Chrome DevTools (25%), Terminal (15%)",
    badge: "Preset",
  },
  {
    id: "preset-research",
    action: "Research & Writing Preset",
    category: "workspace",
    keys: ["⌃", "⌥", "⌘", "2"],
    displayString: "⌃⌥⌘2",
    description:
      "Restore document layout: Arc / Safari (70%) + Notion / Notes (30%)",
    badge: "Preset",
  },
  {
    id: "snapshot-save",
    action: "Snapshot Current Workspace",
    category: "workspace",
    keys: ["⌃", "⌥", "⌘", "S"],
    displayString: "⌃⌥⌘S",
    description:
      "Capture active layout coordinates and save as a custom workspace snapshot",
  },

  // Utilities & Focus
  {
    id: "toggle-scratchpad",
    action: "Summon Quake Scratchpad",
    category: "utility",
    keys: ["⌥", "Space"],
    displayString: "⌥Space",
    description:
      "Toggle instant floating terminal or scratchpad; press ESC to dismiss",
    badge: "Instant",
  },
  {
    id: "universal-fullscreen-escape",
    action: "Universal Fullscreen Escape",
    category: "utility",
    keys: ["⌃", "⌘", "F"],
    displayString: "⌃⌘F",
    description:
      "Instant exit from multi-level fullscreen for both Native and Electron apps",
  },
  {
    id: "open-settings",
    action: "Open FlowSnap Settings",
    category: "utility",
    keys: ["⌃", "⌥", ","],
    displayString: "⌃⌥,",
    description:
      "Configure custom shortcuts, inner/outer margin gaps, and launch on login",
  },
];
