# Data Model: Workspace Snapshot & Restoration (US-WORK-011)

**Feature Slug:** `workspace-snapshot-restoration` · **Status:** pending Gate 2 approval

## 1. Entities

### Workspace (aggregate root)

```swift
struct Workspace: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String                 // unique case-insensitive (BR-008)
    var icon: String                 // SF Symbol name, curated picker
    var placements: [WindowPlacement] // ordered by orderIndex
    var createdAt: Date
    var lastRestoredAt: Date?
}
```

### WindowPlacement (value object — ADR-001)

```swift
struct WindowPlacement: Codable, Hashable, Sendable {
    var bundleIdentifier: String      // intent key, survives app restarts
    var zone: LayoutZone              // normalized zone enum (portable, no pixels)
    var expectedWindowCount: Int      // captured at save (ASM-WORK-002)
    var orderIndex: Int               // deterministic restore order
}
```

### RestoreSummary (result type)

```swift
struct RestoreSummary: Sendable {
    let placedCount: Int
    let totalPlacements: Int
    let skipped: [SkippedApp]
    var isFullSuccess: Bool { skipped.isEmpty && placedCount == totalPlacements }
}

struct SkippedApp: Sendable, Hashable {
    let bundleIdentifier: String
    let reason: SkipReason            // notInstalled | launchTimeout | noWindow
}
```

## 2. Persistence Document

File: `~/Library/Application Support/FlowSnap/workspaces.json`

```json
{
  "schemaVersion": 1,
  "workspaces": [
    {
      "id": "UUID",
      "name": "Coding",
      "icon": "hammer",
      "createdAt": "2026-08-31T10:00:00Z",
      "lastRestoredAt": null,
      "placements": [
        {
          "bundleIdentifier": "com.microsoft.VSCode",
          "zone": "left60_40",
          "expectedWindowCount": 1,
          "orderIndex": 0
        }
      ]
    }
  ]
}
```

- Envelope object with `schemaVersion: Int` (additive-forward, NFR-5).
- `LayoutZone` serializes via its existing `String` raw value (e.g. `left60_40`).
- Unknown fields ignored on decode (forward compatible with v1.1 `mode` field).

## 3. Validation Rules

| Rule | Enforcement |
|---|---|
| Name non-empty, not whitespace-only | `WorkspaceManager` pre-capture guard |
| Name unique case-insensitive | `WorkspaceManager` checks loaded list before upsert |
| `expectedWindowCount >= 1` | Decoded values clamped to ≥ 1 |
| `orderIndex` unique within workspace | Normalized on save (0..<n) |
| Zone is a valid `LayoutZone` raw value | Decode fails → corrupt file path (E7) |
| Max placements per workspace | Soft cap 8 (UI guard; decode does not enforce) |

## 4. Storage Lifecycle

- **Create:** `saveWorkspaces` writes the full envelope atomically (temp + rename).
- **Read:** On app start, `WorkspaceManager` loads once; store caches nothing (stateless reads).
- **Corrupt file (E7):** `loadWorkspaces` returns `[]` and exposes `WorkspaceStoreError.corruptFile`;
  UI shows a non-blocking warning; next successful save rewrites the file.
- **Delete:** Full-envelope rewrite after removal (no tombstones).
- **Rollback plan:** No migration exists (stub never persisted). If a future schema bump fails
  to decode, v1 reader degrades to empty list — user data loss is impossible beyond the file itself.

## 5. In-Memory Flow

- `WorkspaceManager` holds `@Published private(set) var workspaces: [Workspace]` (loaded at init
  via store, refreshed after every mutation) so SwiftUI lists bind directly.
- All mutations go: UI → `WorkspaceManager` → `await store` → refresh published list.
