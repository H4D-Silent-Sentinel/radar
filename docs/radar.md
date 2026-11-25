# Bench radar (RD-03D)

A small 24 GHz radar module stands in for a real air-search radar. Radar plots feed the same fused track as the acoustic nodes and cameras. When the drone leaves the radar beam, the other sensors keep the **same track** number.

The RD-03D reaches about 8 m and only reports things that move (up to 3 targets, ~10 frames/s). It sees people too, so the radar track on its own is unclassified.

## Parts

- Ai-Thinker RD-03D (comes with a 4-pin cable)
- Any ESP32-S3 dev board, or a USB-serial adapter that supports 256000 baud (CH340, CP2102N)

## Wiring (ESP32-S3 bridge)

| RD-03D | ESP32-S3 |
|---|---|
| 5V | 5V (VBUS); it does not run reliably on 3.3 V |
| GND | GND |
| TX | GPIO17 |
| RX | GPIO18 |

GPIO17/18 are also free on a listening node.

**USB-serial adapter instead of the ESP32:** radar TX → adapter RX, radar RX → adapter TX, GND → GND. No firmware needed. The radar needs **5 V power but 3.3 V signals**, so the adapter must have a separate 5 V pin with 3.3 V logic. Boards like the SparkFun Serial Basic use one jumper for both. On 3.3 V they can't power the radar, and on 5 V they send 5 V signals into the radar's RX. With one of those, power the radar from a separate 5 V source (shared GND), or use the ESP32 bridge.

3D-printed enclosure: `cad/` (see `cad/README.md`).

```sh
arduino-cli compile --fqbn $FQBN firmware/radar_bridge
arduino-cli upload  --fqbn $FQBN -p /dev/cu.usbmodemXXXX firmware/radar_bridge
```

## Bring-up

```sh
.venv/bin/python -m cuas radar --port /dev/cu.usbmodemXXXX     # walk in front of it: range / angle / speed
```

## Demo

```sh
# laptop mic as the acoustic node + the radar, map at http://127.0.0.1:8080
.venv/bin/python -m cuas listen --site sites/demo_bench_radar.json --radar /dev/cu.usbmodemXXXX --map
```

1. Set `yaw_deg` for `r1` in `sites/demo_bench_radar.json` to the direction the radar faces. If a target moving right shows up moving left, set `"flip_x": true`.
2. Move the drone (or a phone playing drone audio) in front of the radar: track appears with source **radar:r1**.
3. Move it out of the radar's view (behind a metal sheet or a wall, or out to the side) while the mic still hears it: `radar:r1` gets crossed out on the map, **acoustic** stays live, same track number.

Simulated version at city scale (radar out west, the drone flies into the intersection out of radar coverage):

```sh
.venv/bin/python -m cuas sim --site sites/radar_gap.json --map
```
