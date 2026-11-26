import SwiftUI

struct SettingsSheet: View {
    @ObservedObject var model: PlayerModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("唱机材质") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 12)], spacing: 12) {
                        ForEach(DeckTheme.all) { theme in
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    model.themeID = theme.id
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [theme.plinthTop, theme.plinthBottom],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(height: 46)
                                        .overlay(
                                            Circle()
                                                .fill(theme.accent)
                                                .frame(width: 14, height: 14)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                                .stroke(
                                                    model.themeID == theme.id ? Color.accentColor : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                    Text(theme.name)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("转速") {
                    Picker("转速", selection: Binding(
                        get: { model.rpm < 40 ? 0 : 1 },
                        set: { model.rpm = $0 == 0 ? 33.333 : 45 }
                    )) {
                        Text("33⅓ RPM").tag(0)
                        Text("45 RPM").tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                Section("音源") {
                    LabeledContent("当前", value: model.sourceLabel)
                    if let notice = model.notice {
                        Text(notice)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Button("重新读取音乐库") {
                        Task { await model.loadLibraryIfPossible() }
                    }
                    Text("真实播放走系统音乐 App；没授权或库里没专辑时用内置演示唱片，唱片照样转。")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Section("关于") {
                    LabeledContent("版本", value: "1.0 (1)")
                    LabeledContent("标识", value: "com.haojunnong.vinylplayer")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
