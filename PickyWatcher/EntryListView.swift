import SwiftUI
import AppKit

struct EntryListView: View {
    var entries: [M3UEntry]
    var selection: Set<M3UEntry.ID>
    var onToggle: (M3UEntry.ID, Bool) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(entries) { entry in
                    EntryRow(entry: entry, isSelected: selection.contains(entry.id))
                        .onTapGesture {
                            onToggle(entry.id, NSEvent.modifierFlags.contains(.command))
                        }
                    Divider()
                        .padding(.leading, 8)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}
