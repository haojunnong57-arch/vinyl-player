import SwiftUI

/// 唱片：黑胶质感 + 中心圆形封面 + 旋转。
struct VinylDisc: View {
    let cover: UIImage?
    let tint: Color
    let playing: Bool
    let diameter: CGFloat

    @State private var accumulated: Double = 0
    @State private var startedAt: Date?

    private var degreesPerSecond: Double { 33.333 * 6.0 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            let angle: Double = angleAt(context.date)
            disc.rotationEffect(.degrees(angle))
        }
        .frame(width: diameter, height: diameter)
        .onAppear {
            if playing { startedAt = Date() }
        }
        .onChange(of: playing) { _, value in
            let now = Date()
            accumulated = angleAt(now)
            startedAt = value ? now : nil
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
        ZStack {
            baseDisc
            grooves
            sheen
            label
            spindle
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .overlay(outerRim)
        .shadow(color: .black.opacity(0.35), radius: diameter * 0.02, x: 0, y: diameter * 0.01)
    }

    private var baseDisc: some View {
        let colors: [Color] = [
            Color(white: 0.11),
            Color(white: 0.05),
            Color(white: 0.09)
        ]
        let gradient = RadialGradient(
            colors: colors,
            center: .center,
            startRadius: diameter * 0.1,
            endRadius: diameter * 0.5
        )
        return Circle().fill(gradient)
    }

    private var grooves: some View {
        ForEach(0..<52, id: \.self) { index in
            let inset: CGFloat = diameter * 0.028 + CGFloat(index) * diameter * 0.0042
            let opacity: Double = 0.020 + Double(index % 4) * 0.010
            let width: CGFloat = index % 7 == 0 ? 0.8 : 0.45
            let ring: some View = Circle().strokeBorder(Color.white.opacity(opacity), lineWidth: width)
            ring.padding(inset)
        }
    }

    private var sheen: some View {
        let colors: [Color] = [
            Color.white.opacity(0.16),
            Color.clear,
            Color.white.opacity(0.07),
            Color.clear,
            Color.white.opacity(0.12),
            Color.clear
        ]
        let gradient = AngularGradient(colors: colors, center: .center)
        return Circle()
            .fill(gradient)
            .blendMode(.screen)
            .opacity(0.55)
    }

    private var label: some View {
        let labelSize: CGFloat = diameter * 0.52
        let content: some View = Group {
            if let cover {
                Image(uiImage: cover)
                    .resizable()
                    .scaledToFill()
            } else {
                tint.opacity(0.9)
            }
        }
        let clipped = content
            .frame(width: labelSize, height: labelSize)
            .clipShape(Circle())
        let ring: some View = Circle()
            .strokeBorder(Color.black.opacity(0.35), lineWidth: 1.5)
            .frame(width: labelSize, height: labelSize)
        return clipped.overlay(ring)
    }

    private var spindle: some View {
        let hole: CGFloat = diameter * 0.028
        return Circle()
            .fill(Color.black.opacity(0.85))
            .frame(width: hole, height: hole)
            .overlay(Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5))
    }

    private var outerRim: some View {
        let colors: [Color] = [Color.white.opacity(0.22), Color.white.opacity(0.02)]
        let gradient = LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        return Circle().strokeBorder(gradient, lineWidth: 1)
    }
}

/// 唱臂：透明轴心片 + 黑色配重 + 银色臂杆 + 黑色唱头。
struct TonearmView: View {
    let size: CGFloat
    let engaged: Bool

    private var angle: Double { engaged ? -34 : -26 }

    var body: some View {
        ZStack(alignment: .top) {
            pivotPlate
            arm
        }
    }

    private var pivotPlate: some View {
        let plateSize: CGFloat = size * 0.30
        let fill = Color.white.opacity(0.06)
        let stroke = LinearGradient(
            colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let plate = Circle()
            .fill(fill)
            .frame(width: plateSize, height: plateSize)
        let rim: some View = Circle().strokeBorder(stroke, lineWidth: 1)
        return plate.overlay(rim)
    }

    private var arm: some View {
        let rodHeight: CGFloat = size * 0.50
        let rodWidth: CGFloat = size * 0.014
        let counter = counterweight
        let rod = Capsule()
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.92), Color(white: 0.55), Color(white: 0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: rodWidth, height: rodHeight)
        let head = headshell
        let stack = VStack(spacing: 0) {
            counter
            rod
            head
        }
        .rotationEffect(.degrees(angle), anchor: .top)
        .offset(y: size * 0.02)
        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: engaged)
        return stack
    }

    private var counterweight: some View {
        let w: CGFloat = size * 0.085
        let h: CGFloat = size * 0.062
        let body = RoundedRectangle(cornerRadius: size * 0.012, style: .continuous)
            .fill(Color(white: 0.10))
            .frame(width: w, height: h)
        let cap = RoundedRectangle(cornerRadius: size * 0.006, style: .continuous)
            .fill(Color(white: 0.18))
            .frame(width: w * 0.72, height: h * 0.36)
        return body.overlay(cap)
    }

    private var headshell: some View {
        let w: CGFloat = size * 0.105
        let h: CGFloat = size * 0.040
        let radians: Double = 22 * Double.pi / 180
        let body = RoundedRectangle(cornerRadius: size * 0.008, style: .continuous)
            .fill(Color(white: 0.08))
            .frame(width: w, height: h)
            .rotationEffect(.degrees(22))
            .offset(x: -w * 0.32, y: h * 0.2)
        let stylus: some View = Rectangle()
            .fill(Color(white: 0.03))
            .frame(width: size * 0.006, height: size * 0.022)
            .offset(x: -w * 0.32 + CGFloat(cos(radians)) * w * 0.30, y: h * 0.2 + CGFloat(sin(radians)) * w * 0.30)
        return ZStack {
            body
            stylus
        }
    }
}
