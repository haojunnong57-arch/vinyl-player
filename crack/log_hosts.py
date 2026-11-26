#!/usr/bin/env python3
"""mitmproxy 插件：只记可疑域名，并把响应体落盘，方便事后看字段。

用法:
    mitmdump -p 8080 --set block_global=false -s crack/log_hosts.py
"""
import os
import re

from mitmproxy import ctx, http

LOG = os.environ.get("MDV_LOG", "hosts.log")
OUTDIR = os.path.dirname(LOG) or "."

INTEREST = re.compile(
    r"(revenuecat|itunes|apple\.com|mdvinyl|miidii|vip|pro|purchase|verify|receipt|subscribe|entitle)",
    re.I,
)
DUMP = re.compile(r"(revenuecat|verifyReceipt|/vip|/pro|/purchase|subscribe|entitle)", re.I)


def _write(line: str) -> None:
    os.makedirs(OUTDIR, exist_ok=True)
    with open(LOG, "a", encoding="utf-8") as fh:
        fh.write(line)
        fh.flush()


def response(flow: http.HTTPFlow) -> None:
    url = flow.request.pretty_url
    if not INTEREST.search(url):
        return

    body = flow.response.content or b""
    line = f"{flow.request.method} {url} -> {flow.response.status_code} ({len(body)}B)\n"
    _write(line)
    ctx.log.info(line.strip())

    if DUMP.search(url):
        name = re.sub(r"[^A-Za-z0-9]+", "_", url)[:110] + ".json"
        try:
            with open(os.path.join(OUTDIR, name), "wb") as fh:
                fh.write(body)
        except OSError:
            pass


def done() -> None:
    path = os.path.abspath(LOG)
    ctx.log.info(f"抓包结束，日志在 {path}，把这个文件发回去就能判定走哪条校验链路。")
