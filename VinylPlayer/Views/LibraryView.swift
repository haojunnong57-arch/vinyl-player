import SwiftUI

struct LibraryView: View {
    @ObservedObject var model: PlayerModel
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 108), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(model.albums) { album in
                        Button {
                            model.play(album: album, index: 0)
                            dismiss()
                        } label: {
                            AlbumCell(album: album, isCurrent: album.id == model.current?.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("唱片库")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(model.sourceLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

struct AlbumCell: View {
    let album: VinylAlbum
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ZStack {
                if let art = album.art {
                    Image(uiImage: art)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [album.palette.top, album.palette.bottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Circle()
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        .padding(14)
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .padding(34)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 108)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isCurrent ? Color.accentColor : Color.clear, lineWidth: 2)
            )

            Text(album.title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .foregroundStyle(.primary)
            Text(album.artist)
                .font(.system(size: 11))
                .lineLimit(1)
                .foregroundStyle(.secondary)
        }
    }
}
