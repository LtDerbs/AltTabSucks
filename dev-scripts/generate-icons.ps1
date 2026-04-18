#!/usr/bin/env pwsh
# Generates extension icons (16x16, 48x48, 128x128) into BrowserExtension/icons/.
# Design: dark background (#1A2A3A), gold lightning bolt, white "ATS" text overlay.
# Run once after cloning or whenever the icon design changes.

Add-Type -AssemblyName System.Drawing

$root   = Split-Path $PSScriptRoot -Parent
$outDir = Join-Path $root "BrowserExtension\icons"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

function New-Icon($size, $outPath) {
    $bmp = [System.Drawing.Bitmap]::new($size, $size)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    # Background
    $g.Clear([System.Drawing.Color]::FromArgb(0x1A, 0x2A, 0x3A))

    # Lightning bolt polygon — classic zigzag shape, fills most of the canvas
    $s    = [float]$size
    $bolt = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($s * 0.64, $s * 0.04),
        [System.Drawing.PointF]::new($s * 0.24, $s * 0.54),
        [System.Drawing.PointF]::new($s * 0.50, $s * 0.50),
        [System.Drawing.PointF]::new($s * 0.36, $s * 0.96),
        [System.Drawing.PointF]::new($s * 0.76, $s * 0.46),
        [System.Drawing.PointF]::new($s * 0.50, $s * 0.50)
    )
    $boltBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(0xF5, 0xC5, 0x18))
    $g.FillPolygon($boltBrush, $bolt)

    # "ATS" text — skip at 16px where it's unreadable
    if ($size -ge 32) {
        $fontSize = [float]($size * 0.26)
        $font     = [System.Drawing.Font]::new("Arial", $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $rect     = [System.Drawing.RectangleF]::new(0, 0, $s, $s)
        $sf       = [System.Drawing.StringFormat]::new()
        $sf.Alignment     = [System.Drawing.StringAlignment]::Center
        $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

        # Dark outline for legibility over the bolt
        $shadow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(180, 0x0A, 0x14, 0x1E))
        foreach ($dx in @(-1, 0, 1)) {
            foreach ($dy in @(-1, 0, 1)) {
                if ($dx -ne 0 -or $dy -ne 0) {
                    $shadowRect = [System.Drawing.RectangleF]::new($dx, $dy, $s, $s)
                    $g.DrawString("ATS", $font, $shadow, $shadowRect, $sf)
                }
            }
        }

        $white = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
        $g.DrawString("ATS", $font, $white, $rect, $sf)

        $font.Dispose(); $sf.Dispose(); $shadow.Dispose(); $white.Dispose()
    }

    $g.Dispose(); $boltBrush.Dispose()
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Written: $outPath"
}

New-Icon 16  (Join-Path $outDir "icon-16.png")
New-Icon 48  (Join-Path $outDir "icon-48.png")
New-Icon 128 (Join-Path $outDir "icon-128.png")
