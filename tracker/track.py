#!/usr/bin/env python3
"""Bug Crush tracker: aggregate-only counters, no personal data.

Counts, per day and in total:
  loads  - game actually started (Godot _ready beacon)
  plays  - sessions with at least one accepted swap
  levels - level-ups / bonus splats, counted per level number
  shares - share taps, split email vs X

Deliberately NOT collected: IPs, user-agent strings, cookies,
fingerprints, scores, or anything identifying a player. Bot
user-agents are filtered out so crawlers never inflate the counts.

Endpoints (same origin as the game, so no CORS):
  POST /beacon    {"event": "load"|"play"|"level"|"share",
                   "level": <int>, "kind": "email"|"x"}
  GET  /stats     human-readable stats page
  GET  /stats.json  raw counters as JSON
"""
import json
import os
import re
import threading
from datetime import date
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.path.join(HERE, "data.json")
PORT = 8022

BOT_RE = re.compile(
    r"bot|crawler|spider|slurp|applebot|googlebot|bingbot|"
    r"curl|wget|python|headless|scraper|monitor|uptime",
    re.IGNORECASE,
)

LOCK = threading.Lock()


def blank_day():
    return {"loads": 0, "plays": 0, "shares_email": 0, "shares_x": 0,
            "levels": {}}


def load_data():
    try:
        with open(DATA_FILE) as f:
            data = json.load(f)
        data.setdefault("totals", blank_day())
        data.setdefault("days", {})
        return data
    except (OSError, ValueError):
        return {"totals": blank_day(), "days": {}}


def save_data(data):
    tmp = DATA_FILE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=1, sort_keys=True)
    os.replace(tmp, DATA_FILE)


def record(event, level=None, kind=None):
    today = date.today().isoformat()
    with LOCK:
        data = load_data()
        for bucket in (data["totals"], data["days"].setdefault(today, blank_day())):
            if event == "load":
                bucket["loads"] += 1
            elif event == "play":
                bucket["plays"] += 1
            elif event == "level" and level is not None:
                bucket["levels"][str(level)] = bucket["levels"].get(str(level), 0) + 1
            elif event == "share" and kind == "email":
                bucket["shares_email"] += 1
            elif event == "share" and kind == "x":
                bucket["shares_x"] += 1
        save_data(data)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # no request logging: nothing identifying is kept anywhere

    def _is_bot(self):
        ua = self.headers.get("User-Agent", "")
        return bool(BOT_RE.search(ua))

    def do_POST(self):
        if self.path != "/beacon":
            self.send_response(404)
            self.end_headers()
            return
        length = int(self.headers.get("Content-Length", 0) or 0)
        raw = self.rfile.read(length) if length else b"{}"
        try:
            body = json.loads(raw.decode("utf-8", "replace"))
        except ValueError:
            body = {}
        event = body.get("event")
        if event in ("load", "play", "level", "share") and not self._is_bot():
            record(event, body.get("level"), body.get("kind"))
        self.send_response(204)
        self.end_headers()

    def do_GET(self):
        if self.path == "/stats.json":
            with LOCK:
                data = load_data()
            payload = json.dumps(data, indent=1, sort_keys=True).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return
        if self.path == "/stats":
            with LOCK:
                data = load_data()
            totals = data["totals"]
            rows = []
            for day in sorted(data["days"], reverse=True)[:30]:
                d = data["days"][day]
                lv = ", ".join("L%s: %d" % (k, v)
                               for k, v in sorted(d["levels"].items(),
                                                  key=lambda kv: int(kv[0])))
                rows.append("<tr><td>%s</td><td>%d</td><td>%d</td>"
                            "<td>%d</td><td>%d</td><td>%s</td></tr>" % (
                                day, d["loads"], d["plays"],
                                d["shares_email"], d["shares_x"], lv or "-"))
            tot_lv = ", ".join("L%s: %d" % (k, v)
                               for k, v in sorted(totals["levels"].items(),
                                                  key=lambda kv: int(kv[0])))
            html = """<!DOCTYPE html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Bug Crush stats</title>
<style>body{font-family:sans-serif;background:#111;color:#eee;
margin:20px}table{border-collapse:collapse}td,th{border:1px solid #444;
padding:6px 10px}h1{color:#7CFC00}</style></head><body>
<h1>Bug Crush stats</h1>
<p>Aggregate only. No IPs, cookies, or player identities are collected.</p>
<h2>Totals</h2>
<p>Loads: <b>%d</b> &nbsp; Plays: <b>%d</b> &nbsp;
Shares by email: <b>%d</b> &nbsp; Shares to X: <b>%d</b><br>
Level-ups: %s</p>
<h2>By day (last 30)</h2>
<table><tr><th>Day</th><th>Loads</th><th>Plays</th>
<th>Email shares</th><th>X shares</th><th>Level-ups</th></tr>
%s</table></body></html>""" % (
                totals["loads"], totals["plays"],
                totals["shares_email"], totals["shares_x"],
                tot_lv or "-", "".join(rows))
            payload = html.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(b"bug-crush tracker ok\n")


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
