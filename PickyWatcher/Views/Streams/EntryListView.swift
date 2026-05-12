import SwiftUI
import AppKit

struct EntryListView: View {
    var entries: [M3UEntry]
    var selection: Set<M3UEntry.ID>
    var onToggle: (M3UEntry.ID, Bool) -> Void
    var onShiftSelect: (Int, Int) -> Void
    var onOpenVLC: (M3UEntry) -> Void

    @State private var lastTappedIndex: Int? = nil

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    EntryRow(
                        entry: entry,
                        isSelected: selection.contains(entry.id),
                        onOpenVLC: { onOpenVLC(entry) }
                    )
                    .onTapGesture {
                        let shift = NSEvent.modifierFlags.contains(.shift)
                        let cmd = NSEvent.modifierFlags.contains(.command)
                        if shift, let last = lastTappedIndex {
                            onShiftSelect(last, index)
                        } else {
                            onToggle(entry.id, cmd)
                            lastTappedIndex = index
                        }
                    }
                    Divider()
                        .padding(.leading, 8)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onChange(of: entries) { lastTappedIndex = nil }
    }
}
