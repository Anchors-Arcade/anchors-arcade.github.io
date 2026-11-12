# Generates optimized cover thumbnails (320px JPEG) into .\covers
# from the source covers folder. Re-run to refresh (only changed files are re-done).
param(
    [string]$Source = 'C:\Users\alveb\Downloads\covers-main'
)
$ErrorActionPreference = 'Stop'
$dest = Join-Path $PSScriptRoot 'covers'
if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }

Add-Type -AssemblyName System.Drawing

$files = Get-ChildItem -Path $Source -File |
    Where-Object { $_.Name -cmatch '^\d+(-[A-Za-z0-9]+)?\.(png|gif|jpe?g|webp|bmp)$' }

$created = 0; $skipped = 0; $copied = 0; $failed = 0
$i = 0
$size = 320

foreach ($f in $files) {
    $i++
    $out = Join-Path $dest ($f.BaseName + '.jpg')

    # skip if an up-to-date thumbnail already exists
    if (Test-Path $out) {
        if ((Get-Item $out).LastWriteTime -ge $f.LastWriteTime) { $skipped++; continue }
    }

    # animated gifs are copied as-is (resizing would kill the animation)
    if ($f.Extension -ieq '.gif') {
        Copy-Item $f.FullName (Join-Path $dest $f.Name) -Force
        $copied++
        continue
    }

    try {
        $src = [System.Drawing.Image]::FromFile($f.FullName)
        $bmp = New-Object System.Drawing.Bitmap($size, $size)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $g.Clear([System.Drawing.Color]::FromArgb(255, 16, 19, 26))   # dark backdrop for transparent art

        # center-crop "cover" fit for any source size
        $scale = [Math]::Max($size / $src.Width, $size / $src.Height)
        $dw = $src.Width * $scale; $dh = $src.Height * $scale
        $g.DrawImage($src, [float](($size - $dw) / 2), [float](($size - $dh) / 2), [float]$dw, [float]$dh)
        $g.Dispose()

        $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
            Where-Object { $_.MimeType -eq 'image/jpeg' }
        $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]82)
        $bmp.Save($out, $codec, $ep)
        $ep.Dispose(); $bmp.Dispose(); $src.Dispose()
        $created++
    }
    catch {
        $failed++
        Write-Warning ("Failed on {0}: {1}" -f $f.Name, $_.Exception.Message)
    }

    if ($i % 100 -eq 0) { Write-Output ("{0}/{1} processed..." -f $i, $files.Count) }
}

# pass 2: any source cover without a generated thumbnail (formats GDI+ can't decode,
# e.g. webp/avif mislabeled as .png) is copied as-is - browsers decode those natively.
$copiedRaw = 0
foreach ($f in $files) {
    if (Test-Path (Join-Path $dest ($f.BaseName + '.jpg'))) { continue }
    $raw = Join-Path $dest $f.Name
    if (-not (Test-Path $raw)) { Copy-Item $f.FullName $raw -Force; $copiedRaw++ }
}
if ($copiedRaw) { Write-Output ("Copied {0} cover(s) as-is (unsupported format, browsers handle them natively)" -f $copiedRaw) }

# (favicon.png is owned by _generate-logo.ps1, not this script)

$thumbs = Get-ChildItem $dest -File
Write-Output ("Done. Thumbnails: {0}  (created {1}, up-to-date {2}, gif copied {3}, failed {4})  Total size: {5:N1} MB" -f `
    $thumbs.Count, $created, $skipped, $copied, $failed, (($thumbs | Measure-Object Length -Sum).Sum / 1MB))
