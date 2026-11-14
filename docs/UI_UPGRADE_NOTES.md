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
