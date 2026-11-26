import Foundation
import MediaPlayer
import SwiftUI

struct VinylTrack: Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let duration: TimeInterval
    let art: UIImage?

    var durationText: String {
        let total = Int(duration.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

/// 一张唱片。演示专辑没有 mediaItems，真实专辑带着音乐库条目。
struct VinylAlbum: Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let year: String
    let art: UIImage?
    let tracks: [VinylTrack]
    let palette: Palette
    let mediaItems: [MPMediaItem]

    static func == (lhs: VinylAlbum, rhs: VinylAlbum) -> Bool {
        lhs.id == rhs.id
    }
}

struct Palette: Equatable {
    let top: Color
    let bottom: Color

    static let fallback = Palette(
        top: Color(red: 0.18, green: 0.20, blue: 0.28),
        bottom: Color(red: 0.08, green: 0.09, blue: 0.13)
    )
}
