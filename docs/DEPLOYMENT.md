# Deployment

How the ANITS College Simulation web build is published to GitHub Pages, and how
the signed Android APK is produced.

- **Repository:** <https://github.com/akhilboss118-an/anits-college>
- **Live site:** <https://akhilboss118-an.github.io/anits-college/>
- **Project root:** `C:\Users\AKHILBOSS\OneDrive\Desktop\ANITS-GODOT\new-game-project`
- **Godot:** `C:\Users\AKHILBOSS\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe` (4.7.2 stable)
- **Presets:** `export_presets.cfg` → **Web** (`build/web/index.html`) and
  **Android** (`build/anits.apk`)

---

## 1. How the site is hosted

The site is served from the **`gh-pages` branch**, root folder, by GitHub Pages.
There is no GitHub Actions workflow in the repository.

| Branch | Contents |
| --- | --- |
| `main` | All source, assets, tests, docs and the report. `build/` is ignored. |
| `gh-pages` | Only the static web export: `index.html`, `index.js`, `index.wasm`, `index.pck`, icons, audio worklets and `.nojekyll`. |

Two constraints drove this split:

1. The web export is ~138 MB on disk (`index.pck` alone is 98.6 MB). Keeping it
   in `main` would bloat every clone and every source push.
2. The available GitHub token has **`repo` scope only**. Pushing
   `.github/workflows/pages.yml` is rejected (`workflow` scope is required), so
   the Actions-based deployment used by the first draft was removed.

Publishing a branch directly needs no workflow, no token scope beyond `repo`,
and no build step on GitHub.

> GitHub Pages must be configured once: **Settings → Pages → Build and
> deployment → Source: Deploy from a branch → Branch: `gh-pages` / `(root)`**.
> The API equivalent is a `POST /repos/{owner}/{repo}/pages` with
> `{"source":{"branch":"gh-pages","path":"/"}}`.

---

## 2. Build the web export

### 2.1 Prerequisites

Godot 4.7.2 **web export templates** must be installed at:

```
%APPDATA%\Godot\export_templates\4.7.2.stable\web_release.zip
%APPDATA%\Godot\export_templates\4.7.2.stable\web_debug.zip
```

If the folder is missing, install them from the editor
(**Editor → Manage Export Templates → Download and Install**) or download
`Godot_v4.7.2-stable_export_templates.tpz` and extract `templates/web_*.zip`
into the path above.

### 2.2 Export

```powershell
$GODOT = "C:\Users\AKHILBOSS\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe"
$PROJ  = "C:\Users\AKHILBOSS\OneDrive\Desktop\ANITS-GODOT\new-game-project"

& $GODOT --headless --path $PROJ --export-release "Web" "$PROJ\build\web\index.html"

# GitHub Pages runs Jekyll unless this file exists; Godot exports are static.
New-Item -ItemType File -Path "$PROJ\build\web\.nojekyll" -Force
```

Expected output:

| File | Size (local) |
| --- | --- |
| `index.html` | ~6 KB (plus a small runtime patch on the LAN server) |
| `index.js` | ~280 KB |
| `index.wasm` | ~39.5 MB |
| `index.pck` | ~98.6 MB |
| `.nojekyll` | 0 B |

### 2.3 Test locally before publishing

Any static server works, but it must send `application/wasm` for `.wasm` and
must not rewrite paths. A minimal Node server is enough:

```powershell
node "$env:TEMP\opencode\serve_web.js"   # http://localhost:8100/
```

The local server also exposes `/anits.apk` and patches `index.html` for
insecure origins (muted audio fallback), which the real HTTPS site does not
need.

Check by hand:

- `http://localhost:8100/` loads the menu and the splash reaches the main menu.
- `index.pck` returns **200** and the full byte count.
- `index.wasm` returns **200** with `Content-Type: application/wasm`.

---

## 3. Publish to `gh-pages`

The push is deliberately done from a **throw-away repository** so that the
`gh-pages` history contains only the export and nothing from `main`.

### 3.1 Stage the export

```powershell
$SRC = "$PROJ\build\web"
$TMP = "$env:TEMP\anits-pages"

if (Test-Path $TMP) { Remove-Item $TMP -Recurse -Force }
New-Item -ItemType Directory -Force -Path $TMP | Out-Null
Copy-Item "$SRC\*" $TMP -Recurse -Force
New-Item -ItemType File -Path "$TMP\.nojekyll" -Force | Out-Null

Set-Location $TMP
git init -q
git config user.name  "AKHILBOSS"
git config user.email "akhilboss@users.noreply.github.com"
git add -A
git commit -q -m "ANITS web build v1.0"
```

### 3.2 Push over SSH (recommended for this network)

Large HTTPS pushes to GitHub fail here with **`HTTP 408`** after the pack is
uploaded. SSH on port 443 succeeds. Use a repository **deploy key** with write
access:

```powershell
# one-time: create the key
ssh-keygen -t ed25519 -N '""' -C "anits-deploy" -f "$env:TEMP\anits_deploy_key"

# one-time: add the public key as a deploy key (write access)
#   Settings → Deploy keys → Add deploy key, or:
#   POST /repos/akhilboss118-an/anits-college/keys
#   { "title": "anits-pages-deploy", "key": "<contents of .pub>", "read_only": false }

$KEY = "$env:TEMP\anits_deploy_key"
$env:GIT_SSH_COMMAND = "ssh -i `"$KEY`" -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL -p 443"

git remote add origin "ssh://git@ssh.github.com:443/akhilboss118-an/anits-college.git"
git push --progress -f origin HEAD:gh-pages
```

Notes:

- `-f` is intentional: `gh-pages` is a build artifact branch, not a history to
  preserve. Every deploy replaces it.
- GitHub prints a warning that `index.pck` is larger than the recommended
  50 MB. That is advisory; the hard limit is **100 MB per file**, and the
  largest file is 98.6 MB.
- If a deploy key is not available, HTTPS works for small updates but is
  unreliable for the ~91 MB pack on a slow uplink. Tuning
  `http.postBuffer`, `http.version=HTTP/1.1`, `http.lowSpeedLimit=0` and
  `http.lowSpeedTime` did **not** fix the 408 here; SSH did.

### 3.3 HTTPS alternative (small or already-cached pushes)

```powershell
git remote add origin "https://github.com/akhilboss118-an/anits-college.git"
git push -f origin HEAD:gh-pages
```

Credentials come from the Windows credential helper
(`git credential fill` for `https://github.com`). The token is a 40-character
PAT with `repo` scope; `gh auth login` is **not** configured on this machine.

---

## 4. Verify the deployment

### 4.1 Pages status

```powershell
$cred = @{}
("protocol=https`nhost=github.com`n`n" | git credential fill) |
    ForEach-Object { $kv = $_ -split '=',2; if ($kv.Count -eq 2) { $cred[$kv[0]] = $kv[1] } }
$h = @{ Authorization = "token $($cred['password'])"; 'User-Agent' = 'anits-port' }

Invoke-RestMethod -Headers $h `
    -Uri "https://api.github.com/repos/akhilboss118-an/anits-college/pages" |
    Select-Object status, html_url, @{n='branch';e={$_.source.branch}}
```

Wait for `status = built` (the first build takes a minute or two).

### 4.2 Asset checks

```powershell
$base = "https://akhilboss118-an.github.io/anits-college/"
foreach ($f in "index.html","index.pck","index.wasm","index.js",".nojekyll") {
    $r = Invoke-WebRequest -Method Head -Uri ($base + $f)
    "{0,-12} {1} {2}" -f $f, $r.StatusCode, $r.Headers['Content-Length']
}
```

Expected:

| File | Status | Content-Type | Notes |
| --- | --- | --- | --- |
| `index.html` | 200 | `text/html` | |
| `index.pck` | 200 | `application/octet-stream` | served compressed; the Content-Length differs from the local size |
| `index.wasm` | 200 | `application/wasm` | served compressed, ~9.6 MB |
| `index.js` | 200 | `text/javascript` | |
| `.nojekyll` | 200 | — | |

Content-Length on Pages is the **compressed** size, so it will not match the
local file size. That is normal.

### 4.3 Browser check

Open <https://akhilboss118-an.github.io/anits-college/>. The splash should
reach the year-select screen. If the page is blank:

1. Hard-refresh (`Ctrl+F5`) — Pages caches aggressively at the edge.
2. Check the DevTools console for a 404 on `index.pck` or `index.wasm`.
3. Confirm `Content-Type: application/wasm` on `index.wasm`; a wrong MIME type
   makes the engine refuse to stream-compile.
4. Confirm `.nojekyll` exists; without it, Jekyll can drop files.

---

## 5. Redeploying after a change

1. Edit source on `main`, run the gate (§7).
2. Re-export the web build (§2.2) and add `.nojekyll`.
3. Re-stage and force-push `gh-pages` (§3.1–3.2). The old export is replaced.
4. Wait for `status = built`, then hard-refresh the live URL.

Rollback: `git push -f origin <previous-commit>:gh-pages`, or re-push the
previous export folder. Because `gh-pages` is replaced wholesale, a rollback is
just another force push.

---

## 6. Android APK

### 6.1 Build

The Android export templates must be installed
(`%APPDATA%\Godot\export_templates\4.7.2.stable\android_*.zip`), and the
standard debug keystore must exist at
`C:\Users\AKHILBOSS\.android\debug.keystore`.

```powershell
& $GODOT --headless --path $PROJ --export-release "Android" "$PROJ\build\anits.apk"
Copy-Item "$PROJ\build\anits.apk" "$PROJ\build\ANITS-College-Simulation-v1.0.apk" -Force
```

The preset (`export_presets.cfg`) is:

| Setting | Value |
| --- | --- |
| Package | `com.akhilboss.anits` |
| Version | `1.0` (code `1`) |
| ABI | `arm64-v8a` only |
| Min / target SDK | Godot defaults (24 / 36) |
| Signing | debug keystore (`androiddebugkey`, password `android`) |
| Format | APK, no Gradle build |

The result is ~115.6 MB and signed with APK signature schemes v2 and v3.
The debug keystore is fine for sideloading and testing; it is **not** a Play
Store key. Replace `keystore/release*` in `export_presets.cfg` with a private
upload key before publishing to a store, and never commit that key.

### 6.2 Distribute

The APK is **not** committed (`.gitignore` excludes `*.apk`). It can be:

- attached to a GitHub Release (`v1.0`), or
- served from the LAN test server at `http://<host>:8100/anits.apk`
  (MIME `application/vnd.android.package-archive`), or
- copied to a phone over USB.

On the phone, enable **Install unknown apps** for the browser/file manager,
then open the APK. Android 14+ may warn about the debug certificate; that is
expected for a sideloaded build.

---

## 7. Pre-deploy validation gate

Always run the gate before exporting:

```powershell
powershell -ExecutionPolicy Bypass -File "$PROJ\verify.ps1"
```

It runs, in order:

1. `--headless --import`
2. `tests/run_tests.gd` - **148 checks, 0 failures**
3. a 300-frame headless smoke run
4. the scripted `--check` tour (10 screenshots, full Day 1 route)

Expected tail:

```
OK: import
--- 148 checks, 0 failures ---
OK: unit tests (tests/run_tests.gd)
OK: smoke run (300 frames)
OK: scripted tour (--check)
ALL CHECKS PASSED
```

The benchmark is separate:

```powershell
& $GODOT --path $PROJ --script res://tests/bench.gd -- `
    --bench-profile=desktop --bench-spot=spawn --bench-warmup=14 --bench-seconds=5
```

The bench prints `result=PASS` when the measured average meets the target. The
desktop HIGH ladder settles at 0.60 and **34.5–36.1 fps** on the integrated GPU
(below target); the default AUTO profile selects FAST on this GPU and measures
**54.8 fps** at spawn and **60.6 fps** at the court, while a discrete GPU stays
at 0.88 with HIGH. The phone profile measures **61.6–89.0 fps** across the eight
hotspots on the same laptop.

---

## 8. Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `HTTP 408` / `RPC failed` on push | Large pack over HTTPS on a slow uplink | Use SSH on port 443 with a deploy key (§3.2) |
| `refusing to allow an OAuth App to create or update workflow` | Token lacks `workflow` scope | Do not commit `.github/workflows/*`; deploy from `gh-pages` instead |
| Pages 404 on every asset | Pages source not set to `gh-pages` root | Settings → Pages, or the API call in §1 |
| Page loads but the game stays on the splash | `index.pck` 404, wrong MIME, or cached old build | Check the console/network tab, hard-refresh |
| `index.wasm` MIME is `application/octet-stream` | Server misconfiguration | Pages sets `application/wasm` automatically; fix custom servers |
| Blank page only on the LAN HTTP server | AudioWorklet requires a secure context | Use the HTTPS server on 8443, or the patched HTTP shim in `serve_web.js` |
| APK installs but shows a debug-certificate warning | Signed with the debug keystore | Expected for sideloading; use a private upload key for stores |
| APK build fails with "keystore not found" | Debug keystore missing | Create it with `keytool -genkey -v -keystore %USERPROFILE%\.android\debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"` |
| Export fails with "No export template found" | Templates not installed | Install the 4.7.2 templates (§2.1) |

---

## 9. What is intentionally not deployed

- `build/` (web export, APK, Windows build) — ignored on `main`.
- `ANITS-WEB GAME/` — the 72 MB reference web build; kept locally as the source
  of truth, excluded by `.gitignore` and `.gdignore`.
- `.godot/` — regenerable import cache.
- The PDF report is tracked in `main` (~37.8 MB) but is not part of the Pages
  branch; it is linked from the repository, not the live site.
