$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Base = 'http://127.0.0.1:3845/assets/'
$Dir  = 'C:\Project\Agronoma\Frontend\assets\images'
New-Item -ItemType Directory -Force -Path $Dir | Out-Null

# id aset Figma -> nama berkas lokal (lihat tool/asset-names.json). Aset ini
# URL-nya .png tapi isinya JPEG, jadi disimpan dengan nama .jpg-nya.
$names = Get-Content (Join-Path (Split-Path $Dir) '..\tool\asset-names.json') -Raw | ConvertFrom-Json
$asJpg = @()
foreach ($p in $names.PSObject.Properties) {
  if ($p.Value -like '*.jpg') { $asJpg += $p.Name }
}

foreach ($h in $asJpg) {
  $dest = Join-Path $Dir $names.$h
  try {
    Invoke-WebRequest -Uri ($Base + $h + '.png') -OutFile $dest -UseBasicParsing
    $b = [System.IO.File]::ReadAllBytes($dest)
    if (-not ($b[0] -eq 0xFF -and $b[1] -eq 0xD8)) { throw 'bukan JPEG valid' }
    Write-Host "OK  $($names.$h)  ($([math]::Round($b.Length/1KB,1)) KB)"
  } catch {
    Write-Host "GAGAL $h -> $($_.Exception.Message)"
    Remove-Item $dest -ErrorAction SilentlyContinue
  }
}

Write-Host ''
Write-Host '=== DIMENSI SEMUA GAMBAR ==='
$report = @()
Get-ChildItem $Dir -File | Sort-Object Length -Descending | ForEach-Object {
  try {
    $img = [System.Drawing.Image]::FromFile($_.FullName)
    $report += [pscustomobject]@{
      Name = $_.Name
      Ext  = $_.Extension
      W    = $img.Width
      H    = $img.Height
      KB   = [math]::Round($_.Length/1KB,1)
    }
    $img.Dispose()
  } catch {
    $report += [pscustomobject]@{ Name = $_.Name; Ext = $_.Extension; W = 'ERR'; H = 'ERR'; KB = [math]::Round($_.Length/1KB,1) }
  }
}
$report | Format-Table -AutoSize
Write-Host ("Jumlah gambar : " + $report.Count)
Write-Host ("Total KB      : " + [math]::Round(($report | Measure-Object KB -Sum).Sum,1))
