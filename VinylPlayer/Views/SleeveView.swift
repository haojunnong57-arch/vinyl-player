import SwiftUI

/// 唱片内页：点封面翻到曲目列表，和拆开唱片封套一样。
struct SleeveView: View {
    @ObservedObject var model: PlayerModel
    @Environment(\.dismiss) private var dismiss
    @State private var flipped = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    flipCard
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.45)) { flipped.toggle() }
                        }

                    Text(flipped ? "轻点卡片翻回封面" : "轻点卡片查看曲目")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    trackList
                }
                .padding(18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(model.current?.title ?? "内页")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private var flipCard: some View {
        ZStack {
            coverCard
                .opacity(flipped ? 0 : 1)
                .rotation3DEffect(.degrees(flipped ? -90 : 0), axis: (x: 0, y: 1, z: 0))

            backCard
                .opacity(flipped ? 1 : 0)
                .rotation3DEffect(.degrees(flipped ? 0 : 90), axis: (x: 0, y: 1, z: 0))
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
    }

    private var coverCard: some View {
        ZStack(alignment: .bottomLeading) {
            if let art = model.current?.art {
                Image(uiImage: art)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [
                        model.current?.palette.top ?? Palette.fallback.top,
                        model.current?.palette.bottom ?? Palette.fallback.bottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack {
                    Spacer()
                    Image(systemName: "opticaldisc.fill")
                        .font(.system(size: 110, weight: .thin))
                        .foregroundStyle(.white.opacity(0.18))
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(model.current?.title ?? "")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                Text(model.current?.artist ?? "")
                    .font(.system(size: 13, weight: .medium))
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .padding(16)
            .shadow(radius: 6)
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
    }

    private var backCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("曲目")
                    .font(.system(size: 13, weight: .semibold))
                    .opacity(0.6)
                Spacer()
                Text("\(model.current?.tracks.count ?? 0) 首")
                    .font(.system(size: 11, design: .monospaced))
                    .opacity(0.45)
            }

            ForEach(Array((model.current?.tracks ?? []).enumerated()), id: \.element.id) { offset, track in
                HStack(spacing: 10) {
                    Text(String(format: "%02d", offset + 1))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .opacity(0.4)
                        .frame(width: 22, alignment: .leading)
                    Text(track.title)
                        .font(.system(size: 14, weight: offset == model.trackIndex ? .semibold : .regular))
                        .lineLimit(1)
                    Spacer()
                    Text(track.durationText)
                        .font(.system(size: 11, design: .monospaced))
                        .opacity(0.45)
                }
                .foregroundStyle(offset == model.trackIndex ? model.theme.accent : .primary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 300)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var trackList: some View {
        VStack(spacing: 0) {
            ForEach(Array((model.current?.tracks ?? []).enumerated()), id: \.element.id) { offset, track in
                Button {
                    if let album = model.current {
                        model.play(album: album, index: offset)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: offset == model.trackIndex && model.isPlaying
                              ? "waveform" : "opticaldisc")
                            .font(.system(size: 15))
                            .frame(width: 24)
                            .foregroundStyle(offset == model.trackIndex ? model.theme.accent : .secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                            Text(track.artist)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(track.durationText)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 11)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if offset < (model.current?.tracks.count ?? 0) - 1 {
                    Divider().padding(.leading, 36)
                }
            }
        }
        .padding(.horizontal, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
