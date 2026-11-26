import SwiftUI

struct RootView: View {
    @StateObject private var model = PlayerModel()
    @State private var showLibrary = false
    @State private var showSleeve = false
    @State private var showSettings = false

    private let ticker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        let theme = model.theme
        ZStack {
            DeckBackground(theme: theme)

            VStack(spacing: 10) {
                HeaderView(model: model)

                VinylDeckView(model: model)

                TransportBar(model: model)

                HStack(spacing: 10) {
                    DeckButton(title: "唱片库", icon: "square.stack", theme: theme) {
                        showLibrary = true
                    }
                    DeckButton(title: "内页", icon: "book.closed", theme: theme) {
                        showSleeve = true
                    }
                    DeckButton(title: "设置", icon: "slider.horizontal.3", theme: theme) {
                        showSettings = true
                    }
                }
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
        }
        .preferredColorScheme(theme.prefersLight ? .light : .dark)
        .task { await model.bootstrap() }
        .onReceive(ticker) { _ in model.tick() }
        .sheet(isPresented: $showLibrary) {
            LibraryView(model: model)
        }
        .sheet(isPresented: $showSleeve) {
            SleeveView(model: model)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(model: model)
        }
    }
}

// MARK: - 顶栏

struct HeaderView: View {
    @ObservedObject var model: PlayerModel

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.current?.title ?? "未选择唱片")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .lineLimit(1)
                Text(model.current?.artist ?? "放一张唱片试试")
                    .font(.system(size: 12, weight: .medium))
                    .opacity(0.62)
                    .lineLimit(1)
            }
            Spacer()
            Text(model.sourceLabel)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .overlay(
                    Capsule().stroke(model.theme.ink.opacity(0.35), lineWidth: 0.8)
                )
                .opacity(0.9)
        }
        .foregroundStyle(model.theme.ink)
    }
}

// MARK: - 背景

struct DeckBackground: View {
    let theme: DeckTheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [theme.plinthTop, theme.plinthBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [theme.accent.opacity(0.14), Color.clear],
                center: .top,
                startRadius: 10,
                endRadius: 560
            )
            RadialGradient(
                colors: [Color.black.opacity(0.35), Color.clear],
                center: .bottom,
                startRadius: 30,
                endRadius: 480
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - 底部小按钮

struct DeckButton: View {
    let title: String
    let icon: String
    let theme: DeckTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                Text(title).font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(theme.ink.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.hardware.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(theme.ink.opacity(0.16), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }
}
