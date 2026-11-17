# ANITS Godot — 60 fps performance plan

Scope: the campus scene built by `src/main.gd` → `src/world/campus_builder.gd`
→ `src/world/props_factory.gd`, i.e. 17 buildings, 150 trees, 130 bushes,
4,200 grass cards, 91 cars, ~800 ground-cover props, four walk-in interiors
(Admin Office, Central Library, Room 204, Canteen), a Sky3D sky on desktop and
a procedural sky on the phone profile, and 64 NPCs.

**Measured on 15 Nov 2026** — see §0 below; the bench harness runs and the
numbers are recorded there. Everything from §1 onwards is the design plan and
the knob list.

---

## 0. Measured results (17 Nov 2026)

Machine: Windows 11 laptop, AMD Radeon (TM) Graphics integrated GPU, 1600×900,
Forward+ on D3D12, VSync off during the measurement.

The bench waits for `CampusDB` and starts the real game, so the draw-call and
primitive counts describe the whole campus rather than an empty first frame.
`render_profile` reports the profile `main.gd` actually chose.

| Run | Profile | Scale | fps avg | Frame p50 | Draw calls | Primitives | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Desktop full quality, spawn | HIGH | 0.88 | 22.0 | 44.8 ms | 1,062 | 3.11 M | below 60 |
| Desktop full quality, court | HIGH | 0.88 | 27.0 | 36.6 ms | 548 | 3.01 M | below 60 |
| Desktop after the ladder, spawn | HIGH | 0.60 | 36.1 | 26.1 ms | 795 | 3.04 M | below 60 |
| Desktop after the ladder, court | HIGH | 0.60 | 34.5 | 28.1 ms | 416 | 3.27 M | below 60 |
| Desktop AUTO, spawn | FAST | 0.60 | 54.8 | 18.0 ms | 660 | 1.23 M | below 60 |
| Desktop AUTO, court | FAST | 0.60 | 60.6 | 16.3 ms | 406 | 0.90 M | pass |
| Phone profile, court | FAST | 0.60 | 70.2 | 13.2 ms | 406 | 0.89 M | pass |

The desktop starts at 0.88 but this integrated GPU cannot hold 60 fps at full
quality; the adaptive ladder takes it through 0.78 and 0.68 to 0.60, disables
SSAO and volumetric fog, switches to one shadow split and then turns the sun
shadow off. The settled spawn view measures **36.1 fps** and the court
**34.5 fps**. A discrete GPU holds 0.88.

Because the integrated GPU cannot hold 60 fps with the HIGH campus, the default
**AUTO** graphics profile selects the FAST profile on it. That is the same
phone-class content and lighting path as the APK: cheap procedural sky, one
64 m shadow split with no tree shadows, reduced prop density and no glow / SSAO
/ volumetric fog. It reaches **54.8 fps at spawn** and **60.6 fps at the court**
in this thermal-soak run; the earlier cool-machine phone run measured **72.4**
at spawn and **82.5** at the court, so 54.8 is a conservative floor rather than
the profile's normal speed. **Settings → GRAPHICS PROFILE** can force HIGH or
FAST, and screenshot/benchmark modes pin their profile.

Previous cool-machine phone-profile sweep (15 Nov 2026, same laptop):

| Spot | fps avg | Frame p50 | Draw calls | Primitives |
| --- | --- | --- | --- | --- |
| Spawn | 72.4 | 13.7 ms | 710 | 1.27 M |
| Gate | 73.3 | 13.5 ms | 585 | 1.52 M |
| Admin | 71.6 | 13.6 ms | 570 | 1.48 M |
| Parade | 61.6 | 15.7 ms | 984 | 1.68 M |
| Parking | 89.0 | 11.1 ms | 326 | 0.95 M |
| Court | 82.5 | 11.9 ms | 431 | 0.94 M |
| Canteen | 86.1 | 11.5 ms | 324 | 0.78 M |
| Lawn | 72.5 | 13.5 ms | 510 | 1.57 M |

No physical handset was available: these numbers are the desktop standing in
with the FAST profile, which runs the same code path as the APK.

Bench commands used:

```powershell
# HIGH desktop, full quality
& $GODOT --path $PROJ --script res://tests/bench.gd -- `
    --bench-profile=desktop --bench-label=high --bench-seconds=15

# HIGH desktop, settled ladder
& $GODOT --path $PROJ --script res://tests/bench.gd -- `
    --bench-profile=desktop --bench-label=high-settled --bench-seconds=15 --bench-adaptive

# FAST profile (what AUTO picks on this laptop)
& $GODOT --path $PROJ --script res://tests/bench.gd -- `
    --bench-label=fast --bench-spot=court --bench-warmup=8 --bench-seconds=5 --scale=0.60

# Phone A/B run
& $GODOT --path $PROJ --script res://tests/bench.gd -- `
    --bench-profile=mobile --bench-spot=court --bench-warmup=8 --bench-seconds=5 `
    --bench-adaptive --low-poly
```

---

## 1. The bench harness

`tests/bench.gd` is a `SceneTree` script. It loads the game scene, starts the
game the same way the main menu does (`main.gd::_on_start`), so the campus,
the player and all 64 NPCs exist, warms up, samples the renderer for a fixed
window and prints a compact `key=value` block.

```
godot --path <project> --script res://tests/bench.gd -- [options]
```

### Exact commands (Windows PC, 1080p, Forward+, D3D12)

```powershell
$GODOT = "C:\Users\AKHILBOSS\Desktop\Godot_v4.7.2-stable_win64.exe"
$PROJ  = "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project"

# 1. main gate viewpoint (spawn + gate + guard + the street trees)
& $GODOT --path $PROJ --script res://tests/bench.gd -- `
    --bench-label=pc_gate --bench-seconds=15 --bench-spot=gate

# 2. parade ground (18 NCC cadets in one frame - the worst case for skeletons)
& $GODOT --path $PROJ --script res://tests/bench.gd -- `
    --bench-label=pc_parade --bench-seconds=15 --bench-spot=parade

# 3. parking apron (91 cars) and the basketball court
& $GODOT --path $PROJ --script res://tests/bench.gd -- `
    --bench-label=pc_parking --bench-seconds=15 --bench-spot=parking
& $GODOT --path $PROJ --script res://tests/bench.gd -- `
    --bench-label=pc_court --bench-seconds=15 --bench-spot=court

# 4. worst case: the whole campus in the frustum, 360 deg orbit
& $GODOT --path $PROJ --script res://tests/bench.gd -- `
    --bench-label=pc_orbit --bench-seconds=20 --bench-orbit

# 5. A/B the phone profile on the desktop (0.60 scale, cheap sky, low-poly props)
& $GODOT --path $PROJ --script res://tests/bench.gd -- `
    --bench-label=pc_mobile_sim --bench-seconds=15 --bench-profile=mobile --low-poly

# 6. CI / CPU-only pass (headless: no GPU numbers, script cost only)
& $GODOT --headless --path $PROJ --script res://tests/bench.gd -- `
    --bench-label=ci_cpu --bench-seconds=30
```

### Options

| Option | Default | Meaning |
| --- | --- | --- |
| `--bench-label=NAME` | `default` | label printed in the summary |
| `--bench-mode=game\|load\|empty` | `game` | `game` = load the scene **and** start the game; `load` = scene only; `empty` = bare tree (baseline overhead) |
| `--bench-seconds=N` | `10` | measurement window |
| `--bench-warmup=N` | `3` | warm-up (shader compile, first-frame spikes) |
| `--bench-profile=desktop\|mobile` | `desktop` | applies the phone profile (0.60 3D scale, MSAA off, cheap sky, low-poly density) so the desktop can be used as an A/B rig |
| `--bench-scale=S` | – | pin the 3D render scale on either profile (0.25–1.0) |
| `--bench-adaptive` | off | leave the quality ladder running through the warm-up and measure the settled scale |
| `--bench-hide=LIST` | – | profiling aid: `npcs,labels,trees,grass,interiors,shadows,sky,post,hud,lights` |
| `--bench-target=FPS` | `60` | fps target used for the PASS/FAIL verdict |
| `--bench-spot=NAME` | spawn | `spawn`, `gate`, `admin`, `parade`, `court`, `canteen`, `parking`, `lawn` or raw `X,Y` plan pixels |
| `--bench-orbit` | off | orbit the camera around the campus (worst case) |
| `--bench-vsync=on\|off` | `off` (windowed) | vsync off + `Engine.max_fps = 0` during the window, so the frame time is the real cost and not a 60 Hz cap |
| `--bench-verbose` | off | one line per second |
| `--bench-out=PATH` | – | also write the summary block to a file |
| `--bench-scene=PATH` | `res://src/main.tscn` | scene to bench |

### Output

The block is plain `key=value` lines so it can be diffed between runs:

```
--- summary ---
label=pc_gate
mode=game
profile=desktop
rendering_method=forward_plus
driver=D3D12
headless=false
render_valid=true
window=1920x1080
fps_avg=...
frame_ms_avg=...
frame_ms_p95=...
frames_over_budget=...
draw_calls_max=...
objects_max=...
primitives_max=...
video_mem_mb=...
nodes=...  mesh_instances=...  multimesh_batches=...  multimesh_instances=...
animation_players=...  labels=...  lights=...
cpu_process_ms_avg=...
result=PASS
=== END BENCH ===
```

Exit code: `0` = PASS, `1` = FAIL (below target), `2` = the scene could not be
loaded. Keep the blocks in `tests/bench_results/<label>.txt` (via
`--bench-out=`) and diff them in review.

In `--headless` the renderer is the dummy driver: the draw-call / object /
primitive counters read 0. The summary then reports `render_valid=false` and
the verdict falls back to the **CPU frame time** (`TIME_PROCESS +
TIME_PHYSICS_PROCESS` against the 16.6 ms budget). That is the CI gate: the
script side of the game must fit in the frame budget on every machine.

---

## 2. What is culled today

| What | Rule | Where |
| --- | --- | --- |
| Grass (4,200 cards desktop, 1,680 phone, 32 MultiMeshes) | each chunk is hidden when its centre is **> 95 m** from the camera (phone: 62 m) | `campus_builder.gd::_process` |
| NPC bodies | the visual is hidden **and its AnimationPlayer deactivated** beyond **95 m** (phone: **45 m**) | `npc.gd::_process` → `character_visual.gd::set_active` |
| NPC name labels (`Label3D`) | hidden beyond **62 m** (phone: 45 m) | `npc.gd::_process` |
| Interiors (Admin, Library, Room 204, Canteen) | only the active room is visible; all four are hidden while the player is outside | `main.gd::_set_room_visible` |
| Small props (grass, bushes, ground cover, kerbs, road markings, wall caps, roofs, canopies, signs) | `cast_shadow = SHADOW_CASTING_SETTING_OFF` — they never enter the shadow pass | `campus_builder.gd`, `props_factory.gd::batch` |
| Trees on the phone profile | cheaper species and **no shadow casting** | `campus_builder.gd::_flush_groups` |
| Cars (glass) | glass does not cast shadows | `campus_builder.gd::_build_cars` |
| Mission marker (disc, ring, diamond) | unshaded + no shadow casting | `main.gd::_build_campus` |
| Admin Office omni lights | 6 lights max, only 2 of them cast shadows | `admin_office.gd::_build_lights` |
| Sun shadow (desktop) | 2 splits, 128 m, blur 1.05 | `main.gd::_build_environment` |
| Sun shadow (phone) | one orthogonal split, 64 m, blur 0.85 | `main.gd::_build_low_poly_environment` |
| Distance fade | Sky3D fog ends at 760 m desktop; the phone profile uses depth fog and a 64 m shadow | `main.gd`, `player.gd` (camera `far = 800`) |
| Engine frustum culling | per `MeshInstance3D` and per **MultiMesh AABB** | Godot built-in |

### What is *not* culled (the remaining risk)

`MultiMesh` has **no per-instance culling**: a batch is drawn as a whole as
soon as its bounding box is touched. The grass is chunked (32 chunks, one
small AABB each), but these are **not**:

* **150 trees** (83 on the phone profile) — one MultiMesh per species *and
  surface*. Each batch spans the whole campus, so **every tree is transformed
  and drawn every frame**. Desktop trees cast shadows, so they are drawn twice;
  the phone profile uses four cheaper species and no tree shadows.
* **91 cars** (50 on the phone profile) — 3 MultiMeshes (bodies / glass /
  wheels), always submitted.
* **~800 ground-cover props** (45 % of them on the phone profile) — one
  MultiMesh per species, always submitted.
* **The remaining building detail** — the flat-colour imported buildings
  (Admin, Workshop, Bank, Café, Auditorium) are merged into one vertex-coloured
  mesh each, and the CSE / IT / ECE / EEE / Chemical rows are two MultiMesh
  batches per row, but the other 12 buildings are still ~45 individual
  `MeshInstance3D` nodes. They are frustum-culled individually (fine), and the
  four interiors are hidden unless the player is inside.

This is the single biggest structural cost in the scene and the first thing to
fix if the mobile target is missed (see §6, knob 12).

---

## 3. What is batched today

Everything repeated goes through `props_factory.gd::batch()`, which builds one
`MultiMesh` per *species × surface*:

| Family | Count | Batches | Shadows | Notes |
| --- | --- | --- | --- | --- |
| Trees | 150 desktop / 83 phone | ~10–30 desktop, 4 species × surfaces phone | desktop yes; **phone no** | the phone profile picks the cheapest species |
| Bushes | 130 desktop / 72 phone | 2–4 | no | `Bush_Common`, `Bush_Common_Flowers` |
| Grass | 4,200 desktop / 1,680 phone | **32** (8 × 4 grid) | no | low-poly grass cards, chunked + distance-culled (95 m / 62 m) |
| Ground cover | ~800 desktop / 45 % phone | ~10 | no (rocks yes) | clover ×2, flowers ×2, fern, rocks ×3, pebbles ×2 |
| Cars | 91 desktop / 50 phone | **3** | bodies/wheels yes | body / glass / wheel meshes |
| Kerbs | hundreds | **2** | no | yellow + white |
| Road markings / crosswalk | – | 2 | no | |
| Imported buildings | 5 flat-colour models | **1 per model** | yes | Admin (218 meshes), Workshop (138), Bank, Café and Auditorium are merged into vertex-coloured meshes |
| Row blocks | 5 rows | **2 per row** | yes | CSE / IT / ECE / EEE / Chemical units drawn as MultiMeshes instead of 2 meshes per unit |
| Other buildings | 12 | ~45 | yes | body + roof + canopy per building |
| Interiors | 4 | ~100 each | partly | hidden unless the player is inside that room |
| NPCs | 64 | 64 × ~4–8 mesh parts + 64 `Label3D` | yes | animated, culled at 95 m desktop / 45 m phone |
| Lamps / benches / vending machines | 14 / 7 / 4 | ~25 | no | |

The batch counts are estimates read from the code; the bench prints the exact
`multimesh_batches` / `multimesh_instances` census for the running scene.

Draw-call budget is therefore dominated by **NPCs** (up to ~190 nodes) and the
**tree batches** (~20 colour + ~20 shadow), not by the scenery.

---

## 4. Platform targets

| | Windows PC | Android (mid-range) | Web |
| --- | --- | --- | --- |
| Resolution | 1920×1080, native | 2340×1080 native, **3D at 60 %** | canvas 1280×720 typical, 3D at 60 % on touch devices |
| Renderer | **Forward+** (D3D12) | **Mobile** (Vulkan; GL Compatibility as the no-Vulkan fallback) | **GL Compatibility** (WebGL 2) |
| Target | **60 fps** | **60 fps** target | 60 fps on desktop browsers, 30 fps floor on mobile browsers |
| Frame budget | 16.6 ms | 16.6 ms (at 0.60 scale → 64 % fewer pixels) | 16.6 ms |
| Shadows | 2 splits, 128 m, 2048 map | 1 orthogonal split, 64 m, 1024 map, no tree shadows | phone profile: 1 split, 64 m |
| MSAA | off (code) | off | off |
| Texture compression | BC7 / no VRAM compression | **ETC2 / ASTC** | ETC2 / ASTC (or plain) |

### Budgets (targets; the measured result is in §0)

| Metric | PC 1080p | Android | Web |
| --- | --- | --- | --- |
| `fps_avg` | ≥ 58 at the settled scale | ≥ 55 | ≥ 50 |
| `frame_ms_p95` | ≤ 17.0 | ≤ 17.5 | ≤ 17.5 |
| `draw_calls_max` | ≤ 1200 | ≤ 1000 | ≤ 1000 |
| `objects_max` | ≤ 1700 | ≤ 1300 | ≤ 1300 |
| `primitives_max` | ≤ 3.2 M | ≤ 1.8 M | ≤ 1.8 M |
| `cpu_process_ms_avg` | ≤ 6 | ≤ 6 | ≤ 6 |
| `video_mem_mb` | ≤ 900 | ≤ 500 | ≤ 350 |

The PC numbers are the realistic ceiling for this scene: the full-density tree
batches alone submit ~150 trees × 2 passes every frame, and the NPC crowd at
the parade ground adds ~20 animated characters. The phone profile fits the
Android budget at all eight hotspots (§0).

---

## 5. Mobile / web settings

### What was already in `project.godot` (verified, unchanged)

| Setting | Value | Verdict |
| --- | --- | --- |
| `textures/vram_compression/import_etc2_astc` | `true` | ✅ already correct |
| `lights_and_shadows/directional_shadow/size` / `.mobile` | `2048` / `1024` | ✅ already correct |
| `lights_and_shadows/directional_shadow/soft_shadow_filter_quality` | `1` | ✅ |
| `lights_and_shadows/positional_shadow/atlas_size` | `1024` | ✅ |
| `display/window/stretch/mode` / `aspect` | `canvas_items` / `expand` | ✅ |
| `display/window/size/viewport_width×height` | `1920×1080` | ✅ |

### What was applied in code, not in `project.godot`

`src/main.gd::_apply_mobile_quality()` (runs on every platform):

* `viewport.msaa_3d = MSAA_DISABLED` and `screen_space_aa = DISABLED` — MSAA
  is off **everywhere**, not only on phones.
* `scaling_3d_mode = BILINEAR` on every platform: **0.88** on desktop and
  **0.60** on a mobile GPU; `Engine.max_fps = 60`.
* `_adaptive_quality()` runs everywhere: after 3 s below 58 fps it steps the
  3D scale down (desktop 0.78 → 0.68 → 0.60, phones 0.54 → 0.50 → 0.46) and
  finally turns the sun shadow off.

`src/main.gd::_build_low_poly_environment()` on the phone profile: a cheap
`ProceduralSkyMaterial` instead of the Sky3D raymarched atmosphere, depth fog,
glow / SSAO / volumetric fog off, and one orthogonal sun shadow split at 64 m.
The campus also switches to the low-poly prop set and the trees stop casting
shadows. On desktop `_build_environment()` keeps the Sky3D dome, glow, SSAO,
volumetric fog and two shadow splits at 128 m.

### What I added to `project.godot` (renderer / quality only)

These were **missing**; nothing that existed was removed or weakened.

```ini
[display]
window/handheld/orientation=0            ; landscape (was implicit)

[rendering]
renderer/rendering_method="forward_plus"  ; desktop default, now explicit
renderer/rendering_method.mobile="mobile" ; Vulkan Mobile renderer
renderer/rendering_method.web="gl_compatibility"
scaling_3d/mode.mobile=0                  ; bilinear
scaling_3d/scale.mobile=0.60              ; the 60 % phone 3D scale
anti_aliasing/quality/msaa_3d=0          ; MSAA off (matches main.gd)
lights_and_shadows/directional_shadow/soft_shadow_filter_quality.mobile=0
lights_and_shadows/positional_shadow/atlas_size.mobile=512
```

Why:

* **`rendering_method.mobile = "mobile"`** — the Vulkan *Mobile* renderer is
  Godot's documented Android path: the same feature set as Forward+ minus the
  expensive extras (no SDFGI / SSIL / volumetric fog / SSAO), with cheaper
  shadow and light handling. That is exactly the "60 fps on a mid-range
  phone" target. It requires Vulkan, which every mid-range Android of the
  last several years provides.
  *Fallback:* a device without Vulkan gets the GL Compatibility path — flip
  the one line above to `"gl_compatibility"`. That path is already validated
  by the Web build, so nothing new has to be art-fixed.
* **`rendering_method.web = "gl_compatibility"`** — WebGL 2 is the only
  broadly-supported path in the browser today.
* **`window/handheld/orientation=0`** — landscape, stated explicitly instead
  of relying on the engine default.
* **`scaling_3d/scale.mobile = 0.60`** — mirrors what `main.gd` already
  applies at runtime, but it is now a project setting so it is also applied
  to the editor's mobile preview and to any viewport that is not the root one.
* **`anti_aliasing/quality/msaa_3d=0`** — the project default was 4× MSAA
  while the code turned it off at runtime; the setting now matches the code
  (so the very first frame is already MSAA-free).
* **Shadow quality on mobile** — sharper (filter quality 0) and a smaller
  positional atlas (512) for the two shadow-casting omnis in the Admin Office.

Note on the renderer choice: the *Mobile* renderer still needs the same
shader validation as any other backend. The scene uses only standard
material features plus two custom spatial shaders (`props_factory.gd`'s
foliage wind shader and the ground/road shaders). The phone profile no longer
uses the Sky3D atmospheric dome — it builds a `ProceduralSkyMaterial` — so the
most expensive sky pass is gone on the devices that need it most.

---

## 6. Knob checklist — lower these first when a device misses 60 fps

Work down the list; each step is cheaper visually than the one below it.
Every knob names the place to change it. Items marked **done** are part of the
shipped phone profile (§5); the rest is the escalation order for a weaker
device.

**Tier 0 — free**

1. Make sure the phone actually takes the mobile branch:
   `OS.has_feature("mobile")` must be true (`main.gd::_ready`). Check the
   bench summary: `profile=mobile`.
2. Never "fix" a frame rate by lowering `Engine.max_fps`. It hides the
   problem and breaks the 60 fps contract.

**Tier 1 — almost invisible**

3. 3D render scale **0.60 → 0.54 → 0.50 → 0.46** (`main.gd::_degrade_quality`).
   Pixel count scales with the square: 0.46 is ~41 % fewer pixels than 0.60.
   *(The start at 0.60 is done; the steps are the ladder.)*
4. `soft_shadow_filter_quality.mobile = 0` (done) and
   `sun.shadow_blur = 0.85` (`main.gd::_build_low_poly_environment`).
5. Directional shadow map `1024 → 512`
   (`rendering/lights_and_shadows/directional_shadow/size.mobile`).
6. Keep `glow_enabled = false` on mobile (done).

**Tier 2 — small visual change**

7. Sun shadow: one orthogonal split at **64 m** (done,
   `_build_low_poly_environment`).
8. Grass radius **62 m** on phone (done via
   `props.mobile_density.grass_radius = 0.65`).
9. NPC radius **45 m** and label radius **45 m** (done, `npc.gd`).
10. Depth fog on the phone profile hides the cull ring (done).
11. No cloud layers on the cheap procedural sky (done).

**Tier 3 — visible, but still shippable**

12. **Chunk the tree MultiMeshes spatially and distance-cull them**, exactly
    like the grass (`campus_builder.gd::_build_trees` + `_flush_groups`):
    an 8 × 4 grid, each chunk a separate `MultiMeshInstance3D`, hidden beyond
    ~110 m. On a 217 × 262 m campus that removes most of the far trees *and*
    their shadow pass from every frame, and it is the single biggest win
    available *without* changing the look (the fog hides the cull ring).
13. Do the same for the **cars** (3 batches → 6–8 chunked batches) and the
    **ground-cover props** (~10 batches).
14. Turn **tree shadow casting off** on mobile (done —
    `_flush_groups(groups, "Tree", not low_poly)`).
15. Cut the grass from 4,200 to **1,680 cards** (done via
    `props.mobile_density.grass = 0.40`).
16. Reduce the tree species count to **4** (done via
    `PropsFactory.LOW_POLY_SPECIES`).

**Tier 4 — last resort**

17. Disable the sun shadow completely on the lowest tier
    (`sun.shadow_enabled = false` — the ladder's third step).
18. Replace the Sky3D dome with a plain gradient sky (done on phone).
19. Camera far plane 800 → 400 m (`player.gd`).
20. Drop the grass entirely on the lowest tier.

**Never**

* `Engine.max_fps = 30`.
* Removing the HUD / mission logic to "win" frames.

---

## 7. Profiling procedure

### Windows PC (the reference platform)

1. Close every other application; VSync off, 1080p, `Forward+` + D3D12.
2. Run the bench at the four viewpoints (`gate`, `parade`, `parking`, `court`)
   and the orbit case, and save the blocks:
   `--bench-out=res://tests/bench_results/pc_gate.txt`.
3. Open the editor, run the game, and use **Debug → Monitors** for a live
   view of the same counters (Draw Calls, Objects, Primitives, VRAM, FPS).
4. Use **Debug → Profiler** → *Frame Time* / *Rendering* / *Objects* to see
   whether the time goes to CPU scripts, draw calls or VRAM.
5. For the worst case use the camera orbit (bench) or walk the Day 1 route
   (the `--check` tour in `main.gd::_run_check`).

### Android (mid-range, e.g. Snapdragon 6-series / Dimensity 700 class)

1. Build a **debug** APK and install it:
   `adb install -r build/anits.apk`.
2. Start it and watch the frame rate:
   `adb logcat -s godot` (the bench prints its block to stdout, which lands in
   logcat under the `godot` tag).
   To have the bench run instead of the game, start the build with the
   `--script res://tests/bench.gd` argument (the Godot Android activity
   forwards the intent extra `command_line` if the export sets it, e.g.
   `adb shell am start -n <pkg>/.GodotApp --es command_line "--bench-seconds=15"`).
   If the build does not forward it, use the fallback below.
3. Fallback (always works): run the game on the device and read the counters
   from the editor's **remote debugger** (Debug → *Deploy to Device* /
   Remote Inspector) → the **Monitors** panel shows Draw Calls, Objects,
   Primitives, VRAM and FPS with the same names the bench prints.
4. Read the GPU cost with `adb shell dumpsys gfxinfo <pkg>` or the vendor
   profiler (Snapdragon Profiler / Mali Streamline).
5. Godot 4.7 can emit a **Perfetto** trace on Android (frame timing
   breakdown, GC pauses, thread scheduling, GPU queue). Run the build with
   `--perfetto-trace output.perfetto` (check `godot --help` for the exact
   flag in 4.7) and open the result at <https://ui.perfetto.dev/>.
6. Repeat for the three worst viewpoints and for the `--bench-profile=mobile`
   configuration, which is what the device runs anyway.

### Web (GL Compatibility)

1. Export the Web preset and serve it (`python -m http.server` in the export
   folder).
2. Open it in Chrome/Edge/Firefox, open DevTools → *Performance* → record 10 s
   while walking the campus: check that the frame time stays under 16.6 ms
   and that no long tasks (shader compiles, GC) appear.
3. The Godot remote debugger connects back from the browser, so the
   **Monitors** panel gives the same draw-call / primitive counters.
4. The web shell's canvas size decides the render resolution; test at
   1280×720 and at a phone-sized viewport (the stretch mode is
   `canvas_items` + `expand`, so the 3D viewport follows the canvas).
5. Watch the browser's GPU memory: the Compatibility renderer keeps the whole
   scene in VRAM, so watch the `video_mem_mb` row of the bench block.

### Reading the numbers

* `draw_calls_max` far above the budget → the scene is submitting too many
  batches: chunk the trees (knob 12).
* `primitives_max` high with `draw_calls` low → the geometry itself is the
  problem: trees/cars/grass (knobs 12–16).
* `objects_max` high → the NPC crowd: lower the 95 m radius (knob 9).
* `cpu_process_ms_avg` high → the script side: the per-frame distance
  checks in `campus_builder.gd::_process` and `npc.gd::_process` run for
  every node every frame; they are cheap individually but there are ~130 of
  them.
* `frames_over_budget` > 0 → hitches: usually first-frame shader compiles
  (raise `--bench-warmup`) or a GC pause.

---

## 8. Known gaps / follow-ups

* The bench has run on the Windows laptop (§0) with both the desktop ladder and
  the phone profile; Android device numbers still have to be captured on real
  hardware.
* `props.grass_radius` is now read from `campus_data.json` and scaled by
  `mobile_density.grass_radius`, so the data file is the single source of truth
  (desktop 95 m, phone 62 m).
* The tree / car / ground-cover MultiMeshes are still not spatially chunked
  (§2) — the biggest structural item left. The phone profile reduces their
  density and drops tree shadows instead, and the adaptive ladder keeps the
  frame rate on target.
* `export_presets.cfg` contains the Web and Android presets; both exports are
  built and verified.
* The stable anchors in `main.gd` are now `_apply_mobile_quality`,
  `_build_environment`, `_build_low_poly_environment`, `_degrade_quality`,
  `_run_check`; in the world they are `campus_builder.gd::_process`,
  `campus_builder.gd::_flush_groups`, `npc.gd::_process` and
  `props_factory.gd::batch`.
