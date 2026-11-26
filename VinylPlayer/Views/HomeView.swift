import SwiftUI

/// 主页：3D 音乐库。谜底黑胶的第一个界面是“翻唱片”，不是播放页。
struct HomeView: View {
    let albums: [Album]
    let currentID: Int64?
    let onSelect: (Album) -> Void
    let onSearch: () -> Void
    let onSettings: () -> Void

    @State private var position: CGFloat = 0
    @State private var dragStart: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w: CGFloat = geo.size.width
            let h: CGFloat = geo.size.height
            ZStack {
                backdrop(w: w, h: h)
                stack(w: w, h: h)
                topBar(w: w, h: h)
                bottomBar(w: w, h: h)
            }
        }
        .ignoresSafeArea()
    }

    private var frontAlbum: Album? {
        guard !albums.isEmpty else { return nil }
        let idx = min(max(0, Int(position.rounded())), albums.count - 1)
        return albums[idx]
    }

    private func backdrop(w: CGFloat, h: CGFloat) -> some View {
        let art: some View = Group {
            if let url = frontAlbum?.coverURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.black
                    }
                }
            } else if let tint = frontAlbum?.tint {
                Color(tint)
            } else {
                Color(red: 0.09, green: 0.10, blue: 0.12)
            }
        }
        return art
            .frame(width: w, height: h)
            .clipped()
            .blur(radius: 65)
            .overlay(Color.black.opacity(0.42))
            .ignoresSafeArea()
    }

    private func stack(w: CGFloat, h: CGFloat) -> some View {
        let cardW: CGFloat = w * 0.84
        let cardH: CGFloat = cardW * 0.56
        let step: CGFloat = cardH * 0.30
        let rot: Double = 64

        return ZStack {
            ForEach(Array(albums.enumerated()), id: \.element.id) { index, album in
                let d: CGFloat = CGFloat(index) - position
                if abs(d) < 4.2 {
                    let card = StackCard(album: album, isCurrent: album.id == currentID)
                        .frame(width: cardW, height: cardH)
                    let rotated = card.rotation3DEffect(
                        .degrees(rot),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .center,
                        perspective: 0.55
                    )
                    let scaled = rotated.scaleEffect(1 - min(abs(d), 3) * 0.045)
                    let faded = scaled.opacity(1 - min(abs(d), 3) * 0.20)
                    faded
                        .offset(y: d * step)
                        .zIndex(Double(10 - abs(d)))
                        .onTapGesture {
                            if abs(d) < 0.4 {
                                onSelect(album)
                            } else {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                    position = CGFloat(index)
                                    dragStart = CGFloat(index)
                                }
                            }
                        }
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    dragStart = position - value.translation.height / step
                }
                .onEnded { _ in
                    let target = dragStart.rounded()
                    let clamped = min(max(0, target), CGFloat(max(0, albums.count - 1)))
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        position = clamped
                        dragStart = clamped
                    }
                }
        )
        .offset(y: h * 0.02)
    }

    private func topBar(w: CGFloat, h: CGFloat) -> some View {
        let wordmark = Text("谜底黑胶")
            .font(.system(size: 13, weight: .semibold))
            .kerning(3)
            .foregroundStyle(.white.opacity(0.9))

        let search = iconButton("magnifyingglass", action: onSearch)
        let gear = iconButton("slider.horizontal.3", action: onSettings)

        let row = HStack(spacing: 16) {
            wordmark
            Spacer()
            search
            gear
        }
        .frame(width: w * 0.86)

        return row.position(x: w * 0.5, y: h * 0.085)
    }

    private func iconButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func bottomBar(w: CGFloat, h: CGFloat) -> some View {
        let shown = min(albums.count, 9)
        let active = min(max(0, Int(position.rounded())), max(0, shown - 1))
        let dots = HStack(spacing: 7) {
            ForEach(0..<shown, id: \.self) { i in
                Circle()
                    .fill(i == active ? Color.white.opacity(0.9) : Color.white.opacity(0.26))
                    .frame(width: 5, height: 5)
            }
        }
        let hint = Text(albums.isEmpty ? "没有唱片，点右上角搜索" : "上下滑动翻唱片 · 轻点唱针播放")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.white.opacity(0.45))
        let stack = VStack(spacing: 12) {
            dots
            hint
        }
        return stack.position(x: w * 0.5, y: h * 0.925)
    }
}
