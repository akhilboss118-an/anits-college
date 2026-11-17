# Records and encodes the 60 s gameplay trailer.
#
#   powershell -ExecutionPolicy Bypass -File tools\build_trailer.ps1
#
# Steps:
#   1. Godot movie writer records 1800 deterministic frames (30 fps, 60 s)
#      while src/main.gd::_run_trailer drives a real gameplay timeline.
#   2. build_trailer_audio.ps1 mixes the game's own voice clips, SFX and
#      ambience from the timeline.json that the run wrote.
#   3. ffmpeg muxes both into build/trailer/ANITS-Trailer.mp4.

param(
	[string]$Godot = 'C:\Users\AKHILBOSS\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe',
	[string]$Project = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
	[switch]$SkipVideo,
	[switch]$SkipAudio
)

$ErrorActionPreference = 'Stop'
$dir = Join-Path $Project 'build\trailer'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

if (-not $SkipVideo) {
	Write-Host '=== Recording 1800 frames (60 s at 30 fps) ==='
	& $Godot --path $Project --resolution 1280x720 `
		--write-movie "$dir\raw.avi" --fixed-fps 30 --quit-after 1800 `
		-- --record-trailer
	# Godot's Windows build is a GUI app: PowerShell leaves $LASTEXITCODE empty
	# for it, so verify the two artifacts the director writes instead.
	if (-not (Test-Path "$dir\raw.avi") -or -not (Test-Path "$dir\timeline.json")) {
		throw 'Godot trailer recording did not produce raw.avi and timeline.json'
	}
	Write-Host "Recorded: $dir\raw.avi"
}

if (-not $SkipAudio) {
	Write-Host '=== Mixing in-game audio ==='
	& (Join-Path $PSScriptRoot 'build_trailer_audio.ps1') -Project $Project
}

$mp4 = Join-Path $dir 'ANITS-Trailer.mp4'
Write-Host '=== Encoding MP4 ==='
# Godot's AVI also carries a short live-audio track. Map the streams
# explicitly; -shortest would cut the trailer to that stray track.
& ffmpeg -y -hide_banner -loglevel warning `
	-i "$dir\raw.avi" -i "$dir\audio.wav" `
	-map 0:v:0 -map 1:a:0 `
	-c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p `
	-c:a aac -b:a 192k -t 60 -movflags +faststart $mp4
if ($LASTEXITCODE -ne 0) {
	throw "ffmpeg failed while encoding the MP4 (exit $LASTEXITCODE)"
}

Write-Host "Trailer ready: $mp4 ($((Get-Item $mp4).Length) bytes)"
