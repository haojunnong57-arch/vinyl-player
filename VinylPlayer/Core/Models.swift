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

    /// id <= 0 是内置演示曲目，没有音频，播放器会走演示模式
    var streamURL: URL? {
        guard id > 0 else { return nil }
        return URL(string: "https://music.163.com/song/media/outer/url?id=\(id).mp3")
    }
}


// MARK: - 离线演示唱片

/// 没有网络也能点：这些曲目没有音频，播放引擎会走演示模式，唱片照转、进度照走。
enum DemoCatalog {
    static let albums: [Album] = [
        Album(
            id: -1,
            name: "夜航",
            artist: "林晚",
            coverURL: nil,
            tracks: [
                Track(id: -101, name: "蓝色信号", artist: "林晚", albumName: "夜航", duration: 224, coverURL: nil),
                Track(id: -102, name: "午夜唱片", artist: "林晚", albumName: "夜航", duration: 258, coverURL: nil),
                Track(id: -103, name: "潮汐", artist: "林晚", albumName: "夜航", duration: 199, coverURL: nil)
            ],
            cover: nil,
            tint: UIColor(red: 0.14, green: 0.23, blue: 0.42, alpha: 1)
        ),
        Album(
            id: -2,
            name: "Afternoon Tape",
            artist: "Paper Season",
            coverURL: nil,
            tracks: [
                Track(id: -201, name: "Side A · 午后", artist: "Paper Season", albumName: "Afternoon Tape", duration: 212, coverURL: nil),
                Track(id: -202, name: "Dust & Light", artist: "Paper Season", albumName: "Afternoon Tape", duration: 187, coverURL: nil)
            ],
            cover: nil,
            tint: UIColor(red: 0.52, green: 0.34, blue: 0.21, alpha: 1)
        ),
        Album(
            id: -3,
            name: "雨落在唱针上",
            artist: "陈默",
            coverURL: nil,
            tracks: [
                Track(id: -301, name: "开场白", artist: "陈默", albumName: "雨落在唱针上", duration: 143, coverURL: nil),
                Track(id: -302, name: "雨声采样", artist: "陈默", albumName: "雨落在唱针上", duration: 268, coverURL: nil)
            ],
            cover: nil,
            tint: UIColor(red: 0.15, green: 0.30, blue: 0.28, alpha: 1)
        )
    ]
}
