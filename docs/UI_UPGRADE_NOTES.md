# UI & animation upgrade (front end only)

Changed file: `src/ui/main_menu.gd` (gameplay, HUD, story, campus, characters untouched).

- Glass panels (translucent, rounded, soft shadow) behind the year, name and main-menu screens; softer glass buttons.
- Animated screen entrance: fade + staggered rise of every element.
- Hover / focus lift and press squash on all buttons and cards; level thumbnails zoom on hover.
- Slow Ken-Burns drift on the campus photo and five floating light orbs (cheap textured quads, no particles).
- Year number "pops" when the year changes; selected character card glows gold.
- Level grid: completed (green), current (pulsing gold halo, NEW), locked (dimmed + padlock); "N / 10 DAYS COMPLETED" progress bar.
- Loading screen: spinner, breathing crest, slow zoom, glowing bar with light sweep, percentage, rotating quotes, pulsing "CLICK ANYWHERE TO START".
- Updated screenshots in `docs/screenshots/godot/menu_*.png`.

Verified with Godot 4.7.2 (headless import, 66 tests pass, `--menu-shot` run without script errors).

## Graphics & in-game HUD upgrade

Changed files: `src/main.gd`, `src/ui/hud.gd`, `src/world/props_factory.gd`,
`src/world/campus_builder.gd`, `verify.ps1`.

Graphics
- Renderer-aware post stack: desktop Forward+ gets FXAA + SSAO; desktop GL
  Compatibility and the web export get 2x MSAA; mobile keeps only the cheap
  grade. All three paths share a full-screen vignette + bottom gradient shader.
- Deeper procedural sky, warmer sun, exposure 0.88, contrast 1.05, saturation
  1.03 (desktop) / 1.03/1.02 (web), stronger glow with a higher bloom threshold.
- Natural turf palette (olive-shifted greens, stronger mowing stripes, extra
  fine mottling), lighter asphalt tint (0.72 -> 0.98) with softer kerb dust,
  warmer sand, and calmer building emission (0.20 -> 0.10) with 0.85 roughness.
- Adaptive quality ladder unchanged in shape; SSAO/MSAA are dropped first,
  shadows switch off at step 3, and screenshot modes skip degradation.

In-game HUD
- Mission card now shows 8 step pips; completed steps fill gold and the active
  step pulses.
- Wallet and energy are driven by `EventBus` signals, so both update live;
  wallet pops on change and the energy bar animates and changes colour.
- Glass toast pill with sparkle icon for mission/dialogue notifications.
- Minimap gained a compass rose, N/E/S/W ticks, a pulsing objective ring and a
  dotted bearing line to the current objective.
- Pause overlay has an entrance animation; buttons have hover lift and press
  squash; HUD elements stagger in at mission start; dialogue lines fade and the
  panel pops.
- Touch controls remain laid out for thumbs at 1280x720 and above; all keyboard
  prompts still show on desktop.

Visual pass verified with the scripted tour (all 8 missions, 10 gameplay
screenshots regenerated).
