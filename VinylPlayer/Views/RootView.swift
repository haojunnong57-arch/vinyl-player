import SwiftUI

struct RootView: View {
    @StateObject private var engine = AudioEngine()
    @State private var library: [Album] = []
    @State private var selected: Album?
    @State private var showSearch = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            if let album = selected {
                PlayerScreen(
                    engine: engine,
                    onBack: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                            selected = nil
                        }
                    },
                    onOpenTracks: {
                        showSearch = false
                        showTracks = true
                    },
                    onOpenSearch: { showSearch = true },
                    onOpenSettings: { showSettings = true }
                )
                .transition(.move(edge: .bottom))
            } else {
                HomeView(
                    albums: library,
                    currentID: album?.id,
                    onSelect: { picked in
                        Task { await open(picked) }
                    },
                    onSearch: { showSearch = true },
                    onSettings: { showSettings = true }
                )
                .transition(.opacity)
            }
        }
        .task { await bootstrap() }
        .sheet(isPresented: $showTracks) {
            TrackListSheet(engine: engine)
        }
        .sheet(isPresented: $showSearch) {
            SearchSheet { album in
                showSearch = false
                Task { await open(album, jumpToPlayer: true) }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(engine: engine)
        }
    }

    @State private var showTracks = false

    private var album: Album? { engine.album }

    private func bootstrap() async {
        guard library.isEmpty else { return }
        do {
            let found = try await NetEaseClient.searchAlbums(keyword: "范特西", limit: 20)
            library = found + DemoCatalog.albums
        } catch {
            library = DemoCatalog.albums
            engine.message = "网易云连不上（\(error.localizedDescription)），先用本地演示唱片。"
        }
    }

    private func open(_ album: Album, jumpToPlayer: Bool = true) async {
        var target = album
        if target.tracks.isEmpty {
            do {
                target = try await NetEaseClient.albumDetail(id: album.id)
            } catch {
                engine.message = error.localizedDescription
                return
            }
        }
        target.cover = await Artwork.load(target.coverURL)
        target.tint = Artwork.tint(from: target.cover)
        if let index = library.firstIndex(where: { $0.id == target.id }) {
            library[index] = target
        } else {
            library.append(target)
        }
        engine.play(album: target)
        if jumpToPlayer {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                selected = target
            }
        }
    }
}
