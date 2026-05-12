import SwiftUI
import UniformTypeIdentifiers

struct M3UDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.init(filenameExtension: "m3u8")!, .init(filenameExtension: "m3u")!] }
    var content: String

    init(content: String) { self.content = content }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        content = String(decoding: data, as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(content.utf8))
    }
}
