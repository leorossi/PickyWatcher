import SwiftUI

struct DownloadingView: View {
    var progress: Double
    var bytesTotal: Int64
    var progressText: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Downloading…")
                .foregroundStyle(.secondary)
            Group {
                if bytesTotal > 0 {
                    ProgressView(value: progress)
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: 320)
            Text(progressText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
