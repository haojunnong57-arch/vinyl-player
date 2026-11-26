import SwiftUI

/// 唱片库：封面像唱片一样竖着插在架子里，3D 透视前后堆叠。
struct LibraryStackView: View {
    let albums: [Album]
    let currentID: Int64?
    let onSelect: (Album) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var position: CGFloat = 0
    @State private var dragStart: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w: CGFloat = geo.size.width
            let h: CGFloat = geo.size.height
            ZStack {
                backdrop(w: w, h: h)
                stack(w: w, h: h)
                chrome(w: w, h: h)
            }
        }
        .ignoresSafeArea()
        .onAppear { anchorToCurrent() }
    }

    private func anchorToCurrent() {
        if let id = currentID, let idx = albums.firstIndex(where: { $0.id == id }) {
            position = CGFloat(idx)
        }
    }

    // MARK: 背景

    private func backdrop(w: CGFloat, h: CGFloat) -> some View {
        let front = currentAlbum
        let base: some View = Group {
            if let url = front?.coverURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.black
                    }
                }
            } else {
                Color(red: 0.10, green: 0.11, blue: 0.13)
            }
        }
        return base
            .frame(width: w, height: h)
            .clipped()
            .blur(radius: 60)
            .overlay(Color.black.opacity(0.45))
            .ignoresSafeArea()
    }

    private var currentAlbum: Album? {
        guard !albums.isEmpty else { return nil }
        let idx = Int(position.rounded())
        let clamped = min(max(0, idx), albums.count - 1)
        return albums[clamped]
    }

    // MARK: 卡片堆

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

    // MARK: 顶部与指示器

    private func chrome(w: CGFloat, h: CGFloat) -> some View {
        let title = Text("唱片库")
            .font(.system(size: 13, weight: .semibold))
            .kerning(2)
            .foregroundStyle(.white.opacity(0.85))

        let close = Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.white.opacity(0.10)))
        }
        .buttonStyle(.plain)

        let top = HStack {
            title
            Spacer()
            close
        }
        .frame(width: w * 0.86)

        let dots = pageDots

        return ZStack {
            top.position(x: w * 0.5, y: h * 0.085)
            dots.position(x: w * 0.5, y: h * 0.93)
        }
    }

    private var pageDots: some View {
        let shown = min(albums.count, 9)
        let active = min(max(0, Int(position.rounded())), max(0, shown - 1))
        return HStack(spacing: 7) {
            ForEach(0..<shown, id: \.self) { i in
                Circle()
                    .fill(i == active ? Color.white.opacity(0.9) : Color.white.opacity(0.28))
                    .frame(width: 5, height: 5)
            }
        }
    }
}

/// 一张插在架子里的封面：顶部色条写歌名 / 艺人，下面是封面图。
struct StackCard: View {
    let album: Album
    let isCurrent: Bool

    var body: some View {
        let strip = Color(album.tint ?? UIColor(red: 0.20, green: 0.35, blue: 0.55, alpha: 1))
        let stripText = Text(album.name)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.black.opacity(0.85))
            .lineLimit(1)
        let artistText = Text(album.artist)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.black.opacity(0.62))
            .lineLimit(1)
        let stripRow = HStack(spacing: 6) {
            stripText
            artistText
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(strip)

        let art: some View = Group {
            if let url = album.coverURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.black.opacity(0.6)
                    }
                }
            } else {
                Color.black.opacity(0.6)
            }
        }

        let bodyCard = VStack(spacing: 0) {
            stripRow
            art.clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.white.opacity(isCurrent ? 0.55 : 0.15), lineWidth: isCurrent ? 1.6 : 0.8)
        )

        return bodyCard.shadow(color: .black.opacity(0.45), radius: 14, x: 0, y: 10)
    }
}
