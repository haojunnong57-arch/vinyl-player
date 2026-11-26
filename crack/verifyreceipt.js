// 伪造 App Store 收据校验通过（面向仍在使用 verifyReceipt 的 App）
// 匹配：buy.itunes.apple.com/verifyReceipt、sandbox.itunes.apple.com/verifyReceipt
//
// 注意：product_id 必须与 App 里的一致，否则 App 会认为“不是这个商品”。
// 真实 product_id 从抓包里看（请求体 JSON 里有 product_id / 返回里有 in_app[].product_id），
// 或从 App Store 页面“App 内购买项目”里读。下面先放占位值。

const PRODUCT_ID = "com.mdstudio.mdvinyl.pro";   // ← 换成抓到的真实值
const BUNDLE_ID = "tech.miidii.MDVinyl";        // ← 如果抓包里 bundle_id 不同，也改这里

const receipt = {
  bundle_id: BUNDLE_ID,
  application_version: "3.10",
  in_app: [
    {
      quantity: "1",
      product_id: PRODUCT_ID,
      transaction_id: "2000000000000001",
      original_transaction_id: "2000000000000001",
      purchase_date: "2020-01-01 00:00:00 Etc/GMT",
      purchase_date_ms: "1577836800000",
      original_purchase_date: "2020-01-01 00:00:00 Etc/GMT",
      original_purchase_date_ms: "1577836800000",
      is_trial_period: "false",
      in_app_ownership_type: "PURCHASED"
    }
  ]
};

const body = {
  status: 0,
  environment: "Production",
  receipt: receipt,
  latest_receipt_info: receipt.in_app,
  latest_receipt: "ZmFrZS1yZWNlaXB0LWZvci1sb2NhbC10ZXN0"
};

$done({
  status: 200,
  headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  body: JSON.stringify(body)
});
