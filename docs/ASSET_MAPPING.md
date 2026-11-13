# ASSET_MAPPING.md — original asset → Godot replacement

**Rule set**

1. **Do not ship an asset whose licence is unknown.** Only the temple (CC-BY-4.0) and the
   ANITS/Little Hearts logos (trademark, used by permission) may be carried over as-is.
2. Every replacement must be **CC0** and must be listed in
   [`EXTERNAL_ASSET_LIBRARY.md`](EXTERNAL_ASSET_LIBRARY.md) with a verified licence.
3. A replacement must preserve the **silhouette, the scale, the colour and the gameplay
   role** of the original — not merely "a building".
4. The **data** (footprints, heights, colours, counts, positions) always comes from this
   documentation, never from the replacement asset's own size.

**Status column**

| Tag | Meaning |
|---|---|
| **KEEP** | carry the original file into the Godot project (licence permitting) |
| **REPLACE** | swap for a CC0 asset |
| **PROCEDURAL** | generate the asset in-engine (no external file) |
| **[P]** | proposed choice — the exact asset should be confirmed by eye in-engine before it is locked in |

---

## 1. Buildings

| Original | Godot replacement | Source | Licence | Notes |
|---|---|---|---|---|
| Mechanical Block (9 bays, south-facing) | Kenney `building-b`..`building-e` repeated 9× + `detail-overhang` as the entrance canopy | Kenney City Kit (Commercial) | CC0 | Scale each unit so 9 bays fill 87.5 m; tint `#d9a07c`; door on the south face |
| Stair Auditorium (walkable tiers) | **PROCEDURAL** — a stepped `CSG`/extruded ramp + seating tiers, plus the Kenney wall kit for the shell | — | — | The interior is gameplay-relevant (walkable height field); build it, do not import it |
| Workshop | Kenney `building-a` + `detail-overhang` | Kenney City Kit (Commercial) | CC0 | 27.3 × 21.0 m, h 7, tint `#8a9bb5` |
| Chemical Block (panel house, east door) | Kenney `building-c` repeated 3× with the door on the east face | Kenney City Kit (Commercial) | CC0 | Tint `#d6ecd6`; add a procedural door + canopy + steps (the original's `door()` helper) |
| EEE Block (west door) | same panel unit, mirrored | Kenney City Kit (Commercial) | CC0 | Tint `#f3d9e2` |
| CSE Block (east door) | same panel unit | Kenney City Kit (Commercial) | CC0 | Tint `#cfe3ff` |
| ECE Block (west door) | same panel unit, mirrored | Kenney City Kit (Commercial) | CC0 | Tint `#e6d8ff` |
| ADMIN BLOCK (4 floors, 9.76 m corridor, statue, porch) | Quaternius Ultimate Buildings multi-storey shell + a **bespoke corridor** (floor, walls, signage) + a procedural statue + porch columns | Quaternius Ultimate Buildings | CC0 | The corridor width and the camera clamp are gameplay-critical — do not approximate |
| IT Block (6 bays, west door) | Kenney `building-d` repeated 6× | Kenney City Kit (Commercial) | CC0 | 15.4 × 65.8 m, h 11, tint `#e8b098` |
| Civil Block (N) (2 bays) | Kenney `building-e` × 2 | Kenney City Kit (Commercial) | CC0 | 57.4 × 39.2 m, h 14, tint `#8a5a45` |
| Civil Block (S) (4 bays) | Kenney `building-e` × 4 | Kenney City Kit (Commercial) | CC0 | 47.6 × 60.9 m, h 14 |
| CSM Block (3 bays, south door) | Kenney `building-f` × 3 | Kenney City Kit (Commercial) | CC0 | 23.1 × 14.0 m, h 7, tint `#e8c070` |
| Canteen / Gate Canteen (café) | Kenney `building-g` + `detail-awning` × 3 + a "CAFE" sign plane | Kenney City Kit (Commercial) | CC0 | Two instances with different rotations; the awnings are the visual signature |
| Temple | **KEEP** `b_temple.bin` (or the original Sketchfab GLB) | — | **CC-BY-4.0** | Attribution required; keep the credits line verbatim |
| Magic Spot (voxel noodle bar) | **PROCEDURAL** voxel or a Kenney shop + a "NOODLE" sign | Kenney City Kit (Commercial) | CC0 | Must read as a noodle bar and carry the interaction ring |
| Bank | Kenney `building-h` + a glass-panel material (opacity 0.22) | Kenney City Kit (Commercial) | CC0 | The ATM interaction point must stay on the east face |
| Open Auditorium pavilion | Quaternius Ultimate Buildings open pavilion | Quaternius Ultimate Buildings | CC0 | Rotate 180° so the steps face west |
| Main gate (FBX, hinged leaves) | **PROCEDURAL** — two pillars + two leaves with `AnimationPlayer` swing + a lintel | — | — | The swing + collider swap is mission-critical |
| Back Gate | **PROCEDURAL** — two 2.2 × 9 m pillars + a lintel, blue `#3a5f9a` + a yellow "Back Gate" label | — | — | Matches the original's `gate()` helper exactly |
| Power Supply Room (substation) | **PROCEDURAL** — the original builds it from primitives (stone plinth, red band, transformers, ceramic bushings, a fenced yard) | — | — | Recreate from the measurements in `BUILDING_INVENTORY.md` §3 |

### Building data that must not be re-derived from the meshes

| Building | Footprint (m) | Height (m) | Tint |
|---|---|---|---|
| Mechanical | 87.5 × 28.0 | 10 | `#d9a07c` |
| Stair Auditorium | 28.7 × 27.3 | 11 | `#e0a85a` |
| Workshop | 27.3 × 21.0 | 7 | `#8a9bb5` |
| Chemical | 32.2 × 23.8 | 11.5 | `#6fa56f` (panel tint `#d6ecd6`) |
| EEE | 42.0 × 21.0 | 11.5 | `#d56a8a` (panel tint `#f3d9e2`) |
| CSE | 37.8 × 24.5 | 11.5 | `#4a8fb8` (panel tint `#cfe3ff`) |
| ECE | 42.0 × 24.5 | 11.5 | `#8e5fc0` (panel tint `#e6d8ff`) |
| ADMIN | 94.5 × 28.0 | 12 | `#d84b4b` |
| IT | 15.4 × 65.8 | 11 | `#e8b098` |
| Civil N | 57.4 × 39.2 | 14 | `#8a5a45` |
| Civil S | 47.6 × 60.9 | 14 | `#8a5a45` |
| CSM | 23.1 × 14.0 | 7 | `#e8c070` |
| Canteen | 19.6 × 11.2 | 5 | `#c0704c` |
| Temple | 14.0 × 12.6 | 4 | `#e89040` |
| Magic Spot | 12.6 × 11.9 | 5 | `#e07ab0` |
| Gate Canteen | 12.6 × 14.0 | 5 | `#c08060` |
| Bank | 12.6 × 11.9 | 6 | `#5a78c0` |

---

## 2. Environment props

| Original | Replacement | Source | Licence |
|---|---|---|---|
| 150 procedural trees (broadleaf 74 % / pine 26 %) | `tree_default`, `tree_oak`, `tree_fat` (broadleaf) + `tree_cone` (pine) | Kenney Nature Kit | CC0 |
| 130 bushes (icosahedron) | `plant_bush`, `plant_bushSmall`, `plant_bushLarge` | Kenney Nature Kit | CC0 |
| 6,923 grass tufts (FBX + atlas) | `grass`, `grass_large`, `grass_leafs` | Kenney Nature Kit | CC0 |
| 2 gattu trees (tree on a round platform) | `tree_default` + a `CylinderGeometry` platform | Kenney Nature Kit | CC0 |
| 14 lamp posts (5.2 m pole + arm + emissive head) | `street_lamp_01` (Poly Haven) or a procedural pole + Kenney `lampSquareFloor` | Poly Haven / Kenney | CC0 |
| 7 park benches | `bench`, `benchCushion` | Kenney Furniture Kit | CC0 |
| 4 office sofas / 4 seats | `loungeSofa`, `loungeSofaLong` | Kenney Furniture Kit | CC0 |
| Office shelves with coloured books | `bookcaseOpen` + `books` | Kenney Furniture Kit | CC0 |
| Office chairs | `chair`, `chairModernFrameCushion` | Kenney Furniture Kit | CC0 |
| Office potted plants | `pottedPlant`, `plantSmall1/2/3` | Kenney Furniture Kit | CC0 |
| Office desk | `desk`, `cabinetBedDrawerTable` | Kenney Furniture Kit | CC0 |
| Restroom toilet | **PROCEDURAL** (a simple box + bowl) | — | — |
| 4 vending machines (voxel body + label) | **PROCEDURAL** body (box + glass + 5 shelves) + the 10 drink label textures (keep the original JPEGs? — licence unknown → **recreate the labels**) | — | — |
| 10 drink can labels (JPGs) | **PROCEDURAL** — draw the can label textures in-engine (colour + word) | — | — |
| 91 parked cars (4 body types, vertex-coloured) | Kenney City Kit (Roads) car kit + Poly Haven `covered_car` | Kenney / Poly Haven | CC0 |
| Parking line paint, aisle arrows, crossings | **PROCEDURAL** — flat quads with an unshaded material | — | — |
| Planters (kerb + grass + shrubs) | **PROCEDURAL** + `plant_bushSmall` | Kenney | CC0 |
| Parking entrance arch | **PROCEDURAL** | — | — |
| Roads (8 rects) + median | Kenney City Kit (Roads) road tiles, tiled to the rects | Kenney | CC0 |
| Yellow/white kerb blocks | **PROCEDURAL** — one `MultiMesh` of 0.14 m boxes | — | — |
| Sand field | `Grass004` / a sand albedo from ambientCG | ambientCG | CC0 |
| Court paint (28 × 15 m at 64 px/m) | **PROCEDURAL** — the same `CanvasTexture` recipe (blue field, orange keys, white lines) | — | — |
| Basketball hoop + backboard | **REPLACE** — Kenney/Poly Haven hoop, or **PROCEDURAL** (ring 0.48 m at 3.05 m + board 1.84 m) | — | — |
| Basketball (r = 0.1195 m) | **PROCEDURAL** sphere with an orange material | — | — |
| Indian flag + 14 m pole | **PROCEDURAL** — a `PlaneMesh` with the tricolour texture, animated by a vertex shader | — | — |
| Building label billboards (17) | **PROCEDURAL** — `Label3D` with the exact `BLD` names | — | — |
| Office signage (6 signs) | **PROCEDURAL** — `Label3D`/texture planes with the exact strings | — | — |
| Grass / asphalt / paving textures | `Grass004`, `PavingStones070`, `Concrete034` | ambientCG | CC0 |

---

## 3. Characters

| Original | Replacement | Source | Licence | Notes |
|---|---|---|---|---|
| Player boy (Mike) | Quaternius Ultimate Animated Character (a rigged student) | Quaternius | CC0 | Retarget the Universal Animation Library clips onto it |
| Player girl (Amy) | Quaternius Ultimate Animated Character (a rigged student) + a procedural **chunni** | Quaternius | CC0 | The chunni is generated from the skeleton in the original — port that code |
| Uniforms 2023 / 2024 / 2025 | **PROCEDURAL** — recolour the shirt/trouser vertex bands + a texture swap | — | — | Keep the exact colours from `CHARACTER_AND_NPC_ANALYSIS.md` |
| Guard (Bajirao) | capsule NPC (cylinder + sphere + eyes + beret) | — | — | The original uses a model; a capsule matches the rest of the cast |
| Laksmi | Quaternius/KayKit female character in a pink tint | Quaternius / KayKit | CC0 | She sits at the desk in the office annex |
| Colonel Singh | Quaternius character + a beret mesh + an olive tint | Quaternius | CC0 | 1.85 m tall |
| Arjun | student character, orange tint | Quaternius | CC0 | |
| 18 NCC cadets | **PROCEDURAL** capsules + navy beret, one `MultiMesh` | — | — | Olive `#8c8a52` uniform, beret `#1a2a5a` |
| 29 Remy-style students | Quaternius/KayKit student, per-instance tint | Quaternius | CC0 | Use `MultiMesh` + per-instance colour |
| 9 girl NPCs | the girl character, per-instance tint + height | Quaternius | CC0 | Heights 1.57–1.66 m |
| Remy | the student character with the walk clip | Quaternius | CC0 | 1.75 m |

### Animation mapping

| Original clip | Replacement | Source |
|---|---|---|
| Breathing idle (9.93 s loop) | `Idle` from the Universal Animation Library | Quaternius (CC0) |
| Run (0.70 s loop) | `Run` | Quaternius (CC0) |
| Walk | `Walking` | Quaternius (CC0) |
| Sit | `Sitting` | KayKit / Quaternius |
| Salute | `Salute` / `Attention` | KayKit (CC0) |
| Drink | `Drinking` / `Eat` | KayKit (CC0) |
| Talk (arm gestures) | `Talking` / `Talking on Phone` | KayKit (CC0) |
| Basketball shot | `Shooting` / a bespoke clip | KayKit (CC0) |

> **Critical port detail:** every clip in the original is forced to play **in place** (the
> hips' X/Z channels are overwritten with their first values, and the stride length is
> measured to match the walk speed). Do the same in Godot, otherwise the characters will
> slide.

---

## 4. Audio

| Original | Replacement | Licence | Notes |
|---|---|---|---|
| 632 voice MP3s | **PROCEDURAL** TTS + on-screen subtitles, **or** re-record with the ANITS cast | depends | No licence file ships with the clips — see `MISSING_INFORMATION.md` |
| Per-character pitch/rate profiles | **PROCEDURAL** — keep the table from `CHARACTER_AND_NPC_ANALYSIS.md` §6.1 and apply it to the TTS | — | 9 profiles |
| Telugu captions | keep the Telugu strings from `clips.json` / `clips_girl.json` (text, not audio) | text data | Render with Noto Sans Telugu |
| "Jai Hind!" chorus | **PROCEDURAL** — play one clip N times with per-voice pitch/delay | — | The original's maths is in `CHARACTER_AND_NPC_ANALYSIS.md` §6.3 |
| Synthesised UI SFX (clunk, beep, error buzz, spicy whoosh) | **PROCEDURAL** — `AudioStreamGenerator` or short generated buffers | — | The original uses WebAudio oscillators; the recipes are in `game.js` |
| Background music | **none in the original** | — | Add only if the client approves |

---

## 5. UI and 2D assets

| Original | Replacement | Licence | Notes |
|---|---|---|---|
| `anits_logo.png` | **KEEP** | trademark (ANITS) | Used on the loading screen, the menu and the office wall |
| `little_hearts_logo.png` | **KEEP** | trademark (Little Hearts) | Publisher mark |
| `assets/ui/bg_clean.jpg` | **REPLACE** — a new gradient/blur background | — | The original's photo background is not licensed for reuse |
| Level-card thumbnails `lv_*.jpg` (10) | **PROCEDURAL** — the files are **missing** from the build; draw 10 simple cards | — | See `MISSING_INFORMATION.md` |
| Drink label JPEGs (10) | **PROCEDURAL** | — | |
| Uniform body textures (4) | **PROCEDURAL** — recolour the imported character | — | |
| Campus palette image (`PAL`) | **PROCEDURAL** | — | The original re-bakes a 256×256 palette to tint the wall swatch |
| Font stack (Figtree / Bricolage Grotesque / Archivo Black / Noto Sans Telugu) | Google Fonts | **OFL-1.1** | The web build declares them but never loads them; the Godot build should |

---

## 6. Priority order for asset work

| Priority | Work package | Why |
|---|---|---|
| **P0** | Ground, roads, kerbs, perimeter walls, both gates | Without them there is no campus |
| **P0** | The 17 building masses with the correct footprints, heights and tints | The player recognises the campus by its blocks |
| **P0** | Player + camera | The core loop |
| **P1** | The Admin Block corridor + the office annex (the game's centrepiece) | Most missions happen there |
| **P1** | Vegetation and props | The look of the campus |
| **P1** | The 6 main NPCs + the cadets | Day 1 cannot run without them |
| **P2** | The 9 vending machines' bodies, the café, the bank, the noodle bar | Day 2/4/8 need them |
| **P2** | The court + hoop (Day 5) and the flag (Day 6) | Missions |
| **P3** | The 29 students, the 9 girls, Remy | Ambience |
| **P3** | The labels and signs | Readability |

---

## 7. Licence ledger (to be shipped with the build)

| Asset family | Source | Licence | Attribution required |
|---|---|---|---|
| Kenney City Kit (Roads / Commercial), Furniture Kit, Nature Kit | kenney.nl | CC0 1.0 | No |
| Quaternius Ultimate Buildings / Nature / Animated Character, Universal Animation Library | quaternius.com | CC0 1.0 | No |
| KayKit Character Animations | kaylousberg.com | CC0 1.0 | No |
| Poly Haven models and textures | polyhaven.com | CC0 1.0 | No |
| ambientCG materials | ambientcg.com | CC0 1.0 | No |
| Google Fonts (4 families) | fonts.google.com | OFL 1.1 | Yes (in the credits) |
| "Indian Temple" model | pranavaryakirtik (Sketchfab) | CC BY 4.0 | **Yes** — keep the credit line |
| ANITS logo, Little Hearts logo | ANITS / Little Hearts | Proprietary | Used by permission of the rights holder |
| Godot addons (Dialogue Manager, Phantom Camera, Terrain3D, Proton Scatter, Beehave, Godot Jolt) | GitHub | MIT | Yes (in the credits) |

---

## 8. Cross-references

[`FREE_GODOT_ASSETS.md`](FREE_GODOT_ASSETS.md) (why each pack was chosen) ·
[`EXTERNAL_ASSET_LIBRARY.md`](EXTERNAL_ASSET_LIBRARY.md) (URLs + verification log) ·
[`ENVIRONMENT_ASSET_INVENTORY.md`](ENVIRONMENT_ASSET_INVENTORY.md) (the original asset list) ·
[`BUILDING_INVENTORY.md`](BUILDING_INVENTORY.md) (per-building dimensions) ·
[`MISSING_INFORMATION.md`](MISSING_INFORMATION.md) (licences still unknown).
