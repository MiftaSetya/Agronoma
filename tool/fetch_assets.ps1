$ErrorActionPreference = 'Stop'

$Root     = 'C:\Project\Agronoma\Frontend'
$Base     = 'http://127.0.0.1:3845/assets/'
$IconDir  = Join-Path $Root 'assets\icons'
$ImageDir = Join-Path $Root 'assets\images'
New-Item -ItemType Directory -Force -Path $IconDir, $ImageDir | Out-Null

# Server aset Figma menyajikan berkas dengan nama = id aset (SHA-1). Daftar id
# di bawah diambil dari `tool/asset-names.json` (id -> nama berkas lokal), jadi
# berkas yang sudah ada dikenali lewat nama lokalnya, bukan lewat id.
$names = Get-Content (Join-Path $Root 'tool\asset-names.json') -Raw | ConvertFrom-Json

$svgs = @()
$pngs = @()
foreach ($p in $names.PSObject.Properties) {
  $local = $p.Value
  if ($local -like '*.svg') { $svgs += "$($p.Name)" }
  elseif ($local -like '*.jpg' -or $local -like '*.png') { $pngs += "$($p.Name)|$local" }
}

$ok = 0; $skip = 0; $fail = @()

foreach ($f in $svgs) {
  $dest = Join-Path $IconDir $names.$f
  if (Test-Path $dest) { $skip++; continue }
  try {
    Invoke-WebRequest -Uri ($Base + $f + '.svg') -OutFile $dest -UseBasicParsing
    $txt = Get-Content -Raw -Path $dest -ErrorAction Stop
    if ($txt -notmatch '<svg') { throw "bukan SVG valid" }
    $ok++
  } catch { $fail += @{ f = $f; e = $_.Exception.Message }; Remove-Item $dest -ErrorAction SilentlyContinue }
}

foreach ($f in $pngs) {
  $sha, $local = $f.Split('|')
  $dest = Join-Path $ImageDir $local
  if (Test-Path $dest) { $skip++; continue }
  try {
    # Figma menyajikan semua raster sebagai .png walau isinya sering JPEG.
    Invoke-WebRequest -Uri ($Base + $sha + '.png') -OutFile $dest -UseBasicParsing
    $b = [System.IO.File]::ReadAllBytes($dest)
    if (-not ($b[0] -eq 0xFF -and $b[1] -eq 0xD8) -and -not ($b[0] -eq 0x89 -and $b[1] -eq 0x50)) { throw 'bukan gambar valid' }
    $ok++
  } catch { $fail += @{ f = $sha; e = $_.Exception.Message }; Remove-Item $dest -ErrorAction SilentlyContinue }
}

Write-Host "=== HASIL UNDUHAN ==="
Write-Host "Berhasil : $ok"
Write-Host "Dilewati : $skip"
Write-Host "Gagal    : $($fail.Count)"
foreach ($x in $fail) { Write-Host ("  GAGAL " + $x.f + " -> " + $x.e) }
Write-Host ""
Write-Host ("SVG di assets/icons : " + (Get-ChildItem $IconDir -Filter *.svg).Count)
Write-Host ("PNG di assets/images: " + (Get-ChildItem $ImageDir -Filter *.png).Count)
Write-Host ("Total ukuran         : " + [math]::Round((Get-ChildItem $IconDir,$ImageDir -File | Measure-Object Length -Sum).Sum / 1KB, 1) + " KB")
