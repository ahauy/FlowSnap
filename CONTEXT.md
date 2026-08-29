# CONTEXT.md — Shared Language (Ubiquitous Language)

> **Purpose:** A single "shared language" for human developers and AI agents. Agents read this file to decode project-specific jargon instead of guessing every time. This implements the Ubiquitous Language pattern (Eric Evans, _Domain-Driven Design_) — origin: `mattpocock/skills`.
>
> **Role in Framework:** `CONTEXT.md` serves as the "Data Plane" bridging the Control Plane (BA pipeline & governance) with execution. Whenever `domain-modeling` or an elicitation interview introduces or refines a domain concept, it must **update inline** this file. Nobody reinvents terminology across sessions.

## Usage Rules

1. **One-line concise definitions** for each term — do not replicate extensive documentation.
2. **Before / After** comparisons to demonstrate value: verbose phrase (Before) → concise shorthand (After).
3. **Naming consistency:** variables, functions, components, and files must strictly adhere to the terms established here.
4. **Update inline:** whenever a decision or definition surfaces during elicitation or domain modeling, add or update the entry immediately (link to the relevant ADR if it is an architectural decision).
5. **Soft immutability:** never delete terms already in use across the codebase; mark them as `deprecated → alias`.

## Tech Stack & System Components Overview

| Component / Layer          | Technology / Tool                   | Description & Role                                                                 |
| :------------------------- | :---------------------------------- | :--------------------------------------------------------------------------------- |
| **Primary Language**       | Swift 6.0                           | Strict concurrency, actor isolation, `@Observable` state management.               |
| **Target Platform**        | macOS 14.0+ (Sonoma / Sequoia)      | Native desktop application with Hardened Runtime enabled.                          |
| **UI Framework**           | SwiftUI & AppKit                    | Declarative UI for settings/menu bar combined with native NSWindow/NSPanel.        |
| **Build & Project Config** | XcodeGen (`project.yml`)            | Declarative Xcode project generation (`FlowSnap`, `FlowSnapTests`, `FlowSnapLab`). |
| **Window & System API**    | macOS Accessibility (`AXUIElement`) | Low-level OS window querying, repositioning, and resizing.                         |
| **Global Shortcuts**       | Carbon / CGEvent Hotkeys            | System-wide keyboard shortcut detection for instant window snapping.               |
| **Testing Framework**      | Swift Testing (`@Test`) & XCTest    | Modern protocol-based dependency injection with test mock doubles.                 |
| **Code Intelligence**      | `code-review-graph` (uvx)           | Local Tree-sitter AST & SQLite graph for call-hierarchy and blast-radius queries.  |

## Glossary (FlowSnap Ubiquitous Language)

| Term                         | Short definition                                      | Before (verbose)                               | After (concise)            | Notes                                         |
| :--------------------------- | :---------------------------------------------------- | :--------------------------------------------- | :------------------------- | :-------------------------------------------- |
| **Workspace**                | Saved intent of window arrangements across apps       | "A saved multi-window setup"                   | `Workspace`                | Spec §38, portable across displays            |
| **WindowPlacement**          | Logical layout assignment for an app window           | "Position and size of an app on screen"        | `WindowPlacement`          | Decoupled from pixel coordinates              |
| **SnapEngine**               | Coordinates snap zone calculations & trigger logic    | "The logic that moves windows to screen edges" | `SnapEngine`               | Core calculation module                       |
| **LayoutEngine**             | Geometric grid & split-screen partition math          | "Screen splitting calculation helper"          | `LayoutEngine`             | Halves, thirds, quarters math                 |
| **AccessibilityService**     | macOS AXUIElement adapter for window manipulation     | "Accessibility wrapper for OS windows"         | `AccessibilityService`     | Infrastructure adapter                        |
| **ManagedWindow**            | Snapshot of a window's state (ID, PID, frame, kind)   | "A tracked window object"                      | `ManagedWindow`            | Pure domain model, no AX refs                 |
| **WindowKind**               | Semantic category of a window (.normal, .dialog...)   | "Window type or window category"               | `WindowKind`               | Filters snappable vs modal windows            |
| **LayoutZone**               | Normalized rectangular partition (0...1 coordinates)  | "A screen tile or slot"                        | `LayoutZone`               | Halves, quarters, custom zones                |
| **SnapTarget**               | Semantic destination enum (left, right, max...)       | "Where the window should snap"                 | `SnapTarget`               | Domain command target                         |
| **PreSnapFrame**             | Cached window bounds before snapping begins           | "The original window position before snapping" | `PreSnapFrame`             | Enables restore action                        |
| **CoordinateTransformer**    | Bidirectional AppKit ↔ AX coordinate conversion math  | "Coordinate flip math helper"                  | `CoordinateTransformer`    | Pure functional, zero system dependencies     |
| **DisplayManaging**          | Protocol for querying displays and active screens     | "Display manager interface"                    | `DisplayManaging`          | Mockable interface for DI                     |
| **DisplayManager**           | AppKit implementation observing screen changes        | "System screen tracker service"                | `DisplayManager`           | Tracks `NSScreen.screens` changes             |
| **KeyboardShortcut**         | Key code + modifier flags representation              | "Key binding or shortcut tuple"                | `KeyboardShortcut`         | Hashable, Codable shortcut model              |
| **GlobalHotkeyManaging**     | Protocol for system-wide hotkey interception          | "Global hotkey service interface"              | `GlobalHotkeyManaging`     | Abstracts Carbon Event Hotkeys                |
| **GlobalHotkeyManager**      | Carbon Event Hotkeys implementation                   | "Low-level system hotkey listener"             | `GlobalHotkeyManager`      | Uses `RegisterEventHotKey`                    |
| **CommandDispatcher**        | Central router dispatching WindowCommands             | "Command execution controller"                 | `CommandDispatcher`        | Routes commands to SnapEngine asynchronously  |
| **WindowCommand**            | Semantic user intent enum (snap, maximize, restore)   | "Action or user command"                       | `WindowCommand`            | Decoupled command payload                     |
| **MenuBarManaging**          | Interface for managing status bar icon & popover      | "Status item controller interface"             | `MenuBarManaging`          | Protocol for Menu Bar lifecycle               |
| **MenuBarViewModel**         | ViewModel driving reactive Menu Bar UI state          | "Menu bar state store"                         | `MenuBarViewModel`         | @Observable state for MenuBarView             |
| **MouseDragTracker**         | Service monitoring global drag & release events       | "Mouse movement & drag listener"               | `MouseDragTracker`         | Uses NSEvent global monitors                  |
| **SnapDetector**             | Evaluates cursor coords against display edge zones    | "Edge collision detection helper"              | `SnapDetector`             | Pure domain logic mapping point -> SnapTarget |
| **SnapPreviewManaging**      | Protocol controlling the HUD snap preview overlay     | "Preview overlay manager interface"            | `SnapPreviewManaging`      | Manages non-activating NSPanel preview life   |
| **SnapLayoutPickerManaging** | Protocol controlling the Top-Edge Layout Picker panel | "Layout picker manager interface"              | `SnapLayoutPickerManaging` | Manages non-activating NSPanel picker life    |
| **LayoutTemplate**           | Predefined multi-window layout grouping in picker     | "Picker layout card or pattern"                | `LayoutTemplate`           | 50/50, 70/30, 3-column, 4-quarters            |
| **LayoutSlot**               | Interactive partition tile inside a LayoutTemplate    | "Picker layout tile or zone cell"              | `LayoutSlot`               | Hit-testable target mapping to SnapTarget     |
| **AppDependencies**          | Root DI container for services and stores             | "Global service locator or singleton list"     | `AppDependencies`          | @MainActor DI container                       |

## Where to Look

- **Scan codebase** to identify existing implicit terms or jargon not yet cataloged here → add them to the table.
- **`adr/`** for load-bearing architectural decisions that require extensive rationale (link from the glossary where applicable).
- **`.specify/features/<slug>/`** for full business rules and finite state machines (this file is an index of ubiquitous language, not a substitute for formal SRS documents).
