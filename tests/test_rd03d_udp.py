"""rd03d_udp: ID association and ROAREE radar messages. Runs without the sentinel patch."""
import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from rd03d import RadarTarget  # noqa: E402
from rd03d_udp import Associator, build_message  # noqa: E402


def test_ids_persist_while_targets_move_within_gate():
    a = Associator()
    (i1, _), (i2, _) = a.update([RadarTarget(0.0, 3.0, 0.5), RadarTarget(2.0, 5.0, -0.3)])
    out = a.update([RadarTarget(2.2, 5.1, -0.3), RadarTarget(0.1, 3.2, 0.5)])  # order swapped
    assert [i for i, _ in out] == [i2, i1]


def test_new_id_after_jump_beyond_gate():
    a = Associator()
    (i1, _), = a.update([RadarTarget(0.0, 3.0, 0.5)])
    (i2, _), = a.update([RadarTarget(0.0, 6.0, 0.5)])
    assert i2 != i1


def test_azimuth_from_yaw_and_flip():
    tg = [(1, RadarTarget(1.0, 1.0, 0.0))]  # 45 deg right of boresight
    sensor = {"lat": 40.0, "lon": -73.0, "alt_m": 1.0}
    assert build_message("radar-1", 0.0, sensor, 90.0, False, tg)["tracks"][0]["az_deg"] == 135.0
    assert build_message("radar-1", 0.0, sensor, 90.0, True, tg)["tracks"][0]["az_deg"] == 45.0
    assert build_message("radar-1", 0.0, sensor, 0.0, True, tg)["tracks"][0]["az_deg"] == 315.0


def test_roaree_accepts_message():
    radar = pytest.importorskip("sentinel_c2.radar")
    geo = pytest.importorskip("cuas.geo")
    msg = build_message("radar-1", 100.0, {"lat": 40.8094, "lon": -73.96, "alt_m": 1.0}, 90.0, False,
                        [(7, RadarTarget(0.0, 4.0, -0.5))])
    (obs,) = radar.parse_radar(json.dumps(msg), geo.LocalFrame(40.8094, -73.96))
    (e, n), _, _ = obs.fix()
    assert obs.track_id == 7 and abs(e - 4.0) < 0.05 and abs(n) < 0.05
