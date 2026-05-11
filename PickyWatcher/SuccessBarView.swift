import SwiftUI

enum ToastStatus { case success, error }

struct StatusToast: View {
    var message: String
    var status: ToastStatus
    var onDismiss: (() -> Void)? = nil

    private var background: Color {
        status == .success ? Color(NSColor.systemGreen) : Color(NSColor.systemRed)
    }
    private var icon: String {
        status == .success ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .imageScale(.small)
            Text(message)
                .font(.caption.weight(.medium))
                .lineLimit(2)
            if let onDismiss {
                Spacer(minLength: 6)
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.bold))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(background, in: Capsule())
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
    }
}
