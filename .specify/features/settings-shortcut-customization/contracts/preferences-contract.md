# Contract: Preferences & Shortcut Persistence

## Keys in `UserDefaults`

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `windowGap` | `Double` | `4.0` | Gap between windows (0, 4, 8, 12, 16) |
| `defaultRatio` | `String` | `"equal"` | Default split ratio |
| `customShortcuts` | `Data` (JSON) | `nil` (uses defaults) | Encoded `[String: KeyboardShortcut]` dictionary |
| `isDragToSnapEnabled` | `Bool` | `true` | Enables or disables drag-to-snap |
| `dragPreviewDwellDelay` | `Double` | `0.05` | Dwell time before showing snap preview HUD |
| `launchAtLogin` | `Bool` | `false` | Launch FlowSnap on macOS user login |

## Serialization Format
```json
{
  "leftHalf": {
    "keyCode": 123,
    "carbonModifiers": 4352
  },
  "maximize": {
    "keyCode": 126,
    "carbonModifiers": 4352
  }
}
```
