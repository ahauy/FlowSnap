# Risk Register: Settings UI & Shortcut Customization (US-SNAP-010)

| Risk ID | Description | Severity | Likelihood | Mitigation Strategy |
| :--- | :--- | :--- | :--- | :--- |
| **RISK-SET-001** | User records hotkey conflicting with essential macOS system hotkey (e.g. `⌘Space`, `⌘Tab`). | High | Low | Disallow single `⌘` key shortcuts without modifiers; filter out reserved OS combinations; warn on registration failure via Carbon `OSStatus` code. |
| **RISK-SET-002** | Stored shortcut format corruption in `UserDefaults`. | Medium | Low | Use strongly typed Codable JSON with version fallback; reset to defaults if deserialization fails. |
| **RISK-SET-003** | Dynamic hotkey re-registration during active key repeat causes race condition. | Low | Low | Perform `unregisterAll()` and atomic re-registration on `@MainActor` with thread-safe lock in `GlobalHotkeyManager`. |
| **RISK-SET-004** | Accidental clearing of all shortcuts. | Medium | Low | Confirmation dialog or explicit "Restore Defaults" button with clear visual feedback. |
