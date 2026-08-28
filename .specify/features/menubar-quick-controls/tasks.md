# Tasks Breakdown: Menu Bar Status Item & Quick Snap Controls (US-SNAP-005)

## Task Matrix & Dependencies

- [ ] **TASK-MENU-001 (Domain & Contracts)**: Define `MenuBarAction` and `MenuBarContracts` in `Domain/MenuBar/`.
- [ ] **TASK-MENU-002 (ViewModel)**: Create `MenuBarViewModel.swift` with `@Observable`, `@MainActor`, integrating `AccessibilityService`, `CommandDispatcher`, and `WindowManager`.
- [ ] **TASK-MENU-003 (SwiftUI View)**: Implement `MenuBarView.swift` with permission banner, quick snap grid, shortcut tags, and system items.
- [ ] **TASK-MENU-004 (Integration)**: Wire `MenuBarViewModel` in `AppDependencies.swift` and configure `FlowSnapApp.swift` / `AppDelegate.swift`.
- [ ] **TASK-MENU-005 (Unit Testing)**: Write test suite `MenuBarViewModelTests.swift` covering permission changes, command routing, and auto-dismiss behavior.

---

## Delegation Checklist

### Tasks (Backend / Core)

- [ ] `TASK-MENU-001`: Create `Domain/MenuBar/MenuBarAction.swift`.
- [ ] `TASK-MENU-002`: Create `UI/MenuBar/MenuBarViewModel.swift`.
- [ ] `TASK-MENU-004`: Update `AppDependencies.swift` with `menuBarViewModel`.

### Tasks (Frontend / UI)

- [ ] `TASK-MENU-003`: Update `FlowSnap/UI/MenuBar/MenuBarView.swift` with modern macOS design, 1px borders, and SF Symbols.
- [ ] `TASK-MENU-005`: Create `FlowSnapTests/UI/MenuBarViewModelTests.swift`.
