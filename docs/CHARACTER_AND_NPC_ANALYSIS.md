# CHARACTER_AND_NPC_ANALYSIS.md — the player and the 64 people on campus

**Evidence basis:** `ANITS-WEB GAME/js/game.js` (NPC table, capsule/Remy/Amy rigs, animation
clips), `js/girls.js` (the nine girl NPCs), `js/voice.js` (voice profiles), `js/levels.js`
(scripted dialogue), `js/callpool.js` (phone-call lines), `assets/anims/*.json` (retargeted
sit and basketball clips), plus the runtime NPC census.

**Tags:** [V] verified · [O] observed in screenshot · [U] unknown · [P] proposed.

---

## 1. The player character

| Property | Boy ("Mike") | Girl ("Amy") | Evidence |
|---|---|---|---|
| Model file | `assets/models/b_walk.bin` (2.60 MB FBX, Mixamo-derived) | `assets/models/cadet_amy.glb` (2.75 MB glTF) | [V] `assets.js` |
| Idle animation | `IDLE_DATA` — a retargeted **Breathing Idle**, 9.93 s, loops seamlessly in place | same clip retargeted onto the Amy rig (hips scaled by `hipY / 0.8324`) | [V] |
| Locomotion | `RUN_DATA` — running loop, 0.70 s | same | [V] |
| Walk | the FBX's own walk clip; the hips' X/Z are locked so it plays **in place** and the root motion is measured as the stride length | walk clip embedded in `cadet_amy.glb` | [V] |
| Drinking | the separate "Drinking" FBX is swapped in only while drinking | — (the girl build does not load `b_drink.bin`) | [V] `assets.js` |
| Sitting | `assets/anims/sit.json` — a retargeted sit clip (hips position in metres + quaternions per bone), boy and girl variants | same | [V] |
| Salute | `pclips.salute` clip; the salute lasts `clip.duration` seconds | same | [V] |
| Basketball | `assets/anims/bball.json` — the shot clip used by the Day-5 shootout | same | [V] |
| Uniform | year-dependent body texture + vertex-colour band swap | same **plus a procedural chunni** (navy for 2025, black for 2023) generated from the Spine2/Neck/Arm/Hips bones | [V] `js/uniform.js` |
| Height | normalised to 1.8 m by the renderer (`g.h / hgt`) | same | [V] |
| Spawn | map `(122,448)` → world **(−65.1, 0, 138.6)**, yaw π (facing north toward the gate), outside the main gate | same | [V] |
| Walk speed | 2.4 m/s (measured ≈2.3) | same | [V] |
| Run speed | 5.6 m/s | same | [V] |
| Energy boost | ×1.3 for 30 s | same | [V] |

**Uniform variants** (2024 is the "original" cream/brown look; 2023 and 2025 swap the body
texture and recolour three vertex-colour bands):

| Year | Texture file | Shirt colour | Trousers colour | Chunni (girl) |
|---|---|---|---|---|
| 2023 | `uni2023_boy.jpg` / `uni2023_amy.jpg` | rose `#f0a6c4` | black `#16161b` | `#16161b` / `#050507` |
| 2024 | (original texture) | cream `#e8dfc4` | brown `#3b2a1f` | — |
| 2025 | `uni2025_boy.jpg` / `uni2025_amy.jpg` | sky `#87ceeb` | navy `#101a4a` | `#0b1544` / `#040a28` |

> **Port note.** The player is the single most-seen asset in the game. A CC0 replacement that
> keeps the same skeleton hierarchy (Mixamo-style `mixamorig` bone names) is the safest swap:
> see [`FREE_GODOT_ASSETS.md`](FREE_GODOT_ASSETS.md) (Quaternius Ultimate Animated Character,
> KayKit Character Pack, Universal Animation Library).

---

## 2. NPC census — 64 people [V]

| Group | Count | Model | Behaviour |
|---|---|---|---|
| **Main quest NPCs** | 6 | mixed (see below) | static, full dialogue, mission-linked |
| **NCC cadets** | 18 | capsule body + beret | drill formation, salute, one-line dialogue |
| **Route students** | 9 | Remy model (recoloured) | walk a fixed route, loop |
| **Basketball players** | 3 | Remy model | static on the court, one line |
| **Named walkers** | 10 | Remy model | walk a 2–3 point route, two lines each |
| **Standing groups** | 8 | Remy model | static, two lines each |
| **Remy** | 1 | Remy model | walks a 9-point route across campus |
| **Girl NPCs** | 9 | Amy rig | 5 walk a route, 4 stand still; own names, heights and tints |
| **Total** | **64** | | |

The render style is deliberately low-poly: staff and students are **capsules** (cylinder body
+ sphere head, with two small black eyes) unless a real model is supplied; the cadets wear a
half-sphere **beret**. [V][O]

---

## 3. The six main NPCs

| Id | Name | Map pos | World X,Z (m) | Colour | Height | Facing | Model | Role |
|---|---|---|---|---|---|---|---|---|
| `guard` | **Bajirao (Security)** | 134,438 | −56.7, 131.6 | `#2f5fa8` blue | 1.7 | 0 | `b_guard.bin` | gate check, ID card, day-1 tutorial |
| `clerk` | **Laksmi (Admin)** | 174,337 | −28.7, 60.9 | `#c77ba3` pink | 1.7 | π | `laksmi.glb` | admissions, fee slip, stamps, library card form; also sits at her desk inside the office annex |
| `prof` | **Prof. Rao (HOD CSE)** | 129,287 | −60.2, 25.9 | `#6a5a3a` brown | 1.7 | 1.5π | Remy model | class, signatures, quizzes |
| `suresh` | **Suresh (Lab Assistant)** | 271,243 | 39.2, −4.9 | `#3a8a7a` teal | 1.7 | 0 | Remy model | lab manuals, library card handover |
| `arjun` | **Arjun (Friend)** | 268,128 | 37.1, −85.4 | `#e0883a` orange | 1.7 | 1.5π | Remy model | the friend; canteen, basketball, canteen challenge, fest |
| `colonel` | **Colonel Singh (NCC)** | 214,396 | −0.7, 102.2 | `#5f6b2f` olive | 1.85 | 1.5π | `b_colonel.bin` | parade drill, salute, Day-6 mission |

> When the player is a girl, Arjun's voice switches to the female profile `sushma`, and the
> Colonel's line becomes *"Stand tall, young lady!"* instead of *"…young man!"*. [V]

### 3.1 Dialogue catalogue (verbatim) [V]

**Bajirao (Security)**
- step 0: *"Good morning! Welcome to ANITS. First day?"*
- step 0: *"The Admin Block is the big white building ahead with the ANITS sign on its roof. Your documents must be submitted there."*
- step 0: *"Walk down the main road and talk to Laksmi (Admin) at the office."*
- idle: *"Stay safe and keep your ID card with you!"*
- Day ≥2 gate step: *"Stop! Students need to show their ID card at the gate."* / *"Open your bag with the B key and press Show on your ID card."*
- after showing the ID: *"Thank you! Welcome to ANITS. Go in!"*

**Laksmi (Admin)**
- step 2: *"Ah, a new student! Please hand over your admission documents."*
- step 2: *"...Everything looks fine. Your ID card will be ready by evening."*
- step 2: *"Now go and meet Prof. Rao, the HOD of CSE. Walk straight through the central hallway of this building and you will reach the roads to every block. His block is the blue one beyond it."*
- idle: *"Your ID card is being printed. Please check later."*
- Day 2: *"Fees? Yes, here is your fee slip. The total is Rs. 250."* / *"Take cash from the bank first, then come back to pay me."* / *"Thank you! Rs. 250 received. Here is your receipt."* / *"Now show this receipt to Prof. Rao."*
- Day 4: *"A library card? Fill this form, then go to the library in the west wing."* / *"Answer a small quiz there and the librarian will issue your card."*
- Day 7: *"Stamp done. Take it back to Suresh quickly!"*

**Prof. Rao (HOD CSE)**
- step 3: *"Welcome to the CSE department! I am Prof. Rao."*
- step 3: *"This semester you need a lab manual. Collect it from Suresh at the IT Block, the tall building on the east side."*
- step 3: *"And remember, ANITS is not only about studies."*
- idle: *"Study hard and stay curious!"*
- Day 2: *"Ah, the fee receipt. Very good, you are officially a student!"*
- Day 3: *"Your classroom? Check the west wing, Room 204."* / *"Hurry, the first bell rings soon."*
- Day 7: *"Signature done. Now take the stamp from Laksmi (Admin)."*
- Day 10: *"Welcome to your first class! Let us begin with a short quiz."* / *"Excellent! Class dismissed. Welcome to ANITS, your best four years begin now!"*

**Suresh (Lab Assistant)**
- step 4: *"Hello! Your lab manual? Here it is, still warm from the printer."*
- step 4: *"The canteen is just up the road near the Civil Block. Your friend Arjun is waiting for you there."*
- idle: *"Labs open at 9. Do not forget your record!"*
- Day 4: *"Your library card is ready! Please keep silence inside."*
- Day 7: *"Lab manual run! Get Prof. Rao's signature first."* / *"Perfect! All signatures are complete. Lab entry unlocked!"*

**Arjun (Friend)**
- step 5: *"Hey! You made it! Come, chai is on me."*
- step 5: *"Tip: there are cold-drink vending machines at both canteens, here and near the main gate. Stand in front and press E to buy a drink!"*
- step 5: *"Listen, the NCC cadets are on the big ground near the power station."*
- step 5: *"If you give their Colonel a proper salute, the whole company will remember you. Stand near him and press G!"*
- idle: *"Chai and samosa, the perfect combo!"*
- Day 3: *"Hey! Over here! I saved you a seat in the right room!"*
- Day 5: *"Super shots! You are a proper player!"*
- Day 8: *"You won! Chai and samosa are on me!"*
- Day 9: *"Your dance was super! Everybody clapped!"*

**Colonel Singh (NCC)**
- step 6: *"Stand tall, young man/lady! In the NCC we greet with a salute."* / *"Come close and press G to salute."*
- step 7: *"Jai Hind! A fine salute, cadet."* / *"Welcome to ANITS, fresher. May this college be the best chapter of your life."* / *"You survived your first day. Well done!"*
- idle: *"Jai Hind!"*
- Day 6: *"Cadet, today is the parade drill. Follow my commands sharply!"* / *"Excellent parade! You marched like a true cadet. Jai Hind!"*

---

## 4. Supporting casts

### 4.1 The 18 NCC cadets [V]
- Position: map `(208 − r·4.2, 386.25 + k·3.9)` for `r = 0…2`, `k = 0…5` → three rows of six
  on the sand field. World x −10.8 … −4.9, z 95.4 … 109.0.
- Appearance: olive uniform `#8c8a52`, **navy beret `#1a2a5a`**, facing π/2 (west, toward the
  parade ground).
- Dialogue: only *"Jai Hind! Sir is watching, I cannot talk now!"* (and its Telugu translation).
- Behaviour: they salute in unison with the player (within 16 m) and shout the chorus with
  per-cadet pitch and delay.
- `[O]` `screenshots/05_ncc_ground_colonel.png` shows the company and the Colonel.

### 4.2 Route students (9) [V]

| # | Colour | Route (map px) |
|---|---|---|
| 1 | `#3b82c4` | (125,342) → (245,342) → (245,120) |
| 2 | `#c04a4a` | (100,288) → (238,288) → (238,244) → (100,244) |
| 3 | `#8a5ac0` | (80,175) → (80,340) |
| 4 | `#d0a030` | (160,368) → (235,368) |
| 5 | `#2a9a6a` | (245,130) → (245,342) |
| 6 | `#c06a8a` | (100,244) → (238,244) → (238,288) |
| 7 | `#2aa6a0` | (140,343) → (169,343) → (169,170) |
| 8 | `#e07a30` | (205,343) → (160,343) → (160,170) |
| 9 | `#7a8ad0` | (169,200) → (169,343) → (205,343) |

Each cycles the route; idle lines come from the generic pool.

### 4.3 Basketball players (3) [V]
`#d05030` at (290,275), `#2060c0` at (308,288), `#e0b020` at (320,262); line *"Nice shot! Come
play after class."*

### 4.4 Named walkers (10) [V]

| Name | Route | Lines |
|---|---|---|
| Ravi | (245,342) ⇄ (125,342) | *"Hey! Ravi here, CSE second year. Need any help finding a class?"* / *"The labs upstairs are cold, carry a jacket!"* |
| Kiran | (169,170) ⇄ (169,343) | *"I am rushing to the library before the queue gets long."* / *"Have you collected your lab manual yet?"* |
| Teja | (80,340) ⇄ (80,175) | *"Hi! Teja, ECE. The canteen samosas run out by noon, go early!"* / *"Parking is a mess today, ha."* |
| Harsha | (238,244) → (238,288) → (100,288) | *"Late again! The professor will kill me."* / *"First day? Do not worry, it gets easier."* |
| Vamsi | (245,120) ⇄ (245,342) | *"Bro, did you see the NCC parade this morning? So sharp!"* / *"I am heading to the canteen for chai."* |
| Charan | (160,170) ⇄ (160,343) | *"Exams are near and I have not opened a single book..."* / *"Do you know a good notes shop around here?"* |
| Sai | (100,244) ⇄ (238,244) | *"Hello! Sai from IT. If you need project partners, find me."* / *"The fest rehearsals start this week!"* |
| Mahesh | (235,415) → (235,368) → (160,368) | *"I just got my ID card renewed. Bajirao is strict but fair."* / *"Salute the Colonel when you pass the ground, he likes it."* |
| Naveen | (205,343) → (169,343) → (169,200) | *"Do not sit in the front bench if you did not do the assignment!"* / *"Cold drinks from the vending machine are a lifesaver in this heat."* |
| Dinesh | (140,343) → (245,342) | *"I am looking for my friend, have you seen a guy in a blue shirt?"* / *"Welcome to ANITS!"* |

### 4.5 Standing groups (8) [V]

| Name | Map pos | Facing | Lines |
|---|---|---|---|
| Anil | 262,136 | 0.8π | *"We are waiting for the chai to cool, ha ha."* / *"Join us! The canteen is the best place on campus."* |
| Pavan | 264,133 | 1.8π | *"Anil never finishes his tea, he just talks."* / *"Have you met Prof. Rao yet? He is nice."* |
| Rohit | 172,300 | 0.5π | *"Shh, I am revising for the test."* / *"The library is quiet, but outside it is nicer."* |
| Varun | 174,298 | 1.5π | *"We are discussing the assignment. Want to join?"* / *"First years always look lost on day one!"* |
| Manoj | 213,414 | π | *"I come early to watch the NCC drill, it is impressive."* / *"Colonel Singh is very strict about discipline."* |
| Girish | 141,406 | 0.2π | *"Bajirao knows everyone by name, even the visitors!"* / *"The gate is busiest at nine."* |
| Sunil | 296,282 | 1.2π | *"Nice court, right? Come play after class."* / *"I score more than I attend class!"* |
| Deepak | 314,272 | 0.3π | *"Pass the ball! Oh, hi there."* / *"Freshers' match is coming up, join our team."* |

### 4.6 Remy (1) [V]
Route (map): (118,426) → (118,360) → (140,343) → (160,343) → (160,286) → (160,215) → (160,286)
→ (160,343) → (246,343). Lines: *"Hey! I'm Remy, second year. First day at ANITS?"* /
*"Tip: the canteen near the Civil Block has the best chai."* / *"Sorry, I have to run. I'm late for class!"*

### 4.7 Girl NPCs (9) [V] `js/girls.js`

| Name | Behaviour | Map position / route | Height (m) | Tint (RGB) | Lines (first line) |
|---|---|---|---|---|---|
| Divya | walks | (245,330) ⇄ (245,150) | 1.62 | 1 / 0.86 / 0.8 | *"Oh hi! Sorry, I'm running late to submit my lab record!"* |
| Anjali | walks | (110,342) → (230,342) | 1.58 | 0.82 / 0.9 / 1 | *"Hi! I'm Anjali, ECE first year. Which block are you looking for?"* |
| Priya | walks | (164,170) ⇄ (164,280) | 1.66 | 1 / 0.78 / 0.9 | *"Hey fresher! I'm Priya. I'm rushing to the library before the books are gone."* |
| Sneha | walks | (85,200) ⇄ (85,330) | 1.60 | 0.9 / 1 / 0.85 | *"Hi! Sneha…"* |
| Kavya | walks | (110,286) → (230,286) | 1.64 | 1 / 0.95 / 0.72 | (running to the canteen by noon) |
| Pooja | stands | 118,336 | 1.57 | 0.88 / 0.8 / 1 | *"Hi! I'm Pooja. This is my first week too, everything feels so big!"* |
| Meena | stands | 205,336 | 1.63 | 1 / 0.82 / 0.76 | *"Namaste! I'm Meena, third year. Ask me anything about the campus."* |
| Swathi | stands | 190,297 | 1.59 | 0.85 / 1 / 0.95 | *"Shh... I'm memorising my notes for the test."* |
| Roja | stands | 238,200 | 1.61 | 1 / 0.9 / 0.8 | *"Hi there! I'm Roja. I come from a village near Vizag…"* |

All girl NPCs use the **Amy rig** with the retargeted idle/run clips and their own colour
tint, so the campus reads as co-educational.

### 4.8 Generic student lines (used by the 9 route students) [V]
1. *"Hey! New here? The canteen next to the Civil Block makes the best chai."*
2. *"Parking fills up by 9 AM. Come early next time!"*
3. *"The CSE labs are on the upper floor. Good luck!"*
4. *"Our NCC cadets practise on the big ground every morning."*
5. *"Exams are near... I need to study. See you later!"*
6. *"Basketball ground is open after 4 PM. Join us!"*

---

## 5. Animation system

| Animation | Source | Duration | Loops | Used by |
|---|---|---|---|---|
| `walk` | `b_walk.bin` (boy) / embedded clip (Amy) | model-defined | yes | player when moving; character-select preview |
| `idle` (Breathing Idle) | `IDLE_DATA`, retargeted Mixamo FBX | 9.93 s | yes | player + all Amy-rig NPCs at rest |
| `run` | `RUN_DATA`, retargeted Mixamo FBX | 0.70 s | yes | player when running; Amy NPCs on their routes |
| `drink` | separate "Drinking" FBX | — | no | swapped in for the duration of a drink |
| `sit` | `assets/anims/sit.json` (retargeted, hips in metres + per-bone quaternions) | — | no | sitting on benches and sofas |
| `salute` | `pclips.salute` | clip duration | no | player + the NCC company |
| `bball` | `assets/anims/bball.json` | — | no | the basketball shootout |
| `wave` / `talk` | arm groups on the capsule NPCs (`hold.userData.arms`) | — | yes | talking NPCs |

Implementation notes worth carrying to Godot [V]:
- All walk clips are **forced to play in place**: the `Hips.position` X and Z channels are
  overwritten with their first values, and the stride length is measured from the original
  clip so the foot-slide speed matches the movement speed.
- The girl rig's clips are scaled by `hipY / 0.8324` so the retargeted motion lines up with the
  Amy skeleton's hip height.
- The capsule NPCs animate only their arm groups; Remy-based NPCs animate the skeleton and
  hold a "rest" frame when they stop to talk (`REST = [1/24, 13/24]` of the cycle).
- Remy's walk cycle is time-scaled so his feet match his 1.5 m/s walking speed (`TS = 0.9`).

---

## 6. Voice system

### 6.1 Voice profiles (`js/voice.js`) [V]

| Key | Gender | Pitch | Rate | Used for |
|---|---|---|---|---|
| `you` | male | 1.28 | 1.02 | the player (boy) |
| `youF` | female | 1.14 | 1.00 | the player (girl) |
| `sushma` | female | 0.98 | 1.02 | Arjun when the player is a girl |
| `arjun` | male | 1.12 | 1.08 | Arjun |
| `guard` | male | 0.72 | 0.92 | Bajirao |
| `clerk` | female | 1.00 | 0.95 | Laksmi |
| `prof` | male | 0.82 | 0.90 | Prof. Rao |
| `suresh` | male | 1.05 | 1.00 | Suresh |
| `colonel` | male | 0.55 | 0.85 | Colonel Singh |

Any other NPC gets a deterministic pseudo-random profile derived from a counter
(pitch 0.70–1.14 male / 0.95–1.24 female, rate 0.90–1.14). Voices are chosen from the
browser speech-synthesis list, preferring `en-IN` then `en-GB`, and matching the name against
a female/male name pattern.

### 6.2 Clip banks [V]

| Bank | Entries | Content |
|---|---|---|
| `assets/audio/clips.json` | 340 | male/neutral voice lines, `[telugu, mp3Path]` |
| `assets/audio/clips_girl.json` | 310 | female voice lines |
| `assets/audio/*.mp3` | 632 files | the actual recordings |

Playback order: if an MP3 exists for the line → play it; otherwise → speak it with the browser
TTS; if no TTS voice exists → wait `max(1200, len × 58 + 600)` ms and move on. The Telugu text
is used for the subtitle strip when the player selects Telugu subtitles, and is spoken with a
`te-IN` voice when one is available.

### 6.3 NCC chorus [V]
When the player salutes, every cadet within 16 m plays the "Jai Hind!" clip with a per-cadet
playback rate (male 0.88–1.08, female 0.96–1.08, or 1.26–1.40 if no female clip exists) and a
volume that falls with distance: `clamp(1.15 − d/20, 0.25, 1) × 0.6`. The cadets start 850–1300 ms
after the player.

### 6.4 Phone calls (`js/callpool.js`, `js/story.js`) [V]
- The call bank holds several dozen scripted exchanges, keyed by player gender
  (`window.__POOL.boy` / `.girl`), plus separate cadet pools (`__CADET_M`, `__CADET_F`).
- The overlay shows an animated ring, the friend name ("Best friend – mobile"), Decline and
  Accept; after accepting, the captions panel streams the conversation and `End call` hangs up.
- Calls start automatically 18–38 s after the game starts and only while mission step `si` is
  < 5 (2–4 on later days).

---

## 7. Port plan for characters

| Original | Godot approach | Notes |
|---|---|---|
| `b_walk.bin` + `IDLE_DATA` + `RUN_DATA` | One `CharacterBody3D` with an `AnimationTree`; retarget the CC0 animations onto it | Keep the "play in place" trick — Godot's `AnimationPlayer` clips from Mixamo already are in-place if the root motion is stripped |
| `cadet_amy.glb` | Second `CharacterBody3D` variant (or the same scene with a different mesh + `chunni` node) | The chunni can be re-authored as a simple cloth mesh parented to the chest bone |
| Capsule NPCs | A single `npc_capsule.tscn` (cylinder + sphere + eyes + beret) with `MultiMesh`-free simple meshes | 18 cadets share one mesh → use `MultiMeshInstance3D` for the static formation |
| Remy-model students | One skinned `MeshInstance3D` scene, instanced 29× | Colour per instance via `instance_shader_parameters` or a material override |
| Girl NPCs | 9 instances of the Amy scene with tint material overrides | Route them with `Path3D`/`NavigationAgent3D` |
| Voice | `AudioStreamPlayer3D` per NPC + `Dialogue Manager` resources | Convert MP3 → OGG; keep `clips.json` as the source-of-truth table |

---

## 8. Cross-references

[`GAME_ANALYSIS.md`](GAME_ANALYSIS.md) (mission scripts and dialogue triggers) ·
[`BUILDING_INVENTORY.md`](BUILDING_INVENTORY.md) (where each NPC stands) ·
[`ASSET_MAPPING.md`](ASSET_MAPPING.md) (character asset replacements) ·
[`FREE_GODOT_ASSETS.md`](FREE_GODOT_ASSETS.md) (CC0 character/anim packs) ·
[`MISSING_INFORMATION.md`](MISSING_INFORMATION.md) (licences of the original characters).
