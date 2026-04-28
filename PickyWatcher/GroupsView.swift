import SwiftUI

struct GroupsView: View {
    let groups: [(name: String, entries: [M3UEntry])]
    let selectedGroupName: String?
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(groups, id: \.name) { group in
                    GroupRow(
                        name: group.name,
                        entries: group.entries,
                        isSelected: selectedGroupName == group.name,
                        onSelect: { onSelect(group.name) }
                    )
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct GroupRow: View {
    let name: String
    let entries: [M3UEntry]
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isExpanded = false
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(width: 3)
                    .padding(.vertical, 8)

                HStack(spacing: 8) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption.weight(.semibold))
                            .frame(width: 14)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(name.isEmpty ? "(No Group)" : name)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text("\(entries.count)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            (isSelected ? Color.accentColor : Color.secondary).opacity(0.12)
                        )
                        .clipShape(Capsule())

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                            .imageScale(.small)
                    }
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
            .contentShape(Rectangle())
            .onTapGesture { onSelect() }
            .onHover { isHovered = $0 }

            if isExpanded {
                LazyVStack(spacing: 0) {
                    ForEach(entries) { entry in
                        HStack {
                            Text(entry.name)
                                .font(.callout)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .padding(.leading, 34)
                        .padding(.trailing, 10)
                        Divider().padding(.leading, 34)
                    }
                }
                .background(Color(NSColor.windowBackgroundColor))
            }

            Divider()
        }
    }
}
