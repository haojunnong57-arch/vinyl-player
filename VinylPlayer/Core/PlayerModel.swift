import AVFoundation
import MediaPlayer
import UIKit

/// 播放引擎：AVPlayer + 锁屏控制 + 队列。
@MainActor
final class AudioEngine: NSObject, ObservableObject {
    @Published var album: Album?
    @Published var index: Int = 0
    @Published var isPlaying = false
    @Published var elapsed: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var cover: UIImage?
    @Published var tint: UIColor = UIColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1)
    @Published var message: String?
    @Published var loading = false

    private let player = AVPlayer()
    private var timeObserver: Any?

    var track: Track? {
        guard let album, album.tracks.indices.contains(index) else { return album?.tracks.first }
        return album.tracks[index]
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, elapsed / duration))
    }

    var isLightBackground: Bool { Artwork.isLight(tint) }

    override init() {
        super.init()
        configureAudioSession()
        configureRemoteCommands()
        addPeriodicObserver()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            message = "音频会话初始化失败：\(error.localizedDescription)"
        }
    }

    private func addPeriodicObserver() {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            self.elapsed = time.seconds.isFinite ? max(0, time.seconds) : 0
            if let item = self.player.currentItem {
                let total = item.duration.seconds
                if total.isFinite, total > 0 { self.duration = total }
            }
            if self.player.timeControlStatus == .playing {
                if !self.isPlaying { self.isPlaying = true }
            } else if self.isPlaying, self.player.timeControlStatus == .paused {
                self.isPlaying = false
                self.pushNowPlaying()
            }
        }
    }

    // MARK: 对外操作

    func play(album: Album, index: Int = 0) {
        self.album = album
        self.index = min(max(0, index), max(0, album.tracks.count - 1))
        self.cover = album.cover ?? Artwork.cached(album.coverURL)
        self.tint = album.tint ?? Artwork.tint(from: self.cover)
        self.elapsed = 0
        self.duration = album.tracks.indices.contains(self.index) ? album.tracks[self.index].duration : 0
        startCurrent()
    }

    func toggle() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            if player.currentItem == nil {
                startCurrent()
            } else {
                player.play()
                isPlaying = true
            }
        }
        pushNowPlaying()
    }

    func next() { step(1) }

    func previous() {
        if elapsed > 4 { seek(0); return }
        step(-1)
    }

    private func step(_ delta: Int) {
        guard let album, !album.tracks.isEmpty else { return }
        var target = index + delta
        if target < 0 { target = album.tracks.count - 1 }
        if target >= album.tracks.count { target = 0 }
        index = target
        elapsed = 0
        duration = album.tracks[target].duration
        startCurrent()
    }

    func seek(_ time: TimeInterval) {
        let clamped = min(max(0, time), duration)
        player.seek(to: CMTime(seconds: clamped, preferredTimescale: 600))
        elapsed = clamped
    }

    private func flash(_ text: String) {
        message = text
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if self.message == text { self.message = nil }
        }
    }

    private func startCurrent() {
        guard let track = track, let url = NetEaseClient.playableURL(for: track) else {
            flash("这首歌拿不到播放地址")
            return
        }
        loading = true
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.play()
        isPlaying = true
        if duration <= 0 { duration = track.duration }
        pushNowPlaying()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            self.loading = false
            if let err = self.player.currentItem?.error {
                self.flash("放不了：\(err.localizedDescription)。会员曲目请在设置里填 cookie。")
            }
        }
    }

    // MARK: 锁屏 / 耳机控制

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.toggle() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.toggle() }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.next() }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.previous() }
            return .success
        }
    }

    private func pushNowPlaying() {
        guard let track else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.name,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.albumName,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let cover {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: cover.size) { _ in cover }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
