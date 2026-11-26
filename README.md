# 黑胶唱机 VinylPlayer

iPhone 上的虚拟黑胶唱机。放一张唱片，唱盘转起来，唱臂落针，封面像开唱片封套一样翻开看曲目。

SwiftUI 单 target，XcodeGen 生成工程，GitHub Actions 云编译出**未签名 IPA**，用 AltStore / Sideloadly / TrollStore 装。

## 功能

- **唱盘旋转**：`TimelineView` 驱帧，33⅓ / 45 RPM 两种转速，暂停即停在当前角度
- **唱臂落针**：播放时唱臂摆进去，暂停摆回来，弹簧动画
- **唱片视觉**：32 圈沟槽、角向高光、中心标签显示封面或专辑名
- **内页翻开**：点卡片 3D 翻转，正面封面、背面曲目表，下面还有完整曲目列表可直接点播
- **四种材质**：胡桃木 / 午夜黑 / 奶油白 / 深海蓝，只换材质不动布局
- **音源**：系统音乐库（MediaPlayer，不需要 MusicKit 授权），没授权或库里是空的就用内置演示唱片，画面照样转
- **播放控制**：进度条可拖、上下一首、播放/暂停

## 构建

推送到 `main` 即自动跑，或手动 `workflow_dispatch`：

1. `python3 tools/make_icon.py` 现画 1024 图标（纯标准库，无依赖）
2. `brew install xcodegen` → `xcodegen generate`
3. `xcodebuild ... CODE_SIGNING_ALLOWED=NO` 出 `.app`
4. 打包 `Payload` → `VinylPlayer-unsigned.ipa`
5. 自动发到 release `build-latest`，同时留 artifact 和完整 `build.log`

## 安装

- **TrollStore**（A12–A17 / iOS 14–17.x）：直接装，永久
- **Sideloadly / AltStore**：用自己 Apple ID 签，7 天续签
- 装完首次打开会问音乐库权限，允许即读专辑；不允许也有一张演示唱片

## 目录

```
project.yml                     XcodeGen 工程定义
.github/workflows/build.yml     云编译流水线
tools/make_icon.py              图标生成（纯 Python 写 PNG）
VinylPlayer/
  App/VinylPlayerApp.swift      入口
  Core/Theme.swift              四套唱机材质
  Core/Models.swift             唱片 / 曲目模型
  Core/PlayerModel.swift        播放中枢 + 演示唱片架
  Views/RootView.swift          主界面 + 背景 + 底部按钮
  Views/VinylDeckView.swift     唱盘 / 唱臂 / 旋转逻辑
  Views/TransportBar.swift      进度条与控制键
  Views/SleeveView.swift        内页翻转 + 曲目列表
  Views/LibraryView.swift       唱片库网格
  Views/SettingsSheet.swift     材质 / 转速 / 音源
```

## 已知边界

- 播放走 `MPMusicPlayerController`，需要系统音乐 App 里有内容（Apple Music 订阅或本机同步的歌）；没有就走演示模式
- 未签名 / 自签安装下不接 Apple Music 目录检索（那需要 MusicKit entitlement，免费签拿不到）
- 只做 iPhone 竖屏
