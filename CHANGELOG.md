
# NPC look-at white glow
- Looking toward an NPC (view direction, within 14 m) fades in a soft white outline (tight rim + soft halo); looking away or switching NPC fades out/in cleanly. Depth-tested so walls hide it; cleared instantly on pause/shop/minigame/call.
- Files: js/interaction-outline.js, js/game.js (lookAtNpc).
- Not play-tested (owner request).
# v11: Footpaths removed; only alternating yellow/white kerb blocks as road borders across the campus (gate road included, gaps at zebra crossings)

# v10: Gate zebra crossings + low hedges beside gate paths, deeper brick colour

# v9: Slim brick footpaths (gate only)
- Footpaths now exist ONLY at the gate (gate drive side paths + Gate Canteen/Bank walkway). Road-edge strips, kerb blocks and sand-field apron removed.
- Gate side paths narrowed from 5.6 m to ~1.9 m, kerb height lowered (0.35 m -> 0.14 m above road), slimmer yellow/white kerb blocks.
- All paving is now brick pavers (running bond); sand-field apron slimmed to ~2.2 m; Gate Canteen/Bank plinth is plain concrete with a 1.8 m brick walkway along the road edge.
- Not fully play-tested.

# Clear-daylight / mobile-graphics update
- Balanced campus daylight, sky and haze with gentler directional shadow bias; capped mobile shadow refreshes to player movement / a short interval.
- Raised the readable mobile pixel-ratio floor, reduced excessive auto-resolution changes, improved ground texture angle filtering and made road grain less visually noisy.
- Batched static trees by material into instanced draws; reduced grass draw distance, distant foliage and cloud sprites on lower phone tiers.
- Removed the duplicated raised sand-field path spur beside the main entrance, preserving its crossing, road sidewalks and all existing gate and collision geometry.
- Not run or play-tested at the owner's request.

# Campus environment edition (based on v7)
- Preserved the seven levels, parade stages, mission coordinates, controls, collision map and working v7 gate mechanisms.
- Added locally generated asphalt, natural grass, soil, clay and stone-paver materials; improved road edges, entrance lanes, crossings, paving margins and subdued concrete kerbs.
- Added instanced facade depth, windows, sills, floor trim, rooflines, drainage and academic block signage to the existing departmental model footprints; gave the main gate more masonry relief.
- Locations follow the existing campus-inspired plan and available ANITS public descriptions; exact positions remain approximate. Lighting, sky, crowds and props were not changed.
- Gameplay was not run or play-tested for this edition at the owner's request.

# v7: Gate render fix (low poly)
- Root cause: assets/models/b_gate.glb was ~23,200 triangles (3 lettering meshes alone were ~12,000, one at 10,668), every material had emissiveFactor [1,1,1] (washed-out white), lettering/crest quads floated in front of the walls (coplanar/near-coplanar -> z-fighting/flicker), and the crest "images" were untextured grey quads.
- Fix: the gate is now built procedurally in js/game.js (`lowPolyGate()`), ~600 triangles, flat-shaded Lambert boxes, no textures to load. Signboards use small canvas-text planes with polygonOffset (no z-fighting).
- Unchanged: gate position, scale (K=.0095), colliders, hinge names (Right/Left_gate_hinge_controller), open/close logic, guard animation.
- Removed: assets/models/b_gate.glb (1.1 MB) and its entries in js/assets.js (smaller download, faster load).
- Verified in headless Chrome from several camera positions (screenshots clean, no console errors from the gate). Not play-tested on a real phone; please check FPS with ?perf=1.

# CHANGELOG: Gate / Mission / Voice fix (levels 2, 3, 4, 7 and shared code for 5, 6, 8, 9, 10)

NOTE: These changes were written by code inspection and syntax-checked only. They have NOT been run through the full scripted walkthrough
of levels 2/3/4/7 (the test run was stopped). Please play-test the gate, HUD and voice before shipping.

Engine kept as-is (vanilla JS + three.js, node static server). No rewrite, no backend: progress stays in localStorage.

## New file: js/fixes.js (loaded last by js/assets.js)
- Gate: `window.__gateFlow` with `gateState` (idle | checking | passed | denied) and `hasID`. Duplicate/spammed checks are ignored while `checking`; closing the bag without SHOW returns to `idle`; state is derived from mission index, so reload mid-check is safe. State is saved in localStorage (`anits-gate:v1:<level>`).
- On-screen "SHOW ID CARD" button appears whenever the player is within 6 units of Bajirao and the ID mission is active (works with mouse and touch, z-index above the dialogue and HUD).
- Mission: persistent HUD pin (`#mission-pin`, never blocks clicks) mirrors the current mission; mission is saved in localStorage (`anits-mission:v1:<level>`) and the game save is flushed on every mission change.
- Mission re-announce after every conversation ends (voice + text banner), debounced (700 ms settle, 6 s repeat guard).
- Voice manager wraps `window.__voice`: NPC channel vs mission channel, mission voice cancelled by NPC speech and resumed after the dialogue, audio unlocked on first user gesture (AudioContext + silent Audio + speechSynthesis), text banner always shown (longer when audio does not start), tab hidden -> pause, tab visible -> resume.
- Watchdog (every 250 ms): resets a stuck dialogue flag (`dlg` set but panel hidden) and hides an orphaned dialogue panel.

## Edited files
- js/game.js: `gatePass()`, `gateCheck()`, `resetDialogue()` added; ID check goes through `__gateFlow`; `interact()` ignores presses while the bag is open (touch path used to bypass the keyboard guard); guard explains the temporary ID when the player has no ID card; `__g` exports `gateCheck`, `resetDialogue`.
- js/voice.js: audio element is released on stop (no leaked/looping clips); speech start deferred 50 ms after `cancel()` (Chrome/Safari drop utterances queued in the same tick as a cancel).
- js/inventory.js: `__inv.isOpen()`; bag z-index raised above overlays via fixes.js CSS.
- js/assets.js: loads js/fixes.js.

## Not changed
- Levels 1, 5, 6 were not in the upload; shared code (game.js, voice.js, inventory.js) is used by them, so retest them.


# Security ID + no task reminders
- Press F near guard Bajirao (within ~9 units) to show your ID card; works in every level (Level 1 gate step included). On-screen prompt + SHOW ID CARD (F) button for touch.
- Gate check no longer gets stuck (open dialogue is reset, old state flags ignored); main-gate walk-in point matches Level 1.
- Characters no longer remind you of your tasks after chats (auto situation line, 'task' answers, post-chat voice/banner re-announce, and task-direction lines removed). The mission HUD is the only place tasks show.

- Guard Bajirao now animates: turns to you, raises an arm and inspects your ID card (leans in, card tilts), then waves you through as the gate opens (js/game.js, window.__guardAnim).

## Day 5 shootout fix
- Shoot camera now sits behind the player and looks at the hoop (ring always on screen)
- HUD (mission, wallet, energy, minimap, pill) hidden while shooting; side panel shrunk to a small dots pill
- Easier scoring: bigger target ring (0.30 m), less hand sway, gentler drag sensitivity, closer starting aim

## Performance pass
- Parked cars: far cars (>16 m low tier, >28 m otherwise) swap from ~3-6.7k-triangle models to ~500-triangle silhouettes traced from the real model
- Noodle bar: frustum culling re-enabled (was always drawn)
- ?perf=1 shows FPS / draw calls / triangles

## Guard third-arm fix
- Bajirao the guard: his own left sleeve + hand are now a separate mesh hidden while the inspect/wave gesture arm is shown, so only two arms are ever visible

## Level 6: NCC Parade rebuilt (new file js/parade.js)
Report to the Colonel -> uniform check -> fall in and drill -> march in step -> flag hoisting and salute -> debrief + certificate.
- Uniform check: tap and fix 4 faults (beret, collar button, belt buckle, boots), then hold "attention" for 2.6 s.
- Fall in and drill: 10 Hindi NCC commands (Savdhaan, Vishraam, Daayen Mud, Baayen Mud, Peeche Mud), 8 right to pass.
- March in step: alternate LEFT / RIGHT foot on a 92 BPM beat, 11 of 16 on the beat to pass.
- Flag hoisting: pull / release the rope to keep the flag inside the anthem-pace band, then hold the salute (plays the 3D salute).
- Debrief: star scorecard, grade, certificate with the player's name; saved to the BAG (new "NCC Parade Certificate" slot) and exportable as a PNG.
- Mobile: big pointerdown buttons, layouts checked at 640x360 landscape, 390x780 portrait and desktop; keyboard also works (arrows / WASD / Space / Enter).
- Edited: js/levels.js (level 6 steps), js/inventory.js (ncc item), js/assets.js (loads parade.js). Scores in localStorage 'anits-parade'.

## Level 6: March stage removed, NCC Ground Run is now a real 3D run
- The LEFT/RIGHT arrow "March in step" stage is gone. Level 6 is now: Report, Uniform, Drill, Run, Flag, Debrief.
- NCC ground run: the player cadet (the Mixamo run clip the game already uses) runs 1.4 km = 2 runs of 700 m on a 3D track in 2:00. Runs on its own; hold SPRINT (button, or Space / Shift / W / Up) for a burst, which drains stamina.
- 3D cadets line both sides, raise their arms and cheer; speech bubbles show the player's name ("GO <NAME>!", "<NAME>! <NAME>!"). Banner at each run end; start/finish arch.
- Base speed alone finishes in ~104 s, so 2 runs always fit in 2:00; sprint bursts finish in ~85 s. Score: finish by 1:20 = 100.
- Falls back to a simple 2D track if WebGL or the models are unavailable. Run score shows in the debrief, final grade and certificate.
- Edited: js/parade.js, js/levels.js.

## Levels 8, 9 and 10 removed
- Canteen Challenge, Fest Stage and First Classroom are gone; the game now has 7 levels (Day 7, Lab Manual Run, is the last).
- js/levels.js: level list and mission steps for 8-10 deleted. js/menu.js: the hard-coded "10" (unlock-all, level-complete, Next Level button) now uses the level count, so finishing Day 7 shows only "Level Select".

# Controls v2 (mobile)
- MOVE: the 4-way D-pad is replaced by a floating analog joystick (any angle). It appears under your thumb anywhere in the left zone, glides back to rest on release, lights the arrows you push, and auto-runs (orange glow, "RUN") when pushed to the rim. The RUN button still locks running.
- LOOK stick, BAG, RUN, SALUTE and the contextual Talk/Open/Use button share one glass look with colour accents; Talk pulses when an action is available.
- Mini-games: chunky arrow cross with press-down effect and a large gold SHOOT / TAP button.
- Files: js/touch.js, css/mobile.css (js/game.js untouched; window.__joy / __lookBy contract unchanged).
