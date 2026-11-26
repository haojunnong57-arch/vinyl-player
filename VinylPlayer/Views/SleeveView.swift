import SwiftUI

/// 曲目内页：编号 + 点线 + 3'57" 时长，和截图里的曲目表一致。
struct TrackListSheet: View {
    @ObservedObject var engine: AudioEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                    ForEach(Array((engine.album?.tracks ?? []).enumerated()), id: \.element.id) { offset, track in
                        row(offset: offset, track: track)
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color(.systemBackground))
            .navigationTitle(engine.album?.name ?? "曲目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        let art: some View = Group {
            if let cover = engine.cover {
                Image(uiImage: cover)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.secondary.opacity(0.2)
            }
        }
        let artwork = art
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

        let name = Text(engine.album?.name ?? "")
            .font(.system(size: 22, weight: .heavy))
            .lineLimit(2)
        let artist = Text(engine.album?.artist ?? "")
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
        let count = Text("\(engine.album?.tracks.count ?? 0) 首")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(.secondary)

        let text = VStack(alignment: .leading, spacing: 6) {
            name
            artist
            count
        }

        let row = HStack(alignment: .top, spacing: 14) {
            artwork
            text
            Spacer(minLength: 0)
        }

        return row.padding(18)
    }

    private func row(offset: Int, track: Track) -> some View {
        let active: Bool = offset == engine.index
        let number = Text(String(format: "%02d", offset + 1))
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(width: 26, alignment: .leading)
        let title = Text(track.name)
            .font(.system(size: 15, weight: active ? .semibold : .regular))
            .foregroundStyle(active ? Color.accentColor : Color.primary)
            .lineLimit(1)
        let leader = DottedLeader()
        let duration = Text(track.durationText)
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(.secondary)

        let content = HStack(spacing: 8) {
            number
            title
            leader
            duration
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .contentShape(Rectangle())

        return Button {
            if let album = engine.album {
                engine.play(album: album, index: offset)
            }
        } label: {
            content
        }
        .buttonStyle(.plain)
    }
}

struct DottedLeader: View {
    var body: some View {
        Line()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [1, 4]))
            .foregroundStyle(Color.secondary.opacity(0.5))
            .frame(height: 1)
            .frame(minWidth: 12)
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}
