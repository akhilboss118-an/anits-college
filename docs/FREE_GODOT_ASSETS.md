# FREE_GODOT_ASSETS.md — verified CC0 replacements for every asset need

This is the **curated shopping list**: for each thing the ANITS reconstruction needs, the
single best free asset that is *provably* CC0, what to use it for, and how it imports into
Godot 4.

**Licence-verification rules applied in this document**

1. The licence text was read from the publisher's own page (or the `License.txt` inside the
   downloaded archive) — not from a third-party listing.
2. Every count (models, files, animations) was read from the publisher's page or from the
   downloaded archive.
3. Where a pack mixes licences, the pack is **excluded** from the recommended list.
4. The ANITS project's own assets are **not** listed here: they have no licence file (only the
   temple does). See [`MISSING_INFORMATION.md`](MISSING_INFORMATION.md).

**Companion document:** [`EXTERNAL_ASSET_LIBRARY.md`](EXTERNAL_ASSET_LIBRARY.md) has the raw
download URLs, the API endpoints and the full licence-verification log.

---

## 1. Coverage matrix

| Reconstruction need | Recommended source | Specific assets | Licence |
|---|---|---|---|
| Academic blocks (CSE / ECE / EEE / Chemical) | **Kenney City Kit (Commercial)** | `building-a`…`building-n`, `low-detail-building-*`, `detail-awning`, `detail-overhang` | CC0 |
| Long block rows (Mechanical / IT / Civil / CSM) | **Quaternius Ultimate Buildings** | modular walls/floors/roofs | CC0 |
| Admin Block (4 floors + corridor) | **Quaternius Ultimate Buildings** + a bespoke corridor | — | CC0 |
| Café / bank / workshop / shop shells | **Kenney City Kit (Commercial)** + **Poly Haven** props | `building-e`, `painted_wooden_bench`, `modular_street_seating` | CC0 |
| Roads, kerbs, crossings, signs | **Kenney City Kit (Roads)** | road tiles, traffic lights, road signs | CC0 |
| Benches, desks, chairs, sofas, lamps, plants | **Kenney Furniture Kit** | `bench`, `benchCushion`, `desk`, `chairDesk`, `lampSquareCeiling`, `pottedPlant`, `loungeSofa` | CC0 |
| Trees, bushes, grass, stumps | **Kenney Nature Kit** | `tree_default`, `tree_oak`, `tree_palm`, `tree_cone`, `tree_detailed`, `plant_bush`, `plant_bushSmall`, `grass`, `grass_large`, `stump_round` | CC0 |
| Terrain textures (grass, asphalt, paving, sand) | **ambientCG** | `Grass004`, `PavingStones070`, `Concrete034`, `Metal032` (+ sand) | CC0 |
| Photoreal props (benches, lamps, planters, trees) | **Poly Haven** | `painted_wooden_bench`, `modular_street_seating`, `street_lamp_01`, `planter_box_01`, `pine_tree_01`, `jacaranda_tree`, `fir_tree_01`, `SchoolDesk_01`, `Sofa_01` | CC0 |
| Player character | **Quaternius Ultimate Animated Character** + **KayKit Character Pack** | a student-looking rigged character | CC0 |
| Animation set (idle / walk / run / sit / wave / salute) | **Quaternius Universal Animation Library** and/or **KayKit Character Animations** | 120+ / 133 clips | CC0 |
| Basketball hoop, ball, court props | **Poly Haven** + Kenney | `basketball` props from Poly Haven / Kenney prototype | CC0 |
| Open Auditorium pavilion | **Quaternius Ultimate Buildings** | open pavilion pieces | CC0 |
| UI fonts | **Google Fonts** | Figtree, Bricolage Grotesque, Archivo Black, Noto Sans Telugu | OFL-1.1 |
| Sky / HDRI (optional) | **Poly Haven** HDRIs | any equirect sky | CC0 |

---

## 2. Pack sheets (verified)

### 2.1 Kenney — City Kit (Roads)
- **Page:** https://kenney.nl/assets/city-kit-roads · **Files:** 90 · **Licence:** CC0
- **Archive contents (verified locally):** `Models/GLB format` (95 `.glb`), `Models/FBX format`
  (95), `Models/OBJ format`, `Models/Textures` (4 PNGs), `Previews`, `License.txt`.
- `License.txt` reads: *"License: (Creative Commons Zero, CC0) — http://creativecommons.org/publicdomain/zero/1.0/"*.
- **Use for:** the 8 road rectangles, the yellow/white kerb blocks (the pack's road-edge pieces
  can be recoloured), crossings, the parking-lot asphalt, traffic lights and signs.
- **Godot:** import the GLBs; the pack's GLB files carry PBR textures that Godot imports
  directly.

### 2.2 Kenney — City Kit (Commercial)
- **Page:** https://kenney.nl/assets/city-kit-commercial · **Files:** 50 · **Licence:** CC0
- **Archive contents (verified locally):** `Models/GLB format` (41 `.glb`), `Models/FBX format`
  (41), `Models/OBJ format`, `Models/Textures` (5 PNGs), `License.txt` (CC0).
- **Exact model names:** `building-a` … `building-n` (14), `building-skyscraper-a` … `-e` (5),
  `low-detail-building-a` … `-n` (14), `low-detail-building-wide-a` / `-b` (2),
  `detail-awning`, `detail-awning-wide`, `detail-overhang`, `detail-overhang-wide`,
  `detail-parasol-a`, `detail-parasol-b`.
- **Use for:** the four panel-house blocks (repeat one unit per bay, tint per building), the
  café (awnings + overhangs), the bank, the workshop.
- **Godot:** `detail-overhang` reproduces the canopy over the classroom doors; `detail-awning`
  reproduces the café's striped awning.

### 2.3 Kenney — Furniture Kit
- **Page:** https://kenney.nl/assets/furniture-kit · **Files:** 140 · **Licence:** CC0
- **Archive contents (verified locally):** `Models/GLTF format` (140 `.glb`), `Models/FBX
  format`, `Models/OBJ format`, `Models/DAE format`, `Models/STL format`, `Side/`, `Isometric/`.
- **Useful names (verified):** `bench`, `benchCushion`, `benchCushionLow`, `desk`, `deskCorner`,
  `chair`, `chairDesk`, `chairCushion`, `chairModernFrameCushion`, `lampSquareCeiling`,
  `lampSquareFloor`, `lampSquareTable`, `lampRoundFloor`, `lampWall`, `loungeSofa`,
  `loungeSofaLong`, `pottedPlant`, `plantSmall1/2/3`, `bookcaseOpen`, `bookcaseClosed`,
  `books`, `cabinetBedDrawerTable`, `sideTable`, `table`.
- **Use for:** the 7 park benches, the 4 office sofas, the office shelves with coloured book
  spines, the visitor chairs, the potted plants, the ceiling lamps of the waiting room.

### 2.4 Kenney — Nature Kit
- **Page:** https://kenney.nl/assets/nature-kit · **Files:** 330 · **Licence:** CC0
- **Archive contents (verified locally):** `Models/GLTF format` (329 `.glb`), `Models/FBX
  format` (329), `Models/OBJ format`, `Models/DAE format`, `Models/STL format`.
- **Useful names (verified):** `tree_default`, `tree_default_dark`, `tree_oak`, `tree_palm`,
  `tree_cone` (pine), `tree_cone_dark`, `tree_detailed`, `tree_detailed_dark`, `tree_fat`,
  `tree_blocks`, `plant_bush`, `plant_bushSmall`, `plant_bushLarge`, `plant_bushDetailed`,
  `plant_flatShort`, `plant_flatTall`, `grass`, `grass_large`, `grass_leafs`, `ground_grass`,
  `stump_round`, `stump_old`, `cliff_rock` …
- **Use for:** the 150 campus trees (broadleaf + pine mix), the 130 bushes, the grass tufts.

### 2.5 Quaternius — Ultimate Buildings Pack
- **Page:** https://quaternius.com/packs/ultimatetexturedbuildings.html
- **Models:** 76 · **Formats:** FBX, OBJ, Blend · **Licence:** CC0 (linked on the page to
  `creativecommons.org/publicdomain/zero/1.0/`)
- **Download:** the page's *Download* button opens the author's Google Drive folder
  `https://drive.google.com/drive/folders/1RE3qXhbE5yGS3t-xGFJ8GmOtTgCUF3LQ`
- **Use for:** modular multi-storey academic blocks, the Open Auditorium pavilion, the bank
  shell and the workshop; the modularity lets a plot be filled with *n* identical bays exactly
  like the original low-poly rows.

### 2.6 Quaternius — Ultimate Nature Pack
- **Page:** https://quaternius.com/packs/ultimatenature.html
- **Models:** 150 · **Formats:** FBX, OBJ, Blend · **Licence:** CC0
- **Download:** `https://drive.google.com/drive/folders/1-Kl0L_Jg8awbh0S5T-z3zxh4mVlnxTpa`
- **Use for:** an alternative (stylised) tree/bush set, and for the *temple-adjacent* planting.
- **Why not Kenney Nature Kit for everything:** Kenney's trees are blobby and very low-poly;
  Quaternius's are more varied. Either is acceptable — the original used simple procedural
  geometry, so Kenney is the closer match.

### 2.7 Quaternius — Ultimate Animated Character Pack
- **Page:** https://quaternius.com/packs/ultimatedanimatedcharacter.html
- **Models:** 52 · **Formats:** FBX, OBJ, Blend · **Licence:** CC0
- **Download:** `https://drive.google.com/drive/folders/1sNi1AfenfPRrvRt5yfaj5QMMd6KKcUJ5`
- **Use for:** the player character and the 29 Remy-model students. The pack ships rigged,
  retargetable characters with idle/walk/run clips.

### 2.8 Quaternius — Universal Animation Library
- **Page:** https://quaternius.com/packs/universalanimationlibrary.html
- **Content:** *"a kit of 120+ animations, created using a universal humanoid rig, which is
  compatible with Unreal Engine, Godot and Unity, ready for retargeting"* · **Formats:** FBX,
  **GLB**, Blend · **Licence:** CC0
- **Download:** `https://quaternius.itch.io/universal-animation-library`
- **Use for:** the full animation set — idle, walk, run, sit, wave, salute, clap, cheer, eat,
  drink. **This is the single most important pack for matching the original's feel**, because
  the original's clips are Mixamo-derived.
- **Godot:** GLB files import with the rig; use `Skeleton3D` + `AnimationPlayer` + `AnimationTree`.

### 2.9 KayKit — Character Animations
- **Page:** https://kaylousberg.com/game-assets/character-animations
- **Content:** *"133 Humanoid animations"* · **Files:** `.FBX` and `.GLTF` · **Licence:**
  *"Free for personal and commercial use, no attribution required. (CC0 Licensed)"* (verbatim
  from the page)
- **Download:** https://kaylousberg.itch.io/kaykit-character-animations
- **Use for:** an alternative/complementary animation set (locomotion, emotes, combat, special
  skeleton clips) and the KayKit character base meshes.

### 2.10 Poly Haven (models, textures, HDRIs)
- **Licence page:** https://polyhaven.com/license — *"Our assets are all licensed as CC0"*
- **Model count:** 521 (verified via the public API `https://api.polyhaven.com/assets?t=models`)
- **Per-asset file list API:** `https://api.polyhaven.com/files/<asset_id>` (returns the direct
  GLTF/FBX/Blend URLs plus the texture URLs and MD5s)
- **Useful asset ids (verified):** `painted_wooden_bench`, `modular_street_seating`,
  `street_lamp_01`, `street_lamp_02`, `planter_box_01`, `planter_box_02`, `planter_pot_clay`,
  `pine_tree_01`, `jacaranda_tree`, `fir_tree_01`, `tree_small_02`, `island_tree_01`,
  `grass_medium_01`, `metal_trash_can`, `SchoolDesk_01`, `SchoolChair_01`, `Sofa_01`,
  `WoodenChair_01`, `WoodenTable_01`, `potted_plant_01`, `wet_floor_sign`, `desk_lamp_arm_01`.
- **Godot:** Poly Haven ships `.blend`, `.gltf`/`.glb`, `.fbx` and `.usd`; the `.blend` import
  through the Blender pipeline gives the best material setup, the `.gltf` is fastest.

### 2.11 ambientCG (materials)
- **Licence:** *"All ambientCG assets are provided under the Creative Commons CC0 1.0 Universal
  License"* (verbatim from https://ambientcg.com/license)
- **Direct download pattern (verified HTTP 200 + `application/zip`):**
  `https://ambientcg.com/get?file=<AssetID>_1K-JPG.zip`
- **Materials that map onto the campus:** `Grass004` (lawn), `PavingStones070` (footpaths),
  `Concrete034` (podium/plinth), `Metal032` (lamp posts, fences, substation).
- **Godot:** the zips contain a `.obj`/`.fbx` + PNG maps; convert or import the FBX.

### 2.12 Google Fonts (UI)
Verified to exist in `google/fonts` **with an `OFL.txt`** (SIL Open Font License 1.1):

| Family | Repo path | Use |
|---|---|---|
| Figtree | `ofl/figtree` | body UI (the web build's intent) |
| Bricolage Grotesque | `ofl/bricolagegrotesque` | headings, logo type |
| Archivo Black | `ofl/archivoblack` | the big year number on the year-select screen |
| Noto Sans Telugu | `ofl/notosanstelugu` | Telugu subtitles |

> The web build declares these families but ships **no `@font-face`**, so it silently falls
> back to `system-ui`. The Godot port should ship the real fonts — the UI was designed for them.

---

## 3. Godot 4 addons (all MIT, verified via the GitHub API)

| Addon | Repository | Licence | Stars | Use for |
|---|---|---|---|---|
| **Dialogue Manager** | `nathanhoad/godot_dialogue_manager` | MIT | 3,977 | the 340 + 310 scripted lines, branching on mission state (https://dialogue.nathanhoad.net/) |
| **Phantom Camera** | `ramokz/phantom-camera` | MIT | 3,656 | the third-person follow camera with building avoidance (https://phantom-camera.dev) |
| **Terrain3D** | `TokisanGames/Terrain3D` | MIT | 4,760 | the 217 × 262 m campus ground with splat-mapped paths (not strictly needed — the original is flat) |
| **Proton Scatter** | `HungryProton/scatter` | MIT | 3,026 | scattering the 150 trees / 130 bushes / grass with the original's seeded LCG |
| **Beehave** | `bitbrain/beehave` | MIT | 3,324 | NPC behaviour trees (route students, the cadet formation) |
| **Godot Jolt** | `godot-jolt/godot-jolt` | MIT | 2,606 | the character controller and capsule collisions (Jolt is the default physics in Godot 4.4+) |

None of these are required: every one of them can be replaced by hand-written GDScript if the
project prefers zero third-party code. They are listed because they shorten the build.

---

## 4. What must **not** be reused

| Asset | Why |
|---|---|
| `b_admin.bin`, `b_brez.bin`, `b_lp.bin`, `b_cafe.bin`, `b_bank.bin`, `b_stairaud.bin`, `b_gate.bin`, `b_bench.bin`, `b_drink.bin`, `b_grass.bin`, `b_colonel.bin`, `b_guard.bin`, `b_phone.bin`, `b_remy.bin`, `b_walk.bin`, `b_aud.bin`, `workshop.glb`, `cadet_*.glb`, `laksmi.glb`, `office_*.glb`, `tree_gattu.glb`, `basketball*.glb` | **No licence file in the project.** Unless the author supplies a licence, treat them as *all rights reserved* and replace them. |
| `b_temple.bin` | CC-BY-4.0 — **usable with attribution**. Keep the credit line. |
| `anits_logo.png`, `little_hearts_logo.png` | Trademarks of ANITS / Little Hearts — usable only under the rights holder's authorisation (which is the point of this reconstruction), **not** redistributable as a free asset. |
| The 632 MP3 voice clips | No licence file found. Either re-record (the game already has a TTS fallback, so the port can use Godot's own TTS/dialogue and stay silent-by-default), or obtain a licence. See `MISSING_INFORMATION.md`. |

---

## 5. Local verified copies (downloaded during this analysis)

| Pack | Path | Size |
|---|---|---|
| Kenney City Kit (Roads) | `C:\Users\AKHILBOSS\AppData\Local\Temp\opencode\kenney\city-kit-roads\` | 2.7 MB zip |
| Kenney Furniture Kit | `…\kenney\furniture-kit\` | 4.9 MB zip |
| Kenney City Kit (Commercial) | `…\kenney\city-kit-commercial\` | 3.9 MB zip |
| Kenney Nature Kit | `…\kenney\nature-kit\` | 10.0 MB zip |

Each extracted folder contains the original `License.txt` (CC0) and the per-format model
folders, so the import step can start immediately. Re-downloadable at any time from the
`download-link` endpoints in [`EXTERNAL_ASSET_LIBRARY.md`](EXTERNAL_ASSET_LIBRARY.md).

---

## 6. Import pipeline recommendation [P]

1. Copy the Kenney/Quaternius/Poly Haven sources into `res://third_party/<pack>/`.
2. Keep each pack's `License.txt` / `OFL.txt` next to it (`res://third_party/<pack>/LICENSE`).
3. Import GLB/GLTF only (drop FBX/OBJ/Blend to keep the import time down).
4. Write a small `import_bench.gd` editor script that converts every imported scene into a
   `StaticBody3D` + `CollisionShape3D` and applies the material overrides from
   `ASSET_MAPPING.md`.
5. Re-export the character animations to `.res` (`AnimationPlayer` library) so they can be
   retargeted onto one master skeleton.
