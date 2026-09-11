export interface MetricProofItem {
  id: string;
  value: string;
  label: string;
  sublabel: string;
  icon: "concurrency" | "shield" | "check" | "speed" | "fps";
}

export const metricsProof: MetricProofItem[] = [
  {
    id: "concurrency",
    value: "Swift 6",
    label: "Crash-Free Stability",
    sublabel: "Strict Concurrency • Zero Memory Leaks & Data Races",
    icon: "concurrency",
  },
  {
    id: "private-api",
    value: "0",
    label: "Private APIs Required",
    sublabel: "100% Gatekeeper Safe • Public AppKit & Accessibility APIs",
    icon: "shield",
  },
  {
    id: "tests",
    value: "470+",
    label: "Verified Precision",
    sublabel: "Swift Testing (@Test) Suite Covering 100% Snap Math",
    icon: "check",
  },
  {
    id: "latency",
    value: "< 1ms",
    label: "Instant Response",
    sublabel: "Snap Math • Zero Disk I/O In-Memory Engine",
    icon: "speed",
  },
  {
    id: "drag-fps",
    value: "60 FPS",
    label: "Silky Smooth Resizing",
    sublabel: "Divider Dragging • 16.6ms Throttled Fluid Multi-Window Reflow",
    icon: "fps",
  },
];
