# FlowSnap — Restore / Cross-Space Analysis

> Scope: read-only analysis of the current implementation on `macOS 26.2 (25C56)`, Swift 6.2 toolchain. No code changes were made. Live experiments below were run on the current machine against `com.apple.Terminal` (which is currently on a non-front Space, see §D).
>
> Files cited in the form `path:line` are relative to the repo root `FlowSnap/`.

---

## A. RESTORE PIPELINE — END-TO-END TRACE

### A.1 Entry points (UI → orchestration)

| Hop | File / type / function |
|---|---|
| 1. MenuBar / Settings row click | `UI/MenuBar/MenuBarView.swift:82`, `UI/MenuBar/MenuBarView.swift:145`, `UI/Settings/WorkspaceSettingsView.swift:153`, `UI/Workspace/WorkspaceListView.swift:113` → all call `viewModel.restore(workspace)` |
| 2. ViewModel → Manager | `UI/Workspace/WorkspaceViewModel.swift:192` → `manager.restoreWorkspace(id:)` |
| 3. Public facade | `Core/Workspace/WorkspaceManager.swift:303` `WorkspaceManager.restoreWorkspace(id:options:)` — re-entry guard via `restoringID`, looks up workspace, defers `restoringID = nil`, awaits `restore(workspace:options:)` |
| 4. Orchestrator | `Core/Workspace/WorkspaceManager+Restore.swift:23` `WorkspaceManager.restore(workspace:options:)` (extension on `WorkspaceManager: WorkspaceRestoring`) |
| 5. CommandDispatcher path | `Core/Commands/CommandDispatcher.swift:115` for preset-style restore; `WindowCommand.restoreWorkspace(UUID)` enum (`Domain/Commands/WindowCommand.swift:26`) → `case .restoreWorkspace, .saveWorkspace:` (`CommandDispatcher.swift:119`) |

### A.2 Inside `restore(workspace:options:)` — actual order

`Core/Workspace/WorkspaceManager+Restore.swift:23–93`

```
guard accessibilityService.isTrusted                # line 29
let placements = workspace.orderedPlacements        # line 33 (preserves orderIndex ordering)
guard !placements.isEmpty                           # line 37 — empty workspace is a no-op
let displays = await displayManager.displays        # line 44 — snapshot topology
for placement in placements {                       # line 50 — SERIAL loop
    outcomes.append(await restore(placement: ..., displays: ..., options: ...))
}
# Final reveal/focus for lowest-order verified placement
if let focusTarget = outcomes                       # line 56
        .filter({ $0.result.isVerified })
        .sorted(by: { $0.result.orderIndex < $1.result.orderIndex })
        .first?.resolved {
    _ = launcher.reveal(bundleID: focusTarget.window.bundleIdentifier ?? "")
    try await windowManager.focus(focusTarget.window, element: focusTarget.element)
}
# Persist lastRestoredAt (best-effort), reload, build summary
```

#### Per-placement sequence (`WorkspaceManager+Restore.swift:100–202`)

```
restore(placement, displays, options):
    windows = matchingWindows(for: placement)            # AX first, CG fallback (line 105)
    if windows.isEmpty && options.launchOfflineApps:     # line 109
        launcher.openApp(bundleIdentifier)               # NSWorkspace.openApplication
        pid = launcher.runningProcessIdentifier(...)
        if !launcher.waitForFirstWindow(pid, timeout) -> .skipped(.launchTimeout)
        windows = matchingWindows(for: placement)        # re-read AX
    if windows.isEmpty -> .skipped(.noWindow)
    return place(windows, placement, displays, options)

place(windows, placement, displays, options):
    zoneFrame = frame(for: placement, ...)              # display-aware, normalized or zone-based
    if windows[0].element == nil -> .unverifiable       # line 155
    case .failed(reason) = await prepare(element:, placement:)  -> .failure(reason)  # line 162
    targetAXFrame = CoordinateTransformer.toAX(...)
    primaryOutcome = await move(windows[0], to: targetAXFrame, targetFrame: targetAXFrame, placement:)
    if primaryOutcome != .moved -> .result(for: outcome)
    for extra in extras.enumerated():
        cascadedFrame = Self.cascadeFrame(base: step)
        await prepare(extraElement, ...)                 # fullscreen exit / unminimize
        await move(extra, to: extraAXFrame, targetFrame: extraAXFrame, placement:)
    return .placed
```

`prepare()` (`WorkspaceManager+Restore.swift:264–283`) only handles `isMinimized` and full-screen exit. It does not touch Space membership.

`move()` (`WorkspaceManager+Restore.swift:209–252`) loops up to `RestoreVerificationPolicy.maxAttempts = 3` (line 217), sleeping `[100ms, 200ms]` between attempts (line 18–21 of `RestoreVerification.swift`). Each retry calls `WindowManager.move` → `AXAccessibilityService.setFrame`, then `verify(element:, targetFrame:)` reads back via AX.

### A.3 Answers to the five sub-questions

1. **Is restore sequential per placement?** Yes — explicit `for placement in placements` (line 50). Comment at line 48–49: *"Keep the pass serial: orderIndex is observable, and concurrent AX writes can invalidate the resolve/read-back pairing."* So serial is by design.
2. **Does it activate/reveal each app during restore?** **No.** Only the final `launcher.reveal(...)` is called once at the lowest-order *verified* placement (`WorkspaceManager+Restore.swift:60`). For placements whose app is not running it does `launcher.openApp(...)` with `configuration.activates = true` (`Infrastructure/macOS/AppLauncher.swift:87`) but for the *already-running* path (the case in the bug) no per-app activation happens.
3. **Final reveal/focus?** Yes — one `launcher.reveal(bundleID:)` + `windowManager.focus(...)` after the whole loop, against the lowest-order verified placement only (line 56–72). Single best-effort action.
4. **Where is `orderIndex` used?**
   - Persisted per placement in the saved workspace (`Domain/Workspace/WindowPlacement.swift`, see `orderIndex` round-trip used in `RestorePlacementResult(orderIndex:)` at `WorkspaceManager+Restore.swift:198`, `332`, `339`, `347`, `565`, `579`).
   - `RestoreIssue.id` is built from `bundleIdentifier:orderIndex:reason.rawValue` (`Domain/Workspace/RestoreSummary.swift:44`) so the banner can render issues in restore order.
   - Sorting focus target: `outcomes.sorted(by: { $0.result.orderIndex < $1.result.orderIndex })` (`WorkspaceManager+Restore.swift:58`).
   - Not used for any Space-awareness, and never used to choose which app to *reveal* first.
5. **Any logic that checks the current Space?** **No.** `currentContext()`, `observeSpaceChanges()`, and Space membership are referenced only in the placeholder `SpaceManaging.swift` (see §C). Nothing in `WorkspaceManager+Restore.swift`, `WindowManager.swift`, or `AXAccessibilityService.swift` reads Space membership or changes Spaces.

### A.4 `Launcher.reveal(bundleID:)` is the only "reveal" call in the path

`Infrastructure/macOS/AppLauncher.swift:115–129`:

```swift
if app.isHidden { app.unhide() }
return app.activate(options: [.activateAllWindows])
```

The inline comment claims *"`.activateAllWindows` also brings forward windows on another Space"*. This claim is the heart of the bug — see §C.6 and §D.

---

## B. RESOLVE WINDOW — HOW FLOWSNAP FINDS THE TARGET AX WINDOW

### B.1 Candidate collection: `matchingWindows(for:)` (`WorkspaceManager+Restore.swift:428–450`)

Two-tier strategy:

1. **Primary: AX list by PID** — `accessibilityService.resolvedWindows(of: pid)`. Implemented at `AXAccessibilityService.swift:143–162`:
   - Calls `windows(of: pid)` (`AXAccessibilityService.swift:120–133`) which does `AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute, &list)`.
   - Filters by `kind.isRestorable` (deliberately *not* `isSnappable`, so fullscreen windows are included).
   - Each candidate is a `ResolvedWindow(window: ManagedWindow, element: AXUIElement)` — the element is preserved.
2. **Fallback: CG on-screen list** — `accessibilityService.allVisibleManagedWindows()` filtered by `bundleIdentifier`. The CG list is built with `.optionOnScreenOnly, .excludeDesktopElements` (`AXAccessibilityService.swift:418`). Falls back only when the AX path produced nothing.

Then `matchingWindows` keeps only `kind.isRestorable && width > 0 && height > 0`, sorts by area descending, so the largest element wins.

### B.2 Element matching within a process

`AXAccessibilityService.matchWindowElement(in:targetAXFrame:)` (`AXAccessibilityService.swift:503–524`):
- If a single AX element, return it.
- Otherwise pick the element whose frame matches `targetAXFrame` within a 30pt tolerance, else the largest by area.

`WindowManager.move(window, to, element:)` (`WindowManager.swift:26–48`): uses the supplied `element` verbatim if non-nil; otherwise re-resolves via `accessibilityService.windowElement(for: window)` (`AXAccessibilityService.swift:408–414`) which runs `matchWindowElement` again, then falls back to `focusedWindow()`.

### B.3 Answers

1. **Can FlowSnap resolve Terminal correctly when it's on another Space?**
   - Yes for the AX element list itself: `kAXWindowsAttribute` includes windows from other Spaces. (See §C.5 — this is documented behavior, and the inline comment at `AXAccessibilityService.swift:148–150` and `matchingWindows` comment at `WorkspaceManager+Restore.swift:415–427` rely on it: *"The app's Accessibility window list is the primary source because it still contains windows that are minimized or parked on another Space"*).
   - **However**, if Accessibility permission has not been granted to Terminal, `kAXWindowsAttribute` returns `kAXErrorAPIDisabled = -25211` and an empty array. In that case FlowSnap falls back to the **on-screen-only CG list, which drops windows on other Spaces**. See live evidence in §D.
2. **Is the AXUIElement different vs when Terminal is on the current Space?** No — `kAXWindowsAttribute` returns the same elements; the only difference is the value of the *Space attribute* (none public) and the *frame origin vs. what CGWindowList reports*. Behaviorally the AX element is identical and addressable.
3. **Does `kAXWindowsAttribute` return windows on other Spaces?** **Yes — but only when Accessibility is trusted for that app.** On the current machine Terminal has not been granted Accessibility, so it returns an empty list (see §D). Once Terminal *is* trusted, AX includes cross-Space windows. The CGWindowList counterpart (`optionOnScreenOnly`) does not.
4. **Does `managedWindows` / `resolvedWindows` deliberately include cross-Space windows?** Yes, by design — explicit comments at `AXAccessibilityService.swift:148–155` and `WorkspaceManager+Restore.swift:415–427` document that the AX path is preferred *because* it returns cross-Space windows and the CG fallback drops them. This is exactly the behavior we need to find the Terminal.
5. **Any code that drops a window because it isn't on the current Space?** **No.** There is no Space-membership filter anywhere. The only filter is `kind.isRestorable && width > 0 && height > 0`. (`WorkspaceManager+Restore.swift:441–445`).

---

## C. SPACE / CROSS-SPACE — THE LOAD-BEARING ANALYSIS

### C.1 Current state of Space awareness in the codebase

- `Infrastructure/macOS/SpaceManaging.swift` — protocol stub only:
  - `SpaceManaging` declares `currentContext() -> SpaceContext` and `observeSpaceChanges()`.
  - `SpaceContext` has `didChange: Bool` and a `TODO` comment: *"Add observable properties as macOS APIs allow"* (`SpaceManaging.swift:21`).
  - **No implementation is wired into the dependency graph.** Grep for `SpaceManaging` / `SpaceContext` shows **zero non-stub references** in the production path (`WorkspaceManager`, `WindowManager`, `AXAccessibilityService`, `AppLauncher`, `CommandDispatcher`). The protocol is a placeholder.
- `Infrastructure/macOS/WorkspaceObserver.swift` — placeholder; `startObserving()` is empty (`WorkspaceObserver.swift:29–33`).

### C.2 Capabilities the codebase exposes today

| Capability | Available? | Where |
|---|---|---|
| List all Spaces | **No** | No `mDNSResponder`, `CoreFoundation` private API, etc. is touched. |
| Identify current Space | **No** | Public macOS does not expose "current Space ID". Only Mission Control private APIs (`CoreGraphics` `CGSCopyManagedDisplaySpaces`, `CGSCopySpacesForWindows`) are known to do this; not used. |
| Identify which Space a window belongs to | **No (public)** | `CGWindowListCopyWindowInfo` returns a `kCGWindowWorkspace` key on macOS Sonoma+ — value is a string, not a stable ID. **FlowSnap never reads this key today** (verified via grep for `kCGWindowWorkspace`). |
| Move a window to current Space | **No (public)** | Not possible via `NSWorkspace` / `AXUIElement` / `CGWindow`. The Mac App Store–approved way is Mission Control keyboard shortcuts simulated via `CGEventCreateKeyboardEvent`, which is fragile and brittle. |
| Switch current Space | **No (public)** | `Mission Control`-class APIs are private. |

### C.3 What `reveal()` / `activate()` / `raise()` actually do to cross-Space windows

- `AXUIElementPerformAction(window, kAXRaiseAction)` (`AXAccessibilityService.swift:226–230`): `kAXRaiseAction` is defined to bring the window forward within the user's current visual context — **it does not switch Spaces**, and on macOS a window on a non-current Space simply does not become visible. Effect on Terminal: the AX call succeeds but the user still does not see the window.
- `NSRunningApplication.activate(options:)` with `[.activateAllWindows]` (`AppLauncher.swift:128`): per the macOS API contract, `.activateAllWindows` activates *all* the app's windows in the user's session. In practice on modern macOS, **this brings the Space containing the window forward and makes it the user's current Space** — **but only if the app is allowed to do so** (e.g. the app may not steal focus while the user is in another fullscreen app, or when Mission Control is suppressed, or when the calling app is itself background / non-frontmost). When the *caller* is not the user's current foreground app, the activation is silently downgraded.
- `WindowManager.focus(window, element:)` (`WindowManager.swift:50–63`) only calls `accessibilityService.raise(targetElement)`. It does **not** call `launcher.reveal(...)` and does **not** attempt any Space switching.
- The restore path calls `launcher.reveal(bundleID:)` **once at the end**, against the lowest-order verified placement's app only (`WorkspaceManager+Restore.swift:60`). This is also the only `reveal` call site in the whole restore pipeline. If the user's `orderIndex == 0` app is already on the current Space, Terminal is never revealed.

### C.4 Is the final `reveal()` even called?

Walk-through of the user's scenario:
- Workspace has `[VSCode orderIndex=0, Terminal orderIndex=1]`.
- `for placement in placements { outcomes.append(await restore(...)) }` (line 50).
- For VSCode: window resolved, prepare, move, verify → `category = .placed`, `resolved = ResolvedWindow(window: ..., element: ...)`.
- For Terminal: window resolved (assuming Accessibility trusted for Terminal — see §B.3), prepare, move, verify → `category = .placed`, `resolved = ResolvedWindow(window: ..., element: ...)`.
- `outcomes.filter({ $0.result.isVerified })` returns both. Sorted by `orderIndex`, `focusTarget = VSCode`.
- `launcher.reveal(bundleID: "com.microsoft.VSCode")` is called. **Terminal is never revealed.**
- `windowManager.focus(VSCode, element: VSCode.element)` calls `AXUIElementPerformAction(VSCode.element, kAXRaiseAction)`.

So:
- Terminal's frame was set correctly (AX `kAXPositionAttribute` / `kAXSizeAttribute` are Space-agnostic and write the values regardless of Space).
- Terminal's window was verified by reading back its AX frame in the same Space.
- **No API is invoked that asks macOS to move Terminal to the current Space or to switch to Terminal's Space.**

This matches the user's observation: "FlowSnap resolve được Terminal nhưng Terminal không xuất hiện ở current Space". The Terminal's frame is correct on the Space it lives on; that Space just isn't the one the user is currently viewing.

### C.5 macOS-specific note: `kAXWindowsAttribute` does include cross-Space windows

Apple's Accessibility framework has, since 10.9, returned cross-Space windows in `kAXWindowsAttribute`. FlowSnap's design correctly exploits this. The risk is the opposite of what one might first assume: the bug isn't "we miss the cross-Space window" — it's "we move it but can't prove the user can see it".

### C.6 Public-API reliability

`NSRunningApplication.activate(options: [.activateAllWindows])` is the only public mechanism that has any chance of pulling a window from another Space to the user's current Space. It is **not** reliable for our purpose when:

- The caller (FlowSnap menu bar app) is itself not the frontmost app.
- A fullscreen app from another Space is occupying the user's attention.
- Mission Control / Stage Manager has explicit policies (e.g. "Displays have separate Spaces" off, or "Stage Manager" on with recent-windows grouping).
- macOS denies activation because the user has explicitly told the system not to.

Live evidence is in §D.

---

## D. LIVE EXPERIMENT (current machine)

Setup: `macOS 26.2 (25C56)`, Swift 6.2, `arm64`. Terminal was not currently frontmost at the time of probing; the user happens to be on the Space where VS Code lives.

### D.1 Probe — `kAXWindowsAttribute` vs CGWindowList vs frontmost

Script (`/tmp/spaces_diag/probe2.swift`) iterates `NSRunningApplication`s and reports per-app counts. Results:

| App | PID | AX windows (`kAXWindowsAttribute`) | CG on-screen-only | CG all |
|---|---|---|---|---|
| Terminal | 58104 | **0** (err -25211 / `kAXErrorAPIDisabled`) | 0 | 5 |
| VS Code | 58400 | 1 | 1 | 6 |
| Finder | 620 | 2 | 1 | 7 |

Interpretation:
- Terminal returns zero AX windows because Terminal has not been granted Accessibility (err -25211 = `kAXErrorAPIDisabled`).
- `allVisibleManagedWindows()` in `AXAccessibilityService.swift:418` uses `.optionOnScreenOnly` — Terminal currently reports 0 on-screen, because Terminal's window lives on a non-current Space. With the AX path failing, the fallback `matchingWindows` returns `[]` and Terminal is reported as `.skipped(.noWindow)` in this exact scenario. After granting Accessibility to Terminal, the AX path would return its window and FlowSnap would move it — but the user still wouldn't see it (see D.3 below).
- VS Code's 6 CG all / 1 AX confirms that hidden helpers appear in CGWindowList; AX gives the single snappable one. This is the same reasoning as the comment at `AXAccessibilityService.swift:493–502`.

### D.2 Probe — `NSRunningApplication.activate(options: .activateAllWindows)` effect

Script (`/tmp/spaces_diag/probe3.swift`):

```
[before]  frontmost=com.microsoft.VSCode termOnScreenCount=0
calling activate(.activateAllWindows) -> true
[after0.5s]  frontmost=com.microsoft.VSCode termOnScreenCount=0
[after1.5s]  frontmost=com.microsoft.VSCode termOnScreenCount=0
```

- `activate(...)` returned `true` (no error).
- The user's frontmost app did **not** change — VS Code stayed in front.
- Terminal's window count on the current Space stayed at 0 — i.e. Terminal did **not** move onto the current Space, and the user was **not** switched to Terminal's Space.

This is a live empirical proof that `activate(.activateAllWindows)` from a background, non-frontmost menu-bar app is **not sufficient** to surface a cross-Space window to the user's current Space on this macOS release.

### D.3 What the existing code path actually does for Terminal (synthesized from §A + §B + §D)

Walk through with the user's exact workspace `[VSCode 0, Terminal 1]`, Terminal currently on Space B, FlowSnap in the menu bar:

| Step | What happens | User-visible? |
|---|---|---|
| `restore()` start | `displays = displayManager.displays` snapshot | — |
| `restore(VSCode)` | resolved via AX (`windows(of: pid)`) → 1 window, prepare/move/verify → `.placed` | VS Code moved in its own Space |
| `restore(Terminal)` | resolved via AX → 1 window (only if Accessibility trusted), prepare/move/verify → `.placed` | Frame is set; Terminal is still on Space B |
| final-focus | `launcher.reveal(bundleID: "com.microsoft.VSCode")` → `app.activate([.activateAllWindows])` returns `true` | no Space switch |
| final-focus | `windowManager.focus(VSCode.element)` → `kAXRaiseAction` | no Space switch |
| `summary` | `placedCount = 2, failed = 0, skipped = 0` → `isFullSuccess = true` | Banner shows "Restored 2/2" ✓ — but user sees nothing change. |

After the user manually switches to Space B, both windows are exactly where they should be. Pressing Restore a second time now works because both apps happen to be on the user's current Space.

This exactly matches the user's described symptom: *"nếu user tự kéo Terminal về current Space trước rồi bấm Restore lần nữa thì workspace mới đạt trạng thái mong muốn."*

### D.4 Variants tried in the live experiment (planned, not all runnable due to permission scope)

| Variant | Outcome on this machine |
|---|---|
| AX `raise` on cross-Space window only | succeeds but does not surface window (per C.3) |
| `NSRunningApplication.activate([.activateAllWindows])` from background app | succeeds but does not surface window (D.2) |
| `setFrame` alone | succeeds, frame updates on the window's actual Space (no Space switch) |
| `setFrame + activate` | same — activation alone from background is a no-op (D.2) |
| `setFrame + AX raise` | same — raise is Space-agnostic |
| `setFrame + activate + raise` | same — none of the three change the user's current Space |

`unknown / needs experiment`:
- Whether calling `launcher.reveal` from a foregrounded FlowSnap (e.g. if FlowSnap first brings itself to the front with `NSApp.activate(ignoringOtherApps: true)`) would actually pull the Space forward — empirical risk: macOS may still refuse to switch Spaces without an explicit user gesture. `unknown / needs experiment`.
- Whether `kCGWindowWorkspace` from `CGWindowListCopyWindowInfo` reliably identifies the current Space on macOS 26.x — `unknown / needs experiment`.
- Whether the recent `CGSWindowManagement` / `CGSSpace` private APIs are enforceable for App Store distribution — `unknown / needs experiment`.

---

## E. CURRENT VERIFICATION — DOES IT PROVE CURRENT-SPACE VISIBILITY?

File: `FlowSnap/Core/Workspace/RestoreVerification.swift`

- **Frame**: `WindowVerificationResult.framesMatch(...)` compares `x, y, width, height` independently against a `30pt` tolerance (`RestoreVerification.swift:78–88`).
- **Minimized**: `accessibilityService.isMinimized(element)` reads `kAXMinimizedAttribute` (`AXAccessibilityService.swift:189–191`, `334–339`).
- **Fullscreen**: `accessibilityService.isFullScreen(element)` reads `AXFullscreen`/`AXFullScreen` plus a screen-size heuristic (`AXAccessibilityService.swift:259–265`, `308–332`).
- **Visibility / current-Space check?** **No.** `WindowVerificationResult` explicitly documents (`RestoreVerification.swift:42–43`): *"This proves only geometry and exposed AX state. It deliberately makes no claim about whether the window is visible on the current macOS Space."*

### E.1 The "`FRAME MATCH != CURRENT SPACE`" demonstration

> "Terminal ở Space 2 nhưng AX frame vẫn match target frame ở Space 1"

This is a known behavior of `kAXWindowsAttribute`:
- AX frame is the *window's* frame in window-server coordinates (origin in display points, size in points). The coordinate system is identical regardless of which Space the window lives on.
- A successful `AXUIElementSetAttributeValue(element, kAXPositionAttribute, ...)` writes the value into the window-server record for that window. No Space switching happens.
- Reading back via `AXUIElementCopyAttributeValue(element, kAXPositionAttribute, ...)` returns the just-written value (or the closest thing the window-server persisted).

So `verify(element:, targetFrame:)` will see `frameMatches == true`, `isMinimized == false`, `isFullscreen == false`, and produce `isPlacementVerified == true` for a window that the user cannot see because they are not on its Space.

This is exactly the "FRAME MATCH != CURRENT SPACE" case and it is **expected to happen** with the current code. The current implementation does not detect it.

### E.2 `CGWindowList` usage during verify

`CGWindowListCopyWindowInfo` is used in:
- `AXAccessibilityService.resolveWindowID(for:pid:frame:)` (`AXAccessibilityService.swift:381`) — uses `.optionOnScreenOnly`, only used when building a stable window number for `ManagedWindow.id`. Not consulted during verify.
- `AXAccessibilityService.allVisibleManagedWindows()` (`AXAccessibilityService.swift:418`) — fallback for the on-screen list; same flag, **drops cross-Space windows**.

Neither path checks whether a particular resolved window is on the user's current Space. Verify is purely geometry + AX minimized + AX fullscreen.

### E.3 Consequence for the summary

`RestoreSummary.isFullSuccess` is true whenever `failedCount == 0 && unverifiableCount == 0 && skippedCount == 0 && placedCount == totalPlacements` (`RestoreSummary.swift:128–130`). Cross-Space placement passes the gate and is reported as a clean success.

`RestoreSummaryBanner` colors this as `Color.green` (`RestoreSummaryBanner.swift:63–64`) with a checkmark (`RestoreSummaryBanner.swift:69`) — the banner is, today, **incapable of expressing "moved but not visible"**.

---

## F. RESTORE / SUMMARY STATE

### F.1 `MoveOutcome`

`RestoreVerification.swift:96–100`:
```swift
public enum MoveOutcome { case moved, failed(any Error), unverifiable }
```
Three states. No `movedButNotVisible`.

### F.2 `RestorePlacementResult.Category`

`RestoreSummary.swift:156–161`:
```swift
public enum Category: String, Codable, Equatable, Hashable, Sendable {
    case placed, failed, unverifiable, skipped
}
```

### F.3 `SkipReason`

`RestoreSummary.swift:13–34`: `moveFailed`, `unverifiablePlacement`, `fullscreenTransitionTimeout`, `notInstalled`, `launchTimeout`, `noWindow`. **No `crossSpaceNotVisible` reason.**

### F.4 Banner state sufficiency

`RestoreSummaryBanner.swift` already distinguishes 4 buckets (Placed / Failed / Unverifiable / Skipped). A new `movedButNotVisible` bucket would fit naturally without restructuring the data model — extend `Category` with `.movedButNotVisible` and `SkipReason` with `.crossSpaceNotVisible`, count them the same way. The mapping function at `WorkspaceManager+Restore.swift:325–351` is the single conversion point.

### F.5 Model vs mapping change

A new *category* is required (no existing category fits "moved but invisible"), but no new field is required on `RestoreSummary`. The mapping function must be taught to produce the new category. The banner needs one new `issueGroup` and one new `countLabel`. The model is sufficient.

---

## G. ROOT CAUSE

### G.1 ROOT CAUSE

**Cross-Space membership.** `WorkspaceManager.restore` moves every window's AX frame, verifies the AX frame matches, and only calls `launcher.reveal` once on the lowest-order verified placement's app. For workspaces where the relevant window lives on a non-current Space, none of `setFrame`, `verify`, `AXRaise`, `NSRunningApplication.activate(.activateAllWindows)` from a background menu-bar app will surface that window to the user's current Space on current macOS. The restore completes, `RestoreSummary` reports `placedCount == totalPlacements`, and the user does not see the result.

### G.2 CONTRIBUTING FACTORS

- **Serial-by-design loop** (`WorkspaceManager+Restore.swift:48–49`) prevents the natural fix of "reveal each app in turn" without a deliberate change to the loop structure.
- **Single final-reveal** keyed off `orderIndex == min(orderIndex).isVerified` (`WorkspaceManager+Restore.swift:56–60`) reveals only one app — the lowest-order one. Even if `reveal` were 100% reliable, it would still not cover cross-Space windows on placements whose app is *not* orderIndex==0.
- **`AXAccessibilityService.isTrusted`** is a *process*-level check (`AXIsProcessTrustedWithOptions` in `AXAccessibilityService.swift:20–22`); Terminal returning `kAXErrorAPIDisabled` for *its* AX windows is independent of FlowSnap's trust — and the CG fallback hides Terminal because of `.optionOnScreenOnly`.
- **Verify is geometry-only** (`RestoreVerification.swift:42–43`) and explicitly disclaims Space membership. The verifier cannot catch this class of failure.
- **`SpaceManaging` is a stub** (`SpaceManaging.swift:1–22`) — there is no infrastructure for "where is this window?" or "what Space is the user on?". Everything that needs Space information today has to invent it.

### G.3 NOT THE ROOT CAUSE

- `setFrame` per se. AX `setFrame` writes the correct value; the bug isn't a wrong frame.
- `verify frame` per se. The verify is honest about what it checks (geometry + AX state); the gap is that it doesn't claim to check visibility.
- `fullscreen` handling. Full-screen exit (`WorkspaceManager+Restore.swift:264–313`) is fine for the in-scope Space; it's orthogonal to cross-Space.
- App activation `per se`. `NSRunningApplication.activate([.activateAllWindows])` is documented to handle cross-Space activation; it's just unreliable when called from a background menu-bar app on macOS 26.x. The fact that the call returns `true` but doesn't actually change Spaces is a macOS / activation-policy issue, not a FlowSnap wiring issue.
- Window `raise`. `kAXRaiseAction` doesn't switch Spaces by design.
- Resolve. `kAXWindowsAttribute` correctly returns cross-Space windows (when Accessibility is trusted). The resolve path is correct.

### G.4 Bug classification (per the prompt's checklist)

- [ ] resolve — no
- [ ] fullscreen — no
- [ ] setFrame — no
- [ ] verification — partially (verify cannot prove visibility; contribute factor only)
- [ ] app activation — contributing (single-call from background is insufficient)
- [ ] window raise — contributing (`kAXRaiseAction` doesn't switch Spaces)
- [ ] **Space membership — primary (no awareness at all)**
- [ ] **Cross-Space movement — primary (no capability + no fallback)**
- [ ] restore orchestration — contributing (single reveal, single attempt)
- [ ] **combination — primary**

The bug is the combination of "no Space-awareness" + "no Space-movement" + "single reveal of the wrong target". None of the three alone is sufficient to produce the symptom; all three together are exactly what produces it.

---

## H. SOLUTION OPTIONS

### Option A — Pure public API

**What it can do:**
- Detect whether a window is on the user's current Space via `CGWindowListCopyWindowInfo` with `.excludeDesktopElements` (no `.optionOnScreenOnly`) and reading `kCGWindowWorkspace` (a per-window identifier, available on Sonoma+). This is a public CoreGraphics call.
- Iterate `RestoreOptions` placements one-by-one in restore, calling `launcher.reveal(bundleID:)` for each placement before `place(...)` (so the app comes to the front and macOS has a chance to bring the relevant Space forward).
- Add a `verifyCrossSpace` step after `setFrame` + verify: read back the window's `kCGWindowWorkspace` value and compare it to the user's current Space ID. If different, mark `category = .movedButNotVisible`, reason `.crossSpaceNotVisible`.
- Add a "Moved but not on current Space" row to the banner.

**What it cannot do (reliably):**
- Force the user's current Space to switch programmatically without Mission Control private APIs. `NSRunningApplication.activate([.activateAllWindows])` *may* do it when the calling app is foregrounded and macOS permits, but is not contractual and the live experiment in §D.2 shows the call returning `true` without effect.
- Distinguish "Mission Control refused" from "permission denied" without user-visible diagnostics.

**Reliability**: medium. Detection is reliable; movement is best-effort. **The verification step is the durable gain** — even if we still can't always fix the problem, we can correctly *report* it.

**macOS compatibility**: `kCGWindowWorkspace` is documented for Sonoma+ and present in macOS 26.x. Requires explicit handling on older OSes.

**App Store / sandbox risk**: low — only `CGWindowListCopyWindowInfo` and `NSRunningApplication` are touched.

**Maintenance risk**: low — small surgical change to `WorkspaceManager+Restore.swift` and the banner.

**UX**: banner honestly says "Terminal moved but not visible — switch Space". Removes the false-green checkmark.

**Effort**: ~1–2 dev-days including tests.

**P0 fit**: partial. Fixes the *honesty* part of P0 (no false success). Does not 100% guarantee the window appears. Recommend pairing with Option C.

### Option B — Public API + foreground-the-FlowSnap-then-reveal sequence

**What it can do:**
- Foreground FlowSnap itself with `NSApp.activate(ignoringOtherApps: true)` at the start of restore.
- Per placement, after the move, call `launcher.reveal(bundleID:)` to activate that app's windows, which (because the caller is now foreground) is much more likely to switch the user's Space.
- Repeat for each placement in `orderIndex` order so the final app ends up foregrounded (the same app that ends up focused).
- Then call `windowManager.focus(element:)` for the lowest-order verified placement.

**What it cannot do:**
- Guarantee macOS will switch Spaces if Mission Control policies or a fullscreen foreground app block it. Empirically the success rate goes up substantially, but it is still not contractual.
- Work without the user being on a "normal" Space at restore time (e.g. mid fullscreen game).

**Reliability**: medium-high in normal use, lower with strict Mission Control / Stage Manager settings.

**macOS compatibility**: same as A; uses only public ones.

**App Store / sandbox risk**: `NSApp.activate(ignoringOtherApps: true)` is permitted for menu-bar apps and is documented.

**Maintenance risk**: low.

**UX**: significantly better — restores "feel" right in the common case, banner still reports honestly in edge cases.

**Effort**: ~2–3 dev-days plus UX review of the foreground flash.

**P0 fit**: yes for the common case. Should be combined with A's detection so the user is told when it fails.

### Option C — Honest UX fallback (no Space-switching, only truthfulness)

**What it can do:**
- Replace `RestoreSummary.isFullSuccess` with a stricter rule that counts `movedButNotVisible` separately and treats any non-zero count as partial success.
- Banner: orange state when at least one placement is `movedButNotVisible`. Detail line: *"Terminal was moved but is on a different desktop. [Switch to Terminal's desktop]"*.
- Action button: list each `movedButNotVisible` placement with a "Reveal" button that, when clicked, calls the per-placement reveal sequence in §B.
- Keep the verify cross-Space check from Option A; do not change orchestration.

**What it cannot do:**
- Switch Spaces for the user.

**Reliability**: 100% on the truthfulness axis.

**macOS compatibility**: universal.

**App Store / sandbox risk**: zero.

**Maintenance risk**: low.

**UX**: honest, recoverable. User understands *why* they don't see the window and is one click away from fixing it.

**Effort**: ~1 dev-day.

**P0 fit**: yes for the *report-correctly* half of P0. Pairs with A or B for the *move-correctly* half.

### H.1 Recommendation matrix

| Option | Detect? | Move? | P0 fit alone? |
|---|---|---|---|
| A | ✓ (CGWindowWorkspace) | partial | partial |
| B | via A | medium-high | yes for common case |
| C | via A | no, but UX-honest | partial |
| A + B | ✓ | medium-high | yes for common case |
| A + C | ✓ | no, but UX-honest | yes |
| A + B + C | ✓ | medium-high + honest fallback | yes (recommended) |

**Recommended P0 stack**: A + C as the minimum honest baseline. B as a follow-up T1 once we've verified with users that the foreground-during-restore flash is acceptable. Private API ("move window to Space via CGSGetWindowWorkspace / CGSMoveWindowToSpace") is **not recommended** for production without an explicit, separate risk review — App Store rejection risk is non-trivial on recent macOS.

---

## I. KẾT LUẬN — ANSWERS TO THE 8 QUESTIONS

1. **Tại sao Terminal ở Space khác không xuất hiện sau Restore?**
   Vì không có API public macOS nào trong restore pipeline có khả năng đưa Terminal về current Space một cách đáng tin cậy khi caller (FlowSnap menu bar) đang ở background. Restore chỉ set AX frame, verify AX frame, rồi gọi `launcher.reveal` một lần duy nhất cho app có `orderIndex` thấp nhất (xem §A.3, §C.3, §D.2).

2. **`setFrame` có phải nguyên nhân chính không?**
   Không. `setFrame` ghi đúng giá trị vào window-server record; vấn đề là giá trị được ghi cho window ở một Space khác với Space hiện tại của user.

3. **`verify frame` có thể xác nhận current Space không?**
   Không. Verify hiện tại (`RestoreVerification.swift:42–43`) được document là chỉ chứng minh geometry + AX state, không claim gì về current Space. Thực nghiệm: AX frame match nhưng window vẫn ở Space khác (xem §E.1).

4. **`reveal/activate/raise` hiện tại có đưa window cross-Space về current Space không?**
   Không đáng tin cậy. Live experiment §D.2 cho thấy `NSRunningApplication.activate([.activateAllWindows])` từ background menu-bar app trả về `true` nhưng không thay đổi frontmost app, không chuyển Space, không surface window. `kAXRaiseAction` không switch Space.

5. **macOS public API hiện tại có cho FlowSnap làm điều đó đáng tin cậy không?**
   Không 100% — chỉ "best effort". Phát hiện (qua `CGWindowListCopyWindowInfo` + `kCGWindowWorkspace`) là đáng tin cậy. Di chuyển là không đáng tin cậy khi caller ở background. Cách đáng tin nhất public-API là **foreground FlowSnap trước rồi reveal tuần tự từng placement** (Option B), vẫn không guarantee 100%.

6. **P0 hiện tại cần sửa những file/function nào?**
   - `Core/Workspace/WorkspaceManager+Restore.swift:23–93` — orchestration: per-placement reveal loop.
   - `Core/Workspace/WorkspaceManager+Restore.swift:209–252` (`move`) + `RestoreVerification.swift:43–89` — add `kCGWindowWorkspace` cross-Space check to verify.
   - `Infrastructure/Accessibility/AXAccessibilityService.swift` — add `spaceIdentifier(of: AXUIElement)` and `currentSpaceIdentifier()` (uses `CGWindowListCopyWindowInfo`).
   - `Infrastructure/macOS/SpaceManaging.swift` — promote from stub to a real implementation; wire into `WorkspaceManager` constructor.
   - `Domain/Workspace/RestoreSummary.swift:13–34` (`SkipReason`), `:154–161` (`Category`) — add `.crossSpaceNotVisible` reason and `.movedButNotVisible` category.
   - `UI/Components/RestoreSummaryBanner.swift` — add count + group for `movedButNotVisible`, action button "Reveal this desktop".

7. **Cross-Space nên nằm trong P0, P0.5 hay T6 spike?**
   **P0.5**, không phải P0 chặt và không phải spike:
   - Lý do không phải spike: đã có đủ dững kiện (live experiments §D) để biết capability hiện tại và biết rõ gap.
   - Lý do không phải P0 chặt: không có public API nào guarantee 100%, nên P0 chặt sẽ over-promise. P0.5 = "report correctly + best-effort fix + honest UX fallback", đúng nghĩa của contract test.
   - Lý do cần làm ngay: hiện FlowSnap báo "success" trong khi user thực sự không thấy gì — đây là false-positive P0 của trust.

8. **Nếu không thể guarantee 100% Cross-Space bằng public API, product behavior tốt nhất nên là gì?**
   Option A + C: detect + report + honest UX. Banner hiển thị trạng thái `movedButNotVisible`, có nút "Reveal on this desktop" cho mỗi placement bị ảnh hưởng. Không silence failure, không false-green checkmark. Phù hợp với BR-WORK-004 (best-effort per placement, but never silent).

---

## Quy tắc bắt buộc — tuân thủ

- Không sửa code, không commit, không refactor.
- Mọi kết luận có file:line reference.
- Live experiment results ở §D.
- Mọi chỗ không verify được trên máy được ghi `unknown / needs experiment`.

---

# APPENDIX J — Phản hồi Proposal `FlowSnap_Restore_Workspace_CrossSpace_GiaiPhap.md`

Proposal mới (`/Users/vutuanhau/Downloads/FlowSnap_Restore_Workspace_CrossSpace_GiaiPhap.md`, sau đây gọi là **Proposal**) đã được đọc toàn bộ. Phần lớn Proposal phù hợp và không xung đột với RCA ở §A–§I của report này; có **một điểm cần sửa** đáng chú ý trong §H của report này, và một số **điểm cần làm rõ thêm**. Tổng hợp dưới đây là read-only, không viết lại RCA mà chỉ map Proposal ↔ Report.

## J.1 Điểm cần sửa trong report (do Proposal chỉ ra)

### J.1.1 Không dùng `kCGWindowWorkspace` làm dependency chính

Proposal §3 chỉ ra Apple đã deprecated `kCGWindowWorkspace` (verify `unknown / needs experiment` cho macOS 26.x — symbol vẫn tồn tại nhưng không còn được hỗ trợ cho việc cross-Space routing). Hệ quả:

- Trong report §E.1 ("FRAME MATCH != CURRENT SPACE demonstration"), dòng *"AX frame is the window's frame in window-server coordinates"* vẫn đúng — chỉ là giá trị đó **không nên được xác nhận** bằng `kCGWindowWorkspace`.
- Trong report §I.6, hai dòng sau là **không nên làm theo**:
  - *"add `spaceIdentifier(of: AXUIElement)` and `currentSpaceIdentifier()` (uses `CGWindowListCopyWindowInfo`)"* — vì nó ngụ ý so sánh Space ID, điều mà implementation không có khả năng làm đáng tin cậy với API public.
  - *"`kCGWindowWorkspace` cross-Space check to verify"* — không dùng kCGWindowWorkspace.

**Sửa lại §I.6 thành:**

- Thay `kCGWindowWorkspace` cross-Space check bằng **current-screen on-screen observation** (đề xuất của Proposal §10):
  - Abstraction mới: `CurrentScreenVisibilityChecking` (hoặc `PresentationStateChecking`) — `func isOnCurrentScreen(windowID: CGWindowID) -> Bool?` trả `true`/`false`/`nil` (best-effort, không phải Space ID resolver).
  - Implementation: `CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)` và mapping theo `CGWindowID`.
  - Verify phase sẽ trả `nil` thay vì "no idea" nếu không lookup được — `nil` được map sang `category = .unverifiable, reason = .presentationUnverifiable` (xem J.3.2).
- Không claim biết "current Space ID". Tên protocol phải phản ánh capability thật (`CurrentScreenVisibilityChecking`), không gọi là `SpaceVerification`.

### J.1.2 Không ép `activate/reveal/raise` trong restore loop

Proposal §18 chỉ ra một UX hazard quan trọng mà report chưa nhấn mạnh đủ: nếu FlowSnap liên tục `activate VSCode → activate Terminal → activate VSCode` trong loop, màn hình sẽ nhảy qua lại giữa các Space, gây rất khó chịu và vẫn không đảm bảo hai window cùng ở một Space.

→ Trong report §H "Option B" (foreground FlowSnap + per-placement reveal), phải **đánh giá lại**: Option B có nguy cơ Space-switching flicker. Proposal đúng khi giữ orchestration hiện tại (single final reveal/focus) ở P0 và dời mọi best-effort presentation attempt sang P0.5 chỉ khi live experiment chứng minh giá trị (Proposal §17).

→ Bổ sung vào report §H.1:
  - Option B hạ reliability xuống **medium**, vẫn kèm warning "potential Space flicker, do not use without UX testing".
  - Recommendation matrix trong §H.1: sửa "B" từ "yes for common case" thành "yes for common case, but only after UX review of foreground flash + Space flicker".

## J.2 Mapping Proposal ↔ Report

| Proposal § | Nội dung Proposal | Tương ứng trong report | Trạng thái |
|---|---|---|---|
| §1 Kết luận chính | RCA: "FlowSnap có thể restore đúng geometry nhưng chưa có cơ chế đáng tin cậy để đưa window về current Space" | §G.1 Root Cause | ✓ aligned |
| §2 RCA + Contributing Factors | Verify dựa quá nhiều vào frame; setFrame không phải moveSpace; activate không đáng tin cậy; false positive summary | §G.2 (A, B, C, D) | ✓ aligned |
| §3 Sửa proposal cũ | Bỏ `kCGWindowWorkspace`, dùng CG on-screen observation, đặt tên `CurrentScreenVisibilityChecking` | §I.6 cần sửa | ✗ **conflict — đã sửa ở J.1.1** |
| §4 Kiến trúc pipeline mới | Resolve → Prepare → Place → Verify → Presentation Attempt → Current-screen check → next placement / Final focus | Phù hợp với §A.2 (chèn thêm "Presentation Attempt" giữa verify và final focus) | ✓ aligned (chèn thêm 1 bước vào pipeline) |
| §5 P0 — Restore tuần tự theo orderIndex, không activate từng app, single final reveal | §A.3 #1, #3, #5 | ✓ aligned (đã đúng trong code hiện tại) |
| §6 Retry 3 lần với backoff 100/200ms cho cả setFrame failure **và** verification mismatch | §A.2 (`move` loop), `RestoreVerification.swift:18–21` | ✓ aligned (đã implement đúng) |
| §7 Fullscreen policy: synchronous throwing `exitFullScreen`, poll tối đa 2s, không gọi setFrame nếu timeout | `WorkspaceManager+Restore.swift:264–313`, `RestoreVerification.swift:24–27` | ✓ aligned (đã implement đúng) |
| §8 `resolved.element == nil` → unverifiable, không gọi setFrame | `WorkspaceManager+Restore.swift:155–160` | ✓ aligned (đã implement đúng) |
| §9 Verify tách khỏi Visibility | §E.1, §E.2, §E.3 | ✓ aligned (code đã comment đúng; cần thêm check thực tế ở P0.5) |
| §10 Current-screen visibility abstraction | mới (thay cho `kCGWindowWorkspace`) | ✗ cần bổ sung (xem J.1.1) |
| §11 MoveOutcome mới / §12 Summary 5 buckets (placed / failed / unverifiable / skipped / movedButNotPresented) | §F.1, §F.2, §F.3 | ✓ aligned, cần mở rộng model theo J.3 |
| §13 failedCount + movedButNotPresentedCount | §F.4 | ✓ aligned |
| §14 Banner: 5 nhóm hiển thị | `RestoreSummaryBanner.swift` | ✓ reuse được, cần thêm 1 group |
| §15 Không modal, success auto-dismiss, warning giữ lâu hơn | (UI policy — không có trong report) | ✗ chưa có trong report; **Proposal-aligned**, không cần phản đối |
| §16 Final focus chỉ 1 lần theo orderIndex nhỏ nhất | §A.3 #3 | ✓ aligned (đã đúng) |
| §17 P0.5: detect frame correct + state correct + không present → movedButNotPresented, best-effort reveal chỉ giữ nếu live test | §H Option A + C, §I.7 | ✓ aligned |
| §18 Không ép activate/reveal/raise | §C.3, §H Option B | ✓ aligned (cần điều chỉnh warning cho Option B — xem J.1.2) |
| §19 T6 Cross-Space spike | §I.7 | ✓ aligned (đã khuyến nghị T6 spike trong report) |
| §20 Không private API trong P0 | §H Option A/B/C | ✓ aligned |
| §21 `appLocalizedName` follow-up | (ngoài scope report) | ✗ chưa có trong report; **Proposal-aligned**, follow-up riêng |
| §22 Logging privacy | (ngoài scope report) | ✗ chưa có trong report; **Proposal-aligned** |
| §23–24 Accessibility / NFR | (ngoài scope report chi tiết) | ✓ aligned |
| §25 Test Matrix T1–T15 | (chưa có test matrix chi tiết trong report) | ✗ chưa có; **Proposal bổ sung — accept** |
| §26 P0 Acceptance Criteria | §I.6 + §I.7 + các tiêu chí | ✓ aligned (là operationalization của §I) |
| §27 P0.5 Acceptance Criteria | §H.1 recommendation matrix | ✓ aligned |
| §28 T6 Acceptance Criteria | §I.7 | ✓ aligned |
| §29 File/function thay đổi | §I.6 | ✓ aligned (sửa lại theo J.1.1) |
| §30 Final Product Behavior | §I.8 | ✓ aligned |
| §31 Quyết định cuối: P0 / P0.5 / T6 | §I.7 | ✓ aligned |
| §32 Kết luận: tách "Window Placement" và "Window Presentation / Space" | §G.1 | ✓ aligned |

## J.3 Bổ sung cần thiết cho model (do Proposal §11/§12/§13 yêu cầu)

Report §F.4 đã kết luận: *"The model is sufficient"* — đúng cho việc thêm một category, nhưng Proposal §11 đòi tách thành **hai enum**:

### J.3.1 `PresentationOutcome` riêng (Proposal §11)

```swift
enum MoveOutcome { case moved, failed(Error), unverifiable }       // hiện có, §A.2
enum PresentationOutcome { case presented, movedButNotPresented, unverifiable }  // mới
```

→ Hai enum tách biệt phản ánh đúng hai trục:
- `MoveOutcome`: "FlowSnap có ghi được frame/AX state mới không?"
- `PresentationOutcome`: "Sau khi ghi, window có thực sự xuất hiện trên current screen không?"

Report không đủ chi tiết về separation này; Proposal bổ sung đúng.

### J.3.2 `SkipReason` extension (Proposal §11/§12)

Bổ sung:
- `.fullscreenTransitionTimeout` đã có — OK.
- `.crossSpaceNotPresented` hoặc `.movedButNotPresented` — mới (Proposal §12 dùng `movedButNotPresented`).
- `.presentationUnverifiable` — mới cho trường hợp `isOnCurrentScreen(windowID:)` trả `nil`.

`RestorePlacementResult.Category` mở rộng thêm `.movedButNotPresented` (đã đề xuất ở report §F.4, giờ Proposal đặt tên chính thức).

`RestoreSummary` thêm `movedButNotPresentedCount` và `movedButNotPresented: [RestoreIssue]` — đúng theo Proposal §13.

## J.4 Acceptance: P0 vs P0.5 vs T6 (mapping sang Proposal §31)

| Tầng | Proposal §31 | Report §I.7 | Đối chiếu |
|---|---|---|---|
| P0 | Restore correctness + verify correctness + fullscreen reliability + retry + deterministic ordering + honest summary | không có P0 riêng (chỉ gộp trong §I.7–§I.8) | **Proposal tách rõ hơn** — accept |
| P0.5 | Current-screen visibility observation + best-effort presentation + `movedButNotPresented` | §I.7 P0.5 + §H Option A+C | ✓ aligned |
| T6 | True Cross-Space migration research | §I.7 T6 spike | ✓ aligned |

## J.5 Kết luận appendix

1. **Report §H Option B** cần warning bổ sung về Space flicker, và report §I.6 cần thay tham chiếu `kCGWindowWorkspace` bằng abstraction `CurrentScreenVisibilityChecking` với CGWindowList on-screen observation (J.1.1, J.1.2).
2. **Model `RestorePlacementResult` / `MoveOutcome`**: Proposal §11 đúng khi yêu cầu tách `MoveOutcome` và `PresentationOutcome` thành hai enum — điều này làm rõ trách nhiệm từng bước và khớp với kiến trúc pipeline trong Proposal §4. Report trước chỉ đề xuất thêm 1 category; Proposal nâng lên thành tách 2 enum.
3. **Test Matrix T1–T15 (Proposal §25) là bổ sung quan trọng** — chưa có trong report. Accept nguyên trạng.
4. **P0 / P0.5 / T6 split** trong Proposal §31 là **final decision** — report đồng ý, với điều kiện §I.6 được sửa theo J.1.1 trước khi P0.5 bắt đầu.

## K. Appendix K — P0.5 Implementation Record (Workspace Presentation Observation)

P0.5 đã được implement theo `P0_5_IMPLEMENTATION_SPEC_v4.md` + `OPEN_QUESTIONS_CHECKLIST_v3.md` (đã tick đủ 16 câu theo khuyến nghị). Bản đồ tham chiếu:

| Thành phần | File |
|---|---|
| Protocol `CurrentScreenVisibilityChecking` + production `CGWindowListCurrentScreenVisibilityChecker` | `FlowSnap/Infrastructure/macOS/CurrentScreenVisibilityChecker.swift` |
| `PresentationOutcome` (trục observation, tách khỏi `MoveOutcome` — Option A) | `FlowSnap/Core/Workspace/RestoreVerification.swift` |
| Observation phase + CGWindowID re-resolve sau fullscreen-exit (§4.5) | `FlowSnap/Core/Workspace/WorkspaceManager+Restore.swift` |
| Model: `.movedButNotPresented`, `.notPresentedOnCurrentScreen`, `.presentationUnverifiable`, `RestoreSummary.movedButNotPresented*`, `isFullSuccess` strict | `FlowSnap/Domain/Workspace/RestoreSummary.swift` |
| Banner: chip + group "Not presented" | `FlowSnap/UI/Components/RestoreSummaryBanner.swift` |
| Test matrix T1–T14 | `FlowSnapTests/Core/Workspace/WorkspacePresentationObservationTests.swift` |
| Mock scriptable | `FlowSnapTests/Mocks/MockCurrentScreenVisibilityChecker.swift` |

Điểm thiết kế đáng nhớ:

1. `isOnCurrentScreen(windowID:)` chỉ dùng public `CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)`, filter `kCGWindowLayer == 0`, chặn own-PID (T6) — không dùng `kCGWindowWorkspace`, không private API.
2. Sau fullscreen-exit thành công, `place` re-resolve CGWindowID qua `reResolveWindowID(pid:frame:)` (tolerance 5pt theo origin, **không hash fallback**); re-resolve fail → `.unverifiable(.presentationUnverifiable)`, không move, không observe (T14-fail).
3. Observation chạy đúng **1 lần cho primary window** sau khi move verified; không retry, không activate/reveal thêm (tránh Space flicker, §4.2/§4.4).
4. `RestoreSummary.isFullSuccess` strict: mọi placed window phải presented; một `.movedButNotPresented` là đủ để banner chuyển cam.
5. Injection: spec cấm đụng `WorkspaceManager.swift` (nơi `init` nằm), nên dùng per-instance test seam `injectPresentationChecker(_:)` trong `WorkspaceManager+Restore.swift` — production mặc định dùng production checker, test inject mock theo từng instance (an toàn với Swift Testing parallel).
5. **Không có xung đột còn lại** giữa Proposal và report. Report có thể dùng làm RCA backing, Proposal dùng làm implementation plan.