# 📖 User Guide: App Launch Observer & Current Space Policy (US-WORK-013)

> **Target Audience:** Every FlowSnap Mac User (Engineers, Designers, Writers, Researchers & Multitaskers)
> **Applies to:** FlowSnap 1.0+ (macOS 14 Sonoma & macOS 15 Sequoia)
> **Last Updated:** September 2, 2026

---

## 🎯 1. What This Feature Does (in Plain English)

If you've ever launched an app on your Mac and watched it pop up on a *different* Space than the one you're currently looking at — this is the feature that fixes it.

Before FlowSnap's App Launch Observer, macOS frequently routed newly launched windows to whichever Space was last in focus (often a full-screen app you switched away from minutes ago). FlowSnap now quietly listens for every app launch and **forces the new window to appear on the Space and display you are currently looking at**.

You don't need to configure anything. It just works.

```
┌──────────────────────────────────────────────────────────────────────────┐
│                       FLOWSNAP LAUNCH ENGINE                              │
├─────────────────────────────────────┬────────────────────────────────────┤
│ 🔍 Always-On Launch Detection        │ 🎯 Current-Space Anchoring         │
│ • Listens to macOS launch events     │ • Repositions new window to       │
│ • Detects first window within 10s    │   your current display's frame    │
│ • Auto-cleans up when done            │ • No Space switching triggered     │
└─────────────────────────────────────┴────────────────────────────────────┘
```

### Key Things To Know

1. **It runs automatically** — no menu, no button, no setting you have to flip. The moment FlowSnap is running, every app you launch is anchored to the Space you're on.
2. **It's invisible when working** — your CPU stays at idle. There are no polling loops; FlowSnap waits for macOS to send it a notification.
3. **It's safe for headless apps** — apps that never draw a window (background daemons, Gatekeeper-blocked apps) are detected but left alone after 10 seconds.
4. **It uses 100% public Apple APIs** — no private system calls. The App Store-friendly approach.

---

## 🧪 2. How to Verify It's Working

### Test 1: Launch an App While Another Space Is "Active"

This is the single test that proves the feature works end-to-end:

1. Make sure FlowSnap is running (look for its icon in the menu bar).
2. Switch to **Space 2** by pressing `⌃→` twice (so you have at least two Spaces).
3. On Space 2, open a full-screen app (e.g. Terminal → View → Enter Full Screen).
4. From your **other hand**, swipe back to **Space 1** using `⌃←`.
5. **Double-click any third-party app in Dock** (Notes, Safari, anything).
6. **The new app should appear on Space 1 — the Space you are currently looking at — not on Space 2 where the full-screen Terminal lives.**

If the new app lands on Space 1, the feature is working correctly.

### Test 2: Verify the Frame Matches the Display

1. Open an app from Dock (say, Safari).
2. The Safari window should occupy the **entire visible area** of your current display (not a tiny default frame, not an off-center position).
3. If your menu bar takes 25 px at the top, Safari's top edge should be **25 px below the screen top**, not at the very top.

### Test 3: Check the Application Logs

If you want to *see* the launch observer working:

1. Open **Console.app** (from `/Applications/Utilities/`).
2. In the search bar, type `FlowSnap`.
3. Filter to your Mac (the "device" selector at the top).
4. Launch a few apps from Finder or Dock.
6. You should see no error messages and (if you enabled debug logging) one `[WindowPolicyManager]` line per window that was repositioned.

---

## 🛠 3. How to Check Console.app Logs If a Launch Is Misrouted

If an app launches and lands on the wrong Space despite FlowSnap running, walk through this checklist:

### Step 1: Confirm FlowSnap Has Accessibility Permission

1. Open **System Settings → Privacy & Security → Accessibility**.
2. Confirm **FlowSnap** is listed and the toggle is ON.
3. If it's OFF, click the lock, toggle FlowSnap ON, and restart FlowSnap.

> **Why this matters:** Repositioning a window requires Accessibility permission. Without it, FlowSnap can detect launches but cannot move windows.

### Step 2: Check Console.app for Errors

1. Open **Console.app**.
2. Click **Start** to begin streaming live logs.
3. In the filter, type `FlowSnap` and look for lines like:
   - `[WindowPolicyManager] applyPolicy failed for window N: windowNotFound`
     → The window's AX element was not yet resolvable when FlowSnap tried to move it (rare race condition below the 10 s timeout).
   - `[WindowPolicyManager] applyPolicy failed for window N: cannotComplete`
     → macOS denied the frame write (usually because the window is on a different Space than the active one at the exact moment of the write).
4. If you see one of these, relaunch the app. The next launch will succeed because the observer is fresh.

### Step 3: Restart FlowSnap

If launches are still misrouted:

1. Quit FlowSnap from the menu bar icon → **Quit FlowSnap**.
2. Relaunch it from `/Applications`.
3. Try the test from §2 again.

---

## ⚠️ 4. Known Limitations

### Headless Apps Time Out at 10 Seconds

Apps that launch but **never create a window** (background daemons, Gatekeeper-blocked apps, command-line tools invoked via Finder) will have their observer released after 10 seconds. This is intentional — FlowSnap does not waste CPU watching pids that will never draw.

**What you'll see:** nothing. The app launches normally; FlowSnap simply stops watching after 10 s.

### First Launch May Require Accessibility Permission

The very first time you run FlowSnap after install, macOS will prompt you to grant Accessibility permission. If you declined the prompt, you must enable it manually in **System Settings → Privacy & Security → Accessibility**. Without it, FlowSnap can detect launches but cannot reposition windows.

### Some macOS Window Types Cannot Be Repositioned

macOS reserves certain window types (alert dialogs, modal sheets, system windows) from programmatic repositioning. FlowSnap will silently skip them. You will see `[WindowPolicyManager] applyPolicy failed` in the log, but the alert/dialog will appear in its default macOS position — which is correct behaviour.

---

## 🖼 5. Where to See This Feature in the Settings UI

This is a **menu bar / behaviour feature** — there is no dedicated primary UI surface for it. The feature is wired through FlowSnap's **Settings → Applications** tab, which is reserved for the upcoming **Per-App Rules** editor (US-WORK-014) where you will be able to override the default `.currentSpace` policy per bundle ID.

> **Note:** A live screenshot of the Settings → Applications tab mockup is queued for the US-WORK-014 release. Until then, the **Settings → Window Rules** tab in your installed build is the closest visible surface. You can also confirm the feature is active by reviewing the `docs/features/app-launch-current-space-policy/README.md` technical documentation.

---

## 📚 6. Learn More

- **Technical Documentation**: [docs/features/app-launch-current-space-policy/README.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/features/app-launch-current-space-policy/README.md)
- **Architecture Decision Record**: [adr/0008-application-observing-seam.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/adr/0008-application-observing-seam.md)
- **Feature Specification**: [.specify/features/app-launch-current-space-policy/spec.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/app-launch-current-space-policy/spec.md)

---

## ❓ 7. FAQ

**Q: Will this make my Mac slower?**
A: No. FlowSnap waits for macOS to send it notifications — it does not poll. CPU usage from this feature is effectively 0% in steady state.

**Q: What happens if FlowSnap is not running?**
A: macOS uses its own (worse) routing — new apps may land on the wrong Space. FlowSnap needs to be running for the current-space behaviour to apply.

**Q: Can I turn off the current-space behaviour for a specific app?**
A: Not in this release. The "Per-App Rules" UI ships in US-WORK-014. For now, every app uses the default `.currentSpace` policy.

**Q: Will this work with multiple displays?**
A: Yes. New windows appear on the display that was active when you launched the app (not necessarily the display with the menu bar).

**Q: Does this use private macOS APIs that might break in a future macOS update?**
A: No. FlowSnap uses 100% public Apple APIs (`NSWorkspace` notifications, `AXObserver`, `AXUIElement`). The CI gate `scripts/audit-no-private-apis.sh` enforces this on every build.

**Q: My new app window is on the wrong Space. What now?**
A: Walk through §3 above. In 99% of cases, granting Accessibility permission resolves it. If not, check Console.app logs and file a bug with the `[WindowPolicyManager]` log line.