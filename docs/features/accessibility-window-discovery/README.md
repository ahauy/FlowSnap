# Feature: Accessibility & Focused Window Discovery (US-SNAP-001)

- **Feature Slug**: `accessibility-window-discovery`
- **Epic**: `EPIC 01: Accessibility Permission & Focused Window Discovery`
- **Sprint**: Sprint 1
- **Status**: Completed & Verified

---

## 1. Background & Business Value

FlowSnap is a native macOS window management utility. Because macOS sandboxes third-party applications and does not expose cross-application window control via AppKit directly, FlowSnap leverages the public macOS Accessibility API (`AXUIElement`).

This module provides the core system integration:

1. **Zero-Friction Permission Onboarding**: Checks `AXIsProcessTrustedWithOptions`, guides users directly to `Privacy & Security > Accessibility` in System Settings, and dynamically detects granted permissions via active state polling without requiring an application restart.
2. **Focused Window Inspection**: Safely inspects the frontmost application's focused window to extract position, size, PID, bundle identifier, and title.
3. **Safe Window Classification**: Distinguishes standard resizable application windows (`.normal`) from modal sheets, dialogs, and system UI elements (`.dialog`, `.sheet`, `.system`, `.unsupported`).

---

## 2. Architecture & Data Flow

```mermaid
graph TD
    subgraph UI ["UI Layer (FlowSnapLab / MenuBar)"]
        Lab["FlowSnapLabView (@MainActor)"]
    end

    subgraph Core ["Core Layer"]
        WM["WindowManager"]
        WR["actor WindowRegistry"]
    end

    subgraph Domain ["Domain Layer"]
        MW["struct ManagedWindow (Sendable)"]
        WK["enum WindowKind (Sendable)"]
        ASP["protocol AccessibilityService (Sendable)"]
    end

    subgraph Infrastructure ["Infrastructure Layer"]
        AX["final class AXAccessibilityService"]
        Router["struct SystemSettingsRouter"]
        AXAPI["macOS AXUIElement API"]
    end

    Lab --> WM
    WM --> WR
    WM --> ASP
    AX ..|> ASP
    AX --> AXAPI
    Router --> Infrastructure
    WM --> MW
    WR --> MW
    MW --> WK
```

### Module Boundaries:

- **`Domain/Window/ManagedWindow.swift`**: Immutable snapshot value object. Zero CoreFoundation references.
- **`Domain/Window/WindowKind.swift`**: Semantic categorization (`.normal`, `.dialog`, `.sheet`, `.system`, `.utility`, `.fullscreen`, `.unsupported`, `.unknown`).
- **`Infrastructure/Accessibility/AccessibilityService.swift`**: Domain-facing protocol.
- **`Infrastructure/Accessibility/AXAccessibilityService.swift`**: Encapsulates all CoreFoundation `AXUIElement` complexity and memory bridging.
- **`Infrastructure/macOS/SystemSettingsRouter.swift`**: Deep-link router to System Settings.
- **`Core/Window/WindowRegistry.swift`**: Thread-safe `actor` for caching active window states.

---

## 3. Business Rules Implemented

| Rule ID         | Name                    | Description                                                                                                                |
| :-------------- | :---------------------- | :------------------------------------------------------------------------------------------------------------------------- |
| **BR-SNAP-001** | Permission Pre-flight   | If untrusted, return `nil` or throw `AccessibilityError.notTrusted` instead of crashing.                                   |
| **BR-SNAP-002** | Semantic Classification | Strictly filter `kAXStandardWindowSubrole` and resizable bounds into `.normal`. Modal dialogs/sheets marked non-snappable. |
| **BR-SNAP-003** | Title Fallback          | If window title is missing, fallback to `NSRunningApplication.localizedName` or `"Unknown Window"`.                        |
| **BR-SNAP-004** | Geometry Extraction     | Validate and decode `CGPoint` and `CGSize` into `CGRect` with NaN/inf checks.                                              |

---

## 4. Test Verification Summary

All 14 tests across 5 test suites pass with 100% success rate:

- `AccessibilityServiceTests`: Trusted state, untrusted blocking, focused window mock retrieval, System Settings URL.
- `ManagedWindowTests`: `.normal` snappability, non-normal exclusion, equality, and hashability.
- `WindowRegistryTests`: Thread-safe actor insertion, lookup, PID filtering, and eviction.
- `LayoutEngineTests`: Split calculations.
- `LayoutZoneTests`: Zone coverage.
