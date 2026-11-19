#!/usr/bin/env python3
"""把机场订阅里的单个节点转成 sing-box 1.14 完整配置（TUN 透明代理 + 本地 mixed），隐私优先，全部本地转换。

用法：
  # 列出订阅所有节点（找到洛杉矶节点的名字/序号）
  python3 node2singbox.py --sub "https://.../api/v1/liangxin?OwO=xxx" --list

  # 按名字(备注)匹配生成配置；--match 也可匹配服务器地址
  python3 node2singbox.py --sub "<订阅URL>" --match "洛杉矶01" --out ~/.config/orbstack-agent/config.json

  # 或用 --list 里的序号选择(不确定备注时的“按 id 选”)
  python3 node2singbox.py --sub "<订阅URL>" --index 2 --out ~/.config/orbstack-agent/config.json

  # 直接给单个分享链接
  python3 node2singbox.py --link "vless://...#LA" --out config.json

支持协议：vless / vmess / trojan / ss / hysteria2。生成的配置：TUN(auto_route+strict_route)兜底全局，
route 里 sniff + hijack-dns 劫持所有 53 端口流量，并保留 127.0.0.1:7890 mixed 供调试显式使用。
所有出站走节点，DNS 走代理，避免泄漏真实 IP。

注意：fetch_sub 走 urllib，遵守 http_proxy/https_proxy，境内直连订阅站常被 429/断连，先 export 代理再跑。
"""
import sys, json, base64, time, urllib.request, ssl, urllib.parse as up

MIXED_PORT = 7890
TUN_ADDR = "172.19.0.1/30"

def b64d(s: str) -> bytes:
    s = s.strip().replace('-', '+').replace('_', '/')
    s += '=' * (-len(s) % 4)
    return base64.b64decode(s)

def q(params, key, default=None):
    return params.get(key, [default])[0] if key in params else default

def tls_block(sni=None, reality=None, fp=None, insecure=False):
    """构造 sing-box tls 对象；reality=(pbk,sid)。"""
    t = {"enabled": True}
    if sni: t["server_name"] = sni
    if insecure: t["insecure"] = True
    if reality:
        t["reality"] = {"enabled": True, "public_key": reality[0], "short_id": reality[1]}
    if fp: t["utls"] = {"enabled": True, "fingerprint": fp}
    return t

def transport_block(query):
    net = q(query, "type", "tcp"); host = q(query, "host"); path = q(query, "path", "/")
    if net == "ws":
        return {"type": "ws", "path": path, "headers": ({"Host": host} if host else {})}
    if net in ("grpc", "gun"):
        return {"type": "grpc", "service_name": q(query, "serviceName", q(query, "path", "")).lstrip("/")}
    if net in ("http", "h2"):
        return {"type": "http", "host": [host] if host else [], "path": path}
    return None  # tcp/kcp/quic 等：kcp/quic 未处理

def parse(link: str) -> dict:
    if "://" not in link:
        raise SystemExit("不是合法的分享链接（缺少 ://）")
    proto = link.split("://", 1)[0].lower()
    rest = link.split("://", 1)[1]
    name = up.unquote(rest.split("#", 1)[1]) if "#" in rest else ""
    rest = rest.split("#", 1)[0]

    if proto == "vless":
        userinfo, hostport = rest.split("@", 1)
        uuid = up.unquote(userinfo)
        hp = split_hostport(hostport)
        query = dict(up.parse_qs(up.urlsplit("x://" + hostport).query))
        sec = q(query, "security", "none"); net = q(query, "type", "tcp")
        sni = q(query, "sni") or q(query, "peer") or q(query, "host")
        fp = q(query, "fp", "chrome"); flow = q(query, "flow")
        ob = {"type": "vless", "server": hp[0], "server_port": hp[1], "uuid": uuid,
              "packet_encoding": "xudp"}
        if flow: ob["flow"] = flow
        if sec == "reality":
            ob["tls"] = tls_block(sni, reality=(q(query, "pbk"), q(query, "sid", "")), fp=fp)
        elif sec == "tls":
            ob["tls"] = tls_block(sni, insecure=(q(query, "allowInsecure") in ("1", "true")), fp=fp)
        tr = transport_block(query)
        if tr: ob["transport"] = tr
        ob["_name"] = name; ob["_proto"] = "vless"
        return ob

    if proto == "trojan":
        pw, hostport = rest.split("@", 1)
        hp = split_hostport(hostport)
        query = dict(up.parse_qs(up.urlsplit("x://" + hostport).query))
        sni = q(query, "sni") or q(query, "peer")
        fp = q(query, "fp", "chrome")
        ob = {"type": "trojan", "server": hp[0], "server_port": hp[1], "password": up.unquote(pw),
              "tls": tls_block(sni, insecure=(q(query, "allowInsecure") in ("1", "true")), fp=fp)}
        tr = transport_block(query)
        if tr: ob["transport"] = tr
        ob["_name"] = name; ob["_proto"] = "trojan"
        return ob

    if proto == "ss":
        if "@" in rest:  # SIP002
            b64, hostport = rest.split("@", 1)
            hp = split_hostport(hostport)
            method, password = b64d(b64).decode().split(":", 1)
        else:            # legacy ss://base64(method:password@host:port)
            whole = b64d(rest).decode()
            method, remainder = whole.split(":", 1)
            password, hostport = remainder.rsplit("@", 1)
            hp = split_hostport(hostport)
        ob = {"type": "shadowsocks", "server": hp[0], "server_port": hp[1],
              "method": method, "password": password}
        # 注意：obfs/v2ray-plugin 等插件此处忽略
        ob["_name"] = name; ob["_proto"] = "ss"
        return ob

    if proto == "vmess":
        data = json.loads(b64d(rest).decode())
        query = {"type": [data.get("net", "tcp")], "host": [data.get("host", "")],
                 "path": [data.get("path", "/")], "serviceName": [data.get("path", "")]}
        ob = {"type": "vmess", "server": data["add"], "server_port": int(data["port"]),
              "uuid": data["id"], "security": data.get("scy", "auto"),
              "alter_id": int(data.get("aid", 0))}
        if data.get("tls"): ob["tls"] = tls_block(data.get("sni") or data.get("host"), fp=data.get("fp"))
        tr = transport_block(query)
        if tr: ob["transport"] = tr
        ob["_name"] = data.get("ps", name); ob["_proto"] = "vmess"
        return ob

    if proto in ("hysteria2", "hy2"):
        auth, hostport = rest.split("@", 1)
        query = dict(up.parse_qs(up.urlsplit("x://" + hostport).query))
        hp = split_hostport(hostport)
        insecure = (q(query, "insecure") in ("1", "true")) or (q(query, "allowInsecure") in ("1", "true"))
        ob = {"type": "hysteria2", "server": hp[0], "server_port": hp[1], "password": up.unquote(auth),
              "tls": tls_block(q(query, "sni") or q(query, "peer"), insecure=insecure)}
        if q(query, "obfs"): ob["obfs"] = {"type": q(query, "obfs"), "password": q(query, "obfs-password", "")}
        ob["_name"] = name; ob["_proto"] = "hysteria2"
        return ob

    raise SystemExit(f"暂不支持的协议: {proto}")

def split_hostport(hostport: str):
    hostport = hostport.split("?")[0].split("/")[0]
    if hostport.startswith("["):                       # IPv6
        host, port = hostport.split("]"); return host[1:], int(port.lstrip(":"))
    host, port = hostport.rsplit(":", 1)
    return host, int(port)

def build_config(proxy_outbound: dict) -> dict:
    # 出站 tag 直接用节点名，登录 banner 靠 jq .route.final 讀回来，不用另存 sidecar。
    tag = (proxy_outbound.get("_name") or "").strip() or "proxy"
    proxy_outbound = dict(proxy_outbound)   # 不改调用方的 dict，调用方还要拿 _name 报节点名
    proxy_outbound["tag"] = tag
    for k in ("_name", "_proto"): proxy_outbound.pop(k, None)
    return {
        "log": {"level": "warn", "timestamp": True},
        "dns": {
            "servers": [
                {"type": "https", "tag": "remote", "server": "dns.google", "detour": tag},
                {"type": "local", "tag": "local"}
            ],
            "strategy": "ipv4_only",
            "final": "remote"
        },
        "inbounds": [
            {"type": "mixed", "tag": "mixed-in", "listen": "127.0.0.1", "listen_port": MIXED_PORT},
            {"type": "tun", "tag": "tun-in", "interface_name": "singbox",
             "address": [TUN_ADDR], "mtu": 9000, "auto_route": True, "strict_route": True,
             "stack": "mixed"}
        ],
        "outbounds": [proxy_outbound, {"type": "direct", "tag": "direct"}],
        "route": {
            # 必须开：一是避免 sing-box 连节点那条连接被 TUN 抓回去成环，
            # 二是让 dns.local 的引导查询绑到物理网卡、不被自己的 hijack-dns 再劫持一遍。
            "auto_detect_interface": True,
            "default_domain_resolver": {"server": "local", "strategy": "ipv4_only"},
            # 顺序要紧：sniff 先跑，后面按 protocol=dns 才命中。
            # 不用 tun 的 dns_mode/dns_address：显式写 dns_address 会让 sing-box 跳过
            # 自动的 DNS 标记，且它只认自己那个 DNS 地址，系统 resolver 指向别处就漏。
            # 这里按“任意目标 53 端口”劫持，resolv.conf 指哪都跑不掉。
            "rules": [
                {"action": "sniff"},
                {"protocol": "dns", "action": "hijack-dns"}
            ],
            "final": tag
        }
    }

def fetch_sub(url: str):
    ctx = ssl.create_default_context()
    body = None
    last_error = None
    for _ in range(4):
        try:
            with urllib.request.urlopen(url, timeout=30, context=ctx) as r:
                body = r.read()
            break
        except Exception as err:
            last_error = err
            time.sleep(3)
    if body is None:
        raise SystemExit(f"拉订阅失败（重试 4 次）：{last_error}\n境内直连常被 429/断连，先 export https_proxy=<你的本地代理> 再跑。")
    links = []
    try:
        text = b64d(body.decode(errors="ignore")).decode(errors="ignore")
        if "://" in text:
            links = [l.strip() for l in text.splitlines() if "://" in l]
    except Exception:
        pass
    if not links:  # 也许是明文/JSON 订阅
        text = body.decode(errors="ignore")
        links = [l.strip() for l in text.splitlines() if "://" in l]
    if not links:
        raise SystemExit("订阅里没解析出任何节点链接（可能是 clash/yaml 或加密订阅）。请改用 --link 单个节点。")
    return links

def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--sub"); ap.add_argument("--match"); ap.add_argument("--link")
    ap.add_argument("--list", action="store_true"); ap.add_argument("--out")
    ap.add_argument("--index", type=int)
    a = ap.parse_args()

    target = None
    if a.sub:
        links = fetch_sub(a.sub)
        if a.list:
            for i, l in enumerate(links):
                try: nm = parse(l).get("_name", "")
                except Exception: nm = "(无法解析)"
                print(f"[{i}] {l.split('://',1)[0]:9} {nm}")
            return
        cand = []
        if a.index is not None:
            if not (0 <= a.index < len(links)):
                raise SystemExit(f"--index 超出范围(0..{len(links)-1})，先 --list 查看")
            cand = [links[a.index]]
        elif a.match:
            for l in links:
                try: ob = parse(l)
                except Exception: continue
                if a.match in ob.get("_name", "") or a.match in str(ob.get("server", "")):
                    cand.append(l)
            if not cand:
                raise SystemExit(f"没匹配到 '{a.match}'(匹配节点名或服务器地址)，先 --list 看准确内容")
        else:
            raise SystemExit("用了 --sub 需配 --match <名字/地址> 或 --index <序号>，或先 --list 查看")
        if len(cand) > 1:
            print("匹配到多个，请用 --index 指定序号，或用更精确的关键字：", file=sys.stderr)
            for l in cand:
                ob = parse(l); print(f"    name={ob.get('_name')} server={ob.get('server')}", file=sys.stderr)
            raise SystemExit(1)
        target = cand[0]
    elif a.link:
        target = a.link
    else:
        ap.print_help(); raise SystemExit(1)

    ob = parse(target)
    cfg = build_config(ob)
    out = json.dumps(cfg, ensure_ascii=False, indent=2)
    if a.out:
        with open(a.out, "w") as f: f.write(out + "\n")
        print(f"已写入 {a.out}（节点：{ob.get('_name','')}）")
    else:
        print(out)

if __name__ == "__main__":
    main()
