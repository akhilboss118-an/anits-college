# BUILDING_INVENTORY.md — every structure on the ANITS campus

**Evidence basis:** the `BLD` table and all placement code in `ANITS-WEB GAME/js/game.js`
(lines 56–63 for the table; the model-placement blocks for each structure), runtime probes of
`window.__lp` / `window.__admin` / `window.__court`, and the screenshots in `screenshots/`.

**Coordinate system:** the game stores the campus as a *map-pixel* plan and converts to metres
with `S = 0.7`:

```
wx(px) = (px - 215) * 0.7      # map X → world X (metres)
wz(py) = (py - 250) * 0.7      # map Y → world Z (metres)
```

Everything in the tables below is given in **map pixels** (as authored) *and* in **world
metres** (as the 3D scene sees it). See [`CAMPUS_MAP.md`](CAMPUS_MAP.md) for the full map.

**Tags:** [V] verified from source/runtime · [O] observed in a screenshot · [U] unknown ·
[P] proposed reconstruction choice.

---

## 1. Master table — the 17 `BLD` structures

| # | Building (in-game label) | Map rect (x0,y0,x1,y1) | World centre X,Z (m) | Footprint W×D (m) | Height (m) | Base colour | Model used by the game | Entrance faces |
|---|---|---|---|---|---|---|---|---|
| 1 | Mechanical Block | 101,116,226,156 | −36.0, −79.8 | 87.5 × 28.0 | 10 | `#d9a07c` | low-poly block row (`b_lp.bin`) | **South** (onto campus) |
| 2 | Stair Auditorium | 115,157,156,196 | −55.6, −51.4 | 28.7 × 27.3 | 11 | `#e0a85a` | `b_stairaud.bin` (FBX, walkable interior) | South (steps) |
| 3 | Workshop | 183,157,222,187 | −8.8, −54.6 | 27.3 × 21.0 | 7 | `#8a9bb5` | `workshop.glb` | South |
| 4 | Chemical Block | 109,205,155,239 | −58.1, −19.6 | 32.2 × 23.8 | 11.5 | `#6fa56f` | panel house (`b_brez.bin`), tint `#d6ecd6` | **East** (onto central road) |
| 5 | EEE Block | 172,201,232,231 | −9.1, −23.8 | 42.0 × 21.0 | 11.5 | `#d56a8a` | panel house, tint `#f3d9e2` | **West** |
| 6 | CSE Block | 102,246,156,281 | −60.2, 9.4 | 37.8 × 24.5 | 11.5 | `#4a8fb8` | panel house, tint `#cfe3ff` | **East** |
| 7 | ECE Block | 170,244,230,279 | −10.5, 8.0 | 42.0 × 24.5 | 11.5 | `#8e5fc0` | panel house, tint `#e6d8ff` | **West** |
| 8 | ADMIN BLOCK | 97,291,232,331 | −35.3, 42.7 | 94.5 × 28.0 | 12 | `#d84b4b` | 4-floor FBX (`b_admin.bin`), scale K = 0.98 → **16.95 m rendered** | North + South (through corridor) |
| 9 | IT Block | 260,143,282,237 | 39.2, −42.0 | 15.4 × 65.8 | 11 | `#e8b098` | low-poly block row | **West** (onto main road) |
| 10 | Civil Block (north) | 276,61,358,117 | 71.4, −112.7 | 57.4 × 39.2 | 14 | `#8a5a45` | low-poly block row | **West** |
| 11 | Civil Block (south) | 288,137,356,224 | 74.9, −48.6 | 47.6 × 60.9 | 14 | `#8a5a45` | low-poly block row | **West** |
| 12 | CSM Block | 286,226,319,246 | 61.2, −9.8 | 23.1 × 14.0 | 7 | `#e8c070` | low-poly block row | **South** (onto the court) |
| 13 | Canteen ("Back Gate Canteen") | 286,120,314,136 | 59.5, −85.4 | 19.6 × 11.2 | 5 | `#c0704c` | café model (`b_cafe.bin`) | West + East |
| 14 | Temple | 102,331,122,349 | −72.1, 63.0 | 14.0 × 12.6 | 4 | `#e89040` | `b_temple.bin` (Sketchfab "Indian Temple") | East (mandapa) |
| 15 | Magic Spot (Noodle Bar) | 62,349,80,366 | −100.8, 75.3 | 12.6 × 11.9 | 5 | `#e07ab0` | voxel noodle bar | East (onto main road) |
| 16 | Gate Canteen | 62,375,80,395 | −100.8, 94.5 | 12.6 × 14.0 | 5 | `#c08060` | café model | West + East |
| 17 | Bank | 62,400,80,417 | −100.8, 110.9 | 12.6 × 11.9 | 6 | `#5a78c0` | `b_bank.bin` | East (onto main road) |

Height values are the **authored `BLD` heights**; the rendered model heights can differ (see
per-building notes). All heights are single-storey masses of ~3.2–3.5 m per floor.

**Building labels.** Every structure gets a floating black rounded billboard 3.5 m above its
roof, reading the exact `BLD` name (e.g. `ADMIN BLOCK`, `CSM Block`). [V] `reg(label(n.trim()),.22,8,50)`
in `game.js`. The label is part of the game's readability: it is how a first-time player knows
which block is which, and it must be reproduced (as a `Label3D`/sprite) in the port.

---

## 2. Per-building notes

### 2.1 Mechanical Block — `101,116,226,156`
- Low-poly block row, **9 bays** (runtime `window.__lp`), all entrances facing **south** onto
  the campus lawn. Wall colour `#d9a07c` (sand). Height 10 m ≈ 3 floors. [V]
- Longest block on campus (87.5 m). Its west end nearly touches the Stair Auditorium.
- Gameplay role: scenery. No NPC, no mission, no interaction.

### 2.2 Stair Auditorium — `115,157,156,196`
- `b_stairaud.bin` (FBX), scaled `K = 1.2`, offset `CX = 10, CZ = −10`, rotated `θ = 1.25π`.
- **Unique in the game**: it is the only building with a genuinely walkable interior. The FBX is
  parsed into an 84×84 **height field** (`HG`) and the walkable surfaces are the meshes named
  `Mat_Seats | Mat_Inner_Platform | OuterRing | Mat_Ramp_Tile | Stair_wood | Stair_white`.
  `groundHeightAt()` blends that height field with the flat campus. [V]
- Steps and ring platform are the visible landmark near the centre-west of campus.
- `[U]` interior room layout — only the seating tiers and the ramp are modelled.

### 2.3 Workshop — `183,157,222,187`
- `assets/models/workshop.glb` (low-poly workshop), fitted to the plot, **south-facing front**,
  with a roof, a door and a forecourt. [V]
- The plain box placeholder is removed when the GLB loads successfully (a console warning path
  exists for failure). [V]

### 2.4 Chemical Block — `109,205,155,239`
- Panel-house model `b_brez.bin` (a repeated "classroom block" unit), tinted `#d6ecd6`.
  Entrance on the **east** face, i.e. onto the central road that separates the west and east
  academic blocks. Height 11.5 m ≈ 3 floors. [V]
- Panel-house blocks receive a shared door, canopy and steps added procedurally
  (`door()`: 3.4 m door, 3.6 m canopy, 2.4 m-wide steps). [V]

### 2.5 EEE Block — `172,201,232,231`
- Panel house, tint `#f3d9e2`, entrance **west** onto the same central road. [V]
- Faces the Chemical Block across the road (the code comments say "entrances face each other
  across the central road"). [V]

### 2.6 CSE Block — `102,246,156,281`
- Panel house, tint `#cfe3ff`, entrance **east**.
- **Prof. Rao (HOD CSE)** stands outside at map `(129,287)` → world `(−60.2, 25.9)`. [V]
- Day 3 ("Find Your Classroom"), Day 7 (signature) and Day 10 (first class) happen here.

### 2.7 ECE Block — `170,244,230,279`
- Panel house, tint `#e6d8ff`, entrance **west**. [V]

### 2.8 ADMIN BLOCK — `97,291,232,331` (the heart of the game)
- 4-floor FBX (`b_admin.bin`) placed with **model scale K = 0.98**, so the rendered height is
  **17.3 × 0.98 ≈ 16.95 m** (the `BLD` table's `12` is the placeholder-box height, not the
  model height). White/cream body, rooftop signage **"ANITS ADMIN BLOCK"** (observed in
  `screenshots/02_admin_block.png`) and a red/blue vertical entrance strip. [O]
- **Central hallway** running front-to-back, open at both ends. Its collider geometry is
  derived from K: the wings start at `cx ± 5.0·K` (= ±4.90 m) and end at `cx ± 47.7·K`
  (= ±46.75 m); the hall itself is `cx ± 4.88·K` → **≈ 9.56 m wide**, and the building is
  `cz ± 14.5·K` (= ±14.21 m) deep. The camera is clamped to that corridor and to 2.6 m
  height while the player is inside it. [V]
- **Devotional statue** in the middle of the hall (collider ±0.95·K = ±0.93 m, 2.3 m tall). [V]
- **Porch columns** at `cx ± 5.5·K` (= ±5.39 m) and `cz + 19.65·K` (= cz + 19.26 m), 4 m tall;
  the raised porch pad spans `cx ± 6·K`, `cz − 17.2·K … cz + 20.2·K`. [V]
- Interior signage observed in `screenshots/09_admin_hall.png`: **"ADMISSIONS OFFICE"** on the
  west wall and **"BOOK HALL"** on the east side. [O]
- **Admin Office annex** (a sealed room placed far outside the campus map, `OFC`): waiting room
  with 4 sofa seats, a red rug, a low table, 4 potted plants, a ceiling of 4 fluorescent
  panels; a partition with sliding **glass doors** that open after `OFC_WAIT = 10 s`; a
  **RESTROOM** cubicle with a toilet; Ms. Laksmi's desk (model `office_desk.glb`), two visitor
  chairs, four book shelves with coloured book spines, a fridge, and the ANITS logo on the back
  wall. Signs: `ADMIN OFFICE / Ms. Laksmi (Admin)`, `WAITING ROOM / Please take a seat`,
  `EXIT / Back to the Admin hall`, `RESTROOM`. [V]
- Entering the office fades the screen (`#ofc-fade`, 0.4 s) and teleports the player into the
  sealed room; exiting fades back to the hall door. Camera distance 3.4 m, clamped to the room
  box (X ±, Z ±, Y 0.5–3.05 m). [V]
- **Laksmi (Admin)** is physically moved into this office and sits at the desk, breathing only;
  outside the office the game spawns her at the hall door instead (`OFC.doorOut`). [V]

### 2.9 IT Block — `260,143,282,237`
- Low-poly block row, **6 bays**, entrances **west** onto the main road (the road at
  `234,60,252,352`). Height 11 m. [V]
- **Suresh (Lab Assistant)** stands outside at map `(271,243)` → world `(39.2, −4.9)`. [V]
- Four park benches sit along its west face (2 + gap + 2). [V]

### 2.10 Civil Block (north) — `276,61,358,117`
- Low-poly block row, **2 bays**, entrance **west**, height 14 m (the tallest on campus). [V]

### 2.11 Civil Block (south) — `288,137,356,224`
- Low-poly block row, **4 bays**, entrance **west**, height 14 m. [V]
- The Canteen sits directly west of it, across the road.

### 2.12 CSM Block — `286,226,319,246`
- Low-poly block row, **3 bays**, entrance **south**, i.e. onto the basketball ground. Height 7 m. [V]

### 2.13 Canteen ("Back Gate Canteen") — `286,120,314,136`
- `b_cafe.bin`: a small café with a neon **"CAFE"** sign showing a steaming cup, three
  red/white striped awnings over arched windows, and street lamps either side. [O] `screenshots/10_canteen_vending.png`
- Two vending machines stand against its **west** wall:
  `Cold Drinks` (green `#2e9d57`, labelled "Back Gate Canteen") and `Energy Machine` (orange `#e08a1e`). [V]
- Café tables and chairs sit outside; a blackboard menu leans by the door. [O]
- The **noodle shop** is *not* here — it is the separate "Magic Spot" building.

### 2.14 Temple — `102,331,122,349`
- `b_temple.bin`: a custom-packed mesh (156,303 vertices, quantised positions/normals, no UVs —
  the source PNG bake was unusable, so the mesh takes a sandstone material). Scaled ×11,
  rotated 90° so the pillared mandapa faces east. [V]
- Sits on a two-step stone plinth (`#9d9688` / `#aaa395`). [V]
- **The only asset in the game with a public licence credit**: *"Indian Temple" by
  pranavaryakirtik*, CC-BY-4.0, shown in the permanent credits strip. [V] `index.html` `#cred`
- `[O]` `screenshots/08_temple.png` — the carved temple sits on the lawn west of the Admin Block.

### 2.15 Magic Spot (Noodle Bar) — `62,349,80,366`
- A **voxel-built "Cyberpunk Noodle Bar"** (24,300 voxels, base64-packed in `game.js`), scaled to
  the plot and rotated so the counter faces **east onto the main road**. [V]
- The shop sign reads `NOODLE`; the interior is lit by coloured neon and there is a stool
  counter. [O] `screenshots/10_canteen_vending.png` (right edge)
- It is an **interactive service point**: standing in the cyan ground ring in front and pressing
  `E` opens the noodle menu (4 dishes). [V]

### 2.16 Gate Canteen — `62,375,80,395`
- Second café instance (`b_cafe.bin`), just inside the main gate on the west side, on the
  raised footpath. [V][O]
- Two vending machines against its **east** wall:
  `Soda Machine` (red `#c62828`) and `Energy Machine` (blue `#1f5fc8`). [V][O]

### 2.17 Bank — `62,400,80,417`
- `b_bank.bin` low-poly bank with a **glass pane** (opacity 0.22), rotated so the front faces
  the main road to the east; the collider is re-fitted to the "Roof and Walls" mesh bounds. [V]
- **Interactive service point**: an ATM at map `z = 408.5`; a cyan ring marks the interaction
  spot 1.6 m in front of the counter. `E` opens the withdrawal menu (₹100/200/500/1000 + custom). [V]
- Also used as the plain-box fallback if the model fails to load.

---

## 3. Structures that are not in the `BLD` table

| Structure | Location (map) | World | What it is | Evidence |
|---|---|---|---|---|
| **ANITS main gate** | x 100–145 at z 432 | x −80.5…−49.0, z 127.4 | FBX (`b_gate.bin`): two pillars + two hinged leaves + a centre gate panel. Leaves swing open when the player or a student approaches. Pillars 8.2 m tall, leaves 2.9 m. The gate is **locked** until mission step 2 of Day 1. | [V] `game.js` gate block |
| **Back Gate** | centre (236, 98), half-width 22 | x −1.4…29.4, z −106.4 | A procedural gate: two 2.2 × 9 × 2.2 m pillars + a lintel, blue `#3a5f9a`, with a yellow "Back Gate" billboard at 12.5 m. The main north–south road passes straight through it. | [V] the `gate()` helper in `game.js` |
| **Open Auditorium** | 237,396 | 15.4, 102.2 | glTF (`b_aud.bin`) standing on the **sand field** (`SAND = 146,357,249,427`), scaled ×1.6 and rotated 180° so the steps face **west toward the NCC company**. Open-sided pavilion with a blue conical roof and a stage. | [V][O] `screenshots/04_it_block.png` |
| **NCC assembly ground** | on `SAND` | — | The 18 cadets and Colonel Singh drill on the sand field (cadets at map x `208 − r·4.2`, z `386.25 + k·3.9`; Colonel at `(214,396)`). The field itself is bounded by a raised footpath with kerbs. | [V][O] `screenshots/05_ncc_ground_colonel.png` |
| **Indian flag** | 235,377 | 14.0, 88.9 | 14 m flagpole with a 4.2 × 2.8 m waving tricolour, lazily mounted and disposed when far away (`js/flag.js`). | [V] |
| **Power Supply Room** | inside `NCC = 250,320,365,415` | 24.5…105.0, 49.0…115.5 | **Correction to an early misreading**: this rectangle is *not* the parade ground any more. The source comments call it *"Power Supply Room (was the NCC ground)"*: a substation building at map `(306,366)` with a red band, plus a fenced transformer yard, three internal paths and a dense garden of trees and bushes. | [V] `game.js` + [O] `screenshots/04_it_block.png` (label "Power Supply Room") |
| **Basketball court** | `BASK = 260,251,340,314` | centre 59.5, 22.75 | 28 × 15 m regulation court painted on a canvas texture at 64 px/m with a 1.5 m margin, blue field, orange keys, white lines; a real hoop model (rim at 3.05 m, board 1.84 m wide, rim Ø 0.48 m) and a 0.239 m ball. | [V] |
| **Student parking yard** | west strip, world x −108.6…−80.4, z −60.6…+54.2 | — | Four stall rows (41 stalls × 2.8 m pitch each) around a two-way aisle, painted lines, aisle arrows, 6 gap crossings, planters at the ends, a kerb and an entrance arch. **91 low-poly cars** in 4 body types (ambulance / police / hatchback / classic) with random occupancy ≈0.64. | [V][O] `screenshots/07_student_parking.png` |
| **Median green wall** | along the main road | — | Instanced hedges, shrubs and large trees down the middle of the main road, solid to the player, swaying. | [V] |
| **Raised footpath** | west strip (Magic Spot / Gate Canteen / Bank) | — | A raised pavement (0.25 m) with a bevelled kerb carrying the three west-side shops; objects standing on it are lifted. | [V] |
| **Sand field footpath** | around `SAND` | — | A raised kerb path ringing the sand ground. | [V] |

---

## 4. Interior inventory (what is actually modelled inside)

| Space | Modelled? | Contents |
|---|---|---|
| Admin Block hallway | **Yes** | corridor, statue, porch columns, room signs, glass door to the office annex |
| Admin Office + waiting room | **Yes** (separate sealed scene) | sofas, rug, table, plants, shelves with books, fridge, visitor chairs, desk, toilet, glass doors, 6 signs, ceiling lights |
| Stair Auditorium seating | **Yes** | tiers, inner platform, ring, ramp, stairs (walkable height field) |
| CSE / ECE / EEE / Chemical | **No** | exterior massing only; doors and canopies are procedural, interiors are not modelled |
| Mechanical / IT / Civil / CSM | **No** | exterior low-poly rows only |
| Workshop, Bank, Café, Noodle Bar, Temple | **No** | single-mesh exteriors |
| Library | **No** | the Day-4 library is a *marker position* in the west wing of the Admin Block (map `80,175`), not a modelled room |
| Basketball court | **Partly** | painted surface + hoop + ball; no stands or roof |

> `[U]` The real ANITS campus has more buildings than the game models. **Do not add buildings
> that are not in the `BLD` table** — the port must reproduce the game's campus, not the real one.

---

## 5. Collision model

- One global list of axis-aligned boxes (`colliders`), each `{x0, x1, z0, z1, h}` in world metres.
- Boxes are added for: every building footprint (with the real model height), each low-poly bay
  (so a row of blocks is solid per bay, not per plot), the gate pillars/leaves, trees, bushes,
  lamp posts, benches, vending machines, cars, planters, the statue, porch columns, the office
  glass doors, and the gate's swing leaves. [V]
- The player's step-up rule (1.3 m) lets the player walk onto the raised footpath and the sand
  kerb but not onto a building.
- `[P]` In Godot, replace the box list with `StaticBody3D` + `CollisionShape3D` boxes generated
  from the same data table (see `ASSET_MAPPING.md` → `campus_data.json`), so the collision and
  the visuals can never drift apart.

---

## 6. Reconstruction targets per building

| Original model | Godot replacement | Notes |
|---|---|---|
| `b_lp.bin` low-poly block row | **Quaternius Ultimate Buildings** (CC0) modular pieces, or Kenney City Kit Commercial blocks | Must be able to repeat along a plot with a per-bay entrance; keep the `bays` count identical |
| `b_brez.bin` panel house (CSE/ECE/EEE/Chemical) | Kenney City Kit Commercial + a procedural door/canopy/steps node | Tint per building (`#cfe3ff`, `#e6d8ff`, `#f3d9e2`, `#d6ecd6`) via `StandardMaterial3D.albedo_color` |
| `b_admin.bin` 4-floor block | Quaternius Ultimate Buildings multi-storey + a **bespoke 9.76 m corridor** + statue + porch | The corridor geometry and the camera clamp are gameplay-critical |
| `b_cafe.bin` café | Kenney City Kit Commercial + Poly Pizza/Quaternius café props | Needs awning texture; two instances with different rotations |
| `b_temple.bin` temple | **Keep the original GLB** (CC-BY-4.0, attribution required) or re-model; do not substitute a random temple | Attribution text must stay in the credits strip |
| `b_bank.bin` bank | Kenney City Kit Commercial bank + a glass-panel material | Must keep the ATM interaction point |
| `b_aud.bin` open auditorium | Quaternius Ultimate Buildings open pavilion | Rotated 180° relative to the original |
| `workshop.glb` | Kenney City Kit Commercial small industrial | — |
| `b_gate.bin` gate | Bespoke: two pillars + two leaves, `AnimationPlayer` swing | Swing logic + collider swap is gameplay-critical (Day 1 step 2) |
| voxel noodle bar | Bespoke voxel or Kenney/Poly Pizza shop | Must read as "noodle bar" and carry the `NOODLE` sign |

See [`ASSET_MAPPING.md`](ASSET_MAPPING.md) for the full mapping table and
[`EXTERNAL_ASSET_LIBRARY.md`](EXTERNAL_ASSET_LIBRARY.md) for download links and licences.
