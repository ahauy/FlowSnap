# Quickstart Validation: Verified Workspace Restoration

## Prerequisites

- macOS 14+ and Xcode 16 toolchain
- Accessibility permission for FlowSnap when running live validation
- Existing workspace fixtures and test doubles in `FlowSnapTests`

## Build and test

```bash
xcodegen generate
xcodebuild -project FlowSnap.xcodeproj -scheme FlowSnap -configuration Debug build
xcodebuild -project FlowSnap.xcodeproj -scheme FlowSnap -configuration Debug test
swiftlint lint --strict
```

## P0 scripted checks

1. Run silent-write fixture: `setFrame` succeeds but read-back stays old; expect
   three attempts and `unverifiablePlacement`, never `placed`.
2. Run unreadable-frame fixture; expect `unverifiableCount == 1` and no success.
3. Run minimized-after-move fixture; expect verification mismatch and no placed
   count.
4. Run fullscreen exit success fixture; expect polling to observe false before
   `setFrame`.
5. Run fullscreen throw and timeout fixtures; expect zero `setFrame` calls and
   `fullscreenTransitionTimeout`.
6. Run nil-element fixture; expect no move call and `unverifiablePlacement`.
7. Run mixed outcomes in unsorted input; expect sequential `orderIndex` calls,
   counter conservation, and one final focus for the lowest verified index.
8. Inspect diagnostics fixture; expect only allowed fields and no title/content.

See [`RestoreContracts.md`](contracts/RestoreContracts.md) and
[`data-model.md`](data-model.md) for the exact result/interface contracts.
