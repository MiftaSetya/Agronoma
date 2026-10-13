$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Base     = 'http://127.0.0.1:3845/assets/'
$Root     = 'C:\Project\Agronoma\Frontend'
$IconDir  = Join-Path $Root 'assets\icons'
$ImageDir = Join-Path $Root 'assets\images'
$Manifest = Join-Path $Root 'tool\manifest.json'
$Temp     = Join-Path $env:TEMP 'agronoma_raw'
New-Item -ItemType Directory -Force -Path $Temp, $ImageDir | Out-Null

# id aset Figma -> nama berkas lokal (lihat tool/asset-names.json).
$names = Get-Content (Join-Path $Root 'tool\asset-names.json') -Raw | ConvertFrom-Json
$hashes = @()
foreach ($p in $names.PSObject.Properties) {
  if ($p.Value -notlike '*.svg') { $hashes += $p.Name }
}

function Get-MinAlpha([System.Drawing.Bitmap]$b) {
  $rect = New-Object System.Drawing.Rectangle 0, 0, $b.Width, $b.Height
  $d = $b.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $n = $d.Stride * $d.Height
  $buf = New-Object byte[] $n
  [System.Runtime.InteropServices.Marshal]::Copy($d.Scan0, $buf, 0, $n)
  $b.UnlockBits($d)
  $min = 255
  for ($i = 3; $i -lt $n; $i += 16) {
    if ($buf[$i] -lt $min) { $min = $buf[$i]; if ($min -lt 250) { return $min } }
  }
  return $min
}

function Resize-To([System.Drawing.Image]$src, [int]$maxDim) {
  $s = [Math]::Min(1.0, $maxDim / [double][Math]::Max($src.Width, $src.Height))
  $w = [Math]::Max(1, [int][Math]::Round($src.Width * $s))
  $h = [Math]::Max(1, [int][Math]::Round($src.Height * $s))
  $bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.DrawImage($src, 0, 0, $w, $h)
  $g.Dispose()
  return $bmp
}

function Save-Jpeg([System.Drawing.Bitmap]$b, [string]$path, [int]$q) {
  $flat = New-Object System.Drawing.Bitmap $b.Width, $b.Height, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $g = [System.Drawing.Graphics]::FromImage($flat)
  $g.Clear([System.Drawing.Color]::White)
  $g.DrawImage($b, 0, 0, $b.Width, $b.Height)
  $g.Dispose()
  $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
  $p = New-Object System.Drawing.Imaging.EncoderParameters 1
  $p.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), $q
  $flat.Save($path, $enc, $p)
  $flat.Dispose()
}

$meta = @()
$origTotal = 0; $finalTotal = 0

foreach ($h in $hashes) {
  $raw = Join-Path $Temp "$h.bin"
  Invoke-WebRequest -Uri ($Base + $h + '.png') -OutFile $raw -UseBasicParsing
  $origBytes = (Get-Item $raw).Length
  $origTotal += $origBytes

  $img  = [System.Drawing.Image]::FromFile($raw)
  $ow = $img.Width; $oh = $img.Height

  # gambar 32bpp utuh untuk analisa alpha
  $full = New-Object System.Drawing.Bitmap $ow, $oh, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($full)
  $g.DrawImage($img, 0, 0, $ow, $oh)
  $g.Dispose()
  $img.Dispose()

  $minAlpha  = Get-MinAlpha $full
  $useAlpha  = $minAlpha -lt 250
  $cands     = @()

  if ($useAlpha) {
    foreach ($dim in 1024, 768, 512) {
      $b = if ([Math]::Max($ow, $oh) -gt $dim) { Resize-To $full $dim } else { $full }
      $tmp = Join-Path $Temp "$h.$dim.png"
      $b.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png)
      if ($b -ne $full) { $b.Dispose() }
      $cands += [pscustomobject]@{ path = $tmp; ext = 'png'; w = $full.Width; h = $full.Height; bytes = (Get-Item $tmp).Length; dim = $dim }
      if ([Math]::Max($ow, $oh) -le $dim) { break }
    }
  } else {
    foreach ($dim in 1320, 1024, 768) {
      $b = if ([Math]::Max($ow, $oh) -gt $dim) { Resize-To $full $dim } else { $full }
      $tmp = Join-Path $Temp "$h.$dim.jpg"
      Save-Jpeg $b $tmp 88
      if ($b -ne $full) { $b.Dispose() }
      $cands += [pscustomobject]@{ path = $tmp; ext = 'jpg'; w = $b.Width; h = $b.Height; bytes = (Get-Item $tmp).Length; dim = $dim }
      if ([Math]::Max($ow, $oh) -le $dim) { break }
    }
  }

  # kandidat jujur: byte asli persis dari server (tanpa re-encode sama sekali).
  # Data PNG dari Figma seringkali sebenarnya JPEG, jadi cukup salin apa adanya.
  if ($useAlpha) {
    $rawCand = Join-Path $Temp "$h.orig.png"
  } else {
    $rawCand = Join-Path $Temp "$h.orig.jpg"
  }
  Copy-Item $raw $rawCand -Force
  $rawExt = if ($useAlpha) { 'png' } else { 'jpg' }
  $cands += [pscustomobject]@{ path = $rawCand; ext = $rawExt; w = $ow; h = $oh; bytes = (Get-Item $rawCand).Length; dim = -1 }

  $best = $cands | Sort-Object bytes | Select-Object -First 1

  # buang varian lama, tulis pemenang
  Get-ChildItem $ImageDir -Filter "$h.*" -ErrorAction SilentlyContinue | Remove-Item -Force
  # Nama lokal sudah menyertakan ekstensi pemenang saat aset ini pertama
  # dioptimalkan (lihat tool/asset-names.json).
  $finalName = $names.$h
  $finalPath = Join-Path $ImageDir $finalName
  Copy-Item $best.path $finalPath -Force
  $newBytes = (Get-Item $finalPath).Length
  $finalTotal += $newBytes

  Write-Host ("{0,-44} {1,5}x{2,-5} alpha={3,-4} {4,9:N1}KB -> {5,8:N1}KB  {6}" -f `
    $finalName, $ow, $oh, $minAlpha, ($origBytes/1KB), ($newBytes/1KB), $best.ext.ToUpper())

  $meta += [pscustomobject]@{
    sha = $h; name = $finalName; kind = 'image'; ext = $finalName.Split('.')[-1]
    path = "assets/images/$finalName"
    w = $best.w; h = $best.h; bytes = $newBytes
  }
  $full.Dispose()
  Remove-Item $raw -Force -ErrorAction SilentlyContinue
}

# ---------- ikon SVG ----------
$rev = @{}
foreach ($p in $names.PSObject.Properties) { $rev[$p.Value] = $p.Name }
$icons = @()
Get-ChildItem $IconDir -Filter *.svg | ForEach-Object {
  $icons += [pscustomobject]@{
    sha = $rev[$_.Name]; name = $_.BaseName; kind = 'icon'; ext = 'svg'
    path = "assets/icons/$($_.Name)"; w = $null; h = $null; bytes = $_.Length
  }
}

$all = @($icons) + @($meta)
$out = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('s')
  counts = [pscustomobject]@{
    total  = $all.Count
    icons  = $icons.Count
    images = $meta.Count
  }
  assets = $all | Sort-Object kind, name
}
$out | ConvertTo-Json -Depth 5 | Set-Content -Path $Manifest -Encoding UTF8

Remove-Item $Temp -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ''
Write-Host ("Raster sebelum : {0:N1} MB" -f ($origTotal/1MB))
Write-Host ("Raster sesudah : {0:N1} MB" -f ($finalTotal/1MB))
Write-Host ("Hemat          : {0:N1}%" -f ((1 - $finalTotal/$origTotal) * 100))
Write-Host ''
Write-Host ("Manifest : $Manifest  ($($all.Count) entri)")
Write-Host ("icons  : " + (Get-ChildItem $IconDir -File).Count)
Write-Host ("images : " + (Get-ChildItem $ImageDir -File).Count)
