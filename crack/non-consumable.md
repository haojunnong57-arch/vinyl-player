# 买断制内购（non-consumable）怎么破

谜底黑胶的 Pro 是 **US$14.99 一次性买断**（非消耗型内购），不是订阅。
这比订阅容易：官方解锁一次就永久有效，客户端普遍把结果缓存在本地，不需要每次向服务器换 token。

## 三条链路，对应三份脚本

| 抓包看到的域名 | 含义 | 脚本 |
|---|---|---|
| `api.revenuecat.com` | RevenueCat 下发权益 | `crack/revenuecat.js` |
| `buy.itunes.apple.com/verifyReceipt` | 客户端拿收据问苹果，自己解析 `status==0` | `crack/verifyreceipt.js` |
| 自家域名（`/vip` `/pro` `/purchase`） | 后端签发权益 | 需按字段名改脚本 |
| 三个都没有 | 纯本地 plist / Keychain 判断 | 见文末 |

`crack/vinyl-unlock.sgmodule` 已经把前两条都包含进去了，导入一次就行。

## verifyReceipt 这条要改一个值

App 会校验 `product_id` 是否对得上。先把抓包里请求体的 `product_id` 或返回里的 `in_app[].product_id` 读出来，
填到 `crack/verifyreceipt.js` 开头的 `PRODUCT_ID`。填错的表现是：App 不报错，但 Pro 仍然锁着。

## 纯本地判断（无网络请求）

这种情况抓包什么都没有。两条路：

1. **不越狱**：用 iMazing / Apple Configurator 做未加密备份，改 App 域里的 plist（`Library/Preferences/tech.miidii.MDVinyl.plist`），把 `pro` / `purchased` / `unlock` 这类键置真，整机还原。iOS 17 仍可用，但 Keychain 里存的就改不到。
2. **越狱**：`frida -U -f tech.miidii.MDVinyl -l re/midi-vinyl/frida_hook.js`，脚本会扫全部 ObjC 类里 `isPro/isPurchased/isUnlocked` 这类方法强制返回 true，并把 `NSUserDefaults` 里含 pro/purchased 的键改真。

## 判定小技巧

- Pro 页点“恢复购买”：如果它发一次网络请求 → 说明有服务端/收据校验；如果没有 → 基本就是本地 flag
- 断网打开 App，Pro 仍显示已解锁 → 说明结果缓存本地，破完能长期用
- 换 4G 再开一次变回锁 → 说明每次启动都重新校验，得把那条请求也拦下来

## 做完之后

- 杀进程重开，确认 Pro 还在
- 尽量别升级 App：新版本容易加证书固定，规则就失效了
- 代理 App 的证书要放在系统级信任里，否则 HTTPS 解密不生效
