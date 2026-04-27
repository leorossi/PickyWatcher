import SwiftUI
import AppKit

struct EntryRow: View {
    let entry: M3UEntry
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .fontWeight(isSelected ? .semibold : .regular)
                if !entry.group.isEmpty {
                    Text(entry.group)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(entry.url)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 200)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isSelected
                ? Color.accentColor.opacity(0.2)
                : isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.07) : Color.clear
        )
        .onHover { isHovered = $0 }
    }
}
