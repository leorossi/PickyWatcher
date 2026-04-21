import SwiftUI

struct SearchBar: View {
    @Binding var query: String
    var isSearching: Bool = false
    var placeholder: String = "Search"
    let onCommit: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            TextField(placeholder, text: $query)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 280)
                .onSubmit { onCommit() }

            if !query.isEmpty {
                Button {
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }

            Button("Search") { onCommit() }

            if isSearching {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 16, height: 16)
            }
        }
    }
}
