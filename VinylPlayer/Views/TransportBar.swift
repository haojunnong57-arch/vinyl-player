import SwiftUI

/// 底部三个胶囊键，键下挂文字 / 图标标注 —— 截图里就是这种实物按键感。
struct TransportBar: View {
    @ObservedObject var engine: AudioEngine

    var body: some View {
        let light: Bool = engine.isLightBackground
        let fill: Color = light ? Color.black.opacity(0.80) : Color.black.opacity(0.72)
        let labelColor: Color = light ? Color.black.opacity(0.70) : Color.white.opacity(0.88)

        let playCaption: String = engine.isPlaying ? "PAUSE" : "PLAY"
        let play = PillKey(
            caption: playCaption,
            icon: nil,
            widthRatio: 0.26,
            fill: fill,
            labelColor: labelColor,
            action: { engine.toggle() }
        )
        let back = PillKey(
            caption: nil,
            icon: "backward.end.fill",
            widthRatio: 0.18,
            fill: fill,
            labelColor: labelColor,
            action: { engine.previous() }
        )
        let forward = PillKey(
            caption: nil,
            icon: "forward.end.fill",
            widthRatio: 0.18,
            fill: fill,
            labelColor: labelColor,
            action: { engine.next() }
        )

        return HStack(alignment: .top, spacing: 0) {
            play
            Spacer(minLength: 0)
            back
            Spacer().frame(width: 18)
            forward
        }
    }
}

struct PillKey: View {
    let caption: String?
    let icon: String?
    let widthRatio: CGFloat
    let fill: Color
    let labelColor: Color
    let action: () -> Void

    var body: some View {
        GeometryReader { geo in
            let width: CGFloat = geo.size.width * widthRatio * 3.85
            let height: CGFloat = 36
            let pill = RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                .fill(fill)
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.8)
                )

            let label = Group {
                if let caption {
                    Text(caption)
                        .font(.system(size: 9, weight: .bold))
                        .kerning(1.4)
                        .foregroundStyle(labelColor)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(labelColor)
                }
            }

            let stack = VStack(spacing: 9) {
                pill
                label
            }

            Button(action: action) {
                stack
            }
            .buttonStyle(.plain)
            .position(x: geo.size.width / 2, y: height + 18)
        }
        .frame(height: 62)
    }
}
