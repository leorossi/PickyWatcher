import SwiftUI

struct IndexingView: View {
    var progress: Double
    var indexedCount: Int
    var total: Int

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "list.bullet")
                    .font(.system(size: 30, weight: .thin))
                    .foregroundStyle(Color.accentColor)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: 10) {
                Text("Indexing streams…")
                    .font(.headline)

                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(Color.accentColor)
                    .frame(maxWidth: 320)

                Text("\(indexedCount) / \(total) streams")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
