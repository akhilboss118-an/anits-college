# RECONSTRUCTION_ROADMAP.md — build plan for the Godot 4 rebuild

**Goal:** a faithful, playable Godot 4 rebuild of *ANITS College Simulation* that runs on
Windows (primary) and Android (secondary) at 60 FPS on the reference machine
(Ryzen 5 7530U / 16 GB / Radeon integrated).

**Two rules govern the whole plan**

1. **Fidelity beats polish.** Every number, position, colour, line and timing comes from the
   verified documentation in this folder. Nothing is "improved" without a written reason.
2. **No new content.** The rebuilt game has the same 17 buildings, the same 64 NPCs, the same
   10 days and the same dialogue. Do not add a gym, a hostel or a day/night cycle.

**Estimates** are in working days for one developer and are **[P] proposed**, not commitments.

---

## Milestone overview

| Phase | Theme | Days | Gate to pass |
|---|---|---|---|
| 0 | Groundwork: data, tooling, skeleton | 3 | The project opens, the data loads, the unit tests run |
| 1 | World shell: ground, roads, walls, gates | 4 | The player can walk from the spawn to the gate and is stopped by the closed gate |
| 2 | Player controller + camera rig | 4 | Movement, run, boost, camera avoidance, interaction radii match the original |
| 3 | The 17 buildings + the 3 special structures | 8 | Every footprint/height matches `BUILDING_INVENTORY.md`; the Admin corridor works |
| 4 | Vegetation + street props + the parking lot | 5 | The campus matches the screenshots at the same camera positions |
| 5 | NPCs + dialogue + voice | 6 | All 64 NPCs exist with the right positions; every scripted line plays |
| 6 | Mission runner + Day 1 + the HUD | 5 | Day 1 can be played start to finish in ~6 minutes |
| 7 | Days 2–10 + minigames + economy + items | 8 | All ten days are completable; the shop, bank and vending machines work |
| 8 | Menus, pause, touch, calls, credits, saves | 5 | The full front end works on desktop and Android |
| 9 | Performance, Android export, parity QA | 6 | 60 FPS on the reference machine; the parity screenshots match |
| | **Total** | **54** | |

---

## Phase 0 — Groundwork (3 days)

| ID | Task | Deliverable | Acceptance criteria |
|---|---|---|---|
| 0.1 | Create the folder structure | `src/…` tree from `GODOT_ARCHITECTURE.md` §1 | The Godot editor opens the project without errors |
| 0.2 | Write `campus_data.json` | buildings / roads / zones / walls / gates / props | A unit test asserts 17 buildings, 8 roads, 3 zones, 6 wall segments, 2 gates |
| 0.3 | Write `npcs.json`, `drinks.json`, `noodles.json` | the full data set | A test asserts 64 NPCs and the exact prices/energies from `GAME_ANALYSIS.md` §9 |
| 0.4 | Copy the dialogue data | `clips.json` (340), `clips_girl.json` (310), `callpool.json` | The text matches the original line-for-line |
| 0.5 | `campus.gd` helpers | `map_to_world`, `world_to_map` | Round-trip test: `world_to_map(map_to_world(p)) == p` |
| 0.6 | `lcg.gd` | the original's 16807 LCG with seed 5 | Reproduces the original's first 150 tree positions |
| 0.7 | Autoloads | `EventBus`, `GameState`, `Settings`, `SaveSystem` | A headless test can set and read the profile |
| 0.8 | Third-party import | the CC0 packs into `third_party/` with their licences | The credits screen lists every pack |

---

## Phase 1 — World shell (4 days)

| ID | Task | Deliverable | Acceptance criteria |
|---|---|---|---|
| 1.1 | Ground plane + the lawn colour | `ground.tscn` | 217 × 262 m, flat, `#7fb069`-ish |
| 1.2 | The 8 road rectangles | `roads.gd` | Each road matches the map rect; the median strip is present on road 5 |
| 1.3 | The yellow/white kerb blocks | one `MultiMesh` | 1.5 m long, 0.5 m wide, 0.14 m high, skipped inside buildings and at crossings |
| 1.4 | The 6 perimeter walls | 2.4 m sandstone walls | The player cannot leave the campus except through the gate road |
| 1.5 | The main gate | pillars + two hinged leaves + the centre panel | Closed at the start of Day 1; opens on approach after step 1; the colliders follow the leaves |
| 1.6 | The Back Gate | two pillars + a lintel + the yellow label | At map (236, 98); the road passes through it |
| 1.7 | The raised west footpath | +0.25 m pavement + kerb | The Magic Spot / Gate Canteen / Bank sit on it; the player can step up onto it |
| 1.8 | The sand field + its kerb path | `sand` zone | The NCC ground reads as a sand field |

---

## Phase 2 — Player + camera (4 days)

| ID | Task | Deliverable | Acceptance criteria |
|---|---|---|---|
| 2.1 | `player.tscn` + `player.gd` | `CharacterBody3D` | Walk 2.4, run 5.6, boost ×1.3, no jump, step-up 1.3 m, speed smoothing `dt*9` |
| 2.2 | The camera rig | `player_camera.gd` | Distance 5.4 (3.2 dialogue / 3.4 office), height +1.5, look at +1.35, pitch clamp 0.05–1.1 |
| 2.3 | Building avoidance | the 0.4 m step-down to 1.2 m | The camera never enters a building |
| 2.4 | The Admin-hall clamp | X/Y clamping inside the corridor | The camera stays in the corridor while the player is in the hall |
| 2.5 | Mouse + `Q`/`Z` + `I` invert | input handling | Sensitivity 0.006 / 0.004, `Q`/`Z` 1.8 rad/s, `I` toggles the pitch sign |
| 2.6 | The spawn | world (−65.1, 0, 138.6), yaw π | The player starts outside the gate facing the college |
| 2.7 | The interaction resolver | `interaction_resolver.gd` | The priority chain (shop → drink → sit → office door → service → machine → bench → NPC) behaves as in §6 of the architecture doc |

---

## Phase 3 — Buildings (8 days)

| ID | Task | Deliverable | Acceptance criteria |
|---|---|---|---|
| 3.1 | The low-poly row builder | `lowpoly_row.tscn` | Fills a plot with *n* bays, all doors on one face; used by Mechanical (9), IT (6), Civil N (2), Civil S (4), CSM (3) |
| 3.2 | The panel-house builder | `panel_block.tscn` | CSE/ECE/EEE/Chemical, 11.5 m, door on the correct side, procedural door + canopy + steps, per-building tint |
| 3.3 | The Admin Block | `admin_block.tscn` | 94.5 × 28 m, h 12, 9.76 m corridor open at both ends, statue, porch columns, rooftop "ANITS ADMIN BLOCK" sign, "ADMISSIONS OFFICE" and "BOOK HALL" signs |
| 3.4 | The Admin Office annex | `office_Annex.tscn` | Waiting room, 4 sofas, rug, table, plants, shelves with books, fridge, 2 visitor chairs, desk, toilet, sliding glass doors, 6 signs, the 10 s wait + the red lamp |
| 3.5 | The Stair Auditorium | `stair_auditorium.tscn` | Walkable tiers/ramp/ring; the player's height follows the tiers |
| 3.6 | The café, the bank, the workshop | 3 scenes | The café keeps its three striped awnings and the "CAFE" sign; the bank keeps the glass pane |
| 3.7 | The noodle bar (Magic Spot) | `noodle_bar.tscn` | "NOODLE" sign, counter, the interaction ring |
| 3.8 | The temple | **keep the original** (CC-BY-4.0) | The credit line stays in the credits strip |
| 3.9 | The Open Auditorium + the substation | 2 scenes | The pavilion faces west; the substation has the plinth, the red band, the transformers and the fenced yard |
| 3.10 | The building labels | 17 `Label3D`s | The exact `BLD` names, 3.5 m above each roof |
| 3.11 | Collision boxes | one `StaticBody3D` per mass | The player cannot enter any building; can climb the 1.3 m kerbs |

---

## Phase 4 — Vegetation & props (5 days)

| ID | Task | Deliverable | Acceptance criteria |
|---|---|---|---|
| 4.1 | The seeded scatter | `vegetation.gd` | 150 trees (74 % broadleaf / 26 % pine), 130 bushes, the same positions as the original (seed 5) |
| 4.2 | Grass tufts | 46 `MultiMesh` chunks | 6,923 instances; chunks hidden beyond 130 m; a gentle sway |
| 4.3 | The 14 lamp posts | 1 `MultiMesh` | The exact positions from `ENVIRONMENT_ASSET_INVENTORY.md` §3 |
| 4.4 | The 7 benches + 4 office seats | `bench.tscn` | Sitting works; 11 seats total |
| 4.5 | The 4 vending machines | `vending_machine.tscn` | The exact stock lists and prices; the label billboard within 26 m |
| 4.6 | The parking lot | `parking_lot.tscn` | 4 rows × 41 stalls, 91 cars, the painted lines, the planters, the entrance arch |
| 4.7 | The basketball court | `basketball_court.tscn` | The 28 × 15 m painted court, the hoop (rim 3.05 m, board 1.84 m), the ball (r 0.1195 m) |
| 4.8 | The flag + the gattu trees | 3 scenes | The 14 m pole with a 4.2 × 2.8 m waving flag |

---

## Phase 5 — NPCs & dialogue (6 days)

| ID | Task | Deliverable | Acceptance criteria |
|---|---|---|---|
| 5.1 | The NPC base | `npc_capsule.tscn` / `npc_student.tscn` / `npc_girl.tscn` | Idle + walk + talk states; the capsules animate their arms |
| 5.2 | The 6 main NPCs | placed exactly as tabulated | Correct names, colours, facings, heights |
| 5.3 | The 18 cadets | 1 `MultiMesh` formation | 3 rows × 6 on the sand field; they salute together |
| 5.4 | The 29 students + Remy | instanced | The 9 route students, the 10 named walkers, the 8 standing groups, Remy's 9-point route |
| 5.5 | The 9 girl NPCs | 9 instances | The exact names, heights, tints, routes and lines |
| 5.6 | The dialogue service | `dialogue_service.gd` | One line at a time, auto-advance, `E` to skip; the 9 voice profiles; the Telugu captions |
| 5.7 | The "Jai Hind!" chorus | the chorus maths | Per-cadet pitch, 850–1300 ms stagger, distance volume |
| 5.8 | The chat system | the post-dialogue chat | The optional free chat after a line ends |

---

## Phase 6 — Mission runner + Day 1 + HUD (5 days)

| ID | Task | Deliverable | Acceptance criteria |
|---|---|---|---|
| 6.1 | `mission_step.gd` / `mission_day.gd` | the step schema | Matches the `levels.js` schema 1:1 |
| 6.2 | `mission_runner.gd` | the state machine | `npc` / `at` / `salute` / `mini` / `chk` steps resolve correctly |
| 6.3 | The objective marker | the golden beam + ring | Follows the current objective |
| 6.4 | The HUD | mission panel, subtitles, dialogue, wallet, energy, minimap | Matches the original's layout and values |
| 6.5 | The minimap | the baked static map + the player marker | Green base, grey roads, sand, court, 17 building rects |
| 6.6 | Day 1 | the 8 steps | Playable in ≈6 minutes; the gate opens at the right moment |
| 6.7 | The day-complete overlay | the completion screen + the item grant | Grants the ID card on Day 1, the fee receipt on Day 2, the library card on Day 4 |

---

## Phase 7 — Days 2–10, minigames, economy (8 days)

| ID | Task | Deliverable | Acceptance criteria |
|---|---|---|---|
| 7.1 | The economy | wallet, bank, fees | Start ₹200 / ₹2000; the fee is ₹250; the ATM presets are 100/200/500/1000 + custom |
| 7.2 | The energy system | 40 → 100 | Only drinks (+20/+35) and noodles (+20…+50) raise it; nothing drains it |
| 7.3 | The shop panel | one panel for 3 shop types | Keys 1–5, `E`/`Esc` to close |
| 7.4 | The drink animation | can → tray → hand → drink | The energy bar pops; the "drinks tried" counter updates |
| 7.5 | The noodle bar + the spicy effect | the red vignette | Buldak triggers it |
| 7.6 | The 4 minigames | shootout / command / mash / quiz | The exact win conditions (3/5, 6/8, 7/10, 25 in 8 s, 2/3, 3/4) |
| 7.7 | The quiz data | the 7 questions | Verbatim from `levels.js` |
| 7.8 | Days 2–10 | 9 mission chains | Every step, line and gate condition matches `GAME_ANALYSIS.md` §4 |
| 7.9 | The inventory | the 3 items + the SHOW prompt | The gate check opens the bag in "ask" mode |
| 7.10 | The phone calls | the call overlay + the pool | Auto-call after 18–38 s, only while the step index is in range |

---

## Phase 8 — Front end, platform, polish (5 days)

| ID | Task | Deliverable | Acceptance criteria |
|---|---|---|---|
| 8.1 | The menu flow | intro → year → character → name → welcome → main → levels → loading | Identical to the original, including the 12 rotating quotes |
| 8.2 | The character previews | the live 3D cards | The real models animate on the cards with the selected year's uniform |
| 8.3 | The pause menu | resume / restart / level select / settings | `Esc`/`P`, sliders, the EN/TE subtitle switch |
| 8.4 | The touch controls | 2 sticks + 6 buttons | The move stick, the look stick, `E`, `G`, `SIT`, `RUN`, `BAG`, full-screen |
| 8.5 | The save system | per-day autosave | Every 4 s + on focus loss; validated on load |
| 8.6 | The credits | the asset credits + the temple attribution | Matches the `EXTERNAL_ASSET_LIBRARY.md` §9 template |
| 8.7 | The Android build | an APK | Landscape, ≤ 150 MB, runs on a mid-range phone |

---

## Phase 9 — Performance & parity QA (6 days)

| ID | Task | Deliverable | Acceptance criteria |
|---|---|---|---|
| 9.1 | Profiling | a Godot profiler capture on the reference machine | < 180 draw calls, ≤ 6 ms CPU, ≤ 8 ms GPU |
| 9.2 | The quality presets | low / medium / high | Android uses `low`; the reference laptop uses `medium` |
| 9.3 | Dynamic resolution | `scaling_3d_scale` driven by the frame time | Holds 60 FPS when the player is in the dense areas |
| 9.4 | Parity screenshots | the same 12 camera positions as `docs/screenshots/` | Side-by-side comparison, differences explained |
| 9.5 | The data parity test | an automated check | Every building/NPC/prop count matches the documentation |
| 9.6 | The playthrough test | a scripted Day 1 | Asserts the HUD text, the camera distance and the unlock flow |

---

## Risk register

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | The original models turn out to be unlicensed → the campus has to be re-modelled | **High** | High | The mapping already assumes CC0 replacements; the original is only a reference |
| 2 | The 632 voice clips cannot be reused | High | Medium | Ship with TTS + subtitles; offer re-recording as an add-on |
| 3 | The Admin Block corridor is mis-modelled → the camera clips and the office breaks | Medium | High | Build the corridor first, in isolation, and test the camera inside it |
| 4 | Integrated-GPU performance below 60 FPS | Medium | High | MultiMesh everything, dynamic resolution, the quality presets in the architecture doc |
| 5 | The mission schema drifts from `levels.js` | Medium | High | Port the schema literally; keep the original's step order and conditions in the data files |
| 6 | The Android build runs out of memory | Medium | Medium | GLB compression, OGG audio, texture import presets per platform, ≤ 150 MB APK |
| 7 | The day/night system or a jump gets "added" by accident | Low | Medium | The review checklist below |
| 8 | The campus grows new buildings | Low | High | The building count is asserted by a unit test (17) |

---

## Definition of done (per feature)

- [ ] The behaviour matches the documented original (values, timings, radii, order).
- [ ] The data comes from `campus_data.json` / `npcs.json` / the mission resources — not from
      hard-coded values in a script.
- [ ] It works on the touch layout as well as the keyboard/mouse layout.
- [ ] It is covered by a headless test (data) or a parity screenshot (visuals).
- [ ] It respects the performance budget (no new draw-call spikes; props are `MultiMesh`).
- [ ] Nothing was invented: no new buildings, NPCs, items, days or dialogue.

---

## "Do not do" list (read this before changing the design)

| ✗ Do not | Why |
|---|---|
| Add a day/night cycle | The original explicitly removed it ("day/night cycle removed") — the campus is a fixed bright daytime |
| Add jumping, sprint-stamina or a hunger bar | The original has no jump, and energy only ever goes up |
| Add new buildings to make it "more like the real college" | The rebuild reproduces the **game's** campus |
| Re-colour the uniforms "to look nicer" | The three year uniforms are part of the identity |
| Change the mission order or the dialogue wording | They are verified against the original |
| Ship the original models without a licence check | Only the temple has a public licence |
| Remove the building labels | They are how a first-time player navigates |

---

## Cross-references

[`GAME_ANALYSIS.md`](GAME_ANALYSIS.md) (the behaviour to reproduce) ·
[`GODOT_ARCHITECTURE.md`](GODOT_ARCHITECTURE.md) (the technical design) ·
[`ASSET_MAPPING.md`](ASSET_MAPPING.md) (what to build with) ·
[`CAMPUS_MAP.md`](CAMPUS_MAP.md) (the data) ·
[`MISSING_INFORMATION.md`](MISSING_INFORMATION.md) (the open questions).
