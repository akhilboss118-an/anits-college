# ENVIRONMENT_ASSET_INVENTORY.md — the campus as a set of objects

**Scope:** every non-building, non-character object in the ANITS campus, plus the complete
list of shipped model/texture/audio/font files.

**Evidence basis:** `ANITS-WEB GAME/js/game.js` (prop-placement blocks), `js/assets.js`
(asset manifest), `js/voice.js` + `js/core.js` (audio), the `assets/` tree itself, and
runtime counters (`window.__grass`, `window.__parkedCars`, `window.__lp`, `window.__sit`).

**Tags:** [V] verified · [O] observed in screenshot · [U] unknown · [P] proposed.

---

## 1. Ground plan surfaces

| Surface | Definition | World extent | Appearance |
|---|---|---|---|
| Lawn (base) | implicit ground plane | whole campus | flat green; the game's ground colour under everything |
| Roads (8 rects) | `ROADS` table, `game.js` L62 | see below | dark asphalt `#555a63` on the minimap, real mesh in-world |
| Sand field | `SAND = 146,357,249,427` | x −48.3…23.8, z 74.9…123.9 | tan sand `#dcbc8a`; the NCC assembly ground |
| Basketball court | `BASK = 260,251,340,314` | x 31.5…87.5, z 0.7…44.8 | orange `#d87b3c` ground + painted 28×15 m court |
| Substation garden | `NCC = 250,320,365,415` | x 24.5…105.0, z 49.0…115.5 | paths + dense planting (the former "NCC ground") |
| Raised footpath (west strip) | built around Magic Spot / Gate Canteen / Bank | x ≈ −109…−94 | +0.25 m pavement with bevelled kerb |
| Kerb blocks | along both long edges of every road | — | alternating **yellow `#f2c94c` / white `#f4f4ee`**, 1.5 m long × 0.5 m thick × 0.14 m high, **no collider**, skipped inside buildings and at crossings |
| Median green wall | along the main north–south road | x 13.3…25.9 | instanced hedges + shrubs + big trees down the middle, solid |

### Road table (map px → world metres) [V]

| # | Map rect | World X range | World Z range | Role |
|---|---|---|---|---|
| 1 | 64,160,98,345 | −105.7 … −81.9 | −63.0 … 66.5 | west road beside the parking yard |
| 2 | 82,345,100,432 | −93.1 … −80.5 | 66.5 … 127.4 | road down to the main gate |
| 3 | 96,332,256,352 | −83.3 … 28.7 | 57.4 … 71.4 | main east–west road (south of the Admin Block) |
| 4 | 106,345,139,445 | −76.3 … −53.2 | 66.5 … 136.5 | gate approach road (starts outside the gate) |
| 5 | 234,60,252,352 | 13.3 … 25.9 | −133.0 … 71.4 | main north–south road |
| 6 | 100,239,236,246 | −80.5 … 14.7 | −7.7 … −2.8 | central road between the academic blocks |
| 7 | 100,281,236,291 | −80.5 … 14.7 | 21.7 … 28.7 | road between CSE/ECE and the Admin Block |
| 8 | 157,157,171,285 | −40.6 … −30.8 | −65.1 … 24.5 | road between the Stair Auditorium and the Workshop |

---

## 2. Vegetation

| Object | Count | Geometry | Collider | Notes |
|---|---|---|---|---|
| Broadleaf tree | ~111 of 150 (26 % are pines) | cylinder trunk (r 0.28–0.45, h 2.6) + icosahedron canopy r=2 + smaller icosahedron r=1.35 | 0.9 × 0.9 × 6 m | scale 0.8–1.45, 5 canopy greens, random Y rotation |
| Pine tree | ~39 of 150 | trunk + 3 stacked cones (r 1.7, h 2.6) | 0.9 × 0.9 × 6 m | two greens, cones shrink 22 % each level |
| Bush | 130 | icosahedron r=0.8 detail 1, **instanced mesh** | (shared with flowers) | 4 greens |
| Flower | (with the bushes) | sphere r=0.12 | — | 5 colours: pink, yellow, white, orange, purple |
| Gattu tree | 2 | `tree_gattu.glb` — a tree **on a round seating platform** | 1 × 1 × 6 m | map `(160,418)` and `(160,399)`, scale 0.8 |
| Grass tuft | **6,923 instances in 46 chunks** | `b_grass.bin` (`Grass_green.fbx`) + `b_grasstex.png`, instanced per chunk | none | chunks are visible only within **130 m** of the player; a shader uniform drives a gentle sway |

Placement rule (verified): a candidate tree position is rejected if it lands inside a building
rect, a road, one of the three zones, the gate apron (`100,395,145,432`) or the west strip
(`58,150,102,352`); 1,400 candidate samples are drawn to place 150 trees and 2,600 to place
130 bushes. The generator is seeded (`seed = 5`), so the layout is **deterministic** — the
port can reproduce the exact same forest by reusing the same LCG. [V]

> `[P]` Recommended port: keep the seeded generator but express it as a Godot `Resource` that
> emits `MultiMeshInstance3D` batches, and store the seed + counts so the campus can be
> regenerated identically on every platform.

---

## 3. Street furniture and props

| Prop | Count | Details |
|---|---|---|
| Lamp post | **14** | pole (r 0.07–0.11, h 5.2 m) + 0.9 m arm + 0.5 × 0.12 × 0.3 m emissive head `#fff0b8`; collider 0.4 × 0.4 × 5.2 |
| — west side of the main road | 6 | map x = 231, y = 80/120/160/200/262/310 (arm points east) |
| — east side of the main road | 6 | map x = 255, y = 100/140/180/222/262/312 (arm points west) |
| — gate road | 2 | map x = 141, y = 372/404 (arm points west) |
| Park bench | **7** | `b_bench.bin` ("Park Bench made of blocks" FBX), scaled to 1.8 m long, wood `#6e3f1c` + metal `#2d3138`; a ray-cast finds the seat height; 2 seats per bench |
| — basketball ground | 3 | world x 29.7, z 27.1 / 29.6 / 32.1, facing east |
| — IT Block frontage | 4 | world x 30.0, z −46.45 / −44.5 / −39.5 / −37.55, facing west (2 + gap + 2) |
| Office sofa | 2 sofas → **4 seats** | `office_sofa.glb`, in the Admin waiting room |
| Sittable seats (total) | **11** | `window.__sit.seats === 11` |
| Vending machine | **4** | see §4 |
| Parked car | **91** | 4 body types (ambulance, police, hatchback, classic), random body/accents, vertex-coloured, random occupancy ≈ 0.64, 6 stall gaps in the outer rows |
| Parking line paint | 4 rows × 42 | instanced boxes: white `#e9e9e2` stalls, yellow `#f2c94c` aisle arrows, grey `#93959c` crossings |
| Planter | 5 | kerb box `#b9b6ac` + grass top + 3–6 icosahedron shrubs |
| Parking entrance arch | 2 pillars + crossbar | tapered cylinders r 0.22–0.34, h 2.2 m |
| Flagpole | 1 | 14 m pole, 4.2 × 2.8 m waving tricolour (`js/flag.js`) |
| Building label billboards | 17 | black rounded label 3.5 m above each roof |

---

## 4. Interactive props

### Vending machines [V]

| # | Building | Wall | Label | Body colour | Stock (top row → bottom) |
|---|---|---|---|---|---|
| 1 | Gate Canteen | East | Soda Machine | `#c62828` red | Happy Faces, BSODA, Sky, Noob, TV Girl |
| 2 | Gate Canteen | East | Energy Machine | `#1f5fc8` blue | Monster, Red Bull, Night Blizzard, Bloxy, Nyan |
| 3 | Canteen (Back Gate) | West | Cold Drinks | `#2e9d57` green | Nyan, Sky, TV Girl, Bloxy, Happy Faces |
| 4 | Canteen (Back Gate) | West | Energy Machine | `#e08a1e` orange | Red Bull, Monster, Night Blizzard, BSODA, Noob |

Machine geometry: `b_drink.bin` (a voxel model of a vending machine) plus a per-can label
texture (10 drink JPEGs). The stocked cans are drawn as small cylinders with an emissive label
material; a floating billboard label appears within 26 m. Buying a drink plays the
drop → pick-up → drink animation, deducts the price, raises energy and counts the drink in the
"drinks tried" stat. [V][O]

### Bank ATM [V]
A service point on the Bank's east face at map `z = 408.5`. A cyan ring (`RingGeometry`
0.55–0.8, `#37d3ff`) marks the standing spot 1.6 m in front of the counter. `E` opens the
withdrawal menu.

### Noodle bar counter [V]
Same interaction pattern on the east face of the Magic Spot building (map `z = 357.5`).

---

## 5. Complete shipped file inventory

### 5.1 Models (`assets/models/`, 85 files, 55.3 MB)

| File | Size | Format | Used for | Licence |
|---|---|---|---|---|
| `b_admin.bin` | 4.14 MB | FBX | Admin Block (4 floors, corridor, signs) | UNKNOWN |
| `b_brez.bin` | 3.38 MB | FBX | CSE / ECE / EEE / Chemical panel house | UNKNOWN |
| `b_drink.bin` | 7.30 MB | FBX | Vending machine body | UNKNOWN |
| `b_aud.bin` | 2.58 MB | glTF | Open Auditorium pavilion | UNKNOWN |
| `b_walk.bin` | 2.60 MB | FBX | Player (boy) walking + idle + run | UNKNOWN (Mixamo-derived) |
| `b_colonel.bin` | 2.14 MB | FBX | Colonel Singh | UNKNOWN |
| `b_remy.bin` | 1.98 MB | FBX | Remy (walking student/dog companion) | UNKNOWN (Mixamo-derived) |
| `b_temple.bin` | 1.98 MB | custom packed | Temple | **CC-BY-4.0** (pranavaryakirtik, Sketchfab) |
| `b_gate.bin` | 1.98 MB | FBX | Main gate | UNKNOWN |
| `cadet_amy.glb` | 2.75 MB | glTF | Player (girl, Amy) | UNKNOWN |
| `cadet_boy.glb` | 1.66 MB | glTF | Cadet boy | UNKNOWN |
| `cadet_girl.glb` | 1.13 MB | glTF | Cadet girl | UNKNOWN |
| `laksmi.glb` | 1.88 MB | glTF | Ms. Laksmi | UNKNOWN |
| `office_desk.glb` | 3.40 MB | glTF | Admin office desk | UNKNOWN |
| `office_sofa.glb` | 2.40 MB | glTF | Waiting-room sofas | UNKNOWN |
| `office_toilet.glb` | 1.32 MB | glTF | Restroom toilet | UNKNOWN |
| `workshop.glb` | 1.84 MB | glTF | Workshop | UNKNOWN |
| `basketball_hoop.glb` | 1.88 MB | glTF | Hoop + backboard (3 textures) | UNKNOWN |
| `basketball.glb` | 46 KB | glTF | Ball (unit sphere → 0.239 m) | UNKNOWN |
| `tree_gattu.glb` | 944 KB | glTF | Gattu tree + round seating platform | UNKNOWN |
| `b_bench.bin` | 454 KB | FBX | Park bench | UNKNOWN |
| `b_bank.bin` | 683 KB | FBX | Bank | UNKNOWN |
| `b_cafe.bin` | 423 KB | FBX | Café (×2 instances) | UNKNOWN |
| `b_stairaud.bin` | 521 KB | FBX | Stair Auditorium + walkable height field | UNKNOWN |
| `b_guard.bin` | 129 KB | FBX | Security guard | UNKNOWN |
| `b_lp.bin` | 77 KB | FBX | Low-poly block row (Mechanical/IT/Civil/CSM) | UNKNOWN |
| `b_phone.bin` | 293 KB | FBX | Phone prop | UNKNOWN |
| `b_grass.bin` | 64 KB | FBX | Grass tuft | UNKNOWN |
| `uni2023_boy.jpg`, `uni2023_amy.jpg`, `uni2025_boy.jpg`, `uni2025_amy.jpg` | 105–135 KB each | JPG | Uniform body textures | UNKNOWN |
| `cadet_boy_0..6.jpg`, `cadet_amy_*.jpg`, `cadet_girl_0.jpg`, `laksmi_0.png`, `office_sofa_*.png`, `office_toilet_*.png`, `basketball_hoop_*.jpg/png` | — | texture sets for the models above | UNKNOWN |

> **Important:** every model above except the temple has **no licence file in the project**.
> They must be treated as *not reusable* until the author supplies licences. The replacement
> strategy in [`ASSET_MAPPING.md`](ASSET_MAPPING.md) therefore uses only CC0 packs.

### 5.2 Textures & images (`assets/img/`, `assets/ui/`)

| File | Size | Purpose |
|---|---|---|
| `anits_logo.png` | 118 KB | ANITS logo — used on the loading screen, the level-select background and the Admin office wall. **Trademark — not CC0.** |
| `little_hearts_logo.png` | 338 KB | Publisher logo. **Trademark — not CC0.** |
| `b_grasstex.png` | 137 KB | Grass tuft atlas |
| `b_cafetex.png` | 7 KB | Café texture |
| `bg_clean.jpg` | 337 KB | Menu background |
| `1c1f6ccb.jpg`, `1e535694.jpg`, `3ed9cd83.jpg`, `4cb46c67.jpg`, `5299bf07.jpg`, `53cd8d92.jpg`, `8f041cfb.jpg`, `9e229751.jpg`, `a27fd3f5.jpg`, `c27b1e6d.jpg` | 13–24 KB each | the 10 drink can labels |
| `assets/ui/lv_gate.jpg` … `lv_classroom.jpg` | **MISSING** | the 10 level-card thumbnails referenced by `menu.js` are **not present** in the build — the level cards fall back to their CSS background. See `MISSING_INFORMATION.md`. |

### 5.3 Audio (`assets/audio/`, 1,266 files, 15.3 MB)

| Item | Count / size | Notes |
|---|---|---|
| Voice clips | **632 MP3** (≈24 KB each) | hashed filenames (`a9e2145495.mp3`, …) |
| `clips.json` | 340 entries, 56 KB | `[teluguText\|null, mp3Path]` per English line |
| `clips_girl.json` | 310 entries, 56 KB | female voice bank |
| Music | **none found** | no music track ships with the build |

### 5.4 Fonts (`assets/fonts/`)

| File | Size | Status |
|---|---|---|
| `NotoSansTelugu-Regular.woff2` | 42 KB | preloaded in `index.html`, used for Telugu captions |
| `NotoSansTelugu-Bold.woff2` | 43 KB | preloaded |
| `658f6280.woff2` | 20 KB | **not referenced anywhere in the source** — probably a leftover |
| `75c6aa4b.woff2` | 41 KB | **not referenced anywhere in the source** — probably a leftover |

The UI CSS names `Figtree`, `Bricolage Grotesque` and `Archivo Black`, but **no `@font-face`
rule exists** — the web build silently falls back to `system-ui`. [V] For the Godot port, load
the real families (all three are OFL-1.1 — see [`FREE_GODOT_ASSETS.md`](FREE_GODOT_ASSETS.md)).

---

## 6. Material and shader inventory

| Material | Where | Definition |
|---|---|---|
| Campus sandstone / stone | temple, kerbs, planters | `MeshLambertMaterial` with flat colours |
| Building wall palette | panel houses, low-poly rows | a 256×256 palette image is re-baked at runtime, the wall swatch is tinted per building, applied as `map` + `emissiveMap` |
| Glass | Admin Block, bank, office doors | transparent Lambert, opacity 0.22–0.4, `depthWrite = false` |
| Can labels | vending machines | emissive Lambert with the drink JPEG, `emissiveIntensity 0.45` |
| Grass | lawn tufts | instanced Lambert + a sway uniform |
| Sky dome | sky | custom `ShaderMaterial` (gradient + sun glow + hash stars), `BackSide`, `depthWrite false`, `fog false` |
| Court paint | basketball court | `CanvasTexture` painted at 64 px/m |
| Signs | Admin Block, office | `CanvasTexture` planes generated from text |

---

## 7. Port notes for environment work

1. **MultiMesh everything.** 6,923 grass tufts, 130 bushes, ~150 trees, the kerb blocks
   (hundreds), the parking lines and the median hedges must be `MultiMeshInstance3D`.
   On the Ryzen 5 7530U / Radeon integrated target this is the difference between 60 and 25 FPS.
2. **Convert to OGG.** The 632 MP3s are ≈15 MB; OGG Vorbis at q4 halves that. Keep the original
   MP3s only as a fallback for the browser build.
3. **Keep the LCG.** The seeded generator (`seed = 5`, `16807` LCG) reproduces the original
   forest exactly; port it as-is so screenshots match.
4. **Static shadow map.** The web build disables shadow auto-update on mobile. In Godot, use a
   single `DirectionalLight3D` with `directional_shadow_max_distance = 130` and
   `shadow_mode = PSSM_2_SPLITS` (or `ORTHOGONAL` on low-end).
5. **Distance culling.** The grass chunks switch off beyond 130 m; do the same for bushes,
   flowers and distant props, and use `VisibilityRangeFade` on the trees.
