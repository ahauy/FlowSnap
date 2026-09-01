# Contracts: Workspace Snapshot & Restoration (US-WORK-011)

**Feature Slug:** `workspace-snapshot-restoration` · **Status:** pending Gate 2 approval

## 1. WorkspaceStore (actor) — `FlowSnap/Infrastructure/Persistence/WorkspaceStore.swift`

```swift
enum WorkspaceStoreError: Error, Equatable, Sendable {
    case corruptFile
    case cannotCreateDirectory
    case writeFailed
}

actor WorkspaceStore {
    init(directoryURL: URL?)   // nil → default Application Support/FlowSnap (injectable for tests)
    func loadWorkspaces() async throws -> [Workspace]
    func saveWorkspaces(_ workspaces: [Workspace]) async throws
    func loadWorkspace(id: UUID) async throws -> Workspace?
    func upsert(_ workspace: Workspace) async throws
    func deleteWorkspace(id: UUID) async throws
}
```

- Atomic write: temp file in same directory → `rename` over destination.
- Corrupt JSON → throws `corruptFile` (caller degrades to empty list, E7).
- Missing file → returns `[]` (first launch).

## 2. ApplicationLaunching — `FlowSnap/Infrastructure/macOS/AppLauncher.swift`

```swift
protocol ApplicationLaunching: Sendable {
    /// Returns false when no app is installed for the bundle id.
    func openApp(withBundleIdentifier bundleID: String) async -> Bool
    /// Polls AX for the first normal window of pid. True when found within timeout.
    func waitForFirstWindow(pid: pid_t, timeout: TimeInterval) async -> Bool
}
```

- Production: `NSWorkspace.shared.urlForApplication(withBundleIdentifier:)`,
  `NSWorkspace.shared.open`, then `AccessibilityService.windows(of:)` polling at 100ms.
- Test: `MockApplicationLauncher` with scripted outcomes.

## 3. WorkspaceManager — `FlowSnap/Core/Workspace/WorkspaceManager.swift`

```swift
@MainActor
final class WorkspaceManager: ObservableObject {
    @Published private(set) var workspaces: [Workspace]

    init(windowManager: WindowManaging,
         accessibilityService: AccessibilityService,
         displayManager: DisplayManaging,
         layoutEngine: LayoutCalculating,
         workspaceStore: WorkspaceStore,
         appLauncher: any ApplicationLaunching,
         preferencesStore: PreferencesStore)

    // List management
    func refresh() async
    func saveCurrentAsWorkspace(name: String, icon: String) async throws
    func renameWorkspace(id: UUID, to newName: String) async throws
    func deleteWorkspace(id: UUID) async

    // Restore
    func restore(_ workspace: Workspace) async -> RestoreSummary
}
```

### Save algorithm (pure, testable)

1. Guard: name valid + unique (case-insensitive) → else throw `WorkspaceError.duplicateName` / `.invalidName`.
2. `windows = accessibilityService.allVisibleManagedWindows()` filtered:
   own pid excluded, `kind == .normal`, `bundleIdentifier != nil`, not minimized.
3. Group by bundle-id; for each app pick its largest-area window as representative.
4. Target display = `displayManager.display(for: representative.frame)`; use its `visibleFrame`.
5. Zone inference: normalized window frame vs each `LayoutZone.allCases` normalizedRect → max IoU;
   tie-break by `allCases` order (deterministic).
6. `expectedWindowCount = windows(of app).count`; `orderIndex` = descending window area.
7. Upsert into store; refresh published list.

### Restore algorithm

1. Pre-flight: `accessibilityService.isTrusted` else throw `.accessibilityDenied`.
2. Target display: focused window → cursor → primary (via `DisplayManaging`); use `visibleFrame`.
3. Sort placements by `orderIndex`. For each:
   - Find running app windows by bundle-id from `allVisibleManagedWindows()`.
   - If none: `appLauncher.openApp` → false ⇒ skip `notInstalled`;
     true ⇒ `waitForFirstWindow(pid:timeout:10)` ⇒ false ⇒ skip `launchTimeout`/`noWindow`.
   - Re-fetch windows; primary = largest area → `layoutEngine.frame(for: zone, in: visibleFrame, gap: currentGap, uniform: true)`.
   - Extras: cascade offset `+24pt * i` diagonal, clamped so the window stays inside the zone.
   - `windowManager.move(window, to: frame)`; AX failure → log, continue (E6).
4. Return `RestoreSummary(placedCount:totalPlacements:skipped:)`.

## 4. UI Surface

- `MenuBarViewModel`: gains `workspaceManager` dependency; actions `saveWorkspace()`,
  `restore(_:)` (async, dismisses popover, surfaces summary), `deleteWorkspace(_:)`.
- `WorkspaceSaveSheet`: TextField + curated SF Symbol grid; error text for E1/E2/E3.
- `WorkspaceListView`: rows with icon, name, Restore button; empty state text.
- `WorkspaceSettingsView`: list + rename (inline) + delete (confirm) + restore; same errors.
- `SettingsView`: new "Workspaces" tab entry.

## 5. Error Type

```swift
enum WorkspaceError: Error, Equatable, Sendable {
    case invalidName
    case duplicateName
    case noEligibleWindows
    case accessibilityDenied
    case storeFailure(WorkspaceStoreError)
}
```
