import SwiftUI

/// 底部三倀胶囊键：键面是实物黑键，标注挂在键下方。
struct TransportBar: View {
    @ObservedObject var engine: AudioEngine

    var body: some View {
        GeometryReader { geo in
            let barW: CGFloat = geo.size.width
            let keyH: CGFloat = 36
            let light: Bool = engine.isLightBackground
            let fill: Color = light ? Color.black.opacity(0.80) : Color.black.opacity(0.72)
            let labelColor: Color = light ? Color.black.opacity(0.70) : Color.white.opacity(0.88)
            let playCaption: String = engine.isPlaying ? "PAUSE" : "PLAY"

            let play = PillKey(
                caption: playCaption,
                icon: nil,
                width: barW * 0.235,
                height: keyH,
                fill: fill,
                labelColor: labelColor,
                action: { engine.toggle() }
            )
            let back = PillKey(
                caption: nil,
                icon: "backward.end.fill",
                width: barW * 0.155,
                height: keyH,
                fill: fill,
                labelColor: labelColor,
                action: { engine.previous() }
            )
            let forward = PillKey(
                caption: nil,
                icon: "forward.end.fill",
                width: barW * 0.155,
                height: keyH,
                fill: fill,
                labelColor: labelColor,
                action: { engine.next() }
            )

            HStack(alignment: .top, spacing: 0) {
                play
                Spacer(minLength: 0)
                back
                Spacer().frame(width: 16)
                forward
            }
        }
        .frame(height: keyHeight)
    }

    private var keyHeight: CGFloat { 36 + 9 + 13 }
}

struct PillKey: View {
    let caption: String?
    let icon: String?
    let width: CGFloat
    let height: CGFloat
    let fill: Color
    let labelColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 9) {
                pill
                labelView
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PillPressStyle())
    }

    private var pill: some View {
        let shape = RoundedRectangle(cornerRadius: height / 2, style: .continuous)
        let rim: some View = shape.strokeBorder(Color.white.opacity(0.10), lineWidth: 0.8)
        return shape.fill(fill).frame(width: width, height: height).overlay(rim)
    }

    @ViewBuilder private var labelView: some View {
        if let caption {
            Text(caption)
                .font(.system(size: 9, weight: .bold))
                .kerning(1.4)
                .foregroundStyle(labelColor)
        } else if let icon {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(labelColor)
        } else {
            Color.clear.frame(height: 12)
        }
    }
}

struct PillPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
