import Foundation
import MediaPlayer
import SwiftUI

/// 播放中枢：优先用系统音乐库（MPMusicPlayerController，不需要 MusicKit 授权），
/// 拿不到就落到内置演示唱片，保证装上就有东西可转。
@MainActor
final class PlayerModel: ObservableObject {
    @Published private(set) var albums: [VinylAlbum] = []
    @Published var current: VinylAlbum?
    @Published var trackIndex: Int = 0
    @Published var isPlaying = false
    @Published var elapsed: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var themeID: String = "walnut"
    @Published var rpm: Double = 33.333
    @Published var usingDemo = true
    @Published var notice: String?

    private let player = MPMusicPlayerController.applicationMusicPlayer

    var theme: DeckTheme { DeckTheme.named(themeID) }

    var currentTrack: VinylTrack? {
        guard let album = current else { return nil }
        if album.tracks.indices.contains(trackIndex) { return album.tracks[trackIndex] }
        return album.tracks.first
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, elapsed / duration))
    }

    var sourceLabel: String { usingDemo ? "演示唱片" : "我的音乐库" }

    // MARK: - 启动

    func bootstrap() async {
        if albums.isEmpty {
            albums = DemoShelf.albums
        }
        if current == nil, let first = albums.first {
            load(album: first, index: 0, autoPlay: false)
        }
        await loadLibraryIfPossible()
    }

    func loadLibraryIfPossible() async {
        let granted = await requestMediaAccess()
        guard granted else {
            notice = "没有音乐库权限，先用演示唱片。到设置里可直接重试。"
            return
        }
        let query = MPMediaQuery.albums()
        guard let collections = query.collections, !collections.isEmpty else {
            notice = "音乐库里没有专辑，先用演示唱片。"
            return
        }

        var converted: [VinylAlbum] = []
        for (offset, collection) in collections.prefix(80).enumerated() {
            let items = collection.items
            guard let first = items.first else { continue }
            let art = first.artwork?.image(at: CGSize(width: 700, height: 700))
            let tracks: [VinylTrack] = items.map { item in
                VinylTrack(
                    id: String(item.persistentID),
                    title: item.title ?? "未命名曲目",
                    artist: item.artist ?? first.albumArtist ?? "",
                    duration: item.playbackDuration,
                    art: art
                )
            }
            converted.append(
                VinylAlbum(
                    id: "lib-\(offset)",
                    title: first.albumTitle ?? "未命名专辑",
                    artist: first.albumArtist ?? first.artist ?? "未知艺人",
                    year: "",
                    art: art,
                    tracks: tracks,
                    palette: Palette.fallback,
                    mediaItems: items
                )
            )
        }

        guard !converted.isEmpty else {
            notice = "没能读出专辑，先用演示唱片。"
            return
        }

        albums = converted
        usingDemo = false
        notice = nil
        if current == nil || (current.map { $0.mediaItems.isEmpty } ?? true) {
            load(album: converted[0], index: 0, autoPlay: false)
        }
    }

    private func requestMediaAccess() async -> Bool {
        let status = MPMediaLibrary.authorizationStatus()
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                MPMediaLibrary.requestAuthorization { newStatus in
                    continuation.resume(returning: newStatus == .authorized)
                }
            }
        default:
            return false
        }
    }

    // MARK: - 播放控制

    func load(album: VinylAlbum, index: Int, autoPlay: Bool) {
        current = album
        trackIndex = min(max(0, index), max(0, album.tracks.count - 1))
        elapsed = 0
        duration = album.tracks.indices.contains(trackIndex) ? album.tracks[trackIndex].duration : 0
        if autoPlay {
            start()
        }
    }

    func play(album: VinylAlbum, index: Int = 0) {
        load(album: album, index: index, autoPlay: true)
    }

    func playPause() {
        if isPlaying { pause() } else { start() }
    }

    func start() {
        if usingDemo || (current?.mediaItems.isEmpty ?? true) {
            isPlaying = true
            return
        }
        guard let album = current, album.mediaItems.indices.contains(trackIndex) else { return }
        let collection = MPMediaItemCollection(items: album.mediaItems)
        player.setQueue(with: collection)
        player.nowPlayingItem = album.mediaItems[trackIndex]
        player.play()
        isPlaying = true
    }

    func pause() {
        if !usingDemo, !(current?.mediaItems.isEmpty ?? true) {
            player.pause()
        }
        isPlaying = false
    }

    func next() {
        step(by: 1)
    }

    func previous() {
        if elapsed > 4 {
            seek(to: 0)
            return
        }
        step(by: -1)
    }

    private func step(by delta: Int) {
        guard let album = current, !album.tracks.isEmpty else { return }
        let target = trackIndex + delta
        if target < 0 {
            trackIndex = 0
            elapsed = 0
            duration = album.tracks[0].duration
            if isPlaying { start() }
        } else if target >= album.tracks.count {
            trackIndex = 0
            elapsed = 0
            duration = album.tracks[0].duration
            if isPlaying { start() }
        } else {
            load(album: album, index: target, autoPlay: isPlaying)
        }
    }

    func seek(to time: TimeInterval) {
        elapsed = min(max(0, time), duration)
        if !usingDemo, !(current?.mediaItems.isEmpty ?? true) {
            player.currentPlaybackTime = elapsed
        }
    }

    func toggleRPM() {
        rpm = rpm > 40 ? 33.333 : 45
    }

    // MARK: - 进度轮询

    func tick() {
        if usingDemo || (current?.mediaItems.isEmpty ?? true) {
            guard isPlaying else { return }
            elapsed += 0.25
            if duration > 0, elapsed >= duration {
                next()
            }
        } else {
            isPlaying = player.playbackState == .playing
            if let item = player.nowPlayingItem, item.playbackDuration > 0 {
                duration = item.playbackDuration
            }
            elapsed = player.currentPlaybackTime
        }
    }
}

// MARK: - 演示唱片

enum DemoShelf {
    static let albums: [VinylAlbum] = [
        make(
            id: "demo-1",
            title: "夜航",
            artist: "林晚",
            year: "2024",
            palette: Palette(
                top: Color(red: 0.13, green: 0.22, blue: 0.38),
                bottom: Color(red: 0.05, green: 0.08, blue: 0.16)
            ),
            tracks: [
                ("蓝色信号", 224),
                ("午夜唱片", 258),
                ("潮汐", 199),
                ("城市边缘", 241)
            ]
        ),
        make(
            id: "demo-2",
            title: "Afternoon Tape",
            artist: "Paper Season",
            year: "2023",
            palette: Palette(
                top: Color(red: 0.55, green: 0.36, blue: 0.22),
                bottom: Color(red: 0.22, green: 0.13, blue: 0.09)
            ),
            tracks: [
                ("Side A · 午后", 212),
                ("Dust & Light", 187),
                ("旧收音机", 236)
            ]
        ),
        make(
            id: "demo-3",
            title: "雨落在唱针上",
            artist: "陈默",
            year: "2025",
            palette: Palette(
                top: Color(red: 0.16, green: 0.30, blue: 0.28),
                bottom: Color(red: 0.06, green: 0.12, blue: 0.12)
            ),
            tracks: [
                ("开场白", 143),
                ("雨声采样", 268),
                ("黑胶噪点", 205),
                ("谢幕", 176)
            ]
        ),
        make(
            id: "demo-4",
            title: "45RPM",
            artist: "Midnight Trio",
            year: "2022",
            palette: Palette(
                top: Color(red: 0.42, green: 0.16, blue: 0.30),
                bottom: Color(red: 0.16, green: 0.05, blue: 0.12)
            ),
            tracks: [
                ("Neon Groove", 198),
                ("Slow Spin", 232),
                ("Last Track", 187)
            ]
        )
    ]

    private static func make(
        id: String,
        title: String,
        artist: String,
        year: String,
        palette: Palette,
        tracks: [(String, TimeInterval)]
    ) -> VinylAlbum {
        let list = tracks.enumerated().map { offset, item in
            VinylTrack(
                id: "\(id)-t\(offset)",
                title: item.0,
                artist: artist,
                duration: item.1,
                art: nil
            )
        }
        return VinylAlbum(
            id: id,
            title: title,
            artist: artist,
            year: year,
            art: nil,
            tracks: list,
            palette: palette,
            mediaItems: []
        )
    }
}
