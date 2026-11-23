# radar

Bench radar for Silent Sentinel: an Ai-Thinker RD-03D (24 GHz, ~8 m, moving targets only) standing in for a real radar, to demo the radar-to-acoustic handoff.

| File | What |
|---|---|
| `rd03d.py` | RD-03D frame parser, encoder, serial reader |
| `firmware/radar_bridge/` | ESP32-S3 sketch: radar UART (GPIO17/18) passed straight to USB. Compiles. |
| `docs/radar.md` | Wiring, bring-up, demo steps |
| `silent-sentinel-integration.patch` | The full integration into silent-sentinel's `cuas` (radar sites, `--radar` option, map layer, simulated handoff, tests). Apply in a silent-sentinel checkout with `git apply`. Written against commit a555c9f. |
| `radar_handoff.json`, `demo_bench_radar.json` | Site files used by the patch |
| `tests/test_radar.py` | Tests (run inside silent-sentinel after applying the patch) |

Next step when the module arrives: send its targets to sentinel-c2 as `radar` messages on udp/47012 (format in sentinel-c2's `sentinel_c2/radar.py`), so it shows on the C2 radar scope.
