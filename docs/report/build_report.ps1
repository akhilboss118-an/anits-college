<#
.SYNOPSIS
    Builds docs/ANITS_Godot_Report.pdf from docs/report/report.html using a
    headless Chromium browser (Microsoft Edge or Google Chrome).

.DESCRIPTION
    Locates a Chromium-based browser in the standard installation locations,
    runs it headless with --print-to-pdf and --no-pdf-header-footer, and writes
    the PDF to docs/ANITS_Godot_Report.pdf.

    The browser's own header/footer band is disabled because the report already
    carries a running header and a running footer (with page numbers) inside the
    HTML itself.

    If the primary browser fails, the script falls back to the other browser and
    then to the legacy --headless=old mode. If no browser can be found, the
    script prints the exact manual command instead of failing silently.

.PARAMETER Output
    Path of the generated PDF. Defaults to docs/ANITS_Godot_Report.pdf.

.PARAMETER Browser
    Force a specific browser executable ("edge" or "chrome"). By default the
    script tries Edge first, then Chrome.

.PARAMETER SyncCss
    Re-extract the <style> block from report.html into report.css so the two
    stay identical. Enabled by default; use -NoSyncCss to skip.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File docs/report/build_report.ps1
#>
[CmdletBinding()]
param(
    [string]$Output,
    [ValidateSet('edge', 'chrome', 'auto')]
    [string]$Browser = 'auto',
    [switch]$NoSyncCss
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$htmlPath   = Join-Path $scriptDir 'report.html'
$cssPath    = Join-Path $scriptDir 'report.css'

if (-not $Output) {
    $Output = Join-Path $projectDir 'docs\ANITS_Godot_Report.pdf'
}

function Write-Step   ([string]$m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok     ([string]$m) { Write-Host "    [ok]   $m" -ForegroundColor Green }
function Write-Warn   ([string]$m) { Write-Host "    [warn] $m" -ForegroundColor Yellow }
function Write-Err    ([string]$m) { Write-Host "    [fail] $m" -ForegroundColor Red }
function Write-Detail ([string]$m) { Write-Host "           $m" -ForegroundColor DarkGray }

# ---------------------------------------------------------------------------
# 0. Validate inputs
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "ANITS Godot 4 Port - Technical Report PDF builder" -ForegroundColor White
Write-Host "--------------------------------------------------" -ForegroundColor DarkGray

if (-not (Test-Path -LiteralPath $htmlPath)) {
    Write-Err "report.html not found at: $htmlPath"
    exit 1
}
Write-Step "Source"
Write-Detail $htmlPath

# ---------------------------------------------------------------------------
# 1. Keep report.css in sync with the inline <style> block of report.html
# ---------------------------------------------------------------------------
if (-not $NoSyncCss) {
    Write-Step "Synchronising report.css"
    $html = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
    $m = [regex]::Match($html, '(?s)<style[^>]*>(.*?)</style>')
    if ($m.Success) {
        $css = $m.Groups[1].Value.Trim()
        $css = ($css -split "`r?`n" | ForEach-Object { $_.TrimEnd() }) -join "`n"
        Set-Content -LiteralPath $cssPath -Value $css -Encoding UTF8
        Write-Ok "report.css written ($($css.Length) characters)"
    } else {
        Write-Warn "no <style> block found in report.html - report.css left untouched"
    }
}

# ---------------------------------------------------------------------------
# 2. Find a browser
# ---------------------------------------------------------------------------
$edgeCandidates = @(@(
    (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
    (Join-Path $env:ProgramFiles       'Microsoft\Edge\Application\msedge.exe'),
    (Join-Path $env:LOCALAPPDATA       'Microsoft\Edge\Application\msedge.exe')
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) })

$chromeCandidates = @(@(
    (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'),
    (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe')
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) })

$browserExe = $null
switch ($Browser) {
    'edge' {
        if ($edgeCandidates) { $browserExe = $edgeCandidates[0] }
        else { Write-Err "Microsoft Edge was not found in the standard locations." }
    }
    'chrome' {
        if ($chromeCandidates) { $browserExe = $chromeCandidates[0] }
        else { Write-Err "Google Chrome was not found in the standard locations." }
    }
    default {
        if ($edgeCandidates)    { $browserExe = $edgeCandidates[0] }
        elseif ($chromeCandidates) { $browserExe = $chromeCandidates[0] }
    }
}

Write-Step "Browser"
if ($browserExe) {
    Write-Ok $browserExe
    $ver = (Get-Item -LiteralPath $browserExe).VersionInfo.ProductVersion
    if ($ver) { Write-Detail "version $ver" }
} else {
    Write-Err "No Chromium-based browser found."
    Write-Detail "Install Microsoft Edge or Google Chrome, or re-run with -Browser <path-to-exe>."
    Write-Detail "Manual command:"
    Write-Detail "  msedge.exe --headless=new --disable-gpu --no-pdf-header-footer ``"
    Write-Detail "             --print-to-pdf=`"$Output`" `"$htmlPath`""
    exit 2
}

# ---------------------------------------------------------------------------
# 3. Print to PDF
# ---------------------------------------------------------------------------
$htmlUri = ([System.Uri](Resolve-Path -LiteralPath $htmlPath).Path).AbsoluteUri
Write-Step "Printing"
Write-Detail "input : $htmlUri"
Write-Detail "output: $Output"

$outDir = Split-Path -Parent $Output
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}
if (Test-Path -LiteralPath $Output) {
    Remove-Item -LiteralPath $Output -Force
}

function Invoke-Print {
    param(
        [string]$Exe,
        [string]$HeadlessMode = 'new'
    )
    # A temporary profile keeps the user's real browser profile and any running
    # browser session out of the way.
    $profileDir = Join-Path ([System.IO.Path]::GetTempPath()) ("anits-report-" + [guid]::NewGuid().ToString('N'))
    $stdoutLog = Join-Path $profileDir 'stdout.txt'
    $stderrLog = Join-Path $profileDir 'stderr.txt'

    $args = @(
        "--headless=$HeadlessMode",
        '--disable-gpu',
        '--no-sandbox',
        '--no-first-run',
        '--no-default-browser-check',
        '--disable-extensions',
        '--no-pdf-header-footer',
        '--virtual-time-budget=20000',
        '--allow-file-access-from-files',
        "--user-data-dir=$profileDir",
        "--print-to-pdf=$Output",
        $htmlUri
    )

    Write-Detail "browser args: $($args -join ' ')"
    $proc = Start-Process -FilePath $Exe -ArgumentList $args -Wait -PassThru -NoNewWindow `
        -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
    Write-Detail "exit code: $($proc.ExitCode)"

    foreach ($log in @($stdoutLog, $stderrLog)) {
        if (Test-Path -LiteralPath $log) {
            foreach ($line in (Get-Content -LiteralPath $log -ErrorAction SilentlyContinue)) {
                if ("$line" -match 'bytes written to file') { Write-Detail "$line" }
            }
        }
    }
    Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Attempt 1 - modern headless.
$ok = $false
Write-Step "Attempt 1 - headless=new"
Invoke-Print -Exe $browserExe -HeadlessMode 'new'
if (Test-Path -LiteralPath $Output) {
    $ok = $true
} else {
    Write-Warn "no PDF was produced."
}

# Attempt 2 - legacy headless mode (older builds only).
if (-not $ok) {
    Write-Step "Attempt 2 - headless=old"
    Invoke-Print -Exe $browserExe -HeadlessMode 'old'
    if (Test-Path -LiteralPath $Output) { $ok = $true }
    else { Write-Warn "no PDF was produced." }
}

# Attempt 3 - the other browser family.
if (-not $ok) {
    $other = $null
    if ($browserExe -like '*msedge.exe') { if ($chromeCandidates) { $other = $chromeCandidates[0] } }
    else { if ($edgeCandidates) { $other = $edgeCandidates[0] } }

    if ($other) {
        Write-Step "Attempt 3 - fallback browser"
        Write-Detail $other
        Invoke-Print -Exe $other -HeadlessMode 'new'
        if (Test-Path -LiteralPath $Output) { $ok = $true }
        else { Write-Warn "no PDF was produced." }
    } else {
        Write-Warn "no fallback browser is installed."
    }
}

Write-Host ""
if ($ok) {
    $item = Get-Item -LiteralPath $Output
    $mb = [math]::Round($item.Length / 1MB, 2)
    Write-Ok "PDF written: $Output ($mb MB)"
    Write-Host ""
    exit 0
} else {
    Write-Err "The PDF could not be produced automatically."
    Write-Detail "Open the HTML in a browser and use Print > Save as PDF with"
    Write-Detail "'Headers and footers' switched off, then save it as:"
    Write-Detail "  $Output"
    exit 3
}
