import datetime
import json
import os
import re
import subprocess
import sys
import urllib.parse
import urllib.request

RES_DIR = os.path.dirname(os.path.abspath(__file__))
VARS_PATH = os.path.join(RES_DIR, "PanelVars.inc")
FORECAST_PATH = os.path.join(RES_DIR, "WeatherForecast.inc")
RAINMETER = r"C:\Program Files\Rainmeter\Rainmeter.exe"

WMO_ES = {
    0: "Despejado",
    1: "Mayormente despejado",
    2: "Parcial nublado",
    3: "Nublado",
    45: "Niebla",
    48: "Niebla helada",
    51: "Llovizna leve",
    53: "Llovizna",
    55: "Llovizna fuerte",
    56: "Llovizna helada",
    57: "Llovizna helada",
    61: "Lluvia leve",
    63: "Lluvia moderada",
    65: "Lluvia fuerte",
    66: "Lluvia helada",
    67: "Lluvia helada",
    71: "Nieve leve",
    73: "Nieve",
    75: "Nieve intensa",
    77: "Granizo",
    80: "Chaparrones",
    81: "Chaparrones",
    82: "Chaparrones fuertes",
    85: "Nevadas",
    86: "Nevadas",
    95: "Tormenta",
    96: "Tormenta/granizo",
    99: "Tormenta fuerte",
}

WMO_SHORT = {
    0: "Despejado",
    1: "Despejado",
    2: "Parcial",
    3: "Nublado",
    45: "Niebla",
    48: "Niebla",
    51: "Llovizna",
    53: "Llovizna",
    55: "Llovizna",
    56: "Llovizna",
    57: "Llovizna",
    61: "Lluvia",
    63: "Lluvia",
    65: "Lluvia",
    66: "Lluvia",
    67: "Lluvia",
    71: "Nieve",
    73: "Nieve",
    75: "Nieve",
    77: "Granizo",
    80: "Chubascos",
    81: "Chubascos",
    82: "Chubascos",
    85: "Nieve",
    86: "Nieve",
    95: "Tormenta",
    96: "Tormenta",
    99: "Tormenta",
}

WMO_ICON = {
    0: "☀",
    1: "🌤",
    2: "⛅",
    3: "☁",
    45: "🌫",
    48: "🌫",
    51: "🌦",
    53: "🌦",
    55: "🌧",
    56: "🌧",
    57: "🌧",
    61: "🌦",
    63: "🌧",
    65: "🌧",
    66: "🌧",
    67: "🌧",
    71: "❄",
    73: "❄",
    75: "❄",
    77: "❄",
    80: "🌦",
    81: "🌧",
    82: "🌧",
    85: "❄",
    86: "❄",
    95: "⛈",
    96: "⛈",
    99: "⛈",
}

def wmo_icon(code, is_day=1):
    if code == 0 and is_day == 0:
        return "🌙"
    if code in (1, 2) and is_day == 0:
        return "☁"
    return WMO_ICON.get(code, "☀")

DAYS_ES = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]

def read_vars():
    with open(VARS_PATH, "rb") as f:
        raw = f.read()
    enc = "utf-16" if raw.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8-sig"
    text = raw.decode(enc)
    data = {}
    for line in text.splitlines():
        m = re.match(r"^\s*([A-Za-z0-9_]+)\s*=\s*(.*)\s*$", line)
        if m:
            data[m.group(1)] = m.group(2).strip()
    return text, data

def write_vars(updates):
    text, _ = read_vars()
    lines = text.splitlines()
    found = set()
    new_lines = []
    for line in lines:
        m = re.match(r"^(\s*)([A-Za-z0-9_]+)(\s*=)(.*)$", line)
        if m and m.group(2) in updates:
            k = m.group(2)
            new_lines.append(f"{k} ={updates[k]}")
            found.add(k)
        else:
            new_lines.append(line)
    for k, v in updates.items():
        if k not in found:
            new_lines.append(f"{k} ={v}")
    with open(VARS_PATH, "w", encoding="utf-16") as f:
        f.write("\n".join(new_lines) + "\n")

def http_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "StormPulse/1.0"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))

def fmt_temp(val, unit):
    if unit == "F":
        return round(val * 9.0 / 5.0 + 32.0)
    return round(val)

def write_forecast_inc(hourly_rows, daily_rows):
    lines = ["[Variables]"]
    for i in range(10):
        hl, hm, hr = hourly_rows[i] if i < len(hourly_rows) else ("", "", "")
        dl, dm, dr = daily_rows[i] if i < len(daily_rows) else ("", "", "")
        lines.append(f"WH{i}L ={hl}")
        lines.append(f"WH{i}M ={hm}")
        lines.append(f"WH{i}R ={hr}")
        lines.append(f"WD{i}L ={dl}")
        lines.append(f"WD{i}M ={dm}")
        lines.append(f"WD{i}R ={dr}")
    with open(FORECAST_PATH, "w", encoding="utf-16") as f:
        f.write("\n".join(lines) + "\n")

def fetch_weather(lat, lon, label, unit="C"):
    url = (
        f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}"
        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day"
        "&hourly=temperature_2m,weather_code,is_day"
        "&daily=weather_code,temperature_2m_max,temperature_2m_min"
        "&forecast_days=10&timezone=auto"
    )
    try:
        j = http_json(url)
        cur = j.get("current", {})
        cur_time = cur.get("time", "")
        is_day = int(cur.get("is_day", 1))
        temp = fmt_temp(cur.get("temperature_2m", 0), unit)
        feels = fmt_temp(cur.get("apparent_temperature", cur.get("temperature_2m", 0)), unit)
        hum = round(cur.get("relative_humidity_2m", 0))
        wind = round(cur.get("wind_speed_10m", 0))
        code = int(cur.get("weather_code", 0))
        icon = wmo_icon(code, is_day)
        cond = f"{icon} {WMO_ES.get(code, 'Despejado')}"

        # Build next 10 hourly rows starting from the next hour after current time
        hourly = j.get("hourly", {})
        h_times = hourly.get("time", [])
        h_temps = hourly.get("temperature_2m", [])
        h_codes = hourly.get("weather_code", [])
        h_isday = hourly.get("is_day", [1] * len(h_times))
        start_idx = 0
        if cur_time:
            cur_prefix = cur_time[:13]  # YYYY-MM-DDTHH
            for idx, tstr in enumerate(h_times):
                if tstr[:13] > cur_prefix:
                    start_idx = idx
                    break
        hourly_rows = []
        for idx in range(start_idx, min(start_idx + 10, len(h_times))):
            hh = h_times[idx][11:16]
            hcode = int(h_codes[idx])
            hd = int(h_isday[idx]) if idx < len(h_isday) else 1
            hc = f"{wmo_icon(hcode, hd)} {WMO_SHORT.get(hcode, 'Despejado')}"
            ht = f"{fmt_temp(h_temps[idx], unit)}°"
            hourly_rows.append((hh, hc, ht))

        # Build 10 daily rows
        daily = j.get("daily", {})
        d_times = daily.get("time", [])
        d_max = daily.get("temperature_2m_max", [])
        d_min = daily.get("temperature_2m_min", [])
        d_codes = daily.get("weather_code", [])
        daily_rows = []
        for idx in range(min(10, len(d_times))):
            dt = datetime.date.fromisoformat(d_times[idx])
            if idx == 0:
                d_lbl = "Hoy"
            elif idx == 1:
                d_lbl = "Mañ"
            else:
                d_lbl = f"{DAYS_ES[dt.weekday()]} {dt.day:02d}"
            dcode = int(d_codes[idx])
            dc = f"{wmo_icon(dcode, 1)} {WMO_SHORT.get(dcode, 'Despejado')}"
            dr = f"{fmt_temp(d_min[idx], unit):>2}° / {fmt_temp(d_max[idx], unit):>2}°"
            daily_rows.append((d_lbl, dc, dr))

        write_forecast_inc(hourly_rows, daily_rows)
        write_vars({
            "WTemp": str(temp),
            "WCond": cond,
            "WDetails": f"ST {feels}° · {hum}% · {wind} km/h",
            "WeatherLabel": label,
        })
        return f"{temp}|{cond}|ST {feels}° · {hum}% · {wind} km/h"
    except Exception as e:
        return f"--|Error|{e}"

def refresh_skins():
    if os.path.exists(RAINMETER):
        subprocess.run([RAINMETER, "!Refresh", r"StormPulse\Panel"], check=False)
        subprocess.run([RAINMETER, "!Refresh", r"StormPulse\Settings"], check=False)

def search_city(query):
    _, data = read_vars()
    q = (query or data.get("WeatherQuery", "")).strip()
    unit = data.get("WeatherUnit", "C")
    if not q:
        return
    url = f"https://geocoding-api.open-meteo.com/v1/search?name={urllib.parse.quote(q)}&count=1&language=es&format=json"
    try:
        j = http_json(url)
        results = j.get("results") or []
        if not results:
            write_vars({"WCond": f"No hallada: {q[:14]}"})
        else:
            r = results[0]
            name = r.get("name", q)
            cc = r.get("country_code", "")
            lat = f"{r['latitude']:.5f}"
            lon = f"{r['longitude']:.5f}"
            label = f"{name}, {cc}" if cc else name
            write_vars({
                "WeatherCity": name,
                "WeatherLat": lat,
                "WeatherLon": lon,
                "WeatherLabel": label,
            })
            fetch_weather(lat, lon, label, unit)
    except Exception:
        write_vars({"WCond": "Error de búsqueda"})

    refresh_skins()

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "fetch"
    if cmd == "search":
        q = " ".join(sys.argv[2:]).strip()
        search_city(q)
    else:
        _, data = read_vars()
        lat = data.get("WeatherLat", "-34.61315")
        lon = data.get("WeatherLon", "-58.37723")
        label = data.get("WeatherLabel", "Buenos Aires, AR")
        unit = data.get("WeatherUnit", "C")
        out = fetch_weather(lat, lon, label, unit)
        print(out)
        if "--refresh" in sys.argv:
            refresh_skins()
