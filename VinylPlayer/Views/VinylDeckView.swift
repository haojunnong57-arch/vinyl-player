import SwiftUI

struct VinylDeckView: View {
    @ObservedObject var model: PlayerModel

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                plinth(side: side)
                platter(side: side)
                record(side: side)
                speedSwitch(side: side)
                tonearm(side: side)
                brand(side: side)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: 底座

    private func plinth(side: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: side * 0.075, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [model.theme.plinthTop, model.theme.plinthBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: side * 0.075, style: .continuous)
                    .stroke(model.theme.ink.opacity(0.10), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: side * 0.075, style: .continuous)
                    .inset(by: side * 0.012)
                    .stroke(model.theme.accent.opacity(0.10), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.55), radius: side * 0.06, x: 0, y: side * 0.03)
    }

    // MARK: 唱盘

    private func platter(side: CGFloat) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [model.theme.platter, model.theme.platter.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(Circle().stroke(model.theme.hardware.opacity(0.22), lineWidth: 1.4))
            .frame(width: side * 0.84, height: side * 0.84)
            .shadow(color: .black.opacity(0.6), radius: side * 0.04, y: side * 0.02)
            .offset(x: -side * 0.03, y: side * 0.015)
    }

    // MARK: 唱片

    private func record(side: CGFloat) -> some View {
        SpinningRecordView(
            side: side * 0.76,
            isPlaying: model.isPlaying,
            rpm: model.rpm,
            album: model.current,
            theme: model.theme
        )
        .offset(x: -side * 0.03, y: side * 0.015)
    }

    // MARK: 转速开关

    private func speedSwitch(side: CGFloat) -> some View {
        HStack(spacing: 6) {
            speedPill(side: side, label: "33⅓", active: model.rpm < 40) {
                model.rpm = 33.333
            }
            speedPill(side: side, label: "45", active: model.rpm >= 40) {
                model.rpm = 45
            }
        }
        .offset(x: -side * 0.27, y: side * 0.38)
    }

    private func speedPill(side: CGFloat, label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: side * 0.032, weight: .semibold, design: .monospaced))
                .foregroundStyle(active ? model.theme.plinthBottom : model.theme.ink.opacity(0.55))
                .padding(.horizontal, side * 0.022)
                .padding(.vertical, side * 0.012)
                .background(
                    Capsule().fill(active ? model.theme.accent : model.theme.hardware.opacity(0.16))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: 唱臂

    private func tonearm(side: CGFloat) -> some View {
        TonearmView(side: side, engaged: model.isPlaying, hardware: model.theme.hardware)
            .offset(x: side * 0.30, y: -side * 0.20)
    }

    // MARK: 铭牌

    private func brand(side: CGFloat) -> some View {
        VStack(spacing: 1) {
            Text("VINYL")
                .font(.system(size: side * 0.030, weight: .bold, design: .serif))
                .tracking(side * 0.008)
            Text("黑胶唱机")
                .font(.system(size: side * 0.022, weight: .regular))
                .tracking(side * 0.004)
        }
        .foregroundStyle(model.theme.ink.opacity(0.42))
        .offset(x: side * 0.28, y: side * 0.40)
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
            disc
                .rotationEffect(.degrees(angle(at: context.date)))
        }
        .onAppear {
            if isPlaying { startedAt = Date() }
        }
        .onChange(of: isPlaying) { _, playing in
            let now = Date()
            accumulated = angle(at: now)
            startedAt = playing ? now : nil
        }
    }

    private func angle(at date: Date) -> Double {
        guard let start = startedAt else {
            return accumulated.truncatingRemainder(dividingBy: 360)
        }
        let delta = date.timeIntervalSince(start) * degreesPerSecond
        return (accumulated + delta).truncatingRemainder(dividingBy: 360)
    }

    private var disc: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .overlay(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.10),
                            Color.clear,
                            Color.white.opacity(0.06),
                            Color.clear
                        ],
                        center: .center
                    )
                    .clipShape(Circle())
                )

            ForEach(0..<32, id: \.self) { index in
                Circle()
                    .stroke(Color.white.opacity(0.030 + Double(index % 3) * 0.008), lineWidth: 0.6)
                    .padding(side * (0.035 + CGFloat(index) * 0.0118))
            }

            label

            Circle()
                .fill(Color.black)
                .frame(width: side * 0.022, height: side * 0.022)
                .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 0.6))
        }
        .frame(width: side, height: side)
        .clipShape(Circle())
        .overlay(
            Circle().strokeBorder(
                LinearGradient(
                    colors: [Color.white.opacity(0.22), Color.white.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        )
        .shadow(color: .black.opacity(0.55), radius: side * 0.035, y: side * 0.015)
    }

    private var label: some View {
        ZStack {
            if let art = album?.art {
                Image(uiImage: art)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [album?.palette.top ?? Palette.fallback.top,
                             album?.palette.bottom ?? Palette.fallback.bottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(spacing: side * 0.008) {
                    Text(album?.title ?? "黑胶")
                        .font(.system(size: side * 0.045, weight: .semibold, design: .serif))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(album?.artist ?? "")
                        .font(.system(size: side * 0.026))
                        .opacity(0.75)
                        .lineLimit(1)
                }
                .foregroundStyle(theme.ink)
                .padding(side * 0.04)
            }
        }
        .frame(width: side * 0.36, height: side * 0.36)
        .clipShape(Circle())
        .overlay(Circle().stroke(theme.labelWarm.opacity(0.9), lineWidth: 1))
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
            Circle()
                .fill(
                    RadialGradient(
                        colors: [hardware, hardware.opacity(0.55)],
                        center: .center,
                        startRadius: 1,
                        endRadius: side * 0.05
                    )
                )
                .frame(width: side * 0.085, height: side * 0.085)
                .shadow(color: .black.opacity(0.5), radius: side * 0.012, y: 2)

            VStack(spacing: 0) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [hardware.opacity(0.95), hardware.opacity(0.65)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: side * 0.018, height: side * 0.30)

                RoundedRectangle(cornerRadius: side * 0.008, style: .continuous)
                    .fill(hardware)
                    .frame(width: side * 0.062, height: side * 0.03)
                    .rotationEffect(.degrees(-12))
                    .offset(x: -side * 0.012)
            }
            .offset(y: side * 0.018)
            .rotationEffect(.degrees(armAngle), anchor: .top)
            .animation(.spring(response: 0.7, dampingFraction: 0.72), value: engaged)
        }
    }
}
