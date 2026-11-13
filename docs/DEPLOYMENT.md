# Deployment — Godot 4.7 Web Build on GitHub Pages

How the ANITS College Simulation web build is exported and published to GitHub Pages.

- Project root: `C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project`
- Godot binary: `C:\Users\AKHILBOSS\Desktop\Godot_v4.7.2-stable_win64.exe`
- Export preset: `export_presets.cfg` → preset **"Web"** (platform `Web`)
- Export output: `build/web/` (committed to git, deployed by `.github/workflows/pages.yml`)
- Workflow: `.github/workflows/pages.yml` (push to `main` → GitHub Pages)

---

## 1. Prerequisites

### 1.1 Export templates (REQUIRED — currently NOT installed)

Godot needs the web export templates. Check:

```powershell
$env:APPDATA\Godot\export_templates\4.7.2.stable\web_release.zip
$env:APPDATA\Godot\export_templates\4.7.2.stable\web_debug.zip
```

> **Current state:** `%APPDATA%\Godot\export_templates\` exists but is **empty** — there is no
> `4.7.2.stable` folder, so `web_release.zip` / `web_debug.zip` are **missing**.
> The web export will fail with "No export template found at the expected path" until they are installed.

Install them one of these ways:

1. **Editor (recommended):** `Editor > Manage Export Templates...` → download **4.7.2.stable**.
2. **Manual:** download `Godot_v4.7.2-stable_export_templates.tpz` from the official releases page
   and extract it into `%APPDATA%\Godot\export_templates\`, renaming the inner folder to
   `4.7.2.stable` so you end up with:
   `%APPDATA%\Godot\export_templates\4.7.2.stable\web_release.zip`
   `%APPDATA%\Godot\export_templates\4.7.2.stable\web_debug.zip`

### 1.2 ETC2/ASTC textures (already enabled)

`project.godot` already contains `textures/vram_compression/import_etc2_astc=true`, which is
required by the preset option `vram_texture_compression/for_mobile=true`. Without it the
Godot editor refuses to export to Web ("ETC2/ASTC texture compression is required for Web export").
Do **not** remove that project setting.

---

## 2. Local export

### 2.1 The exact command

```powershell
New-Item -ItemType Directory -Force "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project\build\web" | Out-Null
& "C:\Users\AKHILBOSS\Desktop\Godot_v4.7.2-stable_win64.exe" --headless --path "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project" --export-release "Web" "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project\build\web\index.html"
```

Notes:

- `--export-release "Web"` selects the preset by the **name** `Web` from `export_presets.cfg`.
  Use `--export-debug "Web" <path>` only for local debugging — **never** commit a debug build
  (the preset keeps `custom_template/debug` empty so the official release template is used).
- The **output folder must already exist**. Godot aborts with
  *"Target folder does not exist or is inaccessible"* if `build\web` is missing. The `New-Item`
  line above creates it.
- The same path is what the preset stores (`export_path="build/web/index.html"`), so exporting
  from the editor GUI (`Project > Export...`) produces identical output.

### 2.2 First run / after pulling new assets

```powershell
& "C:\Users\AKHILBOSS\Desktop\Godot_v4.7.2-stable_win64.exe" --headless --path "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project" --import
```

`--import` re-imports resources (textures, models) so the exported `.pck` contains up-to-date
data. It is safe to run before every export.

### 2.3 Expected output in `build/web/`

| File | Purpose |
|---|---|
| `index.html` | Entry point — open this / deploy this folder |
| `index.js` | Emscripten loader glue |
| `index.wasm` | Compiled engine (WebAssembly) |
| `index.pck` | Game data pack (scenes, scripts, textures, models) |
| `index.png` | Splash image |
| `index.icon.png`, `index.apple-touch-icon.png` | Favicons (`html/export_icon=true`) |
| `.nojekyll` | **Must be added by hand** — see §4 |

### 2.4 Renderer

The project itself is authored with **Forward Plus** (`config/features=PackedStringArray("4.7", "Forward Plus")`),
but the web build runs the **Compatibility renderer** (`gl_compatibility`):

- Godot's `rendering/renderer/rendering_method.web` setting defaults to `gl_compatibility`,
  so a web build automatically uses the Compatibility renderer even for a Forward+ project.
- The preset additionally sets `custom_features="gl_compatibility"` so the exported resource
  variants match the renderer that will actually run in the browser.
- Forward+/Mobile on the web need WebGPU, which is experimental and unsupported on GitHub Pages.
  Compatibility (WebGL 2) is the only renderer that works everywhere.

---

## 3. GitHub Pages does not send COOP/COEP — do not enable threads

Godot's threaded web build (`variant/thread_support=true`) requires `SharedArrayBuffer`, and
browsers only expose it when the page is served with **both**:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

**GitHub Pages does not send these headers and there is no way to configure custom headers on
github.io.** A threaded build therefore fails to start (blank page / `SharedArrayBuffer is not
defined` in the console).

Consequences, already baked into `export_presets.cfg`:

| Setting | Value | Why |
|---|---|---|
| `variant/thread_support` | `false` | No `SharedArrayBuffer` on GitHub Pages |
| `progressive_web_app/ensure_cross_origin_isolation_headers` | `false` | Nothing to ensure |
| `progressive_web_app/enabled` | `false` | Service worker / offline cache not needed |
| `variant/extensions_support` | `false` | Smaller build, no GDExtension needed |
| `threads/emscripten_pool_size`, `threads/godot_pool_size` | `8`, `4` | Ignored while threads are off |

If threads are ever required, the game must be moved to a host that can set response headers
(e.g. Cloudflare Pages/Workers, Netlify with a `_headers` file, or a self-hosted reverse proxy),
and `variant/thread_support` can then be flipped to `true`.

Also note: the page must be **self-contained**. Do not load scripts, fonts or assets from other
origins — under COEP those would be blocked, and without COEP a cross-origin `SharedArrayBuffer`
is unavailable anyway. The Godot export is fully self-contained, so this is already satisfied.

---

## 4. `.nojekyll` requirement

GitHub Pages' classic branch deployment runs **Jekyll**, which ignores files and folders whose
name starts with `_` and can mangle paths. A `.nojekyll` file in the published root disables
the Jekyll build step entirely.

- Add an empty file `build/web/.nojekyll` **before committing** the build.
- The Actions-based workflow in `.github/workflows/pages.yml` uploads the folder as an artifact
  and serves it verbatim, so Jekyll is bypassed there as well — but keeping `.nojekyll` makes
  the same commit work with a branch-based ("Deploy from a branch") setup and guards against
  future path issues.

```powershell
New-Item -ItemType File -Force "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project\build\web\.nojekyll" | Out-Null
```

Because Godot's export does not create this file, it must be re-created after every clean export
(or copied in by a small post-export step).

---

## 5. MIME types

GitHub Pages has sane defaults, so no extra configuration is required. What matters:

| Extension | Expected `Content-Type` | Notes |
|---|---|---|
| `.html` | `text/html` | Served correctly by Pages |
| `.js` | `text/javascript` | Emscripten loader; must be a JS MIME type |
| `.wasm` | `application/wasm` | **Required** for `WebAssembly.instantiateStreaming`; Pages already sends this. If a host ever sends `application/octet-stream`, Godot falls back to `arrayBuffer()` and still works, just slower |
| `.pck` | `application/octet-stream` | Loaded via `fetch()`; no specific type needed |
| `.png` | `image/png` | Splash + favicons |
| `.json` | `application/json` | Only used by a PWA manifest (PWA disabled here) |

Notes:

- `.wasm` must not be served as `text/plain`.
- If the game is ever moved to a host that does not know `.wasm` (some nginx/apache setups), add
  `types { application/wasm wasm; }` (nginx) or `AddType application/wasm .wasm` (Apache).
- GitHub Pages compresses text assets automatically; the `.wasm`/`.pck` pair is the bulk of the
  download, so keep the release build (not debug) to avoid shipping a large, unoptimised `.pck`.

---

## 6. Committing the build

> **Important:** the repository's `.gitignore` contains `/build/`, so `git add build/web` is a
> **no-op**. Use a forced add (or add a negation rule to `.gitignore`):

```powershell
cd "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project"
git add -f build/web
git add export_presets.cfg .github/workflows/pages.yml docs/DEPLOYMENT.md
git commit -m "Web build: export for GitHub Pages"
```

The workflow reads the build **from the repository** (`actions/checkout` → `build/web`), so the
folder must be committed for every deployment. The workflow fails with a clear error if
`build/web/index.html` is missing.

---

## 7. GitHub setup (one-time)

1. **Create the repository** on GitHub (public for free Pages on `github.io`, or private with
   GitHub Free for Pro accounts).
2. **Point the local repo at it** — currently no remote is configured:

   ```powershell
   cd "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project"
   git remote add origin https://github.com/<owner>/<repo>.git
   git push -u origin main
   ```

3. **Authenticate GitHub CLI** — `gh` is currently not logged in:

   ```powershell
   gh auth login
   gh auth status
   ```

4. **Pages source**: `Settings > Pages > Build and deployment > Source = GitHub Actions`.
   `actions/configure-pages` in the workflow also enables Pages automatically, but setting it
   manually avoids a first-run failure.

---

## 8. Verifying the live URL

After the first successful run the URL is:

```
https://<owner>.github.io/<repo>/            (project pages)
https://<owner>.github.io/<repo>/index.html  (direct)
```

Checks:

```powershell
# 1. The deployment URL reported by the workflow:
gh run list --workflow pages.yml --limit 1
gh api repos/<owner>/<repo>/pages            # -> .html_url, .status, .https_enforced

# 2. The page is served:
curl -I https://<owner>.github.io/<repo>/             # expect HTTP/2 200, content-type: text/html
curl -I https://<owner>.github.io/<repo>/index.wasm   # expect 200, content-type: application/wasm
curl -I https://<owner>.github.io/<repo>/index.pck    # expect 200
curl -I https://<owner>.github.io/<repo>/index.js     # expect 200, content-type: text/javascript
```

3. **In the browser**: open the URL, wait for the splash screen, and confirm the campus scene
   loads. Open DevTools → *Console*; there must be no errors, and the Godot version banner must
   show the **Compatibility** renderer. A blank page with a `SharedArrayBuffer` error means the
   build was exported with threads enabled — set `variant/thread_support=false` and re-export.
4. **In the Actions tab**: the run `Deploy Godot Web Build to GitHub Pages` must be green, and the
   `deploy` job must show the `page_url` output.

> The first deployment can take 1–3 minutes (Pages build + CDN propagation). If the site 404s
> immediately, wait a minute and reload.

---

## 9. Redeploying

**Normal flow (recommended):**

```powershell
# 1. Re-export
& "C:\Users\AKHILBOSS\Desktop\Godot_v4.7.2-stable_win64.exe" --headless --path "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project" --export-release "Web" "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project\build\web\index.html"

# 2. Re-create .nojekyll (the export does not write it)
New-Item -ItemType File -Force "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project\build\web\.nojekyll" | Out-Null

# 3. Commit + push -> the workflow redeploys automatically
cd "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project"
git add -f build/web
git commit -m "Web build: update for GitHub Pages"
git push origin main
```

**Manual trigger** (redeploys the build already committed on `main`):

```powershell
gh workflow run pages.yml          # workflow_dispatch trigger
gh run watch --exit-status          # optional: follow the run
```

**Re-run a failed job:** open the run in the Actions UI → *Re-run failed jobs* / *Re-run all jobs*.

---

## 10. Known blockers (as of this reconnaissance)

| # | Blocker | Impact | Fix |
|---|---|---|---|
| 1 | `gh` is not authenticated | Cannot create the repo / set Pages / monitor runs | `gh auth login` |
| 2 | No git remote configured (`git remote -v` is empty) | Nothing can be pushed | `git remote add origin https://github.com/<owner>/<repo>.git` |
| 3 | Export templates missing (`%APPDATA%\Godot\export_templates\` is empty) | The web export cannot run at all | Install the 4.7.2.stable templates (§1.1) |
| 4 | `.gitignore` ignores `/build/` | The committed `build/web` cannot be added normally | `git add -f build/web`, or add `!/build/web/` to `.gitignore` |
| 5 | `build/web/.nojekyll` must be created by hand | Jekyll could mangle the published files in a branch deployment | Create it after every export (§4) |
| 6 | Repo working tree has many uncommitted changes (`src/`, `project.godot`, data files, plus large untracked asset folders) | Pushing `main` would publish work-in-progress state | Commit/review deliberately before the first push |

---

## 11. Quick reference

```powershell
# Export (release, no threads, Compatibility renderer)
& "C:\Users\AKHILBOSS\Desktop\Godot_v4.7.2-stable_win64.exe" --headless --path "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project" --export-release "Web" "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project\build\web\index.html"

# Add the Jekyll opt-out
New-Item -ItemType File -Force "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project\build\web\.nojekyll" | Out-Null

# Commit the build (forced, because /build/ is gitignored)
cd "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project"; git add -f build/web; git commit -m "Web build"; git push origin main

# Verify
gh run list --workflow pages.yml --limit 1
curl -I https://<owner>.github.io/<repo>/
```
