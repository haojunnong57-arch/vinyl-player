import SwiftUI

// 注意：这个文件里每个修饰符链都拆成带显式类型的局部变量。
// 成因：链式 .fill().overlay().shadow() + CGFloat 运算会让 Swift 类型推断超时
// （上次构建就是 VinylDeckView.swift:49 报 "unable to type-check in reasonable time"）。

struct VinylDeckView: View {
    @ObservedObject var model: PlayerModel

    var body: some View {
        GeometryReader { geo in
            let side: CGFloat = min(geo.size.width, geo.size.height)
            deck(side: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func deck(side: CGFloat) -> some View {
        ZStack {
            plinth(side: side)
            platter(side: side)
            record(side: side)
            speedSwitch(side: side)
            tonearm(side: side)
            brand(side: side)
        }
    }

    // MARK: 底座

    private func plinth(side: CGFloat) -> some View {
        let radius: CGFloat = side * 0.075
        let colors: [Color] = [model.theme.plinthTop, model.theme.plinthBottom]
        let gradient = LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
        let base = RoundedRectangle(cornerRadius: radius, style: .continuous).fill(gradient)
        let outline: some View = RoundedRectangle(cornerRadius: radius, style: .continuous)
            .stroke(model.theme.ink.opacity(0.10), lineWidth: 1)
        let inner: some View = RoundedRectangle(cornerRadius: radius, style: .continuous)
            .inset(by: side * 0.012)
            .stroke(model.theme.accent.opacity(0.10), lineWidth: 0.8)
        let stroked: some View = base.overlay(outline).overlay(inner)
        return stroked.shadow(color: Color.black.opacity(0.55), radius: side * 0.06, x: 0, y: side * 0.03)
    }

    // MARK: 唱盘

    private func platter(side: CGFloat) -> some View {
        let diameter: CGFloat = side * 0.84
        let colors: [Color] = [model.theme.platter, model.theme.platter.opacity(0.55)]
        let gradient = LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        let face = Circle().fill(gradient)
        let rim: some View = Circle().stroke(model.theme.hardware.opacity(0.22), lineWidth: 1.4)
        let sized: some View = face.overlay(rim).frame(width: diameter, height: diameter)
        let shadowed: some View = sized.shadow(color: Color.black.opacity(0.6), radius: side * 0.04, x: 0, y: side * 0.02)
        return shadowed.offset(x: -side * 0.03, y: side * 0.015)
    }

    // MARK: 唱片

    private func record(side: CGFloat) -> some View {
        let diameter: CGFloat = side * 0.76
        let spinning = SpinningRecordView(
            side: diameter,
            isPlaying: model.isPlaying,
            rpm: model.rpm,
            album: model.current,
            theme: model.theme
        )
        return spinning.offset(x: -side * 0.03, y: side * 0.015)
    }

    // MARK: 转速开关

    private func speedSwitch(side: CGFloat) -> some View {
        let fast: Bool = model.rpm >= 40
        let slow: Bool = !fast
        let row = HStack(spacing: 6) {
            speedPill(side: side, label: "33⅓", active: slow) {
                model.rpm = 33.333
            }
            speedPill(side: side, label: "45", active: fast) {
                model.rpm = 45
            }
        }
        return row.offset(x: -side * 0.27, y: side * 0.38)
    }

    private func speedPill(side: CGFloat, label: String, active: Bool, action: @escaping () -> Void) -> some View {
        let fontSize: CGFloat = side * 0.032
        let hPad: CGFloat = side * 0.022
        let vPad: CGFloat = side * 0.012
        let fillColor: Color = active ? model.theme.accent : model.theme.hardware.opacity(0.16)
        let textColor: Color = active ? model.theme.plinthBottom : model.theme.ink.opacity(0.55)
        let background: some View = Capsule().fill(fillColor)
        let caption = Text(label)
            .font(.system(size: fontSize, weight: .semibold, design: .monospaced))
            .foregroundStyle(textColor)
        return Button(action: action) {
            caption
                .padding(.horizontal, hPad)
                .padding(.vertical, vPad)
                .background(background)
        }
        .buttonStyle(.plain)
    }

    // MARK: 唱臂

    private func tonearm(side: CGFloat) -> some View {
        let arm = TonearmView(side: side, engaged: model.isPlaying, hardware: model.theme.hardware)
        return arm.offset(x: side * 0.30, y: -side * 0.20)
    }

    // MARK: 铭牌

    private func brand(side: CGFloat) -> some View {
        let titleSize: CGFloat = side * 0.030
        let subSize: CGFloat = side * 0.022
        let color: Color = model.theme.ink.opacity(0.42)
        let title = Text("VINYL")
            .font(.system(size: titleSize, weight: .bold, design: .serif))
            .foregroundStyle(color)
        let subtitle = Text("黑胶唱机")
            .font(.system(size: subSize, weight: .regular))
            .foregroundStyle(color)
        let plate = VStack(spacing: 1) {
            title
            subtitle
        }
        return plate.offset(x: side * 0.28, y: side * 0.40)
    }
}

// MARK: - 旋转唱片

struct SpinningRecordView: View {
    let side: CGFloat
    let isPlaying: Bool
    let rpm: Double
    let album: VinylAlbum?
    let theme: DeckTheme

    @State private var accumulated: Double = 0
    @State private var startedAt: Date?

    private var degreesPerSecond: Double { rpm * 6.0 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            let angle: Double = angleAt(context.date)
            disc.rotationEffect(.degrees(angle))
        }
        .onAppear {
            if isPlaying { startedAt = Date() }
        }
        .onChange(of: isPlaying) { _, playing in
            let now = Date()
            accumulated = angleAt(now)
            startedAt = playing ? now : nil
        }
    }

    private func angleAt(_ date: Date) -> Double {
        guard let start = startedAt else {
            return accumulated.truncatingRemainder(dividingBy: 360)
        }
        let delta: Double = date.timeIntervalSince(start) * degreesPerSecond
        return (accumulated + delta).truncatingRemainder(dividingBy: 360)
    }

    private var disc: some View {
        let rim: some View = Circle().strokeBorder(
            LinearGradient(
                colors: [Color.white.opacity(0.22), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 1
        )
        let bodyView = ZStack {
            blackFace
            grooves
            label
            spindle
        }
        .frame(width: side, height: side)
        .clipShape(Circle())
        .overlay(rim)
        return bodyView.shadow(color: Color.black.opacity(0.55), radius: side * 0.035, x: 0, y: side * 0.015)
    }

    private var blackFace: some View {
        let sheen = AngularGradient(
            colors: [
                Color.white.opacity(0.10),
                Color.clear,
                Color.white.opacity(0.06),
                Color.clear
            ],
            center: .center
        )
        let shine: some View = sheen.clipShape(Circle())
        return Circle().fill(Color.black).overlay(shine)
    }

    private var grooves: some View {
        ForEach(0..<32, id: \.self) { index in
            let inset: CGFloat = side * (0.035 + CGFloat(index) * 0.0118)
            let opacity: Double = 0.030 + Double(index % 3) * 0.008
            let stroke: some View = Circle().stroke(Color.white.opacity(opacity), lineWidth: 0.6)
            stroke.padding(inset)
        }
    }

    private var label: some View {
        let ring: some View = Circle().stroke(theme.labelWarm.opacity(0.9), lineWidth: 1)
        let sized = labelContent
            .frame(width: side * 0.36, height: side * 0.36)
            .clipShape(Circle())
        return sized.overlay(ring)
    }

    @ViewBuilder private var labelContent: some View {
        if let art = album?.art {
            Image(uiImage: art)
                .resizable()
                .scaledToFill()
        } else {
            gradientLabel
        }
    }

    private var gradientLabel: some View {
        let top: Color = album?.palette.top ?? Palette.fallback.top
        let bottom: Color = album?.palette.bottom ?? Palette.fallback.bottom
        let gradient = LinearGradient(colors: [top, bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
        let title = Text(album?.title ?? "黑胶")
            .font(.system(size: side * 0.045, weight: .semibold, design: .serif))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        let artist = Text(album?.artist ?? "")
            .font(.system(size: side * 0.026))
            .opacity(0.75)
            .lineLimit(1)
        let stack = VStack(spacing: side * 0.008) {
            title
            artist
        }
        .foregroundStyle(theme.ink)
        .padding(side * 0.04)
        return gradient.overlay(stack)
    }

    private var spindle: some View {
        let holeRing: some View = Circle().stroke(Color.white.opacity(0.25), lineWidth: 0.6)
        let dot = Circle()
            .fill(Color.black)
            .frame(width: side * 0.022, height: side * 0.022)
        return dot.overlay(holeRing)
    }
}

// MARK: - 唱臂

struct TonearmView: View {
    let side: CGFloat
    let engaged: Bool
    let hardware: Color

    private var armAngle: Double { engaged ? 26 : 6 }

    var body: some View {
        ZStack(alignment: .top) {
            pivot
            armAssembly
        }
    }

    private var pivot: some View {
        let colors: [Color] = [hardware, hardware.opacity(0.55)]
        let gradient = RadialGradient(
            colors: colors,
            center: .center,
            startRadius: 1,
            endRadius: side * 0.05
        )
        let diameter: CGFloat = side * 0.085
        let circle = Circle().fill(gradient).frame(width: diameter, height: diameter)
        return circle.shadow(color: Color.black.opacity(0.5), radius: side * 0.012, x: 0, y: 2)
    }

    private var armAssembly: some View {
        let colors: [Color] = [hardware.opacity(0.95), hardware.opacity(0.65)]
        let gradient = LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
        let rod = Capsule()
            .fill(gradient)
            .frame(width: side * 0.018, height: side * 0.30)
        let headRotation: Double = -12
        let head = RoundedRectangle(cornerRadius: side * 0.008, style: .continuous)
            .fill(hardware)
            .frame(width: side * 0.062, height: side * 0.03)
            .rotationEffect(.degrees(headRotation))
            .offset(x: -side * 0.012)
        let stack = VStack(spacing: 0) {
            rod
            head
        }
        .offset(y: side * 0.018)
        .rotationEffect(.degrees(armAngle), anchor: .top)
        return stack.animation(.spring(response: 0.7, dampingFraction: 0.72), value: engaged)
    }
}
