# GODOT_ARCHITECTURE.md — the Godot 4 rebuild

**Target project:** `new-game-project` — Godot **4.7**, Forward+ renderer, **Jolt Physics**
(the existing `project.godot` already declares both).
**Targets:** Windows (primary) and Android (secondary), 60 FPS on the reference machine.

**Reference machine (the brief's baseline):** AMD Ryzen 5 7530U (8C/16T, 2.3 GHz base, Radeon
610M/750M-class integrated graphics), 16 GB RAM, no dedicated GPU.

**Ground rules**

1. Every number in the code that describes *the original game* comes from the verified tables
   in this documentation — never from guesswork.
2. The campus is authored in **map pixels** (see `CAMPUS_MAP.md`) and converted to metres at
   load time, so the port can be diffed against the original data.
3. Third-party addons are optional; every one of them can be replaced by hand-written GDScript.

---

## 1. Project layout

```
new-game-project/
├── project.godot
├── addons/                        # optional, see §18
├── docs/                          # this documentation
├── src/
│   ├── autoload/
│   │   ├── event_bus.gd           # signals hub (no cross-node references)
│   │   ├── game_state.gd          # profile, unlocked days, items, wallet/bank/energy
│   │   ├── settings.gd            # volume, sfx, look sensitivity, subtitle language
│   │   ├── save_system.gd         # per-level autosave + profile
│   │   ├── mission_runner.gd      # the data-driven step machine
│   │   ├── dialogue_service.gd    # line lookup, TTS fallback, subtitles
│   │   ├── audio_director.gd      # buses, music/sfx/voice routing
│   │   └── scene_director.gd      # scene transitions + fade
│   ├── data/                      # authored data (JSON + .tres)
│   │   ├── campus_data.json       # buildings, roads, zones, walls, gates (map px)
│   │   ├── npcs.json              # the 64 NPCs: positions, colours, routes, lines
│   │   ├── drinks.json            # 10 drinks
│   │   ├── noodles.json           # 4 dishes
│   │   ├── clips.json             # 340 lines -> [telugu, mp3]
│   │   ├── clips_girl.json        # 310 lines
│   │   └── callpool.json          # phone-call dialogue
│   ├── resources/
│   │   ├── building_spec.gd       # Resource: rect, height, colour, model, bays
│   │   ├── mission_day.gd         # Resource: id, name, steps[]
│   │   ├── mission_step.gd        # Resource: text/at/npc/lines/ok/done/chk/mini
│   │   ├── npc_spec.gd
│   │   └── shop_item.gd
│   ├── actors/
│   │   ├── player/
│   │   │   ├── player.tscn        # CharacterBody3D + Camera rig + interact ray
│   │   │   ├── player.gd
│   │   │   ├── player_male.tscn   # variant scene (Mike)
│   │   │   ├── player_female.tscn # variant scene (Amy) + chunni
│   │   │   ├── player_camera.tscn
│   │   │   └── player_camera.gd
│   │   ├── npc/
│   │   │   ├── npc_capsule.tscn   # cadets, staff
│   │   │   ├── npc_student.tscn   # Remy-style skinned students
│   │   │   └── npc_girl.tscn
│   │   └── props/
│   │       ├── bench.tscn, lamp_post.tscn, vending_machine.tscn, planter.tscn,
│   │       ├── car.tscn, gattu_tree.tscn, flag.tscn, gate_leaf.tscn
│   ├── world/
│   │   ├── campus.tscn            # the single playable scene
│   │   ├── campus_builder.gd      # spawns everything from campus_data.json
│   │   ├── ground.gd
│   │   ├── roads.gd
│   │   ├── vegetation.gd          # seeded LCG -> MultiMesh
│   │   ├── buildings/
│   │   │   ├── admin_block.tscn   # corridor + statue + porch + office annex
│   │   │   ├── stair_auditorium.tscn
│   │   │   ├── panel_block.tscn   # CSE / ECE / EEE / Chemical
│   │   │   ├── lowpoly_row.tscn   # Mechanical / IT / Civil / CSM
│   │   │   ├── cafe.tscn, bank.tscn, workshop.tscn, temple.tscn, noodle_bar.tscn
│   │   │   └── auditorium.tscn, substation.tscn
│   │   ├── court/basketball_court.tscn
│   │   └── parking/parking_lot.tscn
│   ├── minigames/
│   │   ├── minigame_base.gd
│   │   ├── shootout.tscn/.gd      # Day 5
│   │   ├── command.tscn/.gd       # Days 6 & 9
│   │   ├── mash.tscn/.gd          # Day 8
│   │   └── quiz.tscn/.gd          # Days 4 & 10
│   ├── ui/
│   │   ├── hud.tscn/.gd           # mission, subtitles, dialogue, wallet, energy, minimap
│   │   ├── menus/menu_root.tscn   # intro/year/character/name/welcome/main/levels/loading
│   │   ├── pause_menu.tscn
│   │   ├── inventory_panel.tscn
│   │   ├── shop_panel.tscn
│   │   ├── call_overlay.tscn
│   │   ├── credits_panel.tscn
│   │   └── touch/                 # MOVE + LOOK sticks, E/G/SIT/RUN/BAG buttons
│   └── util/
│       ├── campus.gd              # map px <-> world m helpers
│       ├── lcg.gd                # the original's 16807 LCG
│       ├── camera_avoid.gd       # building-avoidance camera solver
│       └── audio_text.gd          # TTS fallback helper
├── third_party/                   # CC0 packs, each with its LICENSE file
│   ├── kenney_city_kit_roads/  kenney_city_kit_commercial/
│   ├── kenney_furniture_kit/   kenney_nature_kit/
│   ├── quaternius_ultimate_buildings/  quaternius_ultimate_nature/
│   ├── quaternius_ultimate_character/ quaternius_universal_animations/
│   ├── kaykit_character_animations/
│   └── polyhaven/  ambientcg/
└── tests/
    ├── unit/                      # headless GDScript tests
    └── parity/                    # screenshot comparisons against the web build
```

---

## 2. Autoloads

| Autoload | Responsibility | Key API |
|---|---|---|
| `EventBus` | Global signals; nothing else may hold a reference to another system | `mission_step_changed(step)`, `dialogue_started/ended`, `energy_changed(v)`, `wallet_changed(v)`, `item_gained(id)`, `day_completed(n)`, `call_started/ended`, `request_interact()` |
| `GameState` | Profile `{name, char, year}`, unlocked day, items, wallet, bank, energy | `reset_progress()`, `unlock(n)`, `give_item(id)`, `spend(n)`, `add_energy(n)` |
| `Settings` | Volume / SFX / look sensitivity / subtitle language; writes `user://settings.cfg` | `voice_volume`, `sfx_volume`, `look_sensitivity`, `subtitle_language` |
| `SaveSystem` | `user://save_level_<n>.json` + `user://profile.json`; autosave every 4 s | `save_level(n)`, `load_level(n)`, `has_save(n)`, `clear_all()` |
| `MissionRunner` | Executes the step machine (see §7) | `start_day(n)`, `current_step`, `advance()`, `is_complete` |
| `DialogueService` | Line lookup → MP3 → TTS fallback → subtitles (EN/TE) | `say(npc, text)`, `say_line(id)` |
| `AudioDirector` | Buses: `Master / Music / SFX / Voice / UI` | `play_voice(stream)`, `play_sfx(name)` |
| `SceneDirector` | Cross-fades between menu and campus | `goto_menu()`, `goto_campus(day)`, `fade_out/in()` |

**Rule:** scenes never talk to each other directly; they talk to `EventBus`. This keeps the
campus scene unloadable between days and makes the headless tests possible.

---

## 3. Data

### 3.1 `campus_data.json` (map pixels — copy the values verbatim from the verified tables)

```jsonc
{
  "scale": 0.7,
  "origin": [215, 250],
  "buildings": [
    { "name": "Mechanical Block", "rect": [101,116,226,156], "height": 10,
      "color": "#d9a07c", "model": "lowpoly_row", "bays": 9, "face": "S" },
    { "name": "CSE Block", "rect": [102,246,156,281], "height": 11.5,
      "color": "#4a8fb8", "model": "panel_block", "bays": 1, "face": "E",
      "tint": "#cfe3ff" }
    /* … all 17 entries, exactly as in BUILDING_INVENTORY.md … */
  ],
  "roads":  [[64,160,98,345], [82,345,100,432], [96,332,256,352], [106,345,139,445],
             [234,60,252,352], [100,239,236,246], [100,281,236,291], [157,157,171,285]],
  "zones":  { "sand": [146,357,249,427], "court": [260,251,340,314],
              "substation": [250,320,365,415] },
  "walls":  [[58,58,58,432], [368,58,368,432], [58,58,234,58],
             [252,58,368,58], [58,432,100,432], [145,432,368,432]],
  "gates":  [ { "id": "main", "rect": [100,432,145,432], "locked_until_step": 1 },
              { "id": "back", "center": [236,98], "half": 22 } ],
  "props":  { "lamps": 14, "trees": 150, "bushes": 130, "cars": 91,
              "benches": 7, "vending_machines": 4, "seed": 5 }
}
```

### 3.2 `npcs.json`

Each entry: `id`, `name`, `pos` (map px), `color`, `height`, `facing`, `model`
(`capsule` | `student` | `girl` | `colonel` | `clerk` | `guard`), `beret`, `route` (optional),
`lines` (idle + per-step). The 64 NPCs are enumerated in
`CHARACTER_AND_NPC_ANALYSIS.md` — copy them from there, do not re-invent them.

### 3.3 Missions

One `MissionDay` resource per day; each holds an array of `MissionStep` resources. The schema
mirrors `levels.js` exactly so the ported logic is a 1:1 translation:

| Field | Type | Meaning |
|---|---|---|
| `text` | String | the objective shown in the HUD |
| `at` | Rect2 (map px) | "walk to this area" trigger (with a radius) |
| `npc` | String | the NPC to talk to |
| `salute` | bool | the step completes when the player salutes |
| `lines` | Dictionary | `npc_id → [line, line, …]` |
| `ok` | Callable | extra gate condition (e.g. `wallet >= 250`) |
| `done` | Callable | side effect (e.g. `pay(250)`) |
| `chk` | Callable | counter condition (e.g. `drinks_tried >= 2`) |
| `mini` | Dictionary | the minigame config |
| `say` | String | a subtitle spoken when the step starts |

Days 2–10 are built as `ID_STEPS + LEVEL_STEPS`, exactly like `levels.js` does
(`Object.keys(R).forEach(k => R[k] = ID.concat(R[k]))`).

---

## 4. Player controller

`CharacterBody3D` + `Script` (or Godot Jolt's `CharacterBody3D` with `floor_max_angle`).

| Parameter | Value | Source |
|---|---|---|
| Walk speed | 2.4 m/s | `game.js` |
| Run speed | 5.6 m/s | `game.js` |
| Boost multiplier | ×1.3 (30 s) | `game.js` |
| Jump | none | `game.js` |
| Step-up | 1.3 m | `game.js` `ok()` test |
| Speed smoothing | `lerp(current, target, min(1, dt * 9))` | `game.js` |
| Collision | axis-aligned boxes, swept per axis | `game.js` `colliders` |
| Interact radius | 3.8 m (NPC) / 3.4 m (machine, service) / 2.8 m (office door) | `game.js` |

**Movement is camera-relative** exactly as in the original:

```gdscript
var fwd := Vector3(sin(cy), 0, cos(cy))
var right := Vector3(-cos(cy), 0, sin(cy))
var wish := (fwd * input_axis.y + right * input_axis.x).limit_length(1.0)
var target := (run ? 5.6 : 2.4) * (boost > 0.0 ? 1.3 : 1.0)
speed = lerp(speed, target, min(1.0, delta * 9.0))
```

The original has **no jump and no gravity ramp** — keep it that way; the whole game is
grounded walking.

---

## 5. Camera rig

Either **Phantom Camera** (MIT, verified) or a hand-written rig. The behaviour that must be
reproduced:

| Rule | Value |
|---|---|
| Distance | 5.4 m (3.2 m in dialogue / drinking / phone calls, 3.4 m inside the office) |
| Height | player `y + 1.5 m` |
| Look target | player `y + 1.35 m` |
| Pitch clamp | 0.05 … 1.1 rad |
| Mouse sensitivity | yaw 0.006 rad/px, pitch 0.004 rad/px, scaled by the `look` setting |
| Key rotate | `Q` / `Z` at 1.8 rad/s |
| Smoothing | `lerp(current, target, min(1, dt * 10))` |

**Building avoidance** (the original's algorithm, ported 1:1):

```gdscript
var d := camera_distance
while d > 1.2:
    var p := player.global_position + Vector3(0, 1.5, 0) - forward * (d * cos(pitch))
    if not solid_aabb_contains(p, campus_colliders, 0.3):
        break
    d -= 0.4                      # step the distance down, 0.4 m at a time
```

**Admin-hall clamp:** while the player is inside the Admin Block, clamp the camera X to the
corridor half-width (±4.88 m × K) and Y to ≤ 2.6 m; outside, snap Z to the hall face.
Inside the office, clamp X/Z to the room box and Y to 0.5…3.05 m.

---

## 6. Interaction system

Every interactable is an `Area3D` with a script that exposes
`can_interact(player) -> bool` and `interact(player)`. The priority chain in the original is:

```
shop open?   -> close shop
drinking?    -> ignore
seated?      -> stand up
office door  -> enter / exit          (2.8 m)
service      -> bank / noodle bar      (3.4 m, if closer than a machine and an NPC)
vending      -> open shop              (3.4 m, if closer than an NPC)
bench        -> sit                    (if closer than an NPC)
npc          -> dialogue               (3.8 m)
```

Implement it as a single `InteractionResolver` that collects all candidates, filters by
`can_interact`, sorts by distance with the priority above as the primary key, and calls the
winner. This reproduces the original's behaviour exactly (including the "the machine wins over
the NPC if you stand closer to the machine" nuance).

---

## 7. Mission system

`MissionRunner` is a small state machine over `MissionStep`s:

```
start_day(n)  -> load MissionDay n -> show step 0
step active   -> objective text in the HUD + golden beam marker at the objective
step resolves -> run done() -> advance() -> next step (or complete the day)
day complete  -> show the completion overlay, grant the item, unlock day n+1
```

Completion conditions per step type:

| Type | Resolves when |
|---|---|
| `npc` | the player finishes the dialogue with that NPC |
| `at` | the player enters the map rect (radius included) |
| `salute` | the player presses `G` within 16 m of ≥1 cadet |
| `mini` | the minigame reports success |
| `chk` | the counter condition becomes true |

**Day 1 is special**: it has no `MissionDay` resource in the original — it is hard-coded in
`game.js` as an 8-step array. Port it as a normal `MissionDay` with the same 8 steps; the
only difference is that Day 1 has **no ID-check prefix** and its gate opens after step 1.

---

## 8. Dialogue and subtitles

- `DialogueService.say(npc, text)`:
  1. look up the line in `clips.json` / `clips_girl.json` (girl bank for female NPCs and for
     the player-as-Amy case),
  2. play the MP3 (converted to OGG) at `Settings.voice_volume`,
  3. show the subtitle, in English or Telugu (`Settings.subtitle_language`),
  4. if no clip exists, fall back to TTS (Godot has no built-in TTS — use the OS TTS on
     Windows via `DisplayServer.tts_*` if available, otherwise show the subtitle for the
     original's estimated duration: `max(1200, len*58+600) ms`).
- Dialogue is **one line at a time**, auto-advancing; `E`/click skips to the next line.
  This is what makes the conversations feel fast — keep it.
- The NCC "Jai Hind!" chorus: play the clip N times with a per-cadet `pitch_scale`
  (0.88–1.08 male / 0.96–1.08 female) and a distance-based volume
  `clamp(1.15 - d/20, 0.25, 1) * 0.6`, staggered by 850–1300 ms.

---

## 9. Minigames

All four share a `MinigameBase` (a `CanvasLayer` overlay + a `signal completed(success)`).

| Minigame | Implementation |
|---|---|
| `shootout` (Day 5) | The camera walks the player to the free-throw line facing the nearest hoop; a power bar oscillates; `SPACE` releases; the ball is a `RigidBody3D` with a rim/backboard response. Target: 3 of 5. |
| `command` (Days 6, 9) | Arrow keys are called out (the parade: ↑ ← →; the dance: ↑ ↓ ← →). 1.7 s (parade) / 1.4 s (dance) per prompt. Target: 6 of 8 / 7 of 10. |
| `mash` (Day 8) | `SPACE` mashing, 25 hits in 8 s, with a progress bar and a per-hit sound. |
| `quiz` (Days 4, 10) | 4 options, 2 of 3 / 3 of 4 correct, with the exact question and answer sets from `levels.js`. |

---

## 10. UI

`docs`-sized UI spec:

| Screen | Node | Contents |
|---|---|---|
| HUD | `hud.tscn` (CanvasLayer) | mission panel (top-left), subtitle strip, dialogue box, wallet strip, energy bar, minimap (bottom-right), touch controls (bottom corners on mobile) |
| Front end | `menu_root.tscn` | intro, year slider, character cards with **live 3D previews**, name entry, welcome, main menu, level grid, loading screen |
| Pause | `pause_menu.tscn` | Resume / Restart Level / Level Select / Settings (voice, effects, look sliders) + subtitle language EN/TE. Opens with `Esc`/`P`; sets `get_tree().paused`. |
| Inventory | `inventory_panel.tscn` | 3 slots (ID card, fee receipt, library card) + the **SHOW** prompt at the gate |
| Shop | `shop_panel.tscn` | shared by the vending machines, the bank and the noodle bar |
| Call | `call_overlay.tscn` | incoming-call ring, Decline/Accept, captions, End call |
| Spicy | part of `hud.tscn` | red vignette + "SPICY!!" for the Buldak noodles |
| Credits | `credits_panel.tscn` | the permanent temple attribution + the new asset credits |

The web build's visual identity (dark navy `#031330`, cyan accents `#3aa0ff`, gold `#ffd54a`,
`Figtree` + `Bricolage Grotesque`) must be carried over — it is part of the ANITS identity.

---

## 11. Save system

| What | Where | Format |
|---|---|---|
| Profile | `user://profile.json` | `{name, char, year, unlocked}` |
| Items | `user://items.json` | `{"id":1,"fee":1,"lib":1}` |
| Settings | `user://settings.cfg` | `ConfigFile` |
| Per-day state | `user://save_day_<n>.json` | `{wallet, bank, energy, step, pos, yaw, time}` |

- Autosave every **4 s** and on `NOTIFICATION_WM_CLOSE_REQUEST` / `NOTIFICATION_APPLICATION_PAUSED`
  / focus-out — mirroring the web build's `beforeunload`, `pagehide`, `visibilitychange`.
- Validate every field on load (the original's `valid()` bounds-checks the wallet, the bank,
  the energy 0–100, the step index and the position); discard invalid payloads.
- Android: write to `user://` (the app's private dir) so a background kill does not lose data.

---

## 12. Audio

| Bus | Content |
|---|---|
| `Master` | everything |
| `Voice` | the 632 line clips (`AudioStreamPlayer3D` for 3D NPC lines, 2D for the player) |
| `SFX` | the synthesised UI sounds (re-implement with `AudioStreamGenerator` or short procedurally generated buffers) |
| `Music` | **empty in the original** — add an ambient track only if the client wants it (see `MISSING_INFORMATION.md`) |
| `UI` | menu clicks, transitions |

Distance attenuation for the voice clips: `attenuation_model = inverse`, `max_distance = 40`.

---

## 13. Rendering & lighting parity

| Original (Three.js) | Godot equivalent |
|---|---|
| Hemisphere light `#dcefff` / `#6d8a5a` @ 0.66 | `DirectionalLight3D` + `WorldEnvironment` ambient (`ambient_light_source = Sky`, `ambient_light_energy = 0.66`, `ambient_light_sky_contribution = 1`) |
| Directional sun `#ffeccb` @ 0.78 | `DirectionalLight3D`, `light_color = #ffeccb`, `light_energy = 0.78`, `shadow_enabled = true` |
| Shadow 2048², ortho ±60 m, far 300 | `shadow_mode = PSSM_2_SPLITS`, `directional_shadow_max_distance = 130`, `directional_shadow_mode = ORTHOGONAL` (or 4 splits for the high preset), `shadow_bias = 0.0006` |
| Fog `#d8edf8`, linear 170 → 540 m | `Environment.fog_mode = FOG_MODE_DEPTH`, `fog_light_color = #d8edf8`, `fog_depth_begin = 170`, `fog_depth_end = 540`, `fog_density = 0` |
| Sky dome gradient + sun glow | `ProceduralSkyMaterial` (`sky_top_color #2f86de`, `sky_horizon_color #d8edf8`, `ground_bottom_color #7fb069`) or the original's `ShaderMaterial` ported 1:1 |
| Drifting clouds | A `MultiMesh` of billboard quads that scrolls and re-centres on the camera |
| `MeshLambertMaterial` | `StandardMaterial3D` with `specular_mode = disabled`, `roughness = 1`, `metallic = 0` |
| Vertex-coloured cars/trees | `StandardMaterial3D` with `vertex_color_use_as_albedo = true` |

---

## 14. Performance plan (Ryzen 5 7530U, 60 FPS @ 1080p)

### 14.1 Draw-call budget

| Category | Technique | Budget |
|---|---|---|
| Buildings (17 + 3 special) | one `MeshInstance3D` per building, merged materials | ≤ 60 draw calls |
| Roads, kerbs, parking paint | **one `MultiMeshInstance3D` per colour** | 6 draw calls |
| Grass (6,923 instances) | 46 chunks → `MultiMeshInstance3D` per chunk, chunk visible only within 130 m | ≤ 24 visible |
| Trees (150) | 2 `MultiMeshInstance3D` (broadleaf / pine) | 2 |
| Bushes + flowers (130 + flowers) | 2 `MultiMeshInstance3D` | 2 |
| Cars (91) | 4 `MultiMeshInstance3D` (one per body type) | 4 |
| Lamp posts, benches, planters, vending machines, gattu trees | one `MultiMeshInstance3D` per type | ≤ 10 |
| NPCs (64) | the 18 cadets → 1 `MultiMeshInstance3D`; the 29 students → 1 `MultiMesh` per LOD; the 9 girls → 9 skinned meshes | ≤ 40 |
| **Total** | | **< 180 draw calls** |

### 14.2 Quality presets

| Setting | `low` (Android) | `medium` (iGPU) | `high` (desktop) |
|---|---|---|---|
| Renderer | Compatibility (GLES3) | Forward+ (Vulkan/D3D12) | Forward+ |
| MSAA | off | 2× | 4× |
| Shadow atlas | 2048, 1 split | 2048, 2 splits | 4096, 4 splits |
| `scaling_3d_scale` | 0.6 – 0.75 | 0.85 – 1.0 | 1.0 |
| SSAO / SSR / SDFGI | off | off | SSAO only |
| Volumetric fog | off | off | on (0.2 density) |
| Grass draw distance | 60 m | 100 m | 130 m |
| NPC update rate | 10 Hz | 20 Hz | 30 Hz |

### 14.3 Frame-time targets (1080p, medium preset, integrated GPU)

| Item | Budget |
|---|---|
| CPU (scripts, AI, physics) | ≤ 6 ms |
| GPU (draw + shading) | ≤ 8 ms |
| Total frame | ≤ 16.6 ms (60 FPS) |

**Levers if the frame rate drops** (in order):
1. `scaling_3d_scale` (dynamic resolution) — biggest win, invisible in motion.
2. Reduce the grass draw distance, then the tree `VisibilityRange`.
3. Reduce the shadow distance / splits.
4. Disable SSAO.

### 14.4 CPU budget rules

- **No per-frame `get_node`/`find_child`** — cache everything in `_ready`.
- **No per-frame allocations** in `_process` — reuse arrays; avoid `duplicate()`.
- NPCs: update their movement at 10–20 Hz (stagger the updates across frames), not every frame.
- Use `MultiMesh` instead of many nodes for all repeated props.
- The original's per-frame `minimap()` redraw is expensive — bake the static map into an
  `ImageTexture` once and only blit the player marker.

---

## 15. Android specifics

- **Orientation:** landscape only (`display/window/handheld/orientation = "landscape"`).
- **Touch:** the two floating sticks + the round buttons, exactly as in `js/touch.js`
  (`RUN` toggles a run lock; the stick past 0.93 also runs).
- **Renderer:** use Forward+ (Vulkan) where available; fall back to Compatibility.
- **Memory:** keep the working set under ~400 MB — the campus has 72 MB of source assets, of
  which the audio (15 MB) and the models (55 MB) dominate. Convert the models to `.glb` with
  Draco/LODs or Meshopt compression and the audio to OGG.
- **APK size:** with the CC0 replacements the project should land under ~150 MB.
- **Lifecycle:** handle `NOTIFICATION_APPLICATION_PAUSED` → save; `NOTIFICATION_APPLICATION_FOCUS_OUT` → pause.
- **Touch precision:** the interact button must work within the original's radii (3.8 m NPC,
  3.4 m machine) — the touch `E` button triggers the same resolver, so it inherits the radii.

---

## 16. Export / build

| Target | Notes |
|---|---|
| Windows | `export_presets.cfg` → Windows Desktop, D3D12 (the project already sets `rendering_device/driver.windows="d3d12"`), `x86_64` |
| Android | Android export preset, `min_sdk = 24`, arm64, `ETC2/ASTC` texture compression for the mobile build |
| Debug symbols | separate release/export templates; keep the debug template out of the shipped build |

---

## 17. Testing & parity verification

| Level | How |
|---|---|
| Unit (headless) | `godot --headless --script tests/unit/run_tests.gd` — the map↔world conversion, the LCG reproducibility, the mission step machine, the save validation, the economy maths |
| Data parity | a script that compares `campus_data.json` against the values in this documentation (17 buildings, 8 roads, 3 zones, 6 wall segments, 64 NPCs, 4 vending machines, 14 lamps) |
| Visual parity | render the Godot build from the same camera positions as the screenshots in `docs/screenshots/` and compare side by side (`tests/parity/`) |
| Behavioural parity | a scripted playthrough of Day 1 (talk → gate → admin → CSE → IT → canteen → salute → colonel) asserting the HUD text and the camera distance |

---

## 18. Optional addons (all MIT, verified)

| Addon | Where it saves time | Fallback if not used |
|---|---|---|
| Dialogue Manager | the 650 scripted lines + branching | a simple `DialogueService` with a dictionary of lines |
| Phantom Camera | the third-person rig + collision avoidance | the hand-written rig in §5 |
| Proton Scatter | the 150 trees / 130 bushes / grass | a custom `MultiMesh` scatterer (the LCG is 20 lines) |
| Beehave | NPC behaviour trees | plain `NavigationAgent3D` + state machines |
| Godot Jolt | already enabled in this project | keep it |
| Terrain3D | not needed — the campus is flat | — |

---

## 19. Implementation order (summary — the full plan is in `RECONSTRUCTION_ROADMAP.md`)

1. Project skeleton, autoloads, data files, map↔world helpers.
2. Ground, roads, kerbs, perimeter walls, gates (collision + swing).
3. Player controller + camera rig (with the avoidance algorithm).
4. Buildings (17) from the CC0 kits, with the exact footprints, heights and colours.
5. Vegetation + props (seeded, MultiMesh).
6. NPCs (64) with the dialogue service.
7. Mission runner + Day 1 + the HUD.
8. Days 2–10, the minigames, the economy, the shops, the inventory, the save system.
9. Menus, pause, touch controls, the call overlay, the credits.
10. Performance pass, Android export, parity screenshots.
