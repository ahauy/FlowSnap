# 📖 User Guide: Per-App Window Policies & Smart Floating Stack (US-WORK-014)

> **Target Audience:** Every FlowSnap Mac User (Engineers, Designers, Writers, Researchers & Multitaskers)  
> **Applies to:** FlowSnap 1.0+ (macOS 14 Sonoma & macOS 15 Sequoia)  
> **Last Updated:** September 3, 2026

---

## 🎯 1. What This Feature Does (in Plain English)

Different applications serve different purposes. While working on a coding project or writing a document, you typically want your primary editor and reference browser locked into a neat split-screen layout. But what happens when you open **Telegram**, **Slack**, a **calculator**, or **Spotify**?

Without per-app policies:

- Opening a chat app either forces your neat split-screen into disarray or launches on a completely different screen.
- Dismissing an auxiliary window leaves you fumbling with the mouse to click back into your main editor.
- Moving between an external 4K monitor and your MacBook screen can cause remembered windows to open off-screen in invisible coordinates.

**FlowSnap's Per-App Window Policies & Smart Floating Stack** solves all of this:

```
┌──────────────────────────────────────────────────────────────────────────┐
│                      FLOWSNAP APP RULES & STACK                          │
├─────────────────────────────────────┬────────────────────────────────────┤
│ 💬 Floating Window Immunity         │ 🔄 Smart Focus Restoration         │
│ • Floating apps (Telegram, Slack)   │ • When you close or hide a         │
│   stay above without resizing or     │   floating app, focus instantly    │
│   disrupting tiled windows beneath   │   returns to your working window   │
├─────────────────────────────────────┼────────────────────────────────────┤
│ 📐 Assigned Canonical Layouts       │ 🖥️ Clamped Remembered Positions    │
│ • VS Code always snaps Left 70%     │ • Spotify remembers where it was,  │
│ • Auto-applied immediately on open  │   safely clamped on active screens │
└─────────────────────────────────────┴────────────────────────────────────┘
```

---

## ⚙️ 2. How to Configure App Rules in Settings

1. Click the **FlowSnap icon** in the macOS menu bar and select **Preferences...** (or press `⌘,`).
2. Navigate to the **App Rules** tab.
3. You will see your configured applications list.
4. Click **Add Application** in the bottom bar to define a new rule:
   - Enter the **Application Name** (e.g., `Slack`) or click a suggestion pill.
   - Enter the **Bundle Identifier** (e.g., `com.tinyspeck.slackmacgap`).
   - Select the desired **Policy**:
     - **Floating**: Exempt from auto-tiling snaps; acts as an overlay tool.
     - **Remember Position**: Automatically restores the exact window position and size last closed.
     - **Assigned Layout**: Snaps the window to a designated screen partition (e.g., _Left Half_, _Left 70%_, _Maximize_).
     - **Current Space**: Default native placement on the active screen.
   - Click **Save Rule**.

---

## 🧪 3. Verifying the Features

### Scenario A: Floating Chat Window & Focus Restoration

1. Open your code editor and browser side-by-side in FlowSnap.
2. Ensure **Telegram** or **Slack** is configured with the **Floating** policy.
3. Open Telegram and type a message. Notice that your editor and browser beneath do not resize or shift.
4. Press `⌘W` to close or `⌘H` to hide Telegram.
5. **Notice that keyboard focus automatically returns to your code editor without needing a mouse click.**

### Scenario B: Multi-Monitor Safe Remembered Position

1. Configure an application (e.g., Spotify) with **Remember Position**.
2. Position Spotify on your external monitor and close the window.
3. Disconnect your external monitor and reopen Spotify on your laptop screen.
4. **Spotify will open safely inside your laptop's screen boundaries — never lost off-screen in disconnected coordinates.**

---

## 💡 4. Frequently Asked Questions (FAQ)

### Q: Does FlowSnap use private macOS APIs to keep windows floating?

**A:** No. FlowSnap adheres 100% to Apple's public macOS APIs. Floating windows maintain standard native window levels, are exempted from auto-tiling grids, and participate in FlowSnap's smart focus stack.

### Q: What happens if an app has no custom rule?

**A:** If an app does not have a specific rule configured in the App Rules tab, it uses the default `.currentSpace` policy (opening cleanly on your active display).
