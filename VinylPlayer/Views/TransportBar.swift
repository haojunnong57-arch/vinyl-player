import SwiftUI

struct TransportBar: View {
    @ObservedObject var model: PlayerModel

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(model.currentTrack?.title ?? "未在播放")
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Spacer(minLength: 6)
                Text("\(timeText(model.elapsed)) / \(timeText(model.duration))")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .opacity(0.6)
            }

            Slider(
                value: Binding(
                    get: { model.elapsed },
                    set: { model.seek(to: $0) }
                ),
                in: 0...max(model.duration, 1)
            )
            .tint(model.theme.accent)

            HStack(spacing: 44) {
                Button {
                    model.previous()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)

                Button {
                    model.playPause()
                } label: {
                    ZStack {
                        Circle()
                            .fill(model.theme.accent)
                            .frame(width: 62, height: 62)
                            .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
                        Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 23, weight: .bold))
                            .foregroundStyle(model.theme.plinthBottom)
                            .offset(x: model.isPlaying ? 0 : 1.5)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    model.next()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(model.theme.ink)
        }
        .foregroundStyle(model.theme.ink)
    }

    private func timeText(_ time: TimeInterval) -> String {
        let total = Int(time.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
