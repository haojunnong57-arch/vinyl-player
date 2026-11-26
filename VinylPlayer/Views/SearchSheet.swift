import SwiftUI

struct SearchSheet: View {
    let onSelect: (Album) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var keyword = ""
    @State private var results: [Album] = []
    @State private var loading = false
    @State private var errorText: String?

    private let columns = [GridItem(.adaptive(minimum: 108), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(results) { album in
                        Button {
                            onSelect(album)
                        } label: {
                            cell(album)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .overlay {
                if loading {
                    ProgressView()
                } else if results.isEmpty {
                    Text(errorText ?? "搜专辑名，或艺人名")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            .searchable(text: $keyword, prompt: "网易云：专辑 / 艺人")
            .onSubmit(of: .search) { Task { await run() } }
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func cell(_ album: Album) -> some View {
        let art: some View = Group {
            if let url = album.coverURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.secondary.opacity(0.15)
                    }
                }
            } else {
                Color.secondary.opacity(0.15)
            }
        }
        let artwork = art
            .frame(height: 108)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

        let name = Text(album.name)
            .font(.system(size: 12, weight: .medium))
            .lineLimit(1)
        let artist = Text(album.artist)
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            .lineLimit(1)

        return VStack(alignment: .leading, spacing: 6) {
            artwork
            name
            artist
        }
    }

    private func run() async {
        let query = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        loading = true
        errorText = nil
        do {
            results = try await NetEaseClient.searchAlbums(keyword: query)
            if results.isEmpty { errorText = "没有搜到专辑" }
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }
}
