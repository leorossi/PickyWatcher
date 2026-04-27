import SwiftUI

struct ErrorBarView: View {
    var message: String
    var onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.callout)
            Spacer()
            Button("Dismiss", action: onDismiss)
                .buttonStyle(.borderless)
        }
        .padding(8)
        .background(Color.red.opacity(0.1))
    }
}
