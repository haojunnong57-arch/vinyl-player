# 谜底黑胶 Pro 解锁（不改包、不越狱）

原理：这类 App 的 Pro 状态由 RevenueCat 下发到客户端，客户端拿到 `entitlements`
就改 UI 和功能开关。拦住这次响应、把它改成「永久有效」，重启 App 就是 Pro。

## 方案 A：手机自带代理 App（推荐，无需电脑）

适合：Shadowrocket / Quantumult X / Loon / Surge。

1. 装代理 App，新建配置。
2. 导入模块或规则：
   - Shadowrocket：配置 → 模块 → 添加 `crack/vinyl-unlock.sgmodule`（可填 raw 链接）
   - Quantumult X：把 `crack/revenuecat-qx.conf` 两段分别粘进 `[rewrite_local]` 和 `[mitm]`
3. **开 HTTPS 解密并安装证书**：
   - 设置 → 证书 → 生成/安装 CA → 到 iOS 设置 → 通用 → VPN与设备管理 → 安装
   - 再到 设置 → 通用 → 关于本机 → 证书信任设置 → 打开对该 CA 的完全信任
4. 启动代理，打开谜底黑胶，进 Pro 页面停 5 秒。
5. 从后台彻底划掉 App，重开 → 看 Pro 图标/功能是否解锁。

## 方案 B：电脑跑 mitmproxy（能看到具体报文，便于判断）

```bash
mitmdump -s re/midi-vinyl/mitm_revenuecat.py --set block_global=false
```
手机 Wi-Fi 代理指向电脑 8080，装并信任 mitm 证书，其余同上。
终端会打印每条 `api.revenuecat.com` 的原始响应，能直接看到订阅字段长什么样。

## 验证是否真的生效

- Pro 页面不再弹订阅，或显示已订阅
- 杀掉重开仍然是 Pro（说明是本地缓存生效）
- 换网络（4G）再开一次：如果变回免费，说明它还会用别的域名校准，得把那条也加上

## 拦不下来怎么办

按可能性排：

1. **TLS 握手失败**：App 做了证书固定（pinning）。这时脚本一次都不会触发。
   判断：代理日志里该域名是失败/断开，没有 response。
   解法：越狱设备 + Frida 去 pinning（`frida -U -f tech.miidii.MDVinyl -l frida_hook.js`，脚本里那段 `bypassPinning()` 取消注释）。
2. **走的是 StoreKit 2 服务端校验**：客户端把 `JWS` 交给自家服务器验，本地改不动。
   判断：抓包里看不到 revenuecat，只有自家域名 + `buy.itunes.apple.com`。
   解法：只能改客户端二进制（见下），或者不用这条路。
3. **请求没走代理**：App 用了自己的网络栈/HTTP2 直连。
   判断：代理日志里压根没这个域名。
   解法：改用「全局代理 + 增强模式」。

## 方案 C：改二进制（真正意义上的「破解」）

前提：拿到**解密后**的 ipa。App Store 下的是 FairPlay 加密的，直接反汇编是乱码。

```bash
# 越狱设备上导出解密包
bagbak tech.miidii.MDVinyl
# 或
frida-ios-dump -o MDVinyl.ipa tech.miidii.MDVinyl
```

拿到后：

```bash
unzip -o MDVinyl.ipa -d app
BIN=app/Payload/MDVinyl.app/MDVinyl
bash re/midi-vinyl/inspect.sh $BIN          # 找 isPro / entitlement / RevenueCat 符号
python3 re/midi-vinyl/patch_pro.py --binary $BIN --offset 0xXXXX --dry-run
python3 re/midi-vinyl/patch_pro.py --binary $BIN --offset 0xXXXX
codesign --force --deep --sign - app/Payload/MDVinyl.app
cd app && zip -qr ../MDVinyl-patched.ipa Payload
```

装：TrollStore（永久）或 Sideloadly（自签 7 天）。

## 说明

- 这套只改本机行为，不动对方服务器。
- 会员曲库/版权内容不在这条链路里，解锁的是 App 自己的 Pro 功能（主题、界面、Roon 等）。
