Add-Type -AssemblyName System.Drawing

$srcPath = Join-Path $PSScriptRoot "assets\img\little_hearts_logo.png"
if (-not (Test-Path $srcPath)) {
    Write-Error "Source icon not found: $srcPath"
    exit 1
}

$src = [System.Drawing.Image]::FromFile($srcPath)

function Resize-And-Center {
    param(
        [System.Drawing.Image]$Source,
        [int]$CanvasWidth,
        [int]$CanvasHeight,
        [double]$ScaleFactor,
        [string]$OutputPath,
        [bool]$Round = $false
    )

    $destBmp = New-Object System.Drawing.Bitmap($CanvasWidth, $CanvasHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($destBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    if ($Round) {
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddEllipse(0, 0, $CanvasWidth, $CanvasHeight)
        $g.SetClip($path)
    }

    $maxW = $CanvasWidth * $ScaleFactor
    $maxH = $CanvasHeight * $ScaleFactor
    $ratio = [Math]::Min($maxW / $Source.Width, $maxH / $Source.Height)
    $drawW = [int]($Source.Width * $ratio)
    $drawH = [int]($Source.Height * $ratio)
    $drawX = [int](($CanvasWidth - $drawW) / 2)
    $drawY = [int](($CanvasHeight - $drawH) / 2)

    $g.DrawImage($Source, $drawX, $drawY, $drawW, $drawH)
    $g.Dispose()

    $destBmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destBmp.Dispose()
    Write-Host "Saved: $OutputPath ($CanvasWidth x $CanvasHeight)"
}

$mipmaps = @(
    @{ Folder = "mipmap-mdpi"; LegacySize = 48; ForegroundSize = 108 },
    @{ Folder = "mipmap-hdpi"; LegacySize = 72; ForegroundSize = 162 },
    @{ Folder = "mipmap-xhdpi"; LegacySize = 96; ForegroundSize = 216 },
    @{ Folder = "mipmap-xxhdpi"; LegacySize = 144; ForegroundSize = 324 },
    @{ Folder = "mipmap-xxxhdpi"; LegacySize = 192; ForegroundSize = 432 }
)

$resDir = Join-Path $PSScriptRoot "android\app\src\main\res"

foreach ($m in $mipmaps) {
    $folder = Join-Path $resDir $m.Folder
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
    
    Resize-And-Center -Source $src -CanvasWidth $m.LegacySize -CanvasHeight $m.LegacySize -ScaleFactor 0.95 -OutputPath (Join-Path $folder "ic_launcher.png")
    Resize-And-Center -Source $src -CanvasWidth $m.LegacySize -CanvasHeight $m.LegacySize -ScaleFactor 0.95 -OutputPath (Join-Path $folder "ic_launcher_round.png") -Round $true
    Resize-And-Center -Source $src -CanvasWidth $m.ForegroundSize -CanvasHeight $m.ForegroundSize -ScaleFactor 0.70 -OutputPath (Join-Path $folder "ic_launcher_foreground.png")
}

$iconsDir = Join-Path $PSScriptRoot "assets\icons"
if (-not (Test-Path $iconsDir)) {
    New-Item -ItemType Directory -Path $iconsDir -Force | Out-Null
}
Resize-And-Center -Source $src -CanvasWidth 192 -CanvasHeight 192 -ScaleFactor 0.95 -OutputPath (Join-Path $iconsDir "icon-192.png")
Resize-And-Center -Source $src -CanvasWidth 512 -CanvasHeight 512 -ScaleFactor 0.95 -OutputPath (Join-Path $iconsDir "icon-512.png")

$src.Dispose()
Write-Host "All icons generated successfully from little_hearts_logo.png!"
