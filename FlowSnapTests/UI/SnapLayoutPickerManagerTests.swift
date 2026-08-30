import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Tests for LayoutTemplate definitions and SnapLayoutPickerManager hit-testing.
///
/// Traces to US-SNAP-007, TC-TOP-003, TC-TOP-004.
@MainActor
struct SnapLayoutPickerManagerTests {

    let primaryDisplay = Display(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 0, y: 25, width: 1920, height: 1055),
        scaleFactor: 2.0,
        isPrimary: true
    )

    // MARK: - TC-TOP-003: Layout Templates & Slots Integrity

    @Test func standardTemplatesCountAndIntegrity() {
        let templates = LayoutTemplate.standardTemplates
        #expect(templates.count == 4)

        // 1. Two Column Equal
        let twoCol = templates[0]
        #expect(twoCol.kind == .twoColumnEqual)
        #expect(twoCol.slots.count == 2)
        #expect(twoCol.slots[0].target == .left50_50)
        #expect(twoCol.slots[1].target == .right50_50)

        // 2. Two Column Asymmetric (70/30)
        let twoColAsym = templates[1]
        #expect(twoColAsym.kind == .twoColumnAsymmetric)
        #expect(twoColAsym.slots.count == 2)
        #expect(twoColAsym.slots[0].target == .left70_30)
        #expect(twoColAsym.slots[1].target == .rightOneThird)

        // 3. Three Column Equal
        let threeCol = templates[2]
        #expect(threeCol.kind == .threeColumnEqual)
        #expect(threeCol.slots.count == 3)
        #expect(threeCol.slots[0].target == .leftThird)
        #expect(threeCol.slots[1].target == .centerThird)
        #expect(threeCol.slots[2].target == .rightThird)

        // 4. Four Quarters
        let fourQ = templates[3]
        #expect(fourQ.kind == .fourQuarters)
        #expect(fourQ.slots.count == 4)
        #expect(fourQ.slots[0].target == .topLeft)
        #expect(fourQ.slots[1].target == .topRight)
        #expect(fourQ.slots[2].target == .bottomLeft)
        #expect(fourQ.slots[3].target == .bottomRight)
    }

    @Test func dynamicTemplatesRespectPreferencesStoreRatio() {
        let defaults = UserDefaults(suiteName: "test-picker-dynamic-\(UUID().uuidString)") ?? .standard
        let store = PreferencesStore(defaults: defaults)
        store.setDefaultRatio(.eightyTwenty)

        let manager = SnapLayoutPickerManager(preferencesStore: store)
        let templates = manager.currentTemplates

        #expect(templates.count == 4)
        // Card 1: 50/50
        #expect(templates[0].kind == .twoColumnEqual)
        #expect(templates[0].slots[0].target == .left50_50)

        // Card 2: 80/20
        #expect(templates[1].kind == LayoutTemplateKind(rawValue: "2-Column (80/20)"))
        #expect(templates[1].slots[0].target == .zone(.left80_20))
        #expect(templates[1].slots[1].target == .zone(.right20_80))
    }

    // MARK: - TC-TOP-004: Presentation & Hit-Testing

    @Test func presentationPositioningAndDismiss() {
        let manager = SnapLayoutPickerManager()

        #expect(manager.isVisible == false)
        #expect(manager.pickerFrame == nil)

        manager.showPicker(on: primaryDisplay)

        #expect(manager.activeDisplayID == 1)
        #expect(manager.pickerFrame != nil)

        if let frame = manager.pickerFrame {
            // Verify horizontally centered on primary display (midX = 960, width = 430 -> minX = 745)
            #expect(abs(frame.midX - primaryDisplay.visibleFrame.midX) <= 1.0)
            // Verify positioned at the top of the visible frame
            #expect(frame.maxY <= primaryDisplay.visibleFrame.maxY)
        }

        manager.hidePicker(animated: false)
        #expect(manager.activeDisplayID == nil)
    }
}
