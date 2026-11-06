import re
import sys

LINE = re.compile(r"PROBE f=(\d+) (\S+) pos=\(([-\d.]+), ([-\d.]+)\).*?vel=\(([-\d.]+), ([-\d.]+)\)(.*)")
items = {}
for raw in sys.stdin:
    if not raw.startswith("PROBE"):
        if "ERROR" in raw or "HARNESS quit" in raw:
            print(raw.rstrip())
        continue
    m = LINE.match(raw)
    if not m:
        continue
    f, name = int(m[1]), m[2]
    x, y, vx, vy = map(float, m.group(3, 4, 5, 6))
    held = '"held": true' in m[7]
    it = items.setdefault(name, {"apex": None, "events": [], "held": False, "last": None, "max_speed": 0.0})
    if held != it["held"]:
        it["events"].append(f"f={f} {'GRAB' if held else 'RELEASE'} pos=({x:.0f},{y:.0f}) vel=({vx:.0f},{vy:.0f})")
        it["held"] = held
    if not held and (it["apex"] is None or y < it["apex"][1]):
        it["apex"] = (f, y, x)
    it["max_speed"] = max(it["max_speed"], (vx * vx + vy * vy) ** 0.5)
    it["last"] = (f, x, y, vx, vy)
for name, it in items.items():
    f, x, y, vx, vy = it["last"]
    print(f"{name}: apex f={it['apex'][0]} y={it['apex'][1]:.0f} x={it['apex'][2]:.0f} | last f={f} pos=({x:.0f},{y:.0f}) vel=({vx:.0f},{vy:.0f}) | max_speed={it['max_speed']:.0f}")
    for e in it["events"]:
        print("   ", e)
