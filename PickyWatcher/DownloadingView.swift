import SwiftUI

struct DownloadingView: View {
    var progress: Double
    var bytesTotal: Int64
    var progressText: String

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundStyle(Color.accentColor)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: 10) {
                Text("Downloading playlist…")
                    .font(.headline)

                Group {
                    if bytesTotal > 0 {
                        ProgressView(value: progress)
                    } else {
                        ProgressView()
                    }
                }
                .progressViewStyle(.linear)
                .tint(Color.accentColor)
                .frame(maxWidth: 320)

                Text(progressText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
