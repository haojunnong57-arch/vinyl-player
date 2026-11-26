// 谜底黑胶 Pro 解锁：拦截 RevenueCat 订阅信息，改成永久有效
// 适用于 Surge / Shadowrocket / Quantumult X / Loon 的 http-response 脚本
// 匹配：api.revenuecat.com/v1/subscribers/... 与 /v1/receipts

const FAR = "2099-12-31T23:59:59Z";
const FAR_MS = "4102415999000";
const BLOCKS = ["entitlements", "subscriptions", "non_subscriptions"];

function activate(item) {
  if (!item || typeof item !== "object") return;
  item.expires_date = FAR;
  item.expires_date_ms = FAR_MS;
  item.purchase_date = item.purchase_date || "2020-01-01T00:00:00Z";
  item.store = item.store || "app_store";
  item.is_sandbox = false;
  item.period_type = "normal";
  delete item.unsubscribe_detected_at;
  delete item.billing_issues_detected_at;
  delete item.refunded_at;
  delete item.cancellation_reason;
  delete item.grace_period_expires_date;
  delete item.grace_period_expires_date_ms;
}

function walk(node) {
  let changed = false;
  if (Array.isArray(node)) {
    node.forEach(function (child) {
      if (walk(child)) changed = true;
    });
    return changed;
  }
  if (!node || typeof node !== "object") return false;

  BLOCKS.forEach(function (key) {
    const block = node[key];
    if (!block || typeof block !== "object" || Array.isArray(block)) return;
    Object.keys(block).forEach(function (id) {
      activate(block[id]);
      changed = true;
    });
  });

  Object.keys(node).forEach(function (key) {
    const value = node[key];
    if (value && typeof value === "object") {
      if (walk(value)) changed = true;
    }
  });
  return changed;
}

(function () {
  const body = $response.body;
  if (!body) { $done({}); return; }
  let data;
  try {
    data = JSON.parse(body);
  } catch (e) {
    $done({});
    return;
  }
  if (!walk(data)) { $done({}); return; }

  const sub = data.subscriber || data;
  if (sub && typeof sub === "object") {
    if (!sub.first_seen) sub.first_seen = "2020-01-01T00:00:00Z";
    if (!sub.original_app_user_id) sub.original_app_user_id = "$RCAnonymousID:patched";
  }
  $done({ body: JSON.stringify(data) });
})();
