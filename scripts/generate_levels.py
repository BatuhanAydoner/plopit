#!/usr/bin/env python3
"""200 unique PlopIt levels. Difficulty is strictly increasing; only 1–3 have no obstacles."""

import json
import math
from pathlib import Path


def clamp(value, low, high):
    return max(low, min(high, value))


def progress(level_id):
    return (level_id - 1) / 199.0


def obstacle_count(level_id):
    if level_id <= 3:
        return 0
    return 1 + (level_id - 4) * 22 // 196


def max_throws(level_id):
    if level_id <= 15:
        return 10
    if level_id <= 40:
        return 8
    if level_id <= 80:
        return 6
    if level_id <= 130:
        return 5
    if level_id <= 170:
        return 4
    return 3


def thickness_for(level_id):
    return 14 if level_id <= 80 else 13 if level_id <= 150 else 12


def target_radius(level_id):
    return round(74 - (level_id - 1) * 48 / 199, 1)


def opening_degrees(level_id):
    return 138 - progress(level_id) * 100


def target_position(level_id):
    t = progress(level_id)
    if level_id == 1:
        return 0.50, 0.70
    if level_id == 2:
        return 0.70, 0.68
    if level_id == 3:
        return 0.30, 0.68

    angle = level_id * 2.399963
    reach = 0.08 + t * 0.36
    x = 0.50 + math.cos(angle) * reach
    y = 0.70 + math.sin(angle) * (0.08 + t * 0.14)
    return round(clamp(x, 0.16, 0.84), 3), round(clamp(y, 0.62, 0.86), 3)


def bar(width, height, x, y, rotation):
    return {
        "width": round(width, 1),
        "height": round(height, 1),
        "x": round(clamp(x, 0.10, 0.90), 3),
        "y": round(clamp(y, 0.24, 0.88), 3),
        "rotation": round(((rotation + 180) % 360) - 180, 1),
    }


def wrap_radius(target_r, extra_pt):
    return (target_r + extra_pt) / 390.0, (target_r + extra_pt) / 720.0


def horseshoe(tx, ty, tr, pieces, opening_deg, opening_dir, length, thick, extra_pt):
    if pieces <= 0:
        return []
    rx, ry = wrap_radius(tr, extra_pt)
    half_gap = math.radians(max(opening_deg, 28) / 2)
    start = math.radians(opening_dir) + half_gap
    span = 2 * math.pi - 2 * half_gap
    obstacles = []
    for i in range(pieces):
        angle = start + span * (i + 0.5) / pieces
        obstacles.append(
            bar(
                length,
                thick,
                tx + math.cos(angle) * rx,
                ty + math.sin(angle) * ry,
                math.degrees(angle) - 90,
            )
        )
    return obstacles


def slalom(count, level_id, thick, t, y_lo=0.30, y_hi=0.54, width=128):
    if count <= 0:
        return []
    obstacles = []
    offset = 0.14 + t * 0.10
    tilt = 6 + t * 18
    for i in range(count):
        frac = i / max(count - 1, 1)
        y = y_lo + (y_hi - y_lo) * frac
        side = 1 if (i + level_id) % 2 == 0 else -1
        w = width - frac * (18 + t * 20)
        obstacles.append(bar(w, thick, 0.50 + side * offset, y, side * tilt))
    return obstacles


def funnel(tx, thick, t, y=0.40):
    mouth = 0.28 - t * 0.10
    tilt = 16 + t * 18
    length = 150 - t * 28
    return [
        bar(length, thick, tx - mouth, y, tilt),
        bar(length, thick, tx + mouth, y, -tilt),
    ]


def gates(count, tx, thick, t):
    obstacles = []
    pairs = count // 2
    leftover = count % 2
    gap = 0.22 - t * 0.08
    height = 96 + t * 16
    for i in range(pairs):
        y = 0.30 + i * (0.09 - t * 0.01)
        sway = 0.05 * math.sin(i * 1.2 + tx * 8)
        obstacles.append(bar(thick, height, tx - gap + sway, y, 0))
        obstacles.append(bar(thick, height, tx + gap + sway, y, 0))
    if leftover:
        obstacles.append(bar(110 - t * 20, thick, 1 - tx, 0.46, (tx * 20) - 10))
    return obstacles[:count]


def stairs(count, thick, t, going_right):
    sign = 1 if going_right else -1
    start_x = 0.32 if going_right else 0.68
    step = 0.10 + t * 0.02
    obstacles = []
    for i in range(count):
        obstacles.append(
            bar(108 - t * 16, thick, start_x + sign * i * step, 0.30 + i * 0.075, sign * (8 + t * 10))
        )
    return obstacles


def chevrons(count, tx, thick, t):
    obstacles = []
    rows = math.ceil(count / 2)
    for row in range(rows):
        y = 0.30 + row * (0.085 + t * 0.008)
        spread = 0.18 + row * 0.025 - t * 0.04
        tilt = 20 + t * 14
        length = 118 - row * 6
        obstacles.append(bar(length, thick, tx - spread, y, tilt))
        if len(obstacles) < count:
            obstacles.append(bar(length, thick, tx + spread, y, -tilt))
    return obstacles[:count]


def zigzag(count, thick, t, level_id):
    obstacles = []
    for i in range(count):
        y = 0.28 + i * (0.07 + t * 0.004)
        side = 1 if i % 2 == 0 else -1
        if level_id % 2:
            side = -side
        obstacles.append(
            bar(
                132 - t * 22,
                thick,
                0.50 + side * (0.20 - t * 0.04),
                y,
                side * (12 + t * 10),
            )
        )
    return obstacles


def pockets(count, tx, thick, t):
    wall_h = 130 + t * 20
    obstacles = [
        bar(thick, wall_h, 0.18, 0.42, 0),
        bar(thick, wall_h, 0.82, 0.42, 0),
        bar(118, thick, 0.22, 0.58 + t * 0.04, 0),
        bar(118, thick, 0.78, 0.58 + t * 0.04, 0),
    ]
    extras = slalom(max(0, count - 4), int(tx * 50), thick, t, 0.30, 0.48, 100)
    return (obstacles + extras)[:count]


def compose(level_id, count, tx, ty, tr, thick):
    if count <= 0:
        return []

    t = progress(level_id)
    opening = opening_degrees(level_id)
    doors = [270, 248, 292, 236, 304, 258, 282]
    door = doors[level_id % len(doors)]
    wrap_len = 86 - t * 18
    wrap_extra = 34 - t * 8

    families = [
        "horseshoe_path",
        "funnel_cup",
        "slalom_lane",
        "gate_run",
        "stair_climb",
        "side_pockets",
        "spiral_in",
        "fortress",
        "chevron",
        "nested_c",
        "zigzag_wall",
        "diamond_lane",
    ]
    family = families[(level_id * 7) % len(families)]

    def with_wrap(base, wrap_n, extra_pt=None):
        pieces = horseshoe(
            tx, ty, tr, wrap_n, opening, door, wrap_len, thick, extra_pt or wrap_extra
        )
        return base + pieces

    if family == "horseshoe_path":
        wrap_n = min(count, 3 + int(t * 8))
        layout = with_wrap(slalom(max(0, count - wrap_n), level_id, thick, t), wrap_n)
    elif family == "funnel_cup":
        layout = with_wrap(funnel(tx, thick, t, y=0.36 + t * 0.04), max(0, count - 2), wrap_extra + 4)
    elif family == "slalom_lane":
        layout = slalom(count, level_id, thick, t, 0.28, 0.58, 136 - t * 24)
    elif family == "gate_run":
        layout = gates(count, tx, thick, t)
    elif family == "stair_climb":
        layout = stairs(count, thick, t, going_right=level_id % 2 == 0)
    elif family == "side_pockets":
        layout = pockets(count, tx, thick, t)
    elif family == "spiral_in":
        inner = max(1, count // 2)
        layout = horseshoe(tx, ty, tr, inner, opening, door, wrap_len, thick, wrap_extra) + horseshoe(
            tx, ty, tr, max(0, count - inner), opening + 16, door, wrap_len + 16, thick, wrap_extra + 28
        )
    elif family == "fortress":
        wrap_n = min(count, max(1, count - 2))
        layout = with_wrap(slalom(max(0, count - wrap_n), level_id, thick, t, 0.28, 0.42, 96), wrap_n, 26)
    elif family == "chevron":
        layout = chevrons(count, tx, thick, t)
    elif family == "nested_c":
        inner = max(1, (count + 1) // 2)
        layout = horseshoe(tx, ty, tr, inner, opening, door, wrap_len - 8, thick, wrap_extra) + horseshoe(
            tx, ty, tr, max(0, count - inner), opening + 12, door + 8, wrap_len + 10, thick, wrap_extra + 22
        )
    elif family == "zigzag_wall":
        layout = zigzag(count, thick, t, level_id)
    else:
        rx, ry = wrap_radius(tr, 32 + t * 8)
        diamond = [
            bar(88 - t * 10, thick, tx, ty + ry, 0),
            bar(88 - t * 10, thick, tx + rx, ty, 90),
            bar(88 - t * 10, thick, tx - rx, ty, 90),
        ]
        layout = diamond + slalom(max(0, count - 3), level_id, thick, t, 0.28, 0.44, 108)

    if len(layout) < count:
        layout.extend(slalom(count - len(layout), level_id + 17, thick, t, 0.28, 0.50, 112))
    return layout[:count]


def make_level(level_id):
    count = obstacle_count(level_id)
    tx, ty = target_position(level_id)
    tr = target_radius(level_id)
    thick = thickness_for(level_id)
    obstacles = compose(level_id, count, tx, ty, tr, thick)
    if len(obstacles) != count:
        raise RuntimeError(f"Level {level_id}: expected {count} obstacles, got {len(obstacles)}")
    return {
        "id": level_id,
        "maxThrows": max_throws(level_id),
        "rethrowFromRest": True,
        "ballStart": {"x": 0.5, "y": 0.13},
        "target": {"radius": tr, "x": tx, "y": ty},
        "obstacles": obstacles,
        "completed": False,
        "throwsToComplete": None,
    }


def layout_fingerprint(level):
    parts = [
        f"{level['target']['x']:.2f},{level['target']['y']:.2f},{level['target']['radius']}"
    ]
    for obs in level["obstacles"]:
        parts.append(
            f"{obs['width']:.0f}x{obs['height']:.0f}@{obs['x']:.2f},{obs['y']:.2f}r{obs['rotation']:.0f}"
        )
    return "|".join(parts)


def assert_increasing_difficulty(levels):
    for prev, curr in zip(levels, levels[1:]):
        if curr["target"]["radius"] > prev["target"]["radius"] + 0.001:
            raise RuntimeError(f"radius grew at {curr['id']}")
        if len(curr["obstacles"]) < len(prev["obstacles"]):
            raise RuntimeError(f"obstacle count dropped at {curr['id']}")


def main():
    levels = [make_level(level_id) for level_id in range(1, 201)]
    fingerprints = [layout_fingerprint(level) for level in levels]
    unique = len(set(fingerprints))
    if unique != 200:
        raise RuntimeError(f"duplicate layouts: {unique}/200 unique")
    assert_increasing_difficulty(levels)

    document = {"version": 4, "levels": levels}
    output = Path(__file__).resolve().parents[1] / "PlopIt" / "levels.json"
    output.write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8")

    counts = {}
    for level in levels:
        n = len(level["obstacles"])
        counts[n] = counts.get(n, 0) + 1

    print(f"wrote {len(levels)} unique levels")
    print("empty:", [level["id"] for level in levels if not level["obstacles"]])
    print("obstacle counts:", dict(sorted(counts.items())))
    print("radius 1 / 100 / 200:", levels[0]["target"]["radius"], levels[99]["target"]["radius"], levels[199]["target"]["radius"])
    print("obs 4 / 50 / 100 / 200:", [len(levels[i]["obstacles"]) for i in (3, 49, 99, 199)])


if __name__ == "__main__":
    main()
