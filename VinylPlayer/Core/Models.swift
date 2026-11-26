import Foundation
import UIKit

struct Album: Identifiable, Equatable {
    let id: Int64
    let name: String
    let artist: String
    let coverURL: URL?
    let tracks: [Track]
    var cover: UIImage?
    var tint: UIColor?

    static func == (lhs: Album, rhs: Album) -> Bool { lhs.id == rhs.id }
}

struct Track: Identifiable, Equatable {
    let id: Int64
    let name: String
    let artist: String
    let albumName: String
    let duration: TimeInterval
    let coverURL: URL?

    /// 3'57" 这种写法，和谜底黑胶的曲目表一致
    var durationText: String {
        let total = Int(duration.rounded())
        return "\(total / 60)'\(String(format: "%02d", total % 60))\""
    }

    var streamURL: URL? {
        URL(string: "https://music.163.com/song/media/outer/url?id=\(id).mp3")
    }
}
