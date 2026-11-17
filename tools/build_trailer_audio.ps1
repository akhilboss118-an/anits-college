param(
	[string]$Project = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
	[string]$Timeline = (Join-Path $Project 'build\trailer\timeline.json'),
	[string]$Out = (Join-Path $Project 'build\trailer\audio.wav')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Timeline)) {
	throw "Timeline not found: $Timeline (run the trailer recording first)"
}

$data = Get-Content $Timeline -Raw | ConvertFrom-Json
$inputs = @()
$filters = @()
$labels = @()
$index = 0

foreach ($event in $data.events) {
	$relative = switch ($event.kind) {
		'voice' { "third_party\anits_original\audio\$($event.file)" }
		'sfx'   { "assets\audio\sfx\$($event.file)" }
		'amb'   { "assets\audio\ambient\$($event.file)" }
		default { continue }
	}
	$path = Join-Path $Project $relative
	if (-not (Test-Path $path)) {
		Write-Warning "Missing audio file, skipped: $path"
		continue
	}

	if ($event.kind -eq 'amb') {
		# Loop the bed for exactly the length of the trailer.
		$inputs += @('-stream_loop', '-1', '-i', $path)
		$filter = "[${index}:a]atrim=0:$($data.seconds),asetpts=PTS-STARTPTS,volume=0.16[a${index}]"
	} else {
		$inputs += @('-i', $path)
		$ms = [int][Math]::Round([double]$event.t * 1000.0)
		$filter = "[${index}:a]adelay=${ms}|${ms}"
		if ($event.kind -eq 'voice' -and $null -ne $event.pitch) {
			$pitch = [double]$event.pitch
			if ([Math]::Abs($pitch - 1.0) -gt 0.01) {
				$filter += ",atempo=$pitch"
			}
		}
		$volume = if ($event.kind -eq 'voice') { '1.0' } else { '0.55' }
		$filter += ",volume=$volume[a${index}]"
	}
	$filters += $filter
	$labels += "[a${index}]"
	$index++
}

if ($index -eq 0) {
	throw 'No audio events were logged in the timeline'
}

$mix = ($labels -join '') + "amix=inputs=$index`:duration=longest:normalize=0," +
	"atrim=0:$($data.seconds),asetpts=PTS-STARTPTS[out]"
$filterComplex = ($filters -join ';') + ';' + $mix

$ffmpegArgs = @('-y', '-hide_banner', '-loglevel', 'warning') + $inputs +
	@('-filter_complex', $filterComplex, '-map', '[out]', '-ac', '2', '-ar', '48000', $Out)

& ffmpeg @ffmpegArgs
if ($LASTEXITCODE -ne 0) {
	throw "ffmpeg failed while mixing the trailer audio (exit $LASTEXITCODE)"
}

Write-Host "Trailer audio: $Out ($index events, $($data.seconds) s)"
