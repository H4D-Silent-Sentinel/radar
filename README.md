# radar

Bench radar for Silent Sentinel: an Ai-Thinker RD-03D (24 GHz, ~8 m, moving targets only) standing in for a real radar, one input to the fused track.

| File | What |
|---|---|
| `rd03d.py` | RD-03D frame parser, encoder, serial reader |
| `firmware/radar_bridge/` | ESP32-S3 sketch: radar UART (GPIO17/18) passed straight to USB. Compiles. |
| `docs/radar.md` | Wiring, bring-up, demo steps |
| `cad/` | 3D-printed enclosure: OpenSCAD source, print-ready STLs, previews, assembly |
| `silent-sentinel-integration.patch` | The full integration into sentinel's `cuas` (radar sites, `--radar` option, map layer, simulated radar coverage gap, tests). Apply in a sentinel checkout with `git apply`. Written against commit a555c9f. |
| `radar_gap.json`, `demo_bench_radar.json` | Site files used by the patch |
| `tests/test_radar.py` | Tests (run inside sentinel after applying the patch) |

Next step when the module arrives: send its targets to ROAREE (roaree repo) as `radar` messages on udp/47012 (format in roaree's `sentinel_c2/radar.py`), so it shows on the C2 radar scope.
