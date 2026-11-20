# ANITS College Simulation (3D Story Game)

## Visual refresh

This edition preserves the original vanilla JavaScript / Three.js game, its seven
days, original models and audio, saved progress, controls, mission locations,
navigation, collision boxes, and gate hinges. Building façades now use subtle
locally generated stone and glass finishes, clearer window framing and roofline
details. When a person is within the existing talk range (or in conversation),
the selected person's actual animated silhouette has a crisp white outline.
The outline adds no collider, no gameplay action and no animation; reduced-motion
players see the same static cue. Only the person closest to the player is outlined
and the effect stops when out of range. Graphics quality settings still control
material resolution and shadows. All artwork needed to run remains in this folder.

All files for the ANITS College 3D simulation game have been saved locally.

## Gate and yellow-white walking paths update

- The **two side paths of the main entrance drive** are now 0.35 m above the road. Their northern and southern ends have gradual slopes, and three pedestrian crossing points on each side have additional road-to-path ramps. The camera, characters and walking height follow the same surfaces.
- Walking tiles at the gate, around the academic circulation roads, outside the Gate Canteen / Bank, and by the sand field alternate yellow and white. Path border blocks along the campus roads and raised paths alternate the same two colours.
- Existing entrances, gate hinges, controls, missions and map coordinates remain in place. No online service is required. Use the instructions below to run this complete project locally.

## Clear-daylight / mobile-graphics update

- The campus now uses balanced clear daytime light, a matching sky and distance haze, and softer shadow bias. On phones with shadows enabled, shadow maps update periodically or when the player moves to a new area rather than on every third frame.
- Mobile graphics use a sharper starting resolution and avoid dropping below a readable pixel ratio. Nearby ground textures have stronger angle filtering and road detail has less noisy grain.
- Static trees are drawn in small batches instead of hundreds of separate draw calls; lower-tier phones draw fewer distant grass tufts, shrubs and clouds. Higher settings retain the fuller scene.
- Removed the raised path running parallel to the entrance sidewalk almost into the main gate. The sand-field crossing and the intended road sidewalks remain; gate coordinates, hinges and gameplay collisions are unchanged.

Settings > Graphics lets you select LOW, MEDIUM or HIGH if you want to compare performance on your phone. AUTO picks a conservative mobile setting; add `?perf=1` to the game URL for an FPS / draw-call readout. Frame rates vary by device.

## Campus environment edition

This edition keeps the v7 map coordinates, missions, parade stages, gate hinges,
collisions, characters, controls, lighting, sky, crowd and props. Only the
environment's visual treatment has changed:

- Tiled paving, mottled grass, exposed earth, mineral court edging and worn
  asphalt replace flat colour planes. The main entrance drive has paved margins,
  a two-lane carriageway, crossings, painted edges and concrete kerbs.
- Existing academic block models retain their entrances and footprints, now
  framed with shaded glazing, floor bands, roof parapets and block nameplates.
  The v7 gate retains its hinge and clearance geometry with additional relief.
- The gate, main circulation spine, teaching blocks and open grounds remain in
  their existing relative positions so story destinations do not move. The
  arrangement is an **approximation**, not a surveyed campus plan. Public
  references: [ANITS at a glance](https://www.anits.edu.in/glance.php) and
  [ANITS prospectus](https://www.anits.edu.in/prospectus_files/Prospectus-2019-20.pdf).

Visual layer: `js/campus-environment.js`. Its textures are generated locally at
runtime; no internet connection or extra dependencies are required for them.
Gameplay was not run or play-tested for this visual delivery at the owner's request.

## How to Play on Localhost

### Option 1 (Double Click):
Double click **`start.bat`** in this folder. It will start the local HTTP server and automatically open the game in your default browser at `http://localhost:3000`.

### Option 2 (Command Line):
1. Open PowerShell or Terminal in this folder (`C:\Users\AKHILBOSS\Desktop\anits-college`).
2. Run:
   ```bash
   node server.js
   ```
   or
   ```bash
   npm start
   ```
3. Open your browser to: [http://localhost:3000](http://localhost:3000)

## Controls:
- **W, A, S, D**: Move
- **Shift**: Run
- **E**: Talk / Interact
- **F**: Show your ID card to the security guard (when standing near him at the gate)
- **G**: Salute
- **Mouse Drag**: Look around
- **1-5**: Select / Drink
- **Esc**: Pause / Close

## Day 2 upgrade (Pay the Fees)
- Level 1 is unchanged (roam and chat freely).
- Bank ATM withdrawal now plays a cinematic: card in, PIN, notes come out one by one, and you tap/press SPACE to take the cash into your wallet.
- Paying Laksmi: drag (or tap) each note onto her desk, she counts it, you submit the Fee Payment Report (stamp animation).
- Receipt: sign it with finger or mouse, press ACCEPT RECEIPT. The signed receipt is saved in your BAG (press B).
- Code: `js/day2.js` (new), small hooks in `js/game.js`, `js/levels.js`, `js/inventory.js`, `js/assets.js`.

## Day 7 upgrade (Lab Manual Run)
- Suresh: sign with finger/mouse to take the lab manual form.
- Prof. Rao: watch him sign the form (animated pen).
- Laksmi: press the stamp yourself, where you tap/click on the form.
- Suresh again: sign the lab register; the signed Lab Manual Form is saved in your BAG (press B).

## Day 3 upgrade (Find Your Classroom)
- Prof. Rao says Room 204. Walk to the west wing and a 3-puzzle sequence starts:
  1. Lift: pick the right floor from the room number.
  2. Four doors with math plates (e.g. 408 / 2): find the one that equals 204. Wrong doors show a funny peek.
  3. Door code: solve the number sequence to open the door.
- Code: new `floor` mini-game in `js/mini.js`, Day 3 steps in `js/levels.js`.

## Levels and mobile play
Only Day 1 is open at first. Each completed day unlocks the next; there is no developer unlock button or unlock-all URL option. Existing saves, items and level progress are cleared once for this release; your player name and graphics/audio choices stay. You can reset progress again from Settings.

On a phone, rotate to landscape and use the left thumb to move, right thumb to look, and the on-screen action buttons. The game adjusts its render resolution to performance. The hosted menu also provides a **Download Full Game .ZIP** link; the downloaded ZIP is already a complete standalone game with its own `server.js`, assets and start scripts, and does not need the hosted service to play.

## Day 4 upgrade (Library Card)
1. Laksmi (Admin Block): sign the application as applicant, then she signs as Admin Officer.
2. Prof. Rao (CSE Block): hand over the form, he signs as HOD.
3. Suresh (IT Block): lab assistant signature.
4. Walk to the Civil Block library (near the canteen) and submit all three signatures. The librarian verifies each one, the library card is issued and saved in your BAG.
- Code: `libsign` in `js/day2.js`, steps in `js/levels.js`, `cine` support for walk-to steps in `js/game.js`.
