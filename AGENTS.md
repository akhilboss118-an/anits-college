# ANITS College Simulation - Godot 4 port

**Engine:** Godot **4.7.2 stable** (official build), GDScript only.
**Binary used on this machine:** `C:\Users\AKHILBOSS\Desktop\Godot_v4.7.2-stable_win64.exe`

This project is a faithful port of the original web game
(`ANITS-WEB GAME/`) to Godot 4: same campus, same Day 1 flow, same voices,
no music. Everything is low-poly and built to hold 60 fps on phones.

## Ground rules for agents

1. **Never edit `.godot/`** - it is a regenerable cache.
2. **Never hand-edit `.tscn` blindly** - the scenes here are generated at runtime
   from data (see `src/data/*.json`), so most "scenes" are code.
3. **Validate headlessly after every edit** (see the gate below). An edit that was
   never parsed is not done.
4. **No per-frame allocations** in `_process` / `_physics_process`
   (no `get_nodes_in_group()` per frame, no string building per frame).
5. **Keep the public API of the shared modules stable** - `main.gd`, `hud.gd`,
   `touch_controls.gd`, `player.gd`, `npc.gd` and the autoloads are consumed by
   each other; grep for the call sites before renaming anything.
6. **GL Compatibility (web/mobile) safe**: no `Light3D.shadow_update_mode`, no
   depth textures, no screen-reading shaders, no `AudioStreamPlayer3D`.

## The validation gate (run this after every batch of edits)

```powershell
$GODOT = "C:\Users\AKHILBOSS\Desktop\Godot_v4.7.2-stable_win64.exe"
$PROJ  = "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project"

& $GODOT --headless --path $PROJ --import                      # full import
& $GODOT --headless --path $PROJ --script res://tests/run_tests.gd   # 57 checks
& $GODOT --path $PROJ --resolution 1600x900 --quit-after 5000 -- --check   # tour + screenshots
& $GODOT --path $PROJ --resolution 1600x900 --quit-after 9000 -- --beauty # beauty shots
& $GODOT --path $PROJ --script res://tests/bench.gd -- --bench-label=pc --bench-seconds=15
```

`verify.ps1` runs the first three steps in one go.

## Project map

| Path | What it is |
| --- | --- |
| `src/main.gd` | root scene: environment, campus, player, NPCs, HUD, mission, `--check` / `--beauty` modes |
| `src/autoload/` | `campus_db.gd`, `mission_runner.gd`, `dialogue_service.gd`, `voice_bank.gd`, `settings.gd`, `game_state.gd`, `event_bus.gd` |
| `src/world/` | `campus_builder.gd` (geometry), `props_factory.gd` (materials), `character_visual.gd` (rigs), `original_models.gd` (web asset loader), `admin_office.gd` (interior) |
| `src/actors/` | `player.gd` (controller + camera boom), `npc.gd` (NPC rig, labels, routes) |
| `src/ui/` | `hud.gd`, `touch_controls.gd`, `main_menu.gd` |
| `src/data/` | campus layout, NPC tables, economy (verbatim from the web build) |
| `third_party/anits_original/` | the original FBX/GLB models, textures and 632 voice clips |
| `tests/` | `run_tests.gd` (57 checks), `bench.gd` (fps/draw-call harness), `PERFORMANCE.md` |
| `docs/` | screenshots, report (`docs/report/`), deployment notes |

## Coordinates

The campus is authored in **web-game plan pixels** (`src/data/campus_data.json`).
`Campus.map_to_world()` converts plan px to metres (1 plan px = 0.7 m, origin
`(215, 250)`). Never hard-code metre positions for campus content - use plan px.

## Export

* Windows: `--export-release "Windows Desktop" build/win/game.exe`
* Web (GitHub Pages): `--export-release "Web" build/web/index.html`
  (preset in `export_presets.cfg`, `gl_compatibility`, then add `build/web/.nojekyll`)
* Android: `--export-release "Android" build/android/game.apk`
  (needs the export templates and a debug keystore - see `docs/DEPLOYMENT.md`)
