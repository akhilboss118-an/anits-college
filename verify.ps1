# Headless validation gate for the ANITS Godot port.
# Usage:  powershell -ExecutionPolicy Bypass -File verify.ps1
param(
	[string]$Godot = "C:\Users\AKHILBOSS\Desktop\Godot_v4.7.2-stable_win64.exe",
	[string]$Project = "C:\Users\AKHILBOSS\Desktop\ANITS-GODOT\new-game-project",
	[switch]$SkipTour
)

$ErrorActionPreference = "Continue"
$failures = 0

function Step([string]$name, [scriptblock]$body) {
	Write-Host ""
	Write-Host "=== $name ===" -ForegroundColor Cyan
	& $body
	if ($LASTEXITCODE -ne 0) {
		Write-Host "FAILED: $name (exit $LASTEXITCODE)" -ForegroundColor Red
		$script:failures++
	} else {
		Write-Host "OK: $name" -ForegroundColor Green
	}
}

Step "import" { & $Godot --headless --path $Project --import 2>&1 | Out-Host }

Step "unit tests (tests/run_tests.gd)" {
	& $Godot --headless --path $Project --script res://tests/run_tests.gd 2>&1 | Out-Host
}

Step "smoke run (300 frames)" {
	& $Godot --headless --path $Project --quit-after 300 2>&1 | Out-Host
}

if (-not $SkipTour) {
	Step "scripted tour (--check)" {
		& $Godot --path $Project --resolution 1600x900 --quit-after 5000 -- --check 2>&1 | Out-Host
	}
}

Write-Host ""
if ($failures -eq 0) {
	Write-Host "ALL CHECKS PASSED" -ForegroundColor Green
	exit 0
}
Write-Host "$failures STEP(S) FAILED" -ForegroundColor Red
exit 1
