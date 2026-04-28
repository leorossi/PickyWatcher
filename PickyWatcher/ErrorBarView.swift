import SwiftUI

struct ErrorBarView: View {
    var message: String
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.red)
                .frame(width: 4)

            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .imageScale(.small)
                Text(message)
                    .font(.callout)
                    .lineLimit(2)
                Spacer()
                Button("Dismiss", action: onDismiss)
                    .buttonStyle(.borderless)
                    .font(.callout)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.red.opacity(0.08))
        }
    }
}
