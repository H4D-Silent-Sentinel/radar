// Silent Sentinel bench radar enclosure
// RD-03D radar (front, facing out through a window) + bridge board (behind it, USB out the back).
//
//   part   = "base" | "lid" | "assembly"
//   bridge = "esp32"      ESP32-S3-DevKitC-1 (official Espressif, 62.7 x 25.4 mm) on end ledges
//            "usbserial"  SparkFun Serial Basic (CH340C) or similar small USB-serial board on a pad
//
// Export:  openscad -D 'part="base"' -D 'bridge="esp32"' -o base_esp32.stl radar_enclosure.scad
//
// Axes: X = width, Y = depth (radar faces -Y, the "front"), Z = up. Units mm.
// MEASURE YOUR BOARDS FIRST and adjust the numbers below if they differ; clearances are generous.

part   = "assembly";
bridge = "esp32";

$fn = 48;

// ---- print / box -----------------------------------------------------------
wall   = 2.4;
floor_t = 2.4;
lid_t  = 2.0;
fit    = 0.3;        // lid lip clearance

// ---- RD-03D (datasheet: 44.0 x 15.0 mm, +/-0.2) ------------------------------
radar_w   = 44.0;    // long side, horizontal (azimuth)
radar_h   = 15.0;
radar_t   = 1.6;     // PCB thickness
radar_gap = 1.0;     // air gap between radar face and the inside of the front wall
radar_back = 7.0;    // room behind the radar for its connector + cable bend
slot_clr  = 0.5;     // extra width in the grooves
groove    = 2.0;     // how far each radar edge sits into a groove
win_w = 40; win_h = 11;  // front window (antennas see through an opening, no plastic)

// ---- ESP32-S3-DevKitC-1 -------------------------------------------------------
esp_l = 63.5;        // official board 62.74; clones up to ~70 also sit on the long front ledge
esp_w = 25.4;
esp_clear_l = 72;    // bay length
pcb_t = 1.6;
standoff = 21.0;     // board bottom above floor: pins hang ~8.5 mm below the board, and the radar
                     // cable's dupont sockets push onto them from below (~12 mm more), no soldering
ledge_half = 8.0;    // ledges stay between the two header rows (rows are +/-11.4 from centre)

// ---- USB-serial variant -------------------------------------------------------
us_pad_h = 3.0;      // pad the small board sits on (stick it with foam tape)

// ---- derived --------------------------------------------------------------------
post_w = 6;                                   // radar holder posts
in_w   = radar_w + 2 * (post_w - groove) + 2 * slot_clr;  // interior width
radar_y = radar_gap;                          // radar front face, from inside of front wall
bay_y0 = radar_y + radar_t + radar_back;      // start of the board bay
in_d   = bay_y0 + esp_clear_l + 0.5;
usb_top = standoff + pcb_t + 1.6 + 4.25;      // top of the USB opening, above the floor
in_h   = max(radar_h + 6, usb_top + 2.5);   // lid lip (2 mm) stays above the USB opening
out_w = in_w + 2 * wall; out_d = in_d + 2 * wall; out_h = floor_t + in_h;
boss_d = 6.5; pilot = 2.6; clear_hole = 3.4;  // M3 x 8 self-tapping screws
boss_xy = [[wall + boss_d/2, wall + bay_y0 + 4], [out_w - wall - boss_d/2, wall + bay_y0 + 4],
           [wall + boss_d/2, out_d - wall - boss_d/2], [out_w - wall - boss_d/2, out_d - wall - boss_d/2]];
cx = out_w / 2;

module rounded_box(w, d, h, r = 3) {
    hull() for (x = [r, w - r], y = [r, d - r]) translate([x, y, 0]) cylinder(r = r, h = h);
}

// ---- base -------------------------------------------------------------------------
module base() {
    difference() {
        union() {
            difference() {
                rounded_box(out_w, out_d, out_h);
                translate([wall, wall, floor_t]) cube([in_w, in_d, in_h + 1]);
            }
            radar_posts();
            for (p = boss_xy) translate([p[0], p[1], 0]) cylinder(d = boss_d, h = out_h);
            if (bridge == "esp32") esp_supports(); else us_pad();
            tripod_boss();
        }
        // front window, flared outward so +/-60 deg azimuth isn't shadowed by the wall
        translate([cx, 0, floor_t + radar_h / 2])
            hull() {
                translate([0, wall + 0.01, 0]) cube([win_w, 0.02, win_h], center = true);
                translate([0, -0.01, 0]) cube([win_w + 2 * wall * 1.8, 0.02, win_h + 2 * wall * 1.2], center = true);
            }
        for (p = boss_xy) translate([p[0], p[1], floor_t + 2]) cylinder(d = pilot, h = out_h);
        usb_cutout();
        tripod_hole();
    }
}

module radar_posts() {
    // two posts with vertical grooves; the radar slides in from the top
    gy = wall + radar_y;  // groove front face
    for (side = [0, 1]) {
        x0 = side == 0 ? wall : wall + in_w - post_w;
        difference() {
            translate([x0, wall, 0]) cube([post_w, radar_y + radar_t + slot_clr + 2, out_h - 2.5]);
            gx = side == 0 ? x0 + post_w - groove - slot_clr : x0 - 0.01;
            translate([gx, gy - slot_clr / 2, floor_t]) cube([groove + slot_clr + 0.01, radar_t + slot_clr, radar_h + 5]);
            // lead-in chamfer at the top of each groove
            translate([gx + (groove + slot_clr) / 2, gy + radar_t / 2, floor_t + radar_h + 2])
                rotate([0, 0, 0]) cylinder(d1 = radar_t + slot_clr, d2 = radar_t + slot_clr + 2, h = 0.01 + 1, center = true);
        }
    }
}

module esp_supports() {
    y_rear = wall + in_d - 0.5;          // USB end of the board, against the back wall
    // rear ledge (under the USB end), front ledge long enough for 62-70 mm boards
    translate([cx - ledge_half, y_rear - 4, 0]) cube([2 * ledge_half, 4, floor_t + standoff]);
    translate([cx - ledge_half, y_rear - esp_clear_l + 0.5, 0]) cube([2 * ledge_half, esp_clear_l - esp_l + 6, floor_t + standoff]);
    // side guides keep the board centred (outside the header rows)
    for (s = [-1, 1], y = [y_rear - 10, y_rear - esp_l + 8])
        translate([cx + s * (esp_w / 2 + 0.4) + (s < 0 ? -1.2 : 0), y - 3, 0])
            cube([1.2, 6, floor_t + standoff + 3]);
}

module us_pad() {
    translate([cx - 12, wall + in_d - 32, 0]) cube([24, 30, floor_t + us_pad_h]);
}

module usb_cutout() {
    if (bridge == "esp32") {
        zc = floor_t + standoff + pcb_t + 1.6;          // USB-C centre height
        translate([cx, out_d - wall / 2, zc]) cube([2 * 13, wall + 2, 8.5], center = true);
    } else {
        zc = floor_t + us_pad_h + pcb_t + 1.6;
        translate([cx, out_d - wall / 2, zc + 2]) cube([14, wall + 2, 12], center = true);
    }
}

// 1/4"-20 tripod nut, dropped in from inside, screw from below
tripod_y = wall + bay_y0 + esp_clear_l / 2;
module tripod_boss() { translate([cx, tripod_y, 0]) cylinder(d = 17, h = floor_t + 6); }
module tripod_hole() {
    translate([cx, tripod_y, -1]) cylinder(d = 6.8, h = 20);
    translate([cx, tripod_y, floor_t + 6 - 5.8]) cylinder(d = 11.4 / cos(30) + 0.4, h = 10, $fn = 6);
}

// ---- lid --------------------------------------------------------------------------
module lid() {
    difference() {
        union() {
            rounded_box(out_w, out_d, lid_t);
            // locating lip that drops inside the walls (clears posts and bosses)
            difference() {
                translate([wall + fit, wall + fit, -2]) cube([in_w - 2 * fit, in_d - 2 * fit, 2]);
                translate([wall + fit + 1.2, wall + fit + 1.2, -3]) cube([in_w - 2 * fit - 2.4, in_d - 2 * fit - 2.4, 4]);
                for (p = boss_xy) translate([p[0], p[1], -3]) cylinder(d = boss_d + 1, h = 4);
                translate([wall, wall, -3]) cube([in_w, radar_y + radar_t + slot_clr + 2.5, 4]);
            }
            // tab that holds the radar down in its grooves
            rt = out_h - (floor_t + radar_h + 0.4);
            translate([wall + post_w + 1, wall + radar_y - 0.5, -rt]) cube([in_w - 2 * post_w - 2, radar_t + 1, rt]);
        }
        for (p = boss_xy) translate([p[0], p[1], -3]) {
            cylinder(d = clear_hole, h = 10);
            translate([0, 0, 3 + lid_t - 1.6]) cylinder(d1 = clear_hole, d2 = 6.5, h = 1.61);
        }
        // boresight arrow (points where the radar looks) engraved in the top
        translate([cx, 0, lid_t - 0.8]) linear_extrude(1) {
            translate([0, 14]) polygon([[-7, 0], [7, 0], [0, -10]]);
            translate([-1.8, 13.9]) square([3.6, 16]);
        }
    }
}

// ---- stand-in parts for the assembly view ------------------------------------------
module radar_dummy() {
    color("seagreen") translate([wall + post_w - groove, wall + radar_y, floor_t]) cube([radar_w, radar_t, radar_h]);
}
module esp_dummy() {
    color("royalblue") translate([cx - esp_w / 2, wall + in_d - 0.5 - esp_l, floor_t + standoff]) cube([esp_w, esp_l, pcb_t]);
}

if (part == "base") base();
else if (part == "lid") translate([0, 0, lid_t]) rotate([180, 0, 0]) translate([0, -out_d, 0]) lid(); // print top-down
else {
    base();
    radar_dummy();
    if (bridge == "esp32") esp_dummy();
    color("lightgray", 0.35) translate([0, 0, out_h + 8]) lid();
}
