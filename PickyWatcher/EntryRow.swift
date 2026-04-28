import SwiftUI
import AppKit

struct EntryRow: View {
    let entry: M3UEntry
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isSelected ? Color.accentColor : Color.clear)
                .frame(width: 3)
                .padding(.vertical, 8)

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.name)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .lineLimit(1)

                    if !entry.group.isEmpty {
                        Text(entry.group)
                            .font(.caption2)
                            .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                (isSelected ? Color.accentColor : Color.secondary).opacity(0.12)
                            )
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Text(entry.url)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 180)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isSelected
                ? Color.accentColor.opacity(0.1)
                : isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.06) : Color.clear
        )
        .animation(.easeOut(duration: 0.1), value: isHovered)
        .onHover { isHovered = $0 }
    }
}
