# ANITS College Simulation — Godot 4 port

A third-person campus game rebuilt from the original **ANITS – First Day** web game
in **Godot 4.7.2**. Same campus, same models, same voices — now with the complete
**10-day campaign**, four walk-in interiors, five minigames, a student bag, roads
around the whole college, a photo main menu, a 5 × 2 level-select grid, a
stride-matched walk cycle and two adaptive quality profiles tuned for desktop and
low-end mobile.

**Play in the browser:** <https://akhilboss118-an.github.io/anits-college/>

**Android APK (v1.0):** [download the signed arm64 APK](https://github.com/akhilboss118-an/anits-college/releases/download/v1.0/ANITS-College-Simulation-v1.0.apk)
(115.6 MB) — or build it locally with the command in [Build](#build).

---

## What is in the build

| Area | Content |
| --- | --- |
| Campus | 17 buildings, 12 streets, 6 wall runs, main gate + Back Gate, four walk-in interiors (Admin Office, Central Library, Room 204, Canteen), 150 trees, 130 bushes, 4,200 grass cards, 91 parked cars, benches, lamps, vending machines. Flat-colour imported buildings are merged into single meshes and the row blocks are MultiMesh batches; phones drop to 83 trees / 72 bushes / 1,680 grass cards / 50 cars |
| People | 64 NPCs with name labels, routes and the original dialogue (62 animated rigs), plus the player (Mike / Amy) |
| Story | All 10 days play from start to finish. Day 1 tutorial; fees, bank ATM and Room 204 on Day 3; library quiz, basketball, NCC drill and fest; lab-manual run; canteen challenge; final first-class quiz. Each day unlocks the next. |
| Minigames | Basketball shootout with mouse/touch aim and a THROW button (gravity arc, rim and backboard collisions, 7 s shot clock, 5 shots / 3 hits), NCC cadence drill, samosa typing, fest dance battle, quiz engine, plus mash and command QTE variants — all with keyboard and touch input |
| Inventory | Student bag on `B` / touch **Bag**: ID card, stamped fee receipt, library card and signed lab manual; **SHOW ID** clears the gate check on every day |
| Front end | Year select (2023–2025 uniforms), character select with live 3D previews, name entry, photo main menu, 10-card level grid, loading screen |
| UI | Anchored HUD (mission, wallet, energy, minimap, prompts, subtitles, toasts), pause menu, touch layout with a virtual stick |
| Audio | The web build's original voice clips; **no music** |
| Modes | `--check` scripted tour, `--beauty` / `--beauty-low` screenshot passes, `--touch-preview` phone layout, `--menu-shot` menu captures, `--low-poly` phone profile on desktop |

## Controls

### Keyboard and mouse

| Input | Action |
| --- | --- |
| `W` `A` `S` `D` / arrow keys | Move |
| `Shift` | Run |
| Mouse drag | Orbit the camera |
| `Q` / `Z` | Turn the camera left / right |
| `E` | Talk / use / advance dialogue |
| `G` | Salute |
| `B` | Open the student bag (show ID during gate checks) |
| Mouse move / drag | Aim the basketball shot |
| Click / `Space` | Throw the basketball (or use the on-screen THROW button) |
| `Esc` | Pause |

### Touch

Left thumb stick to move, drag anywhere on the right to look, and the on-screen
`E`, `G`, `RUN` and `BAG` buttons. The touch layer only appears on touch devices
(or with `-- --touch-preview`), and only once a level has started — the menus and
level grid stay clean. In the basketball shootout, drag to aim and tap the
**THROW** button.

## Performance

The frame rate is protected on every platform. MSAA is off, and the game ships
two quality profiles:

- **Desktop (Forward+)** starts at **0.88**. If the game stays below **58 fps**
  for three seconds the ladder steps the 3D scale to **0.78 → 0.68 → 0.60**,
  turns SSAO and volumetric fog off, switches to one shadow split and finally
  turns the sun shadow off.
- **Phone / web-touch / `--low-poly`** starts at **0.60**, replaces the Sky3D
  atmosphere with a cheap procedural sky and depth fog, uses one 64 m shadow
  split with no tree shadows, disables glow / SSAO / volumetric fog, and runs
  the reduced-density low-poly prop set (83 trees, 72 bushes, 1,680 grass cards,
  50 cars, 45 % ground cover). If needed it steps to **0.54 → 0.50 → 0.46** and
  then drops the shadow.

Measured on a Windows 11 laptop with an AMD Radeon integrated GPU (1080p,
Forward+, D3D12), with `tests/bench.gd`:

| Run | Scale | fps avg | Frame p50 | Draw calls | Primitives |
| --- | --- | --- | --- | --- | --- |
| Desktop full quality, spawn | 0.88 | 21.3 | 47.0 ms | 1,150 | 3.11 M |
| Desktop full quality, court | 0.88 | 27.0 | 36.6 ms | 548 | 3.01 M |
| Desktop after the ladder, spawn | 0.60 | 41.7 | 23.9 ms | 667 | 1.89 M |
| Desktop after the ladder, court | 0.60 | 46.2 | 21.2 ms | 385 | 1.45 M |
| Phone profile, eight hotspots | 0.60 | 61.6–89.0 | 11.1–15.7 ms | 324–984 | 0.78–1.68 M |

The phone profile was measured at all eight bench viewpoints on the same laptop,
standing in for a low-end handset: spawn 72.4, gate 73.3, admin 71.6, parade
61.6, parking 89.0, court 82.5, canteen 86.1 and lawn 72.5 fps. The integrated
desktop GPU does not hold 60 fps at full desktop quality, so the ladder takes it
to 0.60; a discrete GPU stays at 0.88. The full plan, budgets and knob list are
in [`tests/PERFORMANCE.md`](tests/PERFORMANCE.md).

## Build

Godot **4.7.2** and the matching export templates are required. The presets are
already in `export_presets.cfg`.

```powershell
$GODOT = "C:\Users\AKHILBOSS\Desktop\Godot_v4.7.2-stable_win64.exe"
$PROJ  = "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project"

# Web (GitHub Pages) — writes build/web/
& $GODOT --headless --path $PROJ --export-release "Web" "$PROJ\build\web\index.html"
New-Item -ItemType File -Path "$PROJ\build\web\.nojekyll" -Force

# Android — writes a signed arm64 release APK
& $GODOT --headless --path $PROJ --export-release "Android" "$PROJ\build\anits.apk"
```

The shipped APK is `build/ANITS-College-Simulation-v1.0.apk`
(115.6 MB, `com.akhilboss.anits`, version 1.0, minSdk 24, targetSdk 36,
arm64-v8a, signed with the debug keystore). Its SHA-256 is
`534afcf3d09c05b916ba87caf3d54002ccd84aceac957653e5e1790bfddaba6b`.

## Run and verify

```powershell
# play from source
& $GODOT --path $PROJ

# headless gate: import, 142 unit checks, smoke run, scripted tour
powershell -ExecutionPolicy Bypass -File "$PROJ\verify.ps1"

# benchmark
& $GODOT --path $PROJ --script res://tests/bench.gd -- `
    --bench-profile=desktop --bench-spot=spawn --bench-warmup=14 --bench-seconds=5
```

`verify.ps1` currently reports **142 checks, 0 failures**. The suite walks every
day's real mission step machine (gate ID checks, NPC talks, plan and world-space
objectives, salutes, checks, minigame wins), drives each minigame's win path and
checks the interiors, inventory and persistence. The tour walks the whole Day 1
route while writing the screenshots in `docs/screenshots/godot/`.

## Screenshots

| | |
| --- | --- |
| ![Main gate](docs/screenshots/godot/beauty/01_main_gate.png) | ![Campus aerial](docs/screenshots/godot/beauty/10_campus_aerial.png) |
| Main gate and entrance boulevard | Campus aerial with the perimeter road |
| ![Central Library](docs/screenshots/godot/beauty/13_central_library.png) | ![Campus Canteen](docs/screenshots/godot/beauty/15_campus_canteen.png) |
| Central Library interior | Campus Canteen interior |
| ![Room 204](docs/screenshots/godot/beauty/14_classroom_204.png) | ![Level select](docs/screenshots/godot/menu_levels.png) |
| Room 204 interior | Level select — 5 × 2 Day cards |
| ![Desktop court](docs/screenshots/godot/beauty/07_basketball.png) | ![Phone-profile court](docs/screenshots/godot/beauty_low/07_basketball.png) |
| Desktop full quality — basketball court | Phone profile (`--low-poly`) — the same court |

More in [`docs/screenshots/godot/`](docs/screenshots/godot/), including the
full low-poly set in
[`docs/screenshots/godot/beauty_low/`](docs/screenshots/godot/beauty_low/).

## Project layout

| Path | What it is |
| --- | --- |
| `src/main.gd` | root scene: environment, campus, player, NPCs, HUD, mission, adaptive quality, capture modes |
| `src/autoload/` | `game_state`, `mission_runner`, `dialogue_service`, `voice_bank`, `settings`, `campus_db`, `event_bus`, `save_system` |
| `src/world/` | campus geometry, props and materials, character rigs, original model loader, four interiors |
| `src/actors/` | player controller + camera boom, NPC rigs and routes |
| `src/ui/` | HUD, touch controls, minigames, inventory, main menu and level grid |
| `src/data/` | campus layout, NPC tables, economy (ported from the web build) |
| `third_party/anits_original/` | the original models, textures and 632 voice clips |
| `tests/` | `run_tests.gd`, `bench.gd`, `PERFORMANCE.md` |
| `docs/` | screenshots, report source and PDF, deployment and design notes |

## Deployment

- **Source** lives on `main`.
- **Playable web build** lives on the `gh-pages` branch and is served by GitHub
  Pages from the branch root. `build/web/` is intentionally not tracked on
  `main`.
- Redeploy = rebuild `build/web`, copy it to a temporary repo, add `.nojekyll`,
  and push `HEAD:gh-pages`. The full recipe, including the SSH deploy-key
  workaround for GitHub's 100 MB / timeout limits, is in
  [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

## Report

A 34-page technical report covering the port — architecture, campus and roads,
character pipeline, walk cycle, uniforms by joining year, UI, touch controls,
rendering, performance, testing and deployment — is at
[`docs/ANITS_Godot_Report.pdf`](docs/ANITS_Godot_Report.pdf) (37.8 MB). The
source is [`docs/report/report.html`](docs/report/report.html); rebuild it with
`docs/report/build_report.ps1`.

## Credits and licensing

The 3D models, textures and voice clips are the original ANITS web game's assets
and remain the property of their authors; they are included here for this port
only. Engine, sky and third-party asset licences are catalogued in
[`docs/EXTERNAL_ASSET_LIBRARY.md`](docs/EXTERNAL_ASSET_LIBRARY.md) and
[`docs/ASSET_MAPPING.md`](docs/ASSET_MAPPING.md).
