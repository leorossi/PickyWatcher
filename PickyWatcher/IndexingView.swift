import SwiftUI

struct IndexingView: View {
    var progress: Double
    var indexedCount: Int
    var total: Int

    var body: some View {
        VStack(spacing: 16) {
            Text("Indexing…")
                .foregroundStyle(.secondary)
            ProgressView(value: progress)
                .frame(maxWidth: 320)
            Text("\(indexedCount) / \(total) streams")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
