import SwiftUI

struct SettingsSheet: View {
    @ObservedObject var engine: AudioEngine
    @Environment(\.dismiss) private var dismiss

    @State private var cookie = NetEase.cookie
    @State private var saved = false
    @State private var checking = false
    @State private var checkResult: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("网易云账号") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MUSIC_U cookie（会员曲目需要）")
                            .font(.system(size: 12, weight: .medium))
                        TextEditor(text: $cookie)
                            .frame(minHeight: 90)
                            .font(.system(size: 11, design: .monospaced))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 0.8)
                            )
                        Text("桌面浏览器登录 music.163.com，F12 → Application → Cookies，复制 MUSIC_U 那段值，写成 MUSIC_U=xxxxx。")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    Button(saved ? "已保存" : "保存") {
                        NetEase.cookie = cookie.trimmingCharacters(in: .whitespacesAndNewlines)
                        saved = true
                        engine.message = "cookie 已保存"
                    }
                }

                Section("当前播放") {
                    LabeledContent("专辑", value: engine.album?.name ?? "—")
                    LabeledContent("曲目", value: engine.track?.name ?? "—")
                    LabeledContent("音源", value: "网易云直连")
                    if let message = engine.message {
                        Text(message)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Section("连接自检") {
                    Button(checking ? "检测中…" : "检测网易云连通性") {
                        Task { await runCheck() }
                    }
                    if let checkResult {
                        Text(checkResult)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                Section("关于") {
                    LabeledContent("版本", value: "2.0 (2)")
                    LabeledContent("标识", value: "com.haojunnong.vinylplayer")
                    Text("界面参照谜底黑胶的公开截图重做：整屏封面底色、出血黑胶、右上唱臂、底部胶囊键、3D 唱片架、点线曲目表。")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
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

    private func runCheck() async {
        checking = true
        let raw = await NetEaseClient.probe(keyword: "范特西")
        do {
            let albums = try await NetEaseClient.searchAlbums(keyword: "范特西", limit: 3)
            if let first = albums.first {
                let detail = try await NetEaseClient.albumDetail(id: first.id)
                checkResult = "搜索 \(albums.count) 张 · 专辑 \(detail.tracks.count) 首\n\(raw.prefix(200))"
            } else {
                checkResult = "搜索无结果\n\(raw.prefix(200))"
            }
        } catch {
            checkResult = "失败：\(error.localizedDescription)\n\(raw.prefix(200))"
        }
        checking = false
    }

}
