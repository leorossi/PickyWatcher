import AppKit
import SwiftUI

/// Installs a window-level key-event monitor that intercepts Cmd+C and Ctrl+C,
/// calling `onCopy` whenever neither shortcut is already claimed by a focused text view.
struct CopyKeyHandler: NSViewRepresentable {
    var onCopy: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.onCopy = onCopy
        context.coordinator.startMonitoring()
        return NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onCopy = onCopy
    }

    final class Coordinator {
        var onCopy: () -> Void = {}
        private var monitor: Any?

        func startMonitoring() {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else { return event }
                // Let text fields keep their own copy behavior
                if NSApp.keyWindow?.firstResponder is NSTextView { return event }
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                if event.charactersIgnoringModifiers == "c",
                   flags == .command || flags == .control {
                    self.onCopy()
                    return nil // consume the event
                }
                return event
            }
        }

        deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
    }
}
