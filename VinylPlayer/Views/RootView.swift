import SwiftUI

struct RootView: View {
    @StateObject private var engine = AudioEngine()
    @State private var library: [Album] = []
    @State private var showLibrary = false
    @State private var showTracks = false
    @State private var showSearch = false
    @State private var showSettings = false

    var body: some View {
        PlayerScreen(
            engine: engine,
            onOpenLibrary: { showLibrary = true },
            onOpenTracks: { showTracks = true },
            onOpenSearch: { showSearch = true },
            onOpenSettings: { showSettings = true }
        )
        .task { await bootstrap() }
        .sheet(isPresented: $showLibrary) {
            LibraryStackView(albums: library, currentID: engine.album?.id) { album in
                showLibrary = false
                Task { await select(album) }
            }
        }
        .sheet(isPresented: $showTracks) {
            TrackListSheet(engine: engine)
        }
        .sheet(isPresented: $showSearch) {
            SearchSheet { album in
                showSearch = false
                Task { await select(album) }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(engine: engine)
        }
    }

    private func bootstrap() async {
        guard engine.album == nil else { return }
        do {
            let found = try await NetEaseClient.searchAlbums(keyword: "范特西", limit: 20)
            library = found + DemoCatalog.albums
            if let first = found.first {
                await select(first)
            }
        } catch {
            library = DemoCatalog.albums
            if let first = library.first { engine.play(album: first) }
            engine.message = "网易云连不上（\(error.localizedDescription)），先用本地演示唱片。"
        }
    }

    private func select(_ album: Album) async {
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
        if let existing = library.firstIndex(where: { $0.id == target.id }) {
            library[existing] = target
        } else {
            library.append(target)
        }
        engine.play(album: target)
    }
}
