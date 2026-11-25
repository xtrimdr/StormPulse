import os
import re
import subprocess
import sys

RES_DIR = os.path.dirname(os.path.abspath(__file__))
VARS_PATH = os.path.join(RES_DIR, "PanelVars.inc")
RAINMETER = r"C:\Program Files\Rainmeter\Rainmeter.exe"
ALL_MODS = ["CPU", "GPU", "RAM", "NET", "DISK", "WEATHER"]

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

def get_order(data):
    raw = data.get("ModOrder", ",".join(ALL_MODS))
    order = [m.strip().upper() for m in raw.split(",") if m.strip().upper() in ALL_MODS]
    for m in ALL_MODS:
        if m not in order:
            order.append(m)
    return order

def refresh():
    if os.path.exists(RAINMETER):
        subprocess.run([RAINMETER, "!Refresh", r"StormPulse\Panel"], check=False)
        subprocess.run([RAINMETER, "!Refresh", r"StormPulse\Settings"], check=False)

def main():
    if len(sys.argv) < 3:
        return
    action = sys.argv[1].lower()
    _, data = read_vars()
    order = get_order(data)

    if action == "toggle":
        # arg2 can be slot index (0..5) or module name
        arg = sys.argv[2]
        mod = order[int(arg)] if arg.isdigit() and int(arg) < len(order) else arg.upper()
        key = f"Show{mod}"
        cur = data.get(key, "1")
        # Prevent hiding all modules (keep at least 1 visible)
        visible = [m for m in order if data.get(f"Show{m}", "1") == "1"]
        if cur == "1" and len(visible) <= 1:
            return
        new_val = "0" if cur == "1" else "1"
        write_vars({key: new_val})
        refresh()

    elif action == "move" and len(sys.argv) >= 4:
        arg = sys.argv[2]
        direction = sys.argv[3].lower()
        idx = int(arg) if arg.isdigit() else (order.index(arg.upper()) if arg.upper() in order else -1)
        if idx < 0 or idx >= len(order):
            return
        target = idx - 1 if direction == "up" else idx + 1
        if 0 <= target < len(order):
            order[idx], order[target] = order[target], order[idx]
            updates = {"ModOrder": ",".join(order)}
            for i, m in enumerate(order):
                updates[f"Slot{i}"] = m
            write_vars(updates)
            refresh()

if __name__ == "__main__":
    main()
