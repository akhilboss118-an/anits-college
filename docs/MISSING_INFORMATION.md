# MISSING_INFORMATION.md — what is still unknown, and how to close it

This document is the honest ledger of everything that could **not** be determined from the
material available, plus the questions that need a decision from the client.

**Rule:** nothing in this folder was invented. Every "UNKNOWN" below is a genuine gap; every
"[P]" is a proposal made by this analysis, clearly marked as such.

**Priority key:** 🔴 blocks the build · 🟠 affects quality/fidelity · 🟢 nice to know.

---

## 1. 🔴 Asset licences (the single biggest open item)

| # | Unknown | Detail | How to close it | Impact |
|---|---|---|---|---|
| 1.1 | **Licence of the 24 game models** | `b_admin`, `b_brez`, `b_lp`, `b_cafe`, `b_bank`, `b_stairaud`, `b_gate`, `b_bench`, `b_drink`, `b_grass`, `b_colonel`, `b_guard`, `b_phone`, `b_remy`, `b_walk`, `b_aud` (`.bin`), plus `workshop.glb`, `cadet_boy/amy/girl.glb`, `laksmi.glb`, `office_desk/sofa/toilet.glb`, `tree_gattu.glb`, `basketball*.glb` | Ask the author (Little Hearts / AKHILBOSS) for the source and licence of each file. The repo contains **no** `LICENSE`, `CREDITS` or attribution file other than the temple line in `index.html`. | Decides whether the campus is rebuilt from scratch (the current plan) or can use the originals |
| 1.2 | **Licence of the model textures** | `cadet_boy_0..6.jpg`, `cadet_amy_*`, `cadet_girl_0.jpg`, `laksmi_0.png`, `office_sofa_*`, `office_toilet_*`, `basketball_hoop_*`, `uni2023/2025_*.jpg` | Same as 1.1 | Same |
| 1.3 | **Licence of the 632 voice clips** | `assets/audio/*.mp3` + `clips.json` / `clips_girl.json`. The clips are spoken English/Telugu lines; the recording source is unknown (AI TTS? human voice?) and no licence is shipped. | Ask for the voice source + licence. Fallback: re-record or use TTS (see the mapping doc). | Voice identity of the whole game |
| 1.4 | **Licence of the drink-label JPGs and the menu background** | `assets/img/*.jpg` (10 drink labels) and `assets/ui/bg_clean.jpg` | Ask, or recreate (the plan is to recreate) | Low |
| 1.5 | **Mixamo terms for `b_walk.bin` / `b_remy.bin`** | Both are Mixamo-derived characters. Adobe's Mixamo terms allow use *in* projects but restrict redistributing the source FBX. | Confirm before shipping a build that embeds the FBX; the CC0 replacement plan avoids the question entirely | Medium |
| 1.6 | **Rights to the ANITS logo and name** | `anits_logo.png`, `little_hearts_logo.png`, and the name "ANITS" | Obtain written confirmation from ANITS/the rights holder for commercial release of the rebuilt game | 🔴 legal |

---

## 2. 🔴 Missing files in the shipped build

| # | Missing | Evidence | Impact | Plan |
|---|---|---|---|---|
| 2.1 | **The 10 level-card thumbnails** `assets/ui/lv_gate.jpg` … `lv_classroom.jpg` | `menu.js` builds each level card with `background-image:url(assets/ui/lv_<name>.jpg)`, but `assets/ui/` contains only `bg_clean.jpg`. The requests 404. | The level-select screen has empty image areas in the original build | Recreate 10 simple cards (the plan) or ask the author for the originals |
| 2.2 | **The two hashed fonts** `658f6280.woff2`, `75c6aa4b.woff2` | Present in `assets/fonts/` but referenced by **no** CSS or JS file | None — they are dead files | Ignore |
| 2.3 | **Background music** | No music file ships; only 632 voice MP3s and synthesised SFX | The campus is silent apart from dialogue | Ask whether music was intended; add an ambient track only with approval |

---

## 3. 🟠 Behaviour details that are inferred, not proven

| # | Item | What is known | What is inferred |
|---|---|---|---|
| 3.1 | The **buddy** system (`js/buddy.js`) | A friend walks alongside the player from Day 2 with a 60 % chance; `window.__buddyDay` disables it | The exact spawn timing, the follow distance and the farewell behaviour were not traced line-by-line — read `buddy.js` before porting it |
| 3.2 | The **chat** system (`js/chat.js`, 27 KB) | After a dialogue line the player can keep chatting; the panel is suppressed during overlays | The full option set and its line pool were not transcribed — read `chat.js` before porting it |
| 3.3 | The **pause menu** ranges | Voice / effects / look sliders exist and persist (`anits-vol`, `anits-sfx`, `anits-look`) | The exact min/max/step of the "look sensitivity" slider was not read; the code clamps the multiplier, not the slider |
| 3.4 | The **phone-call pool** | `callpool.js` holds boy/girl and cadet exchanges; 18–38 s auto-call; calls only while the step index is in range | The number of exchanges and their exact lines were not enumerated — transcribe before porting |
| 3.5 | The **flag** (`js/flag.js`, 15 KB) | A 14 m pole with a 4.2 × 2.8 m waving tricolour at map (235,377), lazily mounted | The exact cloth simulation parameters were not read |
| 3.6 | The **cinematic intro** | Three timelines (`full` 11 s / `short` 4.1 s / `reduced` 5.8 s), synthesised audio, `lhp-cinematic-seen` | Which timeline the player gets on a first run was not confirmed (the config has a `replay: 'short'` setting) |
| 3.7 | The **girl cadet voice** | `clips_girl.json` has 310 entries and includes a Telugu "Jai Hind!" | Whether the 310 entries are *all* female lines or only a subset is not proven — count the distinct keys when porting |
| 3.8 | **Mobile** behaviour | Touch layout, 1.25 pixel ratio cap, 1024 shadow map, static shadows, 560 m far plane | The exact behaviour of the `?callin`/`?flag`/`?unlock=all` debug parameters on mobile was not tested |
| 3.9 | **Adaptive pixel ratio** | The renderer drops the pixel ratio when the frame time is bad, and the flag system can force it to ≤ 1.25 | The thresholds were not transcribed precisely (`PG.sum`, `PG.n`, `PG.f`) |

---

## 4. 🟠 Content questions for the client

| # | Question | Why it matters |
|---|---|---|
| 4.1 | Should the rebuilt game keep the **ANITS name, logo and branding**? | It is the identity the brief asks to preserve, but it is also a trademark — a commercial release needs the college's permission |
| 4.2 | Should the **Little Hearts / AKHILBOSS credits** stay in the rebuild? | They are the original author's authorship |
| 4.3 | Is the **voice acting** to be re-recorded, or should the build ship with TTS + subtitles? | 632 clips is a large recording project |
| 4.4 | Should **background music** be added? | The original has none |
| 4.5 | Is the real ANITS campus supposed to be represented more faithfully? | The game's campus is a stylised, simplified plan; a faithful rebuild reproduces the **game**, not the real college. Adding real buildings would break the "no new content" rule |
| 4.6 | Which **Android device** is the acceptance target? | The performance plan uses a `low` preset for phones; the specific SoV/Adreno/GPU budget changes the grass distance and the shadow settings |
| 4.7 | Should the **debug URL parameters** (`?lvl`, `?char`, `?year`, `?unlock=all`, `?reset=1`, `?callin`, `?flag`) exist in the Godot build? | Useful for QA, but they are web-specific |
| 4.8 | Should the **web build** keep running alongside the Godot build? | The brief targets Godot only; the web build is the reference |

---

## 5. 🟢 Things that were checked and are *not* missing

| Check | Result |
|---|---|
| The three.js version | **r128** — found in `js/vendor/three.min.js` (`const e="128"`) |
| The live site vs the offline mirror | Byte-identical for `index.html`, `js/game.js`, `js/levels.js`, `assets/models/cadet_boy.glb` (SHA-256) |
| The campus extent | 217.0 × 261.8 m — derived from the `BLD`/`ROADS` tables |
| The building count | 17 |
| The NPC count | 64 (6 + 18 + 9 + 3 + 10 + 8 + 1 + 9) |
| The prop counts | 150 trees, 130 bushes, 14 lamps, 91 cars, 11 seats, 4 vending machines, 6,923 grass tufts in 46 chunks |
| The audio count | 632 MP3s (340 + 310 mappings) |
| The movement speed | walk 2.4 (measured ≈2.3), run 5.6 (measured ≈5.6), boost ×1.3 |
| The camera | 5.4 / 3.2 / 3.4 m, +1.5 m height, +1.35 m target, avoidance down to 1.2 m, pitch 0.05–1.1 |
| The economy | ₹200 wallet, ₹2000 bank, ₹250 fee, 10 drinks, 4 noodles, energy 40→100 |
| The mission scripts | All 10 days transcribed verbatim from `levels.js` |
| The CC0 licence claims | Every pack verified against the publisher's page and/or the archive's `License.txt` (see `EXTERNAL_ASSET_LIBRARY.md` §0) |

---

## 6. 🟢 Known inaccuracies in the original build (documented, not fixed)

These are **facts about the original**, recorded so the port does not accidentally "fix" them
and so the client can decide whether to keep them.

| # | Observation | Evidence |
|---|---|---|
| 6.1 | The level-select card images are broken (404) | `assets/ui/lv_*.jpg` do not exist |
| 6.2 | The UI declares `Figtree` / `Bricolage Grotesque` / `Archivo Black` but never loads them | no `@font-face` in any CSS file → the web build falls back to `system-ui` |
| 6.3 | The `NCC` map rectangle is labelled "NCC ground" in old notes but is now the **Power Supply Room** | the source comment: *"Power Supply Room (was the NCC ground)"*; the on-screen label reads "Power Supply Room" |
| 6.4 | The NCC company stands on the **sand field**, not in the `NCC` rectangle | the cadets' coordinates (x 208…, z 386…) and the 3D view |
| 6.5 | The "ADMISSIONS OFFICE" sign plane is wider than its wall, so the first letter is clipped | visible in `screenshots/09_admin_hall.png` |
| 6.6 | The Admin Block sign reads "DMISSIONS OFFICE" from the camera angle inside the hall | same screenshot |
| 6.7 | The building label billboards overlap each other when many buildings are in view | visible in `screenshots/02_admin_block.png` |
| 6.8 | There is **no music** | the audio folder contains only the 632 voice clips |
| 6.9 | Energy never decreases, and the HUD shows the drinks-tried counter instead of a meaningful stat | `GAME_ANALYSIS.md` §9 |

---

## 7. How to close the remaining gaps — a 90-minute checklist

| Step | Action | Closes |
|---|---|---|
| 1 | Email the original author: ask for the model/audio licences and the missing `lv_*.jpg` thumbnails | 1.1 – 1.6, 2.1 |
| 2 | Get written confirmation that ANITS permits the rebuild to use its name and logo | 4.1 |
| 3 | Read `js/buddy.js`, `js/chat.js`, `js/callpool.js`, `js/flag.js` end-to-end and add the findings to `GAME_ANALYSIS.md` | 3.1 – 3.5 |
| 4 | Transcribe the phone-call pool into `data/callpool.json` | 3.4 |
| 5 | Decide the voice strategy (re-record vs TTS) and the music question with the client | 3.3, 4.3, 4.4 |
| 6 | Confirm the target Android device and fix the `low` preset numbers | 4.6 |
| 7 | Re-run the parity screenshot rig against the Godot build and file the differences | quality gate in `RECONSTRUCTION_ROADMAP.md` §9 |

---

## 8. Cross-references

[`GAME_ANALYSIS.md`](GAME_ANALYSIS.md) (the verified behaviour) ·
[`ASSET_MAPPING.md`](ASSET_MAPPING.md) (the fallback plan for every unknown licence) ·
[`EXTERNAL_ASSET_LIBRARY.md`](EXTERNAL_ASSET_LIBRARY.md) (the licence verification log) ·
[`RECONSTRUCTION_ROADMAP.md`](RECONSTRUCTION_ROADMAP.md) (where the open items land in the plan).
