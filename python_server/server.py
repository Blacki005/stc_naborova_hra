from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
from werkzeug.serving import make_server
import sqlite3
import json
import requests
import ssl
import threading
import ipaddress
from datetime import datetime

# ─────────────────────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────────────────────

HOST      = "localhost"
# HOST       = "192.168.0.111"
HTTP_PORT  = 8080   # Desktop builds (Linux / Windows) — no browser restrictions
HTTPS_PORT = 8443   # Web build on GitHub Pages — requires HTTPS due to mixed content
DB_PATH    = "players.db"

# Origins allowed to make CORS requests:
#   - GitHub Pages web build
#   - null covers locally opened HTML files (file://) during dev
ALLOWED_ORIGINS = [
    "https://blacki005.github.io",
    "localhost",
    "null",
]

app = Flask(__name__)
CORS(app, origins=[
    "https://blacki005.github.io",
    "null"
], 
resources={
    r"/*": {
        "origins": ["https://blacki005.github.io", "null"],
        "allow_headers": ["Content-Type"]
    }
})

# ─────────────────────────────────────────────────────────────────────────────
# CORS — ensure headers on every response including errors
# ─────────────────────────────────────────────────────────────────────────────

# Add localhost pattern separately
@app.after_request
def after_request(response):
    origin = request.headers.get('Origin')
    if origin and origin.startswith('http://localhost:'):
        response.headers['Access-Control-Allow-Origin'] = origin
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
        response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    return response

@app.route("/data",          methods=["OPTIONS"])
@app.route("/players/full",  methods=["OPTIONS"])
@app.route("/players/clear", methods=["OPTIONS"])
def preflight():
    """Handle CORS preflight for all endpoints."""
    return jsonify({}), 200

# ─────────────────────────────────────────────────────────────────────────────
# GEOLOCATION — uses public IP from client data first, then falls back to request IP
# ─────────────────────────────────────────────────────────────────────────────

def is_public_ip(ip_str):
    """Check if an IP address is public (routable on the internet)."""
    try:
        ip = ipaddress.ip_address(ip_str)
        return not (ip.is_private or ip.is_loopback or ip.is_link_local or ip.is_multicast)
    except ValueError:
        return False

def get_client_ip():
    """Get IP from X-Forwarded-For header or direct request."""
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.remote_addr

def geolocate(ip_list=None):
    """
    Geolocate from the first public IP found.
    Tries client-provided IPs first, then falls back to request IP.
    """
    # Try client-provided IPs first (from Godot IP.get_local_addresses())
    if ip_list:
        for ip_str in ip_list:
            if is_public_ip(ip_str):
                return _fetch_geo(ip_str)
    
    # Fall back to request IP (e.g., when on different networks)
    request_ip = get_client_ip()
    if is_public_ip(request_ip):
        return _fetch_geo(request_ip)
    
    return None

def _fetch_geo(ip):
    """Query ip-api.com for geolocation data."""
    try:
        r = requests.get(
            f"http://ip-api.com/json/{ip}"
            f"?fields=status,country,countryCode,regionName,city,lat,lon,isp,org",
            timeout=3
        )
        data = r.json()
        return data if data.get("status") == "success" else None
    except Exception:
        return None

# ─────────────────────────────────────────────────────────────────────────────
# WEALTH ESTIMATION
# ─────────────────────────────────────────────────────────────────────────────

WEALTH_CRITERIA = [
    {"label": "macOS",          "points":  25, "desc": "macOS users statistically own higher-end hardware"},
    {"label": "Windows",        "points":  15, "desc": "Windows — broad range, moderate baseline"},
    {"label": "Linux",          "points":  10, "desc": "Linux — tech-savvy, mid baseline"},
    {"label": "4K screen",      "points":  25, "desc": "3840x2160 or higher resolution display"},
    {"label": "1440p screen",   "points":  18, "desc": "2560x1440 — premium but not top-tier"},
    {"label": "1080p screen",   "points":  10, "desc": "1920x1080 — standard resolution"},
    {"label": "Low-res screen", "points":   3, "desc": "Below 1080p"},
    {"label": "HiDPI / Retina", "points":  20, "desc": "DPI >= 220 — Retina or equivalent premium display"},
    {"label": "Mid DPI",        "points":  10, "desc": "DPI 150-219 — above average display density"},
    {"label": "Standard DPI",   "points":   4, "desc": "DPI 90-149 — typical monitor"},
    {"label": "16+ CPU cores",  "points":  20, "desc": "High-end workstation or enthusiast CPU"},
    {"label": "8-15 CPU cores", "points":  12, "desc": "Mid-to-high range CPU"},
    {"label": "4-7 CPU cores",  "points":   6, "desc": "Mid-range CPU"},
    {"label": "1-3 CPU cores",  "points":   2, "desc": "Entry-level or older CPU"},
    {"label": "Deep colour",    "points":   5, "desc": "30-bit colour depth — professional display"},
    {"label": "24-bit colour",  "points":   2, "desc": "Standard 24-bit colour depth"},
    {"label": "Web platform",   "points": -15, "desc": "Web export hides hardware details — 15% confidence penalty"},
]

def estimate_wealth(data):
    score = 0
    reasons = []

    os_name = (data.get("os_name") or "").lower()
    if "macos" in os_name or "osx" in os_name:
        score += 25; reasons.append("macOS (+25)")
    elif "windows" in os_name:
        score += 15; reasons.append("Windows (+15)")
    elif "linux" in os_name:
        score += 10; reasons.append("Linux (+10)")

    screen = data.get("screen_size", {})
    w, h = screen.get("width", 0), screen.get("height", 0)
    if w >= 3840 or h >= 2160:
        score += 25; reasons.append("4K screen (+25)")
    elif w >= 2560 or h >= 1440:
        score += 18; reasons.append("1440p screen (+18)")
    elif w >= 1920 or h >= 1080:
        score += 10; reasons.append("1080p screen (+10)")
    elif w > 0:
        score += 3;  reasons.append("low-res screen (+3)")

    dpi = data.get("screen_dpi", 0) or 0
    if dpi >= 220:
        score += 20; reasons.append("HiDPI/Retina (+20)")
    elif dpi >= 150:
        score += 10; reasons.append("mid DPI (+10)")
    elif dpi >= 90:
        score += 4;  reasons.append("standard DPI (+4)")

    cores = data.get("processor_count", 0) or 0
    if cores >= 16:
        score += 20; reasons.append(f"{cores} CPU cores (+20)")
    elif cores >= 8:
        score += 12; reasons.append(f"{cores} CPU cores (+12)")
    elif cores >= 4:
        score += 6;  reasons.append(f"{cores} CPU cores (+6)")
    elif cores > 0:
        score += 2;  reasons.append(f"{cores} CPU cores (+2)")

    depth = data.get("screen_color_depth", 0) or 0
    if depth >= 30:
        score += 5; reasons.append("deep colour (+5)")
    elif depth >= 24:
        score += 2; reasons.append("24-bit colour (+2)")

    if data.get("is_web"):
        score = int(score * 0.85)
        reasons.append("web platform (-15% confidence penalty)")

    score = min(score, 100)
    label = "High" if score >= 70 else "Mid" if score >= 35 else "Low"
    return score, label, reasons

# ─────────────────────────────────────────────────────────────────────────────
# DATABASE
# ─────────────────────────────────────────────────────────────────────────────

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    with get_db() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS players (
                fingerprint_hash  TEXT PRIMARY KEY,
                first_seen        TEXT,
                last_seen         TEXT,
                play_count        INTEGER DEFAULT 1,
                os_name           TEXT,
                os_version        TEXT,
                os_locale         TEXT,
                model_name        TEXT,
                processor_name    TEXT,
                user_agent        TEXT,
                timezone          TEXT,
                screen_width      INTEGER,
                screen_height     INTEGER,
                ip_addresses      TEXT,
                raw_data          TEXT,
                country           TEXT,
                country_code      TEXT,
                region_name       TEXT,
                city              TEXT,
                lat               REAL,
                lon               REAL,
                isp               TEXT,
                org               TEXT,
                wealth_score      INTEGER,
                wealth_label      TEXT,
                wealth_reasons    TEXT
            )
        """)
        conn.commit()

# ─────────────────────────────────────────────────────────────────────────────
# HTML DASHBOARD
# ─────────────────────────────────────────────────────────────────────────────

CRITERIA_JSON = json.dumps(WEALTH_CRITERIA)

HTML = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Player Analytics</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
    <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        body { background:#12151c; color:#e4e8f0; font-family:'Courier New',monospace; min-height:100vh; font-size:15px; }

        header { background:#1a1f2e; border-bottom:2px solid #3a5070; padding:22px 36px; display:flex; align-items:center; justify-content:space-between; }
        .header-left { display:flex; align-items:center; gap:16px; }
        header h1 { font-size:20px; font-weight:bold; color:#7eb8ff; letter-spacing:3px; text-transform:uppercase; }
        .dot { width:10px; height:10px; border-radius:50%; background:#4fd87a; box-shadow:0 0 10px #4fd87a; animation:pulse 2s infinite; }
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.4} }
        .last-update { font-size:13px; color:#8090a8; }

        nav { display:flex; border-bottom:2px solid #3a5070; background:#1a1f2e; }
        .nav-btn { padding:16px 32px; background:none; border:none; border-bottom:3px solid transparent; color:#8090a8; font-family:'Courier New',monospace; font-size:14px; text-transform:uppercase; letter-spacing:1px; cursor:pointer; transition:all 0.15s; }
        .nav-btn:hover { color:#e4e8f0; }
        .nav-btn.active { color:#7eb8ff; border-bottom-color:#7eb8ff; }

        .page { display:none; padding:32px; }
        .page.active { display:block; }

        .stats-strip { display:grid; grid-template-columns:repeat(5,1fr); gap:16px; margin-bottom:32px; }
        .stat-card { background:#1a1f2e; border:2px solid #3a5070; padding:22px 26px; }
        .stat-label { font-size:12px; color:#8090a8; text-transform:uppercase; letter-spacing:1px; margin-bottom:10px; }
        .stat-value { font-size:34px; color:#7eb8ff; line-height:1; }
        .stat-sub { font-size:12px; color:#6070a0; margin-top:8px; }
        .stat-value.green { color:#4fd87a; }
        .stat-value.yellow { color:#f0c040; }

        .chart-grid { display:grid; gap:20px; }
        .chart-grid.cols-2 { grid-template-columns:1fr 1fr; }

        .chart-card { background:#1a1f2e; border:2px solid #3a5070; padding:26px; }
        .chart-title { font-size:13px; text-transform:uppercase; letter-spacing:1px; color:#b0c4e0; margin-bottom:20px; display:flex; justify-content:space-between; font-weight:bold; }
        .chart-title span { color:#6070a0; font-size:11px; font-weight:normal; }

        .toolbar { display:flex; gap:12px; margin-bottom:20px; align-items:center; }
        input[type="text"] { background:#1a1f2e; border:2px solid #3a5070; color:#e4e8f0; padding:10px 16px; font-family:'Courier New',monospace; font-size:14px; outline:none; width:280px; }
        input[type="text"]:focus { border-color:#7eb8ff; }
        input[type="text"]::placeholder { color:#4a5a80; }
        button { background:#222840; border:2px solid #3a5070; color:#e4e8f0; padding:10px 20px; font-family:'Courier New',monospace; font-size:14px; cursor:pointer; transition:all 0.15s; }
        button:hover { border-color:#7eb8ff; color:#7eb8ff; }
        button.danger:hover { border-color:#f85149; color:#f85149; }
        .spacer { flex:1; }

        .table-wrap { overflow-x:auto; max-height:calc(100vh - 280px); overflow-y:auto; }
        table { width:100%; border-collapse:collapse; font-size:14px; }
        thead { position:sticky; top:0; background:#1a1f2e; z-index:10; }
        th { padding:14px 18px; text-align:left; font-size:12px; text-transform:uppercase; letter-spacing:1px; color:#8090a8; border-bottom:2px solid #3a5070; cursor:pointer; white-space:nowrap; }
        th:hover { color:#7eb8ff; }
        td { padding:13px 18px; border-bottom:1px solid #1e2840; max-width:200px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
        tr:hover td { background:#1e2535; }

        .badge { display:inline-block; padding:3px 10px; font-size:12px; font-weight:bold; }
        .badge-new       { background:#1a3a2a; color:#4fd87a; border:2px solid #2a6a3a; }
        .badge-returning { background:#1a2a4a; color:#7eb8ff; border:2px solid #2a4a7a; }
        .badge-high      { background:#3a2a0a; color:#f0c040; border:2px solid #6a4a0a; }
        .badge-mid       { background:#2a1a4a; color:#cc9aff; border:2px solid #5a3a8a; }
        .badge-low       { background:#252a3a; color:#8090a8; border:2px solid #3a4a60; }

        .play-count { color:#f0c040; font-weight:bold; }
        .hash { color:#7090b0; font-size:12px; }
        .row-btn { background:none; border:2px solid #3a5070; color:#8090a8; padding:4px 12px; font-size:12px; cursor:pointer; }
        .row-btn:hover { border-color:#7eb8ff; color:#7eb8ff; }

        .modal-overlay { display:none; position:fixed; inset:0; background:rgba(0,0,0,0.78); z-index:100; align-items:center; justify-content:center; }
        .modal-overlay.open { display:flex; }
        .modal { background:#1a1f2e; border:2px solid #3a5070; width:760px; max-height:87vh; display:flex; flex-direction:column; }
        .modal-header { padding:18px 24px; border-bottom:2px solid #3a5070; display:flex; justify-content:space-between; align-items:center; font-size:14px; color:#7eb8ff; text-transform:uppercase; letter-spacing:1px; font-weight:bold; }
        .modal-close { background:none; border:none; color:#8090a8; font-size:20px; cursor:pointer; }
        .modal-close:hover { color:#f85149; }
        .modal-body { padding:24px; overflow-y:auto; flex:1; }
        .modal-section { margin-bottom:28px; }
        .modal-section-title { font-size:12px; text-transform:uppercase; letter-spacing:1px; color:#7eb8ff; border-bottom:2px solid #3a5070; padding-bottom:8px; margin-bottom:18px; font-weight:bold; }
        .field-group { margin-bottom:16px; }
        .field-label { font-size:11px; color:#8090a8; text-transform:uppercase; letter-spacing:1px; margin-bottom:5px; }
        .field-value { color:#e4e8f0; font-size:14px; word-break:break-all; }
        .field-value.highlight { color:#7eb8ff; }
        .grid-2 { display:grid; grid-template-columns:1fr 1fr; gap:18px; }
        .grid-3 { display:grid; grid-template-columns:1fr 1fr 1fr; gap:18px; }
        pre { background:#12151c; border:2px solid #3a5070; padding:14px; font-size:12px; overflow-x:auto; color:#b0c4e0; max-height:180px; overflow-y:auto; }

        .wealth-bar-wrap { height:10px; background:#12151c; border:1px solid #3a5070; margin-top:10px; border-radius:2px; }
        .wealth-bar { height:100%; border-radius:2px; transition:width 0.4s; }

        .region-list { display:flex; flex-direction:column; gap:10px; max-height:340px; overflow-y:auto; }
        .region-row { display:flex; align-items:center; gap:14px; }
        .region-name { width:170px; font-size:13px; color:#c0cce0; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
        .region-bar-wrap { flex:1; background:#12151c; height:10px; border-radius:2px; }
        .region-bar { height:10px; background:#7eb8ff; border-radius:2px; }
        .region-count { width:36px; text-align:right; font-size:13px; color:#7eb8ff; font-weight:bold; }

        .empty { padding:60px; text-align:center; color:#4a5a72; font-size:15px; }
        .wealth-score-big { font-size:56px; font-weight:bold; line-height:1; }
        .reason-item { font-size:13px; color:#b0c4e0; padding:3px 0; }

        .criteria-table { width:100%; border-collapse:collapse; font-size:13px; margin-top:4px; }
        .criteria-table th { padding:11px 16px; text-align:left; font-size:12px; text-transform:uppercase; letter-spacing:1px; color:#8090a8; border-bottom:2px solid #3a5070; }
        .criteria-table td { padding:11px 16px; border-bottom:1px solid #1e2840; }
        .criteria-table tr:hover td { background:#12151c; }
        .pts-plus  { color:#4fd87a; font-weight:bold; }
        .pts-minus { color:#f85149; font-weight:bold; }
    </style>
</head>
<body>

<header>
    <div class="header-left">
        <div class="dot"></div>
        <h1>Player Analytics</h1>
    </div>
    <div class="last-update">Last updated: <span id="ts">—</span></div>
</header>

<nav>
    <button class="nav-btn active" onclick="switchPage('overview',this)">Overview</button>
    <button class="nav-btn" onclick="switchPage('players',this)">Players</button>
    <button class="nav-btn" onclick="switchPage('devices',this)">Devices</button>
    <button class="nav-btn" onclick="switchPage('regions',this)">Regions</button>
    <button class="nav-btn" onclick="switchPage('wealth',this)">Wealth</button>
</nav>

<!-- OVERVIEW -->
<div class="page active" id="page-overview">
    <div class="stats-strip">
        <div class="stat-card"><div class="stat-label">Total Players</div><div class="stat-value" id="s-total">—</div><div class="stat-sub">unique fingerprints</div></div>
        <div class="stat-card"><div class="stat-label">Total Sessions</div><div class="stat-value green" id="s-sessions">—</div><div class="stat-sub">cumulative plays</div></div>
        <div class="stat-card"><div class="stat-label">Return Rate</div><div class="stat-value yellow" id="s-return">—</div><div class="stat-sub">played more than once</div></div>
        <div class="stat-card"><div class="stat-label">Avg Sessions</div><div class="stat-value" id="s-avg">—</div><div class="stat-sub">per player</div></div>
        <div class="stat-card"><div class="stat-label">Avg Wealth Score</div><div class="stat-value yellow" id="s-wealth">—</div><div class="stat-sub">hardware estimate / 100</div></div>
    </div>
    <div class="chart-grid cols-2" style="margin-bottom:20px">
        <div class="chart-card"><div class="chart-title">New vs Returning <span>all time</span></div><div style="height:280px"><canvas id="chart-return"></canvas></div></div>
        <div class="chart-card"><div class="chart-title">Sessions Distribution <span>histogram</span></div><div style="height:280px"><canvas id="chart-sessions-dist"></canvas></div></div>
    </div>
    <div class="chart-card">
        <div class="chart-title">Player Registrations Over Time <span>cumulative</span></div>
        <div style="height:220px"><canvas id="chart-timeline"></canvas></div>
    </div>
</div>

<!-- PLAYERS -->
<div class="page" id="page-players">
    <div class="toolbar">
        <input type="text" id="search" placeholder="Search players..." oninput="filterTable()">
        <button onclick="loadData()">&#x27F3; Refresh</button>
        <button class="danger" onclick="confirmClear()">&#x2715; Clear DB</button>
        <div class="spacer"></div>
        <span style="font-size:13px;color:#6070a0">Auto-refresh in <span id="countdown">30</span>s</span>
    </div>
    <div class="table-wrap">
        <table>
            <thead><tr>
                <th onclick="sortBy('fingerprint_hash')">Hash</th>
                <th onclick="sortBy('region_name')">Region</th>
                <th onclick="sortBy('city')">City</th>
                <th onclick="sortBy('os_name')">OS</th>
                <th onclick="sortBy('play_count')">Plays</th>
                <th onclick="sortBy('wealth_score')">Wealth</th>
                <th onclick="sortBy('first_seen')">First Seen</th>
                <th onclick="sortBy('last_seen')">Last Seen</th>
                <th>Status</th>
                <th></th>
            </tr></thead>
            <tbody id="tbody"></tbody>
        </table>
        <div class="empty" id="empty" style="display:none">No players found</div>
    </div>
</div>

<!-- DEVICES -->
<div class="page" id="page-devices">
    <div class="chart-grid cols-2">
        <div class="chart-card"><div class="chart-title">Operating Systems</div><div style="height:340px"><canvas id="chart-os"></canvas></div></div>
        <div class="chart-card"><div class="chart-title">Platform Type</div><div style="height:340px"><canvas id="chart-platform"></canvas></div></div>
    </div>
</div>

<!-- REGIONS -->
<div class="page" id="page-regions">
    <div class="chart-grid cols-2" style="margin-bottom:20px">
        <div class="chart-card"><div class="chart-title">Players by Region <span>top 10</span></div><div style="height:320px"><canvas id="chart-region"></canvas></div></div>
        <div class="chart-card"><div class="chart-title">Players by City <span>top 10</span></div><div style="height:320px"><canvas id="chart-city"></canvas></div></div>
    </div>
    <div class="chart-grid cols-2">
        <div class="chart-card"><div class="chart-title">Region Breakdown <span>incl. unknown</span></div><div class="region-list" id="region-list"></div></div>
        <div class="chart-card"><div class="chart-title">City Breakdown <span>incl. unknown</span></div><div class="region-list" id="city-list"></div></div>
    </div>
</div>

<!-- WEALTH -->
<div class="page" id="page-wealth">
    <div class="chart-grid cols-2" style="margin-bottom:20px">
        <div class="chart-card"><div class="chart-title">Wealth Tier Distribution</div><div style="height:300px"><canvas id="chart-wealth-tiers"></canvas></div></div>
        <div class="chart-card"><div class="chart-title">Wealth Score Histogram</div><div style="height:300px"><canvas id="chart-wealth-hist"></canvas></div></div>
    </div>
    <div class="chart-grid cols-2" style="margin-bottom:20px">
        <div class="chart-card"><div class="chart-title">Avg Wealth by Region <span>top 8</span></div><div style="height:280px"><canvas id="chart-wealth-region"></canvas></div></div>
        <div class="chart-card"><div class="chart-title">Wealth vs Sessions <span>correlation</span></div><div style="height:280px"><canvas id="chart-wealth-sessions"></canvas></div></div>
    </div>
    <div class="chart-card">
        <div class="chart-title">Scoring Criteria <span>how wealth score is calculated — max 100 pts</span></div>
        <table class="criteria-table">
            <thead><tr><th>Signal</th><th>Points</th><th>Explanation</th></tr></thead>
            <tbody id="criteria-tbody"></tbody>
        </table>
    </div>
</div>

<!-- MODAL -->
<div class="modal-overlay" id="modal" onclick="closeModal(event)">
    <div class="modal">
        <div class="modal-header"><span>Player Detail</span><button class="modal-close" onclick="closeModal()">&#x2715;</button></div>
        <div class="modal-body" id="modal-body"></div>
    </div>
</div>

<script>
const COLORS   = ['#7eb8ff','#4fd87a','#f0c040','#f85149','#cc9aff','#79c0ff','#56d364','#ffa657','#ff7b72','#d2a8ff'];
const GRID     = 'rgba(58,80,112,0.6)';
const TEXT     = '#b0c4e0';
const CRITERIA = """ + CRITERIA_JSON + """;

Chart.defaults.color = TEXT;
Chart.defaults.borderColor = GRID;
Chart.defaults.font.family = "'Courier New', monospace";
Chart.defaults.font.size = 13;

let allPlayers = [], charts = {};
let sortKey = 'last_seen', sortAsc = false, countdown = 30;

const count = (arr, key, fb='Unknown') => {
    const m = {};
    arr.forEach(p => { const v = p[key]||fb; m[v]=(m[v]||0)+1; });
    return m;
};
const topN = (map, n=10) => Object.entries(map).sort((a,b)=>b[1]-a[1]).slice(0,n);

function mkChart(id, type, data, opts={}) {
    if (charts[id]) charts[id].destroy();
    charts[id] = new Chart(document.getElementById(id), {
        type, data,
        options:{ responsive:true, maintainAspectRatio:false, plugins:{legend:{labels:{boxWidth:14,padding:16}}}, ...opts }
    });
}

const scaleOpts = (extra={}) => ({
    scales:{ x:{grid:{color:GRID},ticks:{color:TEXT}}, y:{grid:{color:GRID},ticks:{color:TEXT},beginAtZero:true} },
    ...extra
});

// ── OVERVIEW ──────────────────────────────────────────
function renderOverview() {
    const total     = allPlayers.length;
    const sessions  = allPlayers.reduce((s,p)=>s+p.play_count,0);
    const returning = allPlayers.filter(p=>p.play_count>1).length;
    document.getElementById('s-total').textContent    = total;
    document.getElementById('s-sessions').textContent = sessions;
    document.getElementById('s-return').textContent   = total ? ((returning/total)*100).toFixed(1)+'%' : '—';
    document.getElementById('s-avg').textContent      = total ? (sessions/total).toFixed(1) : '—';
    document.getElementById('s-wealth').textContent   = total ? (allPlayers.reduce((s,p)=>s+(p.wealth_score||0),0)/total).toFixed(0) : '—';

    mkChart('chart-return','doughnut',{
        labels:['New (1 play)','Returning (2+)'],
        datasets:[{data:[total-returning,returning],backgroundColor:['#1a3a2a','#1a2a4a'],borderColor:['#4fd87a','#7eb8ff'],borderWidth:3}]
    },{ plugins:{legend:{position:'bottom'}}, cutout:'65%' });

    const b={'1':0,'2-3':0,'4-5':0,'6-10':0,'11+':0};
    allPlayers.forEach(p=>{ const c=p.play_count; if(c===1)b['1']++; else if(c<=3)b['2-3']++; else if(c<=5)b['4-5']++; else if(c<=10)b['6-10']++; else b['11+']++; });
    mkChart('chart-sessions-dist','bar',{
        labels:Object.keys(b), datasets:[{label:'Players',data:Object.values(b),backgroundColor:COLORS,borderWidth:0}]
    },{ plugins:{legend:{display:false}}, ...scaleOpts() });

    const byDay={};
    allPlayers.forEach(p=>{ const d=(p.first_seen||'').slice(0,10); if(d)byDay[d]=(byDay[d]||0)+1; });
    const days=Object.keys(byDay).sort(); let cum=0;
    mkChart('chart-timeline','line',{
        labels:days,
        datasets:[{label:'Players',data:days.map(d=>{cum+=byDay[d];return cum;}),borderColor:'#7eb8ff',backgroundColor:'rgba(126,184,255,0.12)',fill:true,tension:0.3,pointRadius:4,pointBackgroundColor:'#7eb8ff'}]
    },{ plugins:{legend:{display:false}}, ...scaleOpts() });
}

// ── DEVICES ───────────────────────────────────────────
function renderDevices() {
    const osTop = topN(count(allPlayers,'os_name'),6);
    mkChart('chart-os','pie',{
        labels:osTop.map(e=>e[0]), datasets:[{data:osTop.map(e=>e[1]),backgroundColor:COLORS,borderColor:'#12151c',borderWidth:3}]
    },{ plugins:{legend:{position:'bottom'}} });

    const plat={Web:0,Desktop:0,Mobile:0,Unknown:0};
    allPlayers.forEach(p=>{ try{ const r=JSON.parse(p.raw_data||'{}'); if(r.is_web)plat.Web++; else if(r.is_mobile)plat.Mobile++; else if(r.os_name)plat.Desktop++; else plat.Unknown++; }catch{plat.Unknown++;} });
    mkChart('chart-platform','doughnut',{
        labels:Object.keys(plat),
        datasets:[{data:Object.values(plat),backgroundColor:['#1a2a4a','#1a3a2a','#3a2a1a','#2a253a'],borderColor:['#7eb8ff','#4fd87a','#f0c040','#cc9aff'],borderWidth:3}]
    },{ plugins:{legend:{position:'bottom'}}, cutout:'60%' });
}

// ── REGIONS ───────────────────────────────────────────
function renderRegions() {
    const regionMap = count(allPlayers,'region_name');
    const cityMap   = count(allPlayers,'city');

    mkChart('chart-region','bar',{
        labels:topN(regionMap).map(e=>e[0]),
        datasets:[{label:'Players',data:topN(regionMap).map(e=>e[1]),backgroundColor:COLORS,borderWidth:0}]
    },{ plugins:{legend:{display:false}}, ...scaleOpts() });

    mkChart('chart-city','bar',{
        labels:topN(cityMap).map(e=>e[0]),
        datasets:[{label:'Players',data:topN(cityMap).map(e=>e[1]),backgroundColor:COLORS,borderWidth:0}]
    },{ indexAxis:'y', plugins:{legend:{display:false}}, ...scaleOpts() });

    const barList = (map, elId) => {
        const max = Math.max(...Object.values(map), 1);
        document.getElementById(elId).innerHTML = Object.entries(map).sort((a,b)=>b[1]-a[1])
            .map(([k,v])=>`<div class="region-row">
                <div class="region-name" title="${k}">${k}</div>
                <div class="region-bar-wrap"><div class="region-bar" style="width:${(v/max*100).toFixed(1)}%"></div></div>
                <div class="region-count">${v}</div>
            </div>`).join('');
    };
    barList(regionMap, 'region-list');
    barList(cityMap,   'city-list');
}

// ── WEALTH ────────────────────────────────────────────
function renderWealth() {
    const tierMap={High:0,Mid:0,Low:0,Unknown:0};
    allPlayers.forEach(p=>{ tierMap[p.wealth_label||'Unknown']++; });
    mkChart('chart-wealth-tiers','doughnut',{
        labels:Object.keys(tierMap),
        datasets:[{data:Object.values(tierMap),backgroundColor:['#3a2a0a','#2a1a4a','#252a3a','#1a1e28'],borderColor:['#f0c040','#cc9aff','#8090a8','#4a5a72'],borderWidth:3}]
    },{ plugins:{legend:{position:'bottom'}}, cutout:'60%' });

    const hist={'0-19':0,'20-39':0,'40-59':0,'60-79':0,'80-100':0};
    allPlayers.forEach(p=>{ const s=p.wealth_score||0; if(s<20)hist['0-19']++; else if(s<40)hist['20-39']++; else if(s<60)hist['40-59']++; else if(s<80)hist['60-79']++; else hist['80-100']++; });
    mkChart('chart-wealth-hist','bar',{
        labels:Object.keys(hist),
        datasets:[{label:'Players',data:Object.values(hist),backgroundColor:['#8090a8','#cc9aff','#7eb8ff','#4fd87a','#f0c040'],borderWidth:0}]
    },{ plugins:{legend:{display:false}}, ...scaleOpts() });

    const byRegion={};
    allPlayers.forEach(p=>{ const r=p.region_name||'Unknown'; if(!byRegion[r])byRegion[r]=[]; byRegion[r].push(p.wealth_score||0); });
    const avgByRegion=Object.entries(byRegion).map(([k,v])=>([k,(v.reduce((a,b)=>a+b,0)/v.length).toFixed(0)])).sort((a,b)=>b[1]-a[1]).slice(0,8);
    mkChart('chart-wealth-region','bar',{
        labels:avgByRegion.map(e=>e[0]),
        datasets:[{label:'Avg Score',data:avgByRegion.map(e=>e[1]),backgroundColor:COLORS,borderWidth:0}]
    },{ plugins:{legend:{display:false}}, ...scaleOpts() });

    mkChart('chart-wealth-sessions','scatter',{
        datasets:[{label:'Players',data:allPlayers.map(p=>({x:p.play_count||1,y:p.wealth_score||0})),backgroundColor:'rgba(126,184,255,0.65)',pointRadius:7,pointHoverRadius:9}]
    },{ plugins:{legend:{display:false}}, scales:{
        x:{grid:{color:GRID},ticks:{color:TEXT},title:{display:true,text:'Sessions',color:TEXT}},
        y:{grid:{color:GRID},ticks:{color:TEXT},title:{display:true,text:'Wealth Score',color:TEXT},min:0,max:100}
    }});

    document.getElementById('criteria-tbody').innerHTML = CRITERIA.map(c =>
        `<tr>
            <td><strong>${c.label}</strong></td>
            <td>${c.points > 0 ? `<span class="pts-plus">+${c.points} pts</span>` : `<span class="pts-minus">${c.points}%</span>`}</td>
            <td style="color:#b0c4e0">${c.desc}</td>
        </tr>`
    ).join('');
}

// ── TABLE ─────────────────────────────────────────────
function renderTable(players) {
    const tbody = document.getElementById('tbody');
    const empty = document.getElementById('empty');
    if (!players.length) { tbody.innerHTML=''; empty.style.display='block'; return; }
    empty.style.display = 'none';
    const sorted = [...players].sort((a,b)=>{
        const va=a[sortKey]??'', vb=b[sortKey]??'';
        return sortAsc ? (va>vb?1:-1) : (va<vb?1:-1);
    });
    tbody.innerHTML = sorted.map(p => {
        const isNew = p.play_count === 1;
        const wl    = p.wealth_label || 'Unknown';
        return `<tr>
            <td class="hash" title="${p.fingerprint_hash}">${(p.fingerprint_hash||'').toString().slice(0,10)}…</td>
            <td>${p.region_name||'Unknown'}</td>
            <td>${p.city||'—'}</td>
            <td>${p.os_name||'—'}</td>
            <td class="play-count">${p.play_count}</td>
            <td><span class="badge badge-${wl.toLowerCase()}">${wl} (${p.wealth_score||0})</span></td>
            <td>${p.first_seen?.slice(0,16).replace('T',' ')||'—'}</td>
            <td>${p.last_seen?.slice(0,16).replace('T',' ')||'—'}</td>
            <td><span class="badge ${isNew?'badge-new':'badge-returning'}">${isNew?'NEW':'RETURNING'}</span></td>
            <td><button class="row-btn" onclick='showDetail(${JSON.stringify(p)})'>Detail</button></td>
        </tr>`;
    }).join('');
}

function filterTable() {
    const q = document.getElementById('search').value.toLowerCase();
    renderTable(allPlayers.filter(p => Object.values(p).some(v => String(v).toLowerCase().includes(q))));
}

function sortBy(key) {
    if (sortKey===key) sortAsc=!sortAsc; else { sortKey=key; sortAsc=false; }
    filterTable();
}

function showDetail(p) {
    const raw     = JSON.parse(p.raw_data||'{}');
    const ips     = JSON.parse(p.ip_addresses||'[]');
    const reasons = JSON.parse(p.wealth_reasons||'[]');
    const barColor = p.wealth_label==='High'?'#f0c040':p.wealth_label==='Mid'?'#cc9aff':'#8090a8';
    document.getElementById('modal-body').innerHTML = `
        <div class="modal-section">
            <div class="modal-section-title">Identity</div>
            <div class="grid-2">
                <div class="field-group"><div class="field-label">Fingerprint</div><div class="field-value highlight">${p.fingerprint_hash}</div></div>
                <div class="field-group"><div class="field-label">Play Count</div><div class="field-value highlight">${p.play_count}</div></div>
                <div class="field-group"><div class="field-label">First Seen</div><div class="field-value">${p.first_seen?.replace('T',' ')||'—'}</div></div>
                <div class="field-group"><div class="field-label">Last Seen</div><div class="field-value">${p.last_seen?.replace('T',' ')||'—'}</div></div>
            </div>
        </div>
        <div class="modal-section">
            <div class="modal-section-title">Location</div>
            <div class="grid-3">
                <div class="field-group"><div class="field-label">Country</div><div class="field-value">${p.country||'Unknown'} ${p.country_code?'('+p.country_code+')':''}</div></div>
                <div class="field-group"><div class="field-label">Region</div><div class="field-value">${p.region_name||'—'}</div></div>
                <div class="field-group"><div class="field-label">City</div><div class="field-value">${p.city||'—'}</div></div>
                <div class="field-group"><div class="field-label">Coordinates</div><div class="field-value">${p.lat&&p.lon?p.lat+', '+p.lon:'—'}</div></div>
                <div class="field-group"><div class="field-label">IP Addresses</div><div class="field-value">${ips.join(', ')||'—'}</div></div>
            </div>
        </div>
        <div class="modal-section">
            <div class="modal-section-title">Wealth Estimate</div>
            <div class="grid-2">
                <div class="field-group">
                    <div class="field-label">Score / Tier</div>
                    <div class="wealth-score-big" style="color:${barColor}">${p.wealth_score||0}</div>
                    <div class="wealth-bar-wrap"><div class="wealth-bar" style="width:${p.wealth_score||0}%;background:${barColor}"></div></div>
                    <div style="margin-top:8px;font-size:16px;color:${barColor};font-weight:bold">${p.wealth_label||'Unknown'}</div>
                </div>
                <div class="field-group">
                    <div class="field-label">Score Breakdown</div>
                    ${reasons.map(r=>`<div class="reason-item">&#9658; ${r}</div>`).join('')||'<div class="reason-item">No data</div>'}
                </div>
            </div>
        </div>
        <div class="modal-section">
            <div class="modal-section-title">Hardware &amp; Browser</div>
            <div class="grid-2">
                <div class="field-group"><div class="field-label">OS</div><div class="field-value">${p.os_name||'—'} ${p.os_version||''}</div></div>
                <div class="field-group"><div class="field-label">Screen</div><div class="field-value">${p.screen_width||'—'}x${p.screen_height||'—'}</div></div>
                <div class="field-group"><div class="field-label">Locale / Timezone</div><div class="field-value">${p.os_locale||'—'} / ${p.timezone||'—'}</div></div>
                <div class="field-group"><div class="field-label">Processor</div><div class="field-value">${p.processor_name||'—'}</div></div>
            </div>
            <div class="field-group"><div class="field-label">User Agent</div><div class="field-value">${p.user_agent||'—'}</div></div>
        </div>
        <div class="modal-section">
            <div class="modal-section-title">Raw Data</div>
            <pre>${JSON.stringify(raw,null,2)}</pre>
        </div>`;
    document.getElementById('modal').classList.add('open');
}

function closeModal(e) {
    if (!e || e.target===document.getElementById('modal'))
        document.getElementById('modal').classList.remove('open');
}

async function confirmClear() {
    if (confirm('Delete all players?')) { await fetch('/players/clear',{method:'POST'}); loadData(); }
}

async function loadData() {
    const res = await fetch('/players/full');
    allPlayers = await res.json();
    document.getElementById('ts').textContent = new Date().toLocaleTimeString();
    renderOverview(); renderDevices(); renderRegions(); renderWealth();
    filterTable();
    countdown = 30;
    document.getElementById('countdown').textContent = 30;
}

function switchPage(name, btn) {
    document.querySelectorAll('.page').forEach(p=>p.classList.remove('active'));
    document.querySelectorAll('.nav-btn').forEach(b=>b.classList.remove('active'));
    document.getElementById('page-'+name).classList.add('active');
    btn.classList.add('active');
}

setInterval(()=>{ countdown--; document.getElementById('countdown').textContent=countdown; if(countdown<=0)loadData(); }, 1000);
loadData();
</script>
</body>
</html>
"""

# ─────────────────────────────────────────────────────────────────────────────
# ROUTES
# ─────────────────────────────────────────────────────────────────────────────

@app.route("/")
def dashboard():
    return render_template_string(HTML)

@app.route("/players/full")
def list_players_full():
    with get_db() as conn:
        rows = conn.execute("SELECT * FROM players ORDER BY last_seen DESC").fetchall()
    return jsonify([dict(r) for r in rows])

@app.route("/players/clear", methods=["POST"])
def clear_players():
    with get_db() as conn:
        conn.execute("DELETE FROM players")
        conn.commit()
    return jsonify({"status": "ok"})

@app.route("/data", methods=["POST"])
def receive_data():
    data = request.get_json()
    if not data or "fingerprint_hash" not in data:
        return jsonify({"status": "error", "message": "Missing fingerprint_hash"}), 400

    hash_key  = str(data.get("fingerprint_hash"))
    now       = datetime.utcnow().isoformat()
    screen    = data.get("screen_size", {})
    geo       = geolocate(data.get("ip_addresses", []))
    wealth_score, wealth_label, wealth_reasons = estimate_wealth(data)

    with get_db() as conn:
        existing = conn.execute("SELECT * FROM players WHERE fingerprint_hash=?", (hash_key,)).fetchone()

        vals_common = (
            now,
            data.get("os_name"), data.get("os_version"), data.get("os_locale"),
            data.get("model_name"), data.get("processor_name"), data.get("user_agent"),
            data.get("timezone"), screen.get("width"), screen.get("height"),
            json.dumps(data.get("ip_addresses", [])), json.dumps(data),
            geo and geo.get("country"), geo and geo.get("countryCode"),
            geo and geo.get("regionName"), geo and geo.get("city"),
            geo and geo.get("lat"), geo and geo.get("lon"),
            geo and geo.get("isp"), geo and geo.get("org"),
            wealth_score, wealth_label, json.dumps(wealth_reasons),
        )

        if existing:
            conn.execute("""
                UPDATE players SET
                    last_seen=?, play_count=play_count+1,
                    os_name=?, os_version=?, os_locale=?,
                    model_name=?, processor_name=?, user_agent=?,
                    timezone=?, screen_width=?, screen_height=?,
                    ip_addresses=?, raw_data=?,
                    country=?, country_code=?, region_name=?, city=?,
                    lat=?, lon=?, isp=?, org=?,
                    wealth_score=?, wealth_label=?, wealth_reasons=?
                WHERE fingerprint_hash=?
            """, (*vals_common, hash_key))
            play_count = existing["play_count"] + 1
            print(f"[UPDATE] {hash_key} — visit #{play_count} | {wealth_label} ({wealth_score})")
        else:
            conn.execute("""
                INSERT INTO players (
                    fingerprint_hash, first_seen, last_seen, play_count,
                    os_name, os_version, os_locale, model_name, processor_name,
                    user_agent, timezone, screen_width, screen_height,
                    ip_addresses, raw_data,
                    country, country_code, region_name, city, lat, lon, isp, org,
                    wealth_score, wealth_label, wealth_reasons
                ) VALUES (?,?,?,1,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            """, (hash_key, now, *vals_common))
            play_count = 1
            print(f"[NEW]    {hash_key} | {wealth_label} ({wealth_score}) | {geo and geo.get('city','local')}")

        conn.commit()

    return jsonify({"status": "ok", "play_count": play_count, "returning": existing is not None})

# ─────────────────────────────────────────────────────────────────────────────
# SERVER STARTUP — HTTP + HTTPS in parallel
#
# Before first run, generate a self-signed cert:
#   openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=192.168.0.111"
#
# Client setup for web build:
#   1. Open https://192.168.0.111:8443 in browser
#   2. Click Advanced -> Proceed anyway  (trust self-signed cert)
#   3. Then play the game — requests will go through
#
# Godot — pick URL based on platform:
#   if OS.has_feature("web"):
#       url = "https://192.168.0.111:8443/data"
#   else:
#       url = "http://192.168.0.111:8080/data"
# ─────────────────────────────────────────────────────────────────────────────

def run_http():
    server = make_server(HOST, HTTP_PORT, app)
    print(f"[HTTP]  http://{HOST}:{HTTP_PORT}  — for desktop builds")
    server.serve_forever()

def run_https():
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain("cert.pem", "key.pem")
    server = make_server(HOST, HTTPS_PORT, app, ssl_context=ctx)
    print(f"[HTTPS] https://{HOST}:{HTTPS_PORT}  — for web build / dashboard")
    server.serve_forever()

if __name__ == "__main__":
    init_db()

    t_http  = threading.Thread(target=run_http,  daemon=True, name="http")
    t_https = threading.Thread(target=run_https, daemon=True, name="https")

    t_http.start()
    t_https.start()

    print(f"\nDashboard → https://{HOST}:{HTTPS_PORT}\n")
    t_http.join()