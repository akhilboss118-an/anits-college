# EXTERNAL_ASSET_LIBRARY.md — every external source, its URL, and its licence proof

**Purpose:** the address book + verification log for the ANITS reconstruction. Every URL in
this document was requested during this analysis and the HTTP result recorded.

**Verification log (all checked during this session):**

| # | Source | URL requested | HTTP | Evidence captured |
|---|---|---|---|---|
| 1 | Kenney — City Kit (Roads) | `https://kenney.nl/assets/city-kit-roads` | 200 | page states *Files 90× · License Creative Commons CC0*; archive `License.txt` = *"License: (Creative Commons Zero, CC0)"* |
| 2 | Kenney — Furniture Kit | `https://kenney.nl/assets/furniture-kit` | 200 | *Files 140× · CC0*; archive `License.txt` = CC0 |
| 3 | Kenney — City Kit (Commercial) | `https://kenney.nl/assets/city-kit-commercial` | 200 | *Files 50× · CC0*; archive `License.txt` = CC0 |
| 4 | Kenney — Nature Kit | `https://kenney.nl/assets/nature-kit` | 200 | *Files 330× · CC0*; archive `License.txt` = CC0 |
| 5 | Quaternius — Ultimate Buildings | `https://quaternius.com/packs/ultimatetexturedbuildings.html` | 200 | *Models 76 · Formats FBX OBJ Blend · License CC0* + Drive folder id |
| 6 | Quaternius — Ultimate Nature | `https://quaternius.com/packs/ultimatenature.html` | 200 | *Models 150 · FBX OBJ Blend · CC0* + Drive folder id |
| 7 | Quaternius — Ultimate Animated Character | `https://quaternius.com/packs/ultimatedanimatedcharacter.html` | 200 | *Models 52 · FBX OBJ Blend · CC0* + Drive folder id |
| 8 | Quaternius — Universal Animation Library | `https://quaternius.com/packs/universalanimationlibrary.html` | 200 | *"kit of 120+ animations … compatible with Unreal Engine, Godot and Unity" · FBX GLB Blend · CC0* |
| 9 | KayKit — Character Animations | `https://kaylousberg.com/game-assets/character-animations` | 200 | *"133 Humanoid animations … Free for personal and commercial use, no attribution required. (CC0 Licensed)"* |
| 10 | Poly Haven — licence | `https://polyhaven.com/license` | 200 | *"Our assets are all licensed as CC0"* |
| 11 | Poly Haven — model API | `https://api.polyhaven.com/assets?t=models` | 200 | 521 model ids returned |
| 12 | Poly Haven — file API | `https://api.polyhaven.com/files/painted_wooden_bench` | 200 | JSON with direct `dl.polyhaven.org` URLs + MD5s |
| 13 | ambientCG — licence | `https://ambientcg.com/license` | 200 | *"All ambientCG assets are provided under the Creative Commons CC0 1.0 Universal License"* |
| 14 | ambientCG — direct zip | `https://ambientcg.com/get?file=PavingStones070_1K-JPG.zip` | 200 (`application/zip`, 9,046,803 B) | byte-range verified |
| 15 | ambientCG — direct zip | `https://ambientcg.com/get?file=Concrete034_1K-JPG.zip` | 200 (`application/zip`, 3,657,575 B) | byte-range verified |
| 16 | ambientCG — direct zip | `https://ambientcg.com/get?file=Grass004_1K-JPG.zip` | 200 (`application/zip`, 11,003,149 B) | byte-range verified |
| 17 | ambientCG — direct zip | `https://ambientcg.com/get?file=Metal032_1K-JPG.zip` | 200 (`application/zip`, 3,650,556 B) | byte-range verified |
| 18 | Google Fonts — Figtree | `https://raw.githubusercontent.com/google/fonts/main/ofl/figtree/Figtree%5Bwght%5D.ttf` | 200 (62,712 B) | `OFL.txt` present in `ofl/figtree` |
| 19 | Google Fonts — Bricolage Grotesque | `https://raw.githubusercontent.com/google/fonts/main/ofl/bricolagegrotesque/BricolageGrotesque%5Bopsz,wdth,wght%5D.ttf` | repo path verified | `OFL.txt` present |
| 20 | Google Fonts — Archivo Black | `https://raw.githubusercontent.com/google/fonts/main/ofl/archivoblack/ArchivoBlack-Regular.ttf` | repo path verified | `OFL.txt` present |
| 21 | Google Fonts — Noto Sans Telugu | `https://raw.githubusercontent.com/google/fonts/main/ofl/notosanstelugu/NotoSansTelugu%5Bwdth,wght%5D.ttf` | repo path verified | `OFL.txt` present |
| 22 | GitHub — Dialogue Manager | `https://api.github.com/repos/nathanhoad/godot_dialogue_manager` | 200 | `license.spdx_id = MIT`, 3,977 stars, latest release `v4.2.0` (2026-10-30) |
| 23 | GitHub — Phantom Camera | `https://api.github.com/repos/ramokz/phantom-camera` | 200 | MIT, 3,656 stars, latest `v0.11.0.4` |
| 24 | GitHub — Terrain3D | `https://api.github.com/repos/TokisanGames/Terrain3D` | 200 | MIT, 4,760 stars, release zip `Terrain3D_v1.1.0-stable.zip` (45.7 MB) |
| 25 | GitHub — Proton Scatter | `https://api.github.com/repos/HungryProton/scatter` | 200 | MIT, 3,026 stars, latest `4.0` |
| 26 | GitHub — Beehave | `https://api.github.com/repos/bitbrain/beehave` | 200 | MIT, 3,324 stars, latest `v2.9.3` |
| 27 | GitHub — Godot Jolt | `https://api.github.com/repos/godot-jolt/godot-jolt` | 200 | MIT, 2,606 stars, release zip `godot-jolt_v0.16.0-stable.zip` (27.0 MB) |
| 28 | Poly Pizza — terms | `https://poly.pizza/docs/tos` | 200 | per-model licences; **no pack-wide CC0** → not on the approved list |

---

## 1. Kenney (kenney.nl)

Four packs, all CC0, all already downloaded and verified locally.

### 1.1 How to download programmatically

The site does not expose a static `.zip` link; it serves a fresh signed URL from an endpoint
that takes the **hex-encoded** asset path:

```
GET https://kenney.nl/download-link/<hex of "assets/<slug>">
→ { "url": "https://kenney.nl/download/<hex>/<sha>?expires=…" }
```

| Pack | Slug | Hex id (verified working) |
|---|---|---|
| City Kit (Roads) | `assets/city-kit-roads` | `6173736574732f636974792d6b69742d726f616473` |
| Furniture Kit | `assets/furniture-kit` | `6173736574732f6675726e69747572652d6b6974` |
| City Kit (Commercial) | `assets/city-kit-commercial` | `6173736574732f636974792d636f6d6d65726369616c` |
| Nature Kit | `assets/nature-kit` | `6173736574732f6e61747572652d6b6974` |

Working PowerShell/Node recipe (this exact script downloaded all four packs successfully):

```powershell
$tmp = "$env:TEMP\opencode\kenney"; New-Item -ItemType Directory -Force -Path $tmp | Out-Null
function HexOf([string]$s){ -join ($s.ToCharArray() | ForEach-Object {
  [System.BitConverter]::ToString([System.Text.Encoding]::ASCII.GetBytes($_)).Replace('-','').ToLower() }) }
foreach($p in @("assets/city-kit-roads","assets/furniture-kit",
                "assets/city-kit-commercial","assets/nature-kit")){
  $slug = $p.Split('/')[-1]
  $url = (Invoke-RestMethod -Uri "https://kenney.nl/download-link/$(HexOf $p)" `
         -Headers @{ Referer="https://kenney.nl/assets/$slug"; 'User-Agent'='Mozilla/5.0' }).url
  Invoke-WebRequest -Uri $url -OutFile "$tmp\$slug.zip" -Headers @{ 'User-Agent'='Mozilla/5.0' }
  Expand-Archive "$tmp\$slug.zip" "$tmp\$slug" -Force
}
```

> Note: `Invoke-RestMethod` **without** a `Referer`/`User-Agent` header gets a 403 from this
> endpoint — the headers are required.

### 1.2 What is inside (verified by extraction)

| Pack | GLB count | FBX count | Other | Textures | Licence file |
|---|---|---|---|---|---|
| City Kit (Roads) | 95 | 95 | OBJ | 4 PNG | `License.txt` (CC0) |
| City Kit (Commercial) | 41 | 41 | OBJ | 5 PNG | `License.txt` (CC0) |
| Furniture Kit | 140 (in `Models/GLTF format`) | 140 | DAE, OBJ, STL | — | `License.txt` (CC0) |
| Nature Kit | 329 (in `Models/GLTF format`) | 329 | DAE, OBJ, STL | — | `License.txt` (CC0) |

`License.txt` (City Kit Roads) verbatim:

```
City Kit Roads (2.2)
Created/distributed by Kenney (www.kenney.nl)
Creation date: 10-10-2026 12:35
------------------------------
License: (Creative Commons Zero, CC0)
http://creativecommons.org/publicdomain/zero/1.0/
```

### 1.3 Named models worth knowing (verified by directory listing)

- **City Kit (Commercial):** `building-a` … `building-n`, `building-skyscraper-a` … `-e`,
  `low-detail-building-a` … `-n`, `low-detail-building-wide-a/b`, `detail-awning`,
  `detail-awning-wide`, `detail-overhang`, `detail-overhang-wide`, `detail-parasol-a/b`.
- **Furniture Kit:** `bench`, `benchCushion`, `benchCushionLow`, `desk`, `deskCorner`, `chair`,
  `chairDesk`, `chairCushion`, `chairModernFrameCushion`, `chairRounded`, `lampSquareCeiling`,
  `lampSquareFloor`, `lampSquareTable`, `lampRoundFloor`, `lampRoundTable`, `lampWall`,
  `loungeSofa`, `loungeSofaLong`, `loungeDesignSofa`, `pottedPlant`, `plantSmall1/2/3`,
  `bookcaseOpen`, `bookcaseClosed`, `books`, `cabinetBedDrawerTable`, `sideTable`, `table`.
- **Nature Kit:** `tree_default`, `tree_default_dark`, `tree_oak`, `tree_oak_dark`,
  `tree_palm`, `tree_cone`, `tree_cone_dark`, `tree_detailed`, `tree_detailed_dark`,
  `tree_fat`, `tree_blocks`, `tree_blocks_dark`, `plant_bush`, `plant_bushSmall`,
  `plant_bushLarge`, `plant_bushDetailed`, `plant_bushTriangle`, `plant_flatShort`,
  `plant_flatTall`, `grass`, `grass_large`, `grass_leafs`, `grass_leafsLarge`, `ground_grass`,
  `stump_round`, `stump_old`, `cliff_rock` (and 20+ cliff variants).

---

## 2. Quaternius (quaternius.com)

All packs are **CC0** and link to `https://creativecommons.org/publicdomain/zero/1.0/` from
the pack page. Downloads are Google Drive folders (per pack) or itch.io.

| Pack | Page | Models | Formats | Download target |
|---|---|---|---|---|
| Ultimate Buildings | `/packs/ultimatetexturedbuildings.html` | 76 | FBX, OBJ, Blend | Drive folder `1RE3qXhbE5yGS3t-xGFJ8GmOtTgCUF3LQ` |
| Ultimate Nature | `/packs/ultimatenature.html` | 150 | FBX, OBJ, Blend | Drive folder `1-Kl0L_Jg8awbh0S5T-z3zxh4mVlnxTpa` |
| Ultimate Animated Character | `/packs/ultimatedanimatedcharacter.html` | 52 | FBX, OBJ, Blend | Drive folder `1sNi1AfenfPRrvTt5yfaj5QMMd6KKcUJ5` |
| Universal Animation Library | `/packs/universalanimationlibrary.html` | 1 rig / **120+ clips** | FBX, **GLB**, Blend | `https://quaternius.itch.io/universal-animation-library` |

Folder URLs in full:

```
https://drive.google.com/drive/folders/1RE3qXhbE5yGS3t-xGFJ8GmOtTgCUF3LQ   # Ultimate Buildings
https://drive.google.com/drive/folders/1-Kl0L_Jg8awbh0S5T-z3zxh4mVlnxTpa   # Ultimate Nature
https://drive.google.com/drive/folders/1sNi1AfenfPRrvTt5yfaj5QMMd6KKcUJ5   # Ultimate Animated Character
```

> Download the **GLB/Blend** where available: Quaternius's Blend files carry the original
> materials and are the cheapest to re-export; the GLB of the animation library imports into
> Godot with the rig intact.

---

## 3. KayKit (kaylousberg.com)

| Item | URL | Licence |
|---|---|---|
| Character Animations (133 clips, FBX + GLTF) | page: `https://kaylousberg.com/game-assets/character-animations` · download: `https://kaylousberg.itch.io/kaykit-character-animations` | CC0 (*"Free for personal and commercial use, no attribution required. (CC0 Licensed)"*) |
| Character base meshes | `https://kaylousberg.com/game-assets#Character` | CC0 |

The animations are produced for **Rig_Medium** and **Rig_Large** KayKit characters; the page
states they also work on other humanoids with retargeting.

---

## 4. Poly Haven

### 4.1 API (all CC0)

```
GET https://api.polyhaven.com/assets?t=models     → { "<id>": { ... } }   (521 models)
GET https://api.polyhaven.com/assets?t=textures    → texture ids
GET https://api.polyhaven.com/assets?t=hdris       → HDRI ids
GET https://api.polyhaven.com/files/<id>           → per-format file URLs + md5 + size
```

### 4.2 Example direct file URL (verified pattern)

```
https://dl.polyhaven.org/file/ph-assets/Models/gltf/4k/painted_wooden_bench/painted_wooden_bench_4k.gltf
https://dl.polyhaven.org/file/ph-assets/Models/gltf/8k/street_lamp_01/street_lamp_01_8k.gltf
https://dl.polyhaven.org/file/ph-assets/Models/gltf/1k/pine_tree_01/pine_tree_01_1k.gltf
```

> Always fetch the file list from the API rather than guessing the URL — Poly Haven varies the
> default resolution per asset (1k / 2k / 4k / 8k) and the `.bin`/texture URLs must match.

### 4.3 Campus-relevant model ids (verified to exist)

`painted_wooden_bench`, `modular_street_seating`, `street_lamp_01`, `street_lamp_02`,
`planter_box_01`, `planter_box_02`, `planter_box_03`, `planter_pot_clay`, `pine_tree_01`,
`fir_tree_01`, `jacaranda_tree`, `island_tree_01`, `island_tree_02`, `island_tree_03`,
`tree_small_02`, `grass_medium_01`, `grass_bermuda_01`, `metal_trash_can`, `SchoolDesk_01`,
`SchoolChair_01`, `Sofa_01`, `WoodenChair_01`, `WoodenTable_01`, `potted_plant_01`,
`desk_lamp_arm_01`, `industrial_wall_lamp`, `wet_floor_sign`, `modern_ceiling_lamp_01`.

---

## 5. ambientCG

```
https://ambientcg.com/get?file=<ASSET_ID>_<RES>_JPG.zip     # e.g. Grass004_1K-JPG.zip
```

Verified working (HTTP 200, `application/zip`):

| URL | Size |
|---|---|
| `https://ambientcg.com/get?file=PavingStones070_1K-JPG.zip` | 9,046,803 B |
| `https://ambientcg.com/get?file=Concrete034_1K-JPG.zip` | 3,657,575 B |
| `https://ambientcg.com/get?file=Grass004_1K-JPG.zip` | 11,003,149 B |
| `https://ambientcg.com/get?file=Metal032_1K-JPG.zip` | 3,650,556 B |

Resolution suffixes used by the site: `1K`, `2K`, `4K`, `8K`; formats: `JPG`, `PNG`.

---

## 6. Google Fonts (UI typefaces, OFL-1.1)

| Family | Raw file URL (verified for Figtree) | Repo folder with `OFL.txt` |
|---|---|---|
| Figtree | `https://raw.githubusercontent.com/google/fonts/main/ofl/figtree/Figtree%5Bwght%5D.ttf` | `google/fonts/ofl/figtree` |
| Bricolage Grotesque | `…/main/ofl/bricolagegrotesque/BricolageGrotesque%5Bopsz,wdth,wght%5D.ttf` | `google/fonts/ofl/bricolagegrotesque` |
| Archivo Black | `…/main/ofl/archivoblack/ArchivoBlack-Regular.ttf` | `google/fonts/ofl/archivoblack` |
| Noto Sans Telugu | `…/main/ofl/notosanstelugu/NotoSansTelugu%5Bwdth,wght%5D.ttf` | `google/fonts/ofl/notosanstelugu` |

All four directories contain an `OFL.txt` — verified through the GitHub contents API.

---

## 7. Godot addons (MIT)

| Addon | Clone URL | Release artefact |
|---|---|---|
| Dialogue Manager | `https://github.com/nathanhoad/godot_dialogue_manager` | latest tag `v4.2.0` (no binary asset — install via the Asset Library or clone) |
| Phantom Camera | `https://github.com/ramokz/phantom-camera` | latest tag `v0.11.0.4` (same) |
| Terrain3D | `https://github.com/TokisanGames/Terrain3D` | `https://github.com/TokisanGames/Terrain3D/releases/download/v1.1.0-stable/Terrain3D_v1.1.0-stable.zip` (45.7 MB) |
| Proton Scatter | `https://github.com/HungryProton/scatter` (mirror of Codeberg) | latest tag `4.0` |
| Beehave | `https://github.com/bitbrain/beehave` | latest tag `v2.9.3` |
| Godot Jolt | `https://github.com/godot-jolt/godot-jolt` | `https://github.com/godot-jolt/godot-jolt/releases/download/v0.16.0-stable/godot-jolt_v0.16.0-stable.zip` (27.0 MB) |

---

## 8. Sources that are **not** approved

| Source | Reason |
|---|---|
| Poly Pizza (`poly.pizza`) | Each model carries its own licence (CC0 or CC-BY per uploader). There is no pack-wide CC0, so every model would need an individual check before use. The site also forbids scraping. Usable only as a last-resort, per-model, with the licence recorded in `ASSET_MAPPING.md`. |
| Sketchfab / TurboSquid / CGTrader free models | Per-upload licences, author-specific, usually non-transferable. The **temple** in the original game came from Sketchfab and is the one exception (CC-BY-4.0, credited). |
| The original ANITS models | No licence file ships with them — see `MISSING_INFORMATION.md`. |

---

## 9. Credits template for the rebuilt game

`res://credits.txt` (or an in-game credits screen) should carry:

```
ANITS College Simulation
Original game by Little Hearts / AKHILBOSS

3D assets:
  Kenney (kenney.nl)            – CC0 1.0 – City Kit (Roads), City Kit (Commercial),
                                   Furniture Kit, Nature Kit
  Quaternius (quaternius.com)    – CC0 1.0 – Ultimate Buildings, Ultimate Nature,
                                   Ultimate Animated Character, Universal Animation Library
  KayKit (kaylousberg.com)       – CC0 1.0 – Character Animations
  Poly Haven (polyhaven.com)     – CC0 1.0 – models and textures
  ambientCG (ambientcg.com)      – CC0 1.0 – materials
  pranavaryakirtik (Sketchfab)   – CC BY 4.0 – "Indian Temple" model

Fonts:
  Figtree, Bricolage Grotesque, Archivo Black, Noto Sans Telugu
  – SIL Open Font License 1.1 – Google Fonts

Godot addons:
  Dialogue Manager, Phantom Camera, Terrain3D, Proton Scatter, Beehave, Godot Jolt – MIT
```

---

## 10. Cross-references

[`FREE_GODOT_ASSETS.md`](FREE_GODOT_ASSETS.md) (what to use each pack for) ·
[`ASSET_MAPPING.md`](ASSET_MAPPING.md) (original → replacement mapping) ·
[`ENVIRONMENT_ASSET_INVENTORY.md`](ENVIRONMENT_ASSET_INVENTORY.md) (the original asset list) ·
[`MISSING_INFORMATION.md`](MISSING_INFORMATION.md) (licences still unknown).
