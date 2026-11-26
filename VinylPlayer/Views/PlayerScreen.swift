import SwiftUI

struct PlayerScreen: View {
    @ObservedObject var engine: AudioEngine
    let onBack: () -> Void
    let onOpenTracks: () -> Void
    let onOpenSearch: () -> Void
    let onOpenSettings: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var armAngle: Double = -26

    var body: some View {
        GeometryReader { geo in
            let w: CGFloat = geo.size.width
            let h: CGFloat = geo.size.height
            ZStack {
                backdrop(w: w, h: h)
                discLayer(w: w, h: h)
                tonearmLayer(w: w, h: h)
                infoLayer(w: w, h: h)
                controlLayer(w: w, h: h)
                bannerLayer(w: w, h: h)
                topBar(w: w, h: h)
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(false)
    }

    // MARK: 背景

    private func backdrop(w: CGFloat, h: CGFloat) -> some View {
        let base = Color(engine.tint)
        let dark = base.opacity(0.55)
        let gradient = LinearGradient(
            colors: [base, dark],
            startPoint: .top,
            endPoint: .bottom
        )
        let blurryCover: some View = Group {
            if let cover = engine.cover {
                Image(uiImage: cover)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
                    .blur(radius: 70)
                    .opacity(0.28)
            }
        }
        return ZStack {
            gradient
            blurryCover
            GrainOverlay()
        }
        .frame(width: w, height: h)
        .clipped()
        .ignoresSafeArea()
    }

    // MARK: 唱片

    private func discLayer(w: CGFloat, h: CGFloat) -> some View {
        let diameter: CGFloat = w * 1.02
        let centerX: CGFloat = w * 0.40
        let centerY: CGFloat = h * 0.345
        let disc = VinylDisc(
            cover: engine.cover,
            tint: Color(engine.tint),
            playing: engine.isPlaying,
            diameter: diameter
        )
        return disc
            .position(x: centerX, y: centerY)
            .onTapGesture(count: 2) { onOpenTracks() }
            .simultaneousGesture(TapGesture().onEnded { engine.toggle() })
            .gesture(
                DragGesture(minimumDistance: 40)
                    .onEnded { value in
                        if value.translation.height < -50 { onOpenTracks() }
                        if value.translation.height > 50 { onBack() }
                    }
            )
    }

    // MARK: 唱臂

    private func tonearmLayer(w: CGFloat, h: CGFloat) -> some View {
        let size: CGFloat = w * 0.98
        let pivotX: CGFloat = w * 0.865
        let pivotY: CGFloat = h * 0.215
        let arm = TonearmView(size: size, angle: armAngle)
        return arm
            .frame(width: size, height: size)
            .position(x: pivotX, y: pivotY)
            .gesture(armGesture)
            .onChange(of: engine.isPlaying) { _, playing in
                withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                    armAngle = playing ? -34 : -26
                }
            }
    }

    /// 拖动唱臂：角度直接映射成播放进度；松手决定播放还是暂停
    private var armGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let raw: Double = -26 + Double(value.translation.height) * 0.12
                let clamped: Double = min(-6, max(-42, raw))
                armAngle = clamped
                let ratio: Double = (-clamped - 6) / 36.0
                if engine.duration > 0 {
                    engine.seek(ratio * engine.duration)
                }
            }
            .onEnded { _ in
                let onDisc: Bool = armAngle < -20
                if onDisc != engine.isPlaying {
                    engine.toggle()
                }
            }
    }

    // MARK: 标题

    private func infoLayer(w: CGFloat, h: CGFloat) -> some View {
        let title = Text((engine.album?.name ?? "未播放").uppercased())
            .font(.system(size: w * 0.088, weight: .heavy, design: .default))
            .kerning(-0.5)
            .lineLimit(1)
            .minimumScaleFactor(0.45)

        let artist = Text(engine.album?.artist ?? "网易云音乐")
            .font(.system(size: w * 0.040, weight: .regular))
            .opacity(0.72)
            .lineLimit(1)

        let trackLine = Text(engine.track.map { "\(String(format: "%02d", engine.index + 1))  \($0.name)" } ?? "")
            .font(.system(size: w * 0.032, weight: .medium))
            .opacity(0.5)
            .lineLimit(1)

        let stack = VStack(alignment: .leading, spacing: w * 0.012) {
            title
            artist
            trackLine
        }
        .foregroundStyle(engine.isLightBackground ? Color.black.opacity(0.85) : Color.white)
        .frame(width: w * 0.82, alignment: .leading)

        return stack.position(x: w * 0.5, y: h * 0.735)
    }

    // MARK: 控制键

    private func controlLayer(w: CGFloat, h: CGFloat) -> some View {
        let row = TransportBar(engine: engine)
            .frame(width: w * 0.86)
        return row.position(x: w * 0.5, y: h * 0.90)
    }


    // MARK: 状态提示

    private func bannerLayer(w: CGFloat, h: CGFloat) -> some View {
        let showing: Bool = engine.loading || engine.message != nil
        let text: String = engine.loading ? "正在连接网易云…" : (engine.message ?? "")
        let bubble = HStack(spacing: 8) {
            if engine.loading {
                ProgressView().scaleEffect(0.7)
            }
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8))
        .foregroundStyle(.white)
        .opacity(showing ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: showing)
        .frame(maxWidth: w * 0.82)
        .allowsHitTesting(false)

        return bubble.position(x: w * 0.5, y: h * 0.115)
    }

    // MARK: 顶部小按钮

    private func topBar(w: CGFloat, h: CGFloat) -> some View {
        let color: Color = engine.isLightBackground ? Color.black.opacity(0.55) : Color.white.opacity(0.65)
        let search = ghostButton(icon: "magnifyingglass", color: color, action: onOpenSearch)
        let list = ghostButton(icon: "list.bullet", color: color, action: onOpenTracks)
        let gear = ghostButton(icon: "slider.horizontal.3", color: color, action: onOpenSettings)
        let back = ghostButton(icon: "chevron.down", color: color, action: onBack)
        let row = HStack(spacing: 18) {
            search
            list
            gear
        }
        return ZStack {
            row.position(x: w * 0.80, y: h * 0.078)
            back.position(x: w * 0.11, y: h * 0.078)
        }
    }

    private func ghostButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 纸张颗粒：截图的背景有细微噪点，不是纯渐变。
struct GrainOverlay: View {
    var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 0x9E3779B97F4A7C15
            let count = 1600
            for _ in 0..<count {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                let rx = CGFloat((seed >> 33) & 0xFFFF) / 65535.0
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                let ry = CGFloat((seed >> 33) & 0xFFFF) / 65535.0
                let point = CGPoint(x: rx * size.width, y: ry * size.height)
                let rect = CGRect(x: point.x, y: point.y, width: 1.1, height: 1.1)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.05)))
            }
        }
        .blendMode(.overlay)
        .allowsHitTesting(false)
    }
}
