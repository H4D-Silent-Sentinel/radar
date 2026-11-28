"""RD-03D to ROAREE: reads the radar over USB serial and sends `radar` messages to UDP 47012.

    python rd03d_udp.py --port /dev/cu.usbmodemXXXX --lat 40.80940 --lon -73.96000 --yaw 90
    python rd03d_udp.py --port COM5 --lat ... --lon ... --yaw ... --c2 192.168.1.20 --flip-x

The RD-03D reports up to 3 moving targets per frame without track IDs. Targets are
associated frame to frame by nearest neighbour within GATE_M and keep their ID while
associated. Message format: roaree `sentinel_c2/radar.py`. Elevation is not measured
(2-D radar); reports carry el_deg 0 and the radar mounting height as alt_m.
"""
from __future__ import annotations

import argparse
import itertools
import json
import math
import socket
import time

from rd03d import BAUD, MULTI_TARGET_CMD, FrameParser, RadarTarget

RADAR_PORT = 47012
GATE_M = 1.0  # max movement between frames for a target to keep its ID
RATE_HZ = 5.0  # reports per second with targets
HEARTBEAT_S = 1.0  # report interval with no targets
MAX_RANGE_M = 8.0
RANGE_SIGMA_M = 0.15
AZ_SIGMA_DEG = 3.0
CONF = 0.8


class Associator:
    """Assigns persistent IDs to unlabelled targets by nearest neighbour."""

    def __init__(self, gate_m: float = GATE_M):
        self.gate_m = gate_m
        self.prev: dict[int, RadarTarget] = {}
        self._ids = itertools.count(1)

    def update(self, targets: list[RadarTarget]) -> list[tuple[int, RadarTarget]]:
        pairs = sorted(((math.hypot(t.x_m - p.x_m, t.y_m - p.y_m), i, tid)
                        for i, t in enumerate(targets) for tid, p in self.prev.items()))
        taken_t, taken_id, ids = set(), set(), {}
        for d, i, tid in pairs:
            if d <= self.gate_m and i not in taken_t and tid not in taken_id:
                ids[i] = tid
                taken_t.add(i)
                taken_id.add(tid)
        out = [(ids[i] if i in ids else next(self._ids), t) for i, t in enumerate(targets)]
        self.prev = {tid: t for tid, t in out}
        return out


def build_message(src: str, t: float, sensor: dict, yaw_deg: float, flip_x: bool,
                  targets: list[tuple[int, RadarTarget]]) -> dict:
    tracks = []
    for tid, tg in targets:
        off = -tg.angle_deg if flip_x else tg.angle_deg
        tracks.append({"id": tid, "range_m": round(tg.range_m, 3), "az_deg": round((yaw_deg + off) % 360, 2),
                       "el_deg": 0.0, "vr_mps": round(tg.speed_mps, 2), "conf": CONF,
                       "range_sigma_m": RANGE_SIGMA_M, "az_sigma_deg": AZ_SIGMA_DEG})
    return {"v": 1, "type": "radar", "src": src, "t": round(t, 3), "sensor": sensor, "tracks": tracks}


def parse_addr(s: str) -> tuple[str, int]:
    host, _, port = s.rpartition(":") if ":" in s else (s, "", "")
    return host or "127.0.0.1", int(port) if port else RADAR_PORT


def run(a) -> None:
    import serial  # pyserial

    addr = parse_addr(a.c2)
    sensor = {"lat": a.lat, "lon": a.lon, "alt_m": a.alt, "max_range_m": MAX_RANGE_M}
    tx = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    assoc, last = Associator(), 0.0
    print(f"rd03d_udp: {a.port} -> {addr[0]}:{addr[1]} as {a.src}", flush=True)
    while True:
        try:
            s = serial.Serial()
            s.port, s.baudrate, s.timeout = a.port, BAUD, 0.2
            s.dtr = s.rts = False
            s.open()
            with s:
                s.write(MULTI_TARGET_CMD)
                print(f"rd03d_udp: connected {a.port}", flush=True)
                parser = FrameParser()
                while True:
                    frames = parser.feed(s.read(512))
                    now = time.time()
                    targets = assoc.update(frames[-1]) if frames else None
                    due = 1.0 / RATE_HZ if targets else HEARTBEAT_S
                    if now - last >= due:
                        msg = build_message(a.src, now, sensor, a.yaw, a.flip_x, targets or [])
                        try:
                            tx.sendto(json.dumps(msg, separators=(",", ":")).encode(), addr)
                        except OSError:
                            pass
                        last = now
        except KeyboardInterrupt:
            return
        except Exception as e:  # unplugged: retry
            print(f"rd03d_udp: {e}; retrying in 2 s", flush=True)
            time.sleep(2)


def main(argv=None):
    ap = argparse.ArgumentParser(description="RD-03D to ROAREE radar messages over UDP")
    ap.add_argument("--port", required=True, help="serial port of the radar bridge or USB-serial adapter")
    ap.add_argument("--lat", type=float, required=True, help="radar latitude")
    ap.add_argument("--lon", type=float, required=True, help="radar longitude")
    ap.add_argument("--yaw", type=float, required=True, help="boresight azimuth, degrees true (0 = north, 90 = east)")
    ap.add_argument("--alt", type=float, default=1.0, help="mounting height above ground, m (default 1)")
    ap.add_argument("--src", default="radar-1", help="radar id (default radar-1)")
    ap.add_argument("--c2", default="127.0.0.1:47012", help="ROAREE address host[:port] (default 127.0.0.1:47012)")
    ap.add_argument("--flip-x", action="store_true", help="mirror left/right if targets move the wrong way")
    run(ap.parse_args(argv))


if __name__ == "__main__":
    main()
