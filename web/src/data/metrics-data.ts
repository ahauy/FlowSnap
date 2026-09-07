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
    label: "Strict Concurrency",
    sublabel: "100% Actor Isolation & Zero Data Races",
    icon: "concurrency",
  },
  {
    id: "private-api",
    value: "0",
    label: "Private APIs",
    sublabel: "100% Public AppKit & AXUIElement (Gatekeeper Safe)",
    icon: "shield",
  },
  {
    id: "tests",
    value: "470+",
    label: "Automated Tests",
    sublabel: "Swift Testing (@Test) Suite Covering 100% Snap Math",
    icon: "check",
  },
  {
    id: "latency",
    value: "< 1ms",
    label: "Snap Math",
    sublabel: "Zero Disk I/O In-Memory Coordinate Engine",
    icon: "speed",
  },
  {
    id: "drag-fps",
    value: "60 FPS",
    label: "Divider Dragging",
    sublabel: "16.6ms Throttled Fluid Multi-Window Resizing",
    icon: "fps",
  },
];
