# ANITS Godot 4 Port — Technical Report

This folder holds the print-ready source of **`docs/ANITS_Godot_Report.pdf`**, the
30-page technical report on porting the *ANITS College* web game to Godot 4.7.

| File | What it is |
|---|---|
| `report.html` | The report itself. Self-contained: the CSS is inline, there are no external fonts, no CDN and no network resources of any kind. Opens straight from disk. |
| `report.css` | The same style sheet, extracted from `report.html` for editing and diffing. Regenerated automatically by the build script — do not hand-edit it. |
| `build_report.ps1` | Builds the PDF with a headless Chromium browser (Microsoft Edge or Google Chrome). |
| `README.md` | This file. |

---

## Rebuilding the PDF

```powershell
# from the project root
powershell -ExecutionPolicy Bypass -File docs\report\build_report.ps1
```

The script:

1. locates `msedge.exe` (preferred) or `chrome.exe` in the standard
   installation locations — `%ProgramFiles(x86)%\Microsoft\Edge\Application`,
   `%ProgramFiles%\Microsoft\Edge\Application`,
   `%LOCALAPPDATA%\Microsoft\Edge\Application`, `%ProgramFiles%\Google\Chrome\Application`,
   `%ProgramFiles(x86)%\Google\Chrome\Application`,
   `%LOCALAPPDATA%\Google\Chrome\Application`;
2. re-extracts the `<style>` block from `report.html` into `report.css`;
3. runs the browser headless with `--print-to-pdf` and `--no-pdf-header-footer`
   (the browser's own header/footer band is switched off because the report
   draws its own running header and footer, with page numbers, inside the page
   boxes);
4. writes `docs/ANITS_Godot_Report.pdf`.

### Options

| Switch | Effect |
|---|---|
| `-Output <path>` | Write the PDF somewhere else. Defaults to `docs/ANITS_Godot_Report.pdf`. |
| `-Browser edge\|chrome\|auto` | Force a browser family. `auto` (the default) tries Edge first. |
| `-NoSyncCss` | Skip the `report.css` re-extraction. |

### Fallbacks

If the first attempt does not produce a PDF, the script retries with
`--headless=old` (for older browser builds) and then with the other browser
family. If nothing works it prints the exact manual command and exits with a
non-zero code. Nothing is overwritten silently — the previous PDF is removed
only immediately before a successful print.

### Manual alternative

Open `docs/report/report.html` in any browser, choose **Print → Save as PDF**,
set the paper size to **A4**, margins to **None**, and tick **Background
graphics**. Switch **Headers and footers off**. Save as
`docs/ANITS_Godot_Report.pdf`.

---

## Page structure

The report is 30 designed A4 pages, one `<section class="page">` each. Every
page carries its own running header (section name) and running footer (with a
literal `Page n of 30`), so the page numbers are always correct and the
pagination is stable — no reliance on CSS page counters, which Chromium does
not support outside `@page` margin boxes.

| Page | Section | Page | Section |
|---|---|---|---|
| 1 | Cover | 16 | Day 1 — steps 4 to 8 |
| 2 | Contents | 17 | HUD anatomy |
| 3 | Executive summary I | 18 | Front end / main menu |
| 4 | Executive summary II | 19 | Touch controls |
| 5 | At-a-glance specification | 20 | Admin Office interior |
| 6 | Porting method — translation map | 21 | The cast of sixty-four |
| 7 | Port pairs — the main gate | 22 | Voice, subtitles, no music |
| 8 | Port pairs — Admin Block and hall | 23 | Rendering — the desktop pipeline |
| 9 | Port pairs — CSE and IT Blocks | 24 | Rendering — the Android quality ladder |
| 10 | Port pairs — canteen and parade ground | 25 | Testing — the headless suite |
| 11 | Campus layout — the coordinate system | 26 | Testing — the tour and the mobile preview |
| 12 | Campus layout — the seventeen buildings | 27 | Known limitations and future work |
| 13 | Campus layout — streets, kerbs, markings | 28 | Build and deploy |
| 14 | Day 1 — the eight steps | 29 | Appendix A — controls reference |
| 15 | Day 1 — the gate, the marker, the office | 30 | Appendix B / C — credits and file map |

---

## Which screenshot feeds which section

All paths are relative to `docs/`.

### Godot build — `docs/screenshots/godot/` (captured by the scripted tour)

| File | Used in | Figure |
|---|---|---|
| `01_spawn_gate.png` | §3 (Figure 3.2), §6 (Figure 6.1) | main gate and spawn, side by side with the web build; the full desktop HUD |
| `02_guard.png` | §3 (Figure 3.6), §5 (Figure 5.1) | the security guard at the gate |
| `03_admin.png` | §3 (Figure 3.4), §5 (Figure 5.2) | inside the Admin Office, facing Laksmi |
| `04_cse.png` | §3 (Figure 3.8), §5 (Figure 5.3) | the CSE Block |
| `05_it.png` | §3 (Figure 3.10), §5 (Figure 5.4) | the IT Block |
| `06_canteen.png` | §3 (Figure 3.12), §5 (Figure 5.5) | the canteen and Arjun |
| `07_parade_ground.png` | §3 (Figure 3.14) | the NCC parade ground and the salute |
| `08_colonel.png` | §5 (Figure 5.6) | Colonel Singh and the cadet company |
| `09_campus_overview.png` | §4 (Figure 4.1) | the detached aerial overview of the campus |
| `10_campus_plan.png` | §4 (Figure 4.2) | the top-down plan view |
| `probe_cadets.png` | not used | a diagnostic capture, kept for reference |

### Web build — `docs/screenshots/` (captured from the original Three.js build)

| File | Used in | Figure |
|---|---|---|
| `01_main_gate_spawn.png` | §3 (Figure 3.1) | the web build's main gate and spawn |
| `02_admin_block.png` | §3 (Figure 3.3) | the web build's Admin Block exterior |
| `03_cse_block.png` | §3 (Figure 3.7) | the web build's CSE Block |
| `04_it_block.png` | §3 (Figure 3.9) | the web build's IT Block |
| `05_ncc_ground_colonel.png` | §3 (Figure 3.13) | the web build's parade ground |
| `09_admin_hall.png` | §3 (Figure 3.5) | the web build's Admin Block hallway |
| `10_canteen_vending.png` | §3 (Figure 3.11) | the web build's vending machines |
| `00_year_select.png` | referenced in §6 (Figure 6.2 caption) | the web front end, year screen |
| `00_character_select.png` | referenced in §6 (Figure 6.2 caption) | the web front end, character screen |
| `06_basketball_court.png` | not used | available if the court is documented later |
| `07_student_parking.png` | not used | available if the parking apron is documented later |
| `08_temple.png` | not used | available if the temple is documented later |

---

## Expected screenshot filenames (not yet captured)

Four figures in the report are **placeholders**: a dashed frame that prints the
exact filename to drop in. Save the real capture into `docs/screenshots/godot/`
with exactly these names, then replace the placeholder block in
`report.html` with an `<img>` element pointing at it:

```html
<img src="../screenshots/godot/<name>.png" alt="…">
```

| Expected filename | Section | Page | What to capture |
|---|---|---|---|
| `menu.png` | §6 — The front end | 18 | The Godot main menu: the ANITS logotype, the "PLAYING AS …" line and the START GAME button, at 1920 × 1080. |
| `touch_hud.png` | §7 — Touch controls | 19 | The phone layout, taken with `-- --touch-preview` at a 20:9 viewport: the stick bottom-left, E / G / RUN bottom-right, the minimap top-right. |
| `admin_office.png` | §8 — Admin Office interior | 20 | A wide view of the waiting room from the south-east corner: both sofas, the rug, the coffee table, the plants, the wall clock and the glass-doored partition. |
| `phone_android.png` | §7 — Touch controls | 19 | A real Android handset capture, or the mobile-renderer pass, to close the gap recorded in §11.3 and §12. |

A fifth filename is referenced in the plan but not yet used by a placeholder:

| Expected filename | Where it would go |
|---|---|
| `phone_android.png` | §7 / §11.3 — the device capture that replaces the substituted mobile validation. |

---

## Editing notes

* **Benchmarks.** The report deliberately contains no measured frame-rate
  numbers. Four empty cells in §10 are marked with the HTML comment
  `<!-- BENCH: -->` and print as a dash. Replace the comment with the measured
  value when a device run is available — do not fill them in with estimates.
* **Honest statements.** §4 (mobile testing) and §12 (limitations) record that
  physical-handset testing was replaced by the mobile-renderer and
  touch-preview passes, and that the headless suite's `roads == 8` assertion
  needs re-baselining against the active `campus_data.json` (12 street
  rectangles). Keep both statements until the underlying work is done.
* **No music.** §9 states plainly that the build ships voice and dialogue only
  and no music bed, matching the original.
* **Fonts.** Georgia for body text, Helvetica/Arial for headings and tables.
  Both are present on every Windows and macOS machine; nothing is downloaded.
* **Page numbers.** The footers are literal text (`Page 7 of 30`). If you add or
  remove a page, update the footers and the contents table on page 2.

---

## Verification performed on the layout

The 30-page pagination was verified by rendering the document in headless
Chromium and measuring every page box for overflow, and by confirming that the
exported PDF contains exactly 30 page objects with all images embedded
(~14 MB). No content is clipped and no page bleeds into the next.
