import Foundation
import Observation

@Observable
final class DownloadService {
    var urlString: String = UserDefaults.standard.string(forKey: "lastDownloadURL") ?? ""
    var isDownloading: Bool = false
    var progress: Double = 0.0
    var bytesReceived: Int64 = 0
    var bytesTotal: Int64 = 0

    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var session: URLSession?

    var progressText: String {
        let fmt = ByteCountFormatter()
        fmt.countStyle = .file
        let received = fmt.string(fromByteCount: bytesReceived)
        guard bytesTotal > 0 else { return received }
        return "\(received) / \(fmt.string(fromByteCount: bytesTotal))"
    }

    func cancel() {
        task?.cancel()
        session?.invalidateAndCancel()
        session = nil
        task = nil
        isDownloading = false
    }

    func start(
        onContent: @escaping (String) async -> Void,
        onError: @escaping @MainActor (String) -> Void
    ) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed), url.scheme != nil else {
            Task { @MainActor in onError("Invalid URL") }
            return
        }

        UserDefaults.standard.set(trimmed, forKey: "lastDownloadURL")
        isDownloading = true
        progress = 0.0
        bytesReceived = 0
        bytesTotal = 0

        let newSession = URLSession(configuration: .default)
        session = newSession

        task = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                let (asyncBytes, response) = try await newSession.bytes(from: url)

                if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                    await MainActor.run { [weak self] in
                        self?.isDownloading = false
                        onError("Server returned HTTP \(http.statusCode)")
                    }
                    return
                }

                let total = response.expectedContentLength
                await MainActor.run { [weak self] in self?.bytesTotal = total }

                var buffer = Data(capacity: total > 0 ? Int(min(total, 100_000_000)) : 50_000_000)
                for try await byte in asyncBytes {
                    buffer.append(byte)
                    if buffer.count % (1024 * 1024) == 0 {
                        let received = Int64(buffer.count)
                        let prog = total > 0 ? Double(received) / Double(total) : 0.0
                        Task { @MainActor [weak self] in
                            self?.bytesReceived = received
                            self?.progress = prog
                        }
                    }
                }

                guard let raw = String(data: buffer, encoding: .utf8)
                        ?? String(data: buffer, encoding: .isoLatin1) else {
                    await MainActor.run { [weak self] in
                        self?.isDownloading = false
                        onError("Downloaded file has unsupported encoding")
                    }
                    return
                }

                await MainActor.run { [weak self] in
                    self?.bytesReceived = Int64(buffer.count)
                    self?.isDownloading = false
                }

                await onContent(raw)

            } catch let urlError as URLError where urlError.code == .cancelled {
                await MainActor.run { [weak self] in self?.isDownloading = false }
            } catch is CancellationError {
                await MainActor.run { [weak self] in self?.isDownloading = false }
            } catch {
                await MainActor.run { [weak self] in
                    self?.isDownloading = false
                    onError("Download failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
