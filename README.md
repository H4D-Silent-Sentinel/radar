# radar

Bench radar for Silent Sentinel. An Ai-Thinker RD-03D (24 GHz FMCW, ~8 m range, moving targets only) provides radar plots to the fused track in place of a fielded radar.

| Path | Description |
|---|---|
| `rd03d.py` | RD-03D frame parser, encoder, serial reader |
| `rd03d_udp.py` | Bench use: RD-03D over USB to ROAREE `radar` messages on UDP 47012, with frame-to-frame target IDs |
| `firmware/radar_bridge/` | ESP32-S3 sketch: radar UART (GPIO17/18) passed straight to USB. Compiles. |
| `docs/radar.md` | Wiring, bring-up, demo steps |
| `cad/` | 3D-printed enclosure: OpenSCAD source, print-ready STLs, previews, assembly |
| `silent-sentinel-integration.patch` | The full integration into sentinel's `cuas` (radar sites, `--radar` option, map layer, simulated radar coverage gap, tests). Apply in a sentinel checkout with `git apply`. Written against commit a555c9f. |
| `radar_gap.json`, `demo_bench_radar.json` | Site files used by the patch |
| `tests/test_radar.py` | Tests (run inside sentinel after applying the patch) |

## Status

- [x] Frame parser and USB bridge firmware (compiles; not yet run on hardware)
- [x] Bench path: USB to ROAREE `radar` messages on UDP 47012 (`rd03d_udp.py`; not yet run on hardware)
- [x] On-site radar station over LoRa: firmware in [sentinel](https://github.com/H4D-Silent-Sentinel/sentinel) `firmware/radar_node`, fused by [ROAREE](https://github.com/H4D-Silent-Sentinel/roaree) (compiles; not yet run on hardware)
