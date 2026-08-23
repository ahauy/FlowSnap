import Foundation

/// Pub-sub event bus for decoupled service communication.
///
/// Services publish events (e.g., window created, app launched)
/// and other services subscribe to react. See spec §40.
@MainActor
final class EventBus {

    typealias EventHandler = @MainActor (WindowEvent) -> Void

    private var handlers: [ObjectIdentifier: EventHandler] = [:]

    /// Subscribe to all events.
    func subscribe<T: AnyObject>(_ subscriber: T, handler: @escaping EventHandler) {
        let id = ObjectIdentifier(subscriber)
        handlers[id] = handler
    }

    /// Unsubscribe from events.
    func unsubscribe<T: AnyObject>(_ subscriber: T) {
        let id = ObjectIdentifier(subscriber)
        handlers.removeValue(forKey: id)
    }

    /// Publish an event to all subscribers.
    func publish(_ event: WindowEvent) {
        for handler in handlers.values {
            handler(event)
        }
    }
}
