# ANITS College Simulation — Godot 4 reconstruction specification

This folder is the complete, evidence-based specification for rebuilding the ANITS College
web game (**"ANITS – First Day"**, https://anits-college.vercel.app/) as a native Godot 4
project for Windows and Android.

**Status: implemented — the Godot port ships the full 10-day campaign.**
This folder remains the evidence-based specification it was built from.
Every fact in these documents was read out of the game's own source
(`ANITS-WEB GAME/`) or measured on the running build. Nothing is guessed; everything that is
genuinely unknown is listed in [`MISSING_INFORMATION.md`](MISSING_INFORMATION.md).

---

## Project status (live)

**The Godot project is running: the V2 campus, the player, the camera, all 64 NPCs, the
dialogue system, the full 10-day campaign, four walk-in interiors, five minigames and the
student bag work end to end.**

| Item | State |
|---|---|
| Godot | **4.7.2 stable** — editor at `C:\Users\AKHILBOSS\Desktop\Godot_v4.7.2-stable_win64.exe` |
| Project | `new-game-project/project.godot` — Forward+, **Jolt Physics**, D3D12, 1920×1080, main scene `src/main.tscn` |
| Autoloads | `EventBus`, `GameState`, `Settings`, `SaveSystem`, `CampusDB`, `Mission`, `Dialogue` |
| Campus | **V2 plan** (your new campus picture) in `src/data/campus_data.json` — 17 buildings, 12 roads (including the perimeter ring around the whole college), 5 zones, 6 walls, 2 gates, 1 plan px = 0.7 m (main road = 12 m) |
| NPCs | **64** in `src/data/npcs.json` (6 quest + 18 cadets + 9 route students + 3 basketball + 10 named walkers + 8 standing + Remy + 9 girls), all repositioned onto the V2 plan |
| Economy | `src/data/economy.json` — 10 drinks, 4 dishes, 3 items |
| Systems | world builder (ground/roads/kerbs/walls/gates/buildings/props/collision), player controller + third-person camera with building avoidance, NPC bodies + routes, dialogue with the original lines, mission runner, HUD (mission, dialogue, subtitles, wallet, energy, minimap, prompts, toasts), front-end menu (year → character → name → main → level select) |
| Tests | `tests/run_tests.gd` — **138 checks, 0 failures** (headless) |
| Campaign | **all 10 days play start to finish**, from the Day 1 tour through fees, Room 204, the library quiz, basketball, NCC drill, lab manual, canteen challenge and the final quiz |

### Run it

```powershell
# play it
& "C:\Users\AKHILBOSS\Desktop\Godot_v4.7.2-stable_win64.exe" --path "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project"

# headless test suite
& "C:\Users\AKHILBOSS\Desktop\Godot_v4.7.2-stable_win64.exe" --headless `
  --path "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project" --script res://tests/run_tests.gd

# scripted verification tour (walks Day 1 and saves 10 screenshots)
& "C:\Users\AKHILBOSS\Desktop\Godot_v4.7.2-stable_win64.exe" `
  --path "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project" --resolution 1600x900 -- --check
```

Screenshots from the Godot build land in `docs/screenshots/godot/`.

> `ANITS-WEB GAME/` (the reference web build) contains a `.gdignore`, so Godot does not import
> it — the project went from 1,423 imported files / 51.7 MB to 30 / 5.2 MB, and the reference
> assets can never leak into an export.

---

## The documents

| # | File | What it contains |
|---|---|---|
| 1 | [`GAME_ANALYSIS.md`](GAME_ANALYSIS.md) | The complete behaviour spec: front-end flow, Day 1 + Days 2–10 mission scripts, controls, camera, movement, interaction, HUD, economy, energy, minigames, phone calls, saves, rendering, audio |
| 2 | [`BUILDING_INVENTORY.md`](BUILDING_INVENTORY.md) | All 17 buildings with exact footprints/heights/entrances, the gate, the Back Gate, the auditorium, the substation, the court, the parking, the interiors |
| 3 | [`ENVIRONMENT_ASSET_INVENTORY.md`](ENVIRONMENT_ASSET_INVENTORY.md) | Roads, zones, 150 trees, 130 bushes, 6,923 grass tufts, 14 lamps, 91 cars, benches, vending machines, plus the complete model/texture/audio/font file inventory |
| 4 | [`CHARACTER_AND_NPC_ANALYSIS.md`](CHARACTER_AND_NPC_ANALYSIS.md) | The player (Mike/Amy, uniforms, animation set) and all **64 NPCs** with positions, colours, routes and the full verbatim dialogue |
| 5 | [`FREE_GODOT_ASSETS.md`](FREE_GODOT_ASSETS.md) | The curated CC0 replacement list per need, with the verified counts, model names and Godot import notes |
| 6 | [`EXTERNAL_ASSET_LIBRARY.md`](EXTERNAL_ASSET_LIBRARY.md) | Every external URL + the licence-verification log + the download recipes + the credits template |
| 7 | [`CAMPUS_MAP.md`](CAMPUS_MAP.md) | The coordinate system (1 map px = 0.7 m), the zone/road/waypoint tables, the navigation plan, the walk-time checks |
| 8 | [`GODOT_ARCHITECTURE.md`](GODOT_ARCHITECTURE.md) | The Godot project layout, autoloads, data schema, controller, camera, interaction, missions, UI, save, audio, performance and Android plan |
| 9 | [`ASSET_MAPPING.md`](ASSET_MAPPING.md) | Original asset → replacement, with the licence ledger |
| 10 | [`RECONSTRUCTION_ROADMAP.md`](RECONSTRUCTION_ROADMAP.md) | 10 phases, 54 estimated days, acceptance criteria, a risk register and a "do not do" list |
| 11 | [`MISSING_INFORMATION.md`](MISSING_INFORMATION.md) | Every remaining unknown, with how to close it |

**Generated artefacts**

| File | What it is |
|---|---|
| [`campus_map.svg`](campus_map.svg) | The top-down campus map, plotted directly from the game's `BLD`/`ROADS`/`SAND`/`BASK`/`NCC` tables (920 → 980 px wide, ASCII-safe labels, with a legend) |
| [`_building_table.md`](_building_table.md) | The building dimension table, generated by the same script |
| `screenshots/` | 12 real screenshots captured from the running build (headless Chrome + CDP): year select, character select, the main gate spawn, the Admin Block, the CSE Block, the IT Block, the NCC ground, the basketball court, the student parking, the temple, the Admin hall, the Gate Canteen vending machines |

---

## How the evidence was gathered

| Method | What it gave |
|---|---|
| Static reading of the shipped source (`js/game.js` 1.85 MB, `levels.js`, `menu.js`, `voice.js`, `inventory.js`, `uniform.js`, `touch.js`, `pause.js`, `story.js`, `chat.js`, `buddy.js`, `mini.js`, `save.js`, `callpool.js`, `girls.js`, `flag.js`, `cinematic.js`, `assets.js`) | Every number in the documents: tables, positions, prices, timings, radii, dialogue |
| Runtime probing of the live build (`window.__lp`, `__grass`, `__parkedCars`, `__sit`, `__admin`, `__court`, `__g`, `__saveApi`) | Bay counts, grass chunk counts, car counts, seat counts, the measured walk/run speeds |
| Headless-Chrome + CDP capture rig | The 12 screenshots and the free-camera verification shots |
| SHA-256 comparison of the live site vs the offline mirror | Proof that the offline folder is the same build |
| Publisher pages + archive `License.txt` files + the GitHub contents API | The licence verification log in `EXTERNAL_ASSET_LIBRARY.md` |

---

## Evidence tags used in these documents

| Tag | Meaning |
|---|---|
| **[V]** | Verified — read from the source or measured at runtime |
| **[O]** | Observed — visible in the captured screenshots |
| **[U]** | Unknown — not determinable; listed in `MISSING_INFORMATION.md` |
| **[P]** | Proposed — a reconstruction decision made by this spec, not a fact about the original |

---

## The 10-second orientation

- The game is a **third-person campus life-sim**: walk around an ANITS-style college, talk to
  64 characters, and complete 10 scripted "days" (fee payment, library card, basketball,
  NCC parade, lab signatures, canteen challenge, fest, first class).
- The campus is **217 × 262 m**, flat, with 17 buildings, 12 roads (including the perimeter
  ring), 5 zones, 150 trees and a 91-car parking lot.
- The money, the energy, the shop and the save system are all small and **data-driven** — the
  port is mostly a translation job, not a design job.
- The one genuinely risky area is **asset licensing**: only the temple carries a public
  licence, so the reconstruction plan replaces every other model with verified CC0 assets.
- Target: **Godot 4.7, Forward+, Jolt Physics, 60 FPS** on a Ryzen 5 7530U with integrated
  Radeon graphics, plus an Android build with a `low` quality preset.

---

## Source material

| Path | What it is |
|---|---|
| `../ANITS-WEB GAME/` | The original web build (72.6 MB of assets, 2.75 MB of scripts) — the ground truth for everything above |
| `../project.godot` | The Godot project that will host the rebuild (Godot 4.7, Forward+, Jolt Physics) |
