import Foundation

struct RecentFile: Codable {
    let displayName: String
    let path: String
    let bookmarkData: Data
}
