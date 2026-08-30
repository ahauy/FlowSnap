import AppKit
import CoreGraphics
import Foundation

/// Protocol for coordinating mouse tracking, divider hover, and live window resizing.
@MainActor
public protocol AdaptiveDividerCoordinating: AnyObject {
    var activeDivider: CollinearEdge? { get }
    var hoveredDivider: CollinearEdge? { get }
    var isResizing: Bool { get }
    var currentCursor: NSCursor { get }

    func updateWindows(_ windows: [ManagedWindow])
    func handleMouseMoved(to point: CGPoint) async
    func handleMouseDown(at point: CGPoint) async -> Bool
    func handleMouseDragged(to point: CGPoint) async
    func handleMouseUp(at point: CGPoint) async

    /// Aborts an in-flight divider drag, restoring every window it touched to
    /// the frame it held when the drag began. A no-op when not resizing.
    func cancelResize() async
}
