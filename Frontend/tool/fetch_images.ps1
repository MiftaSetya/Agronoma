$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Base = 'http://127.0.0.1:3845/assets/'
$Dir  = 'C:\Project\Agronoma\Frontend\assets\images'
New-Item -ItemType Directory -Force -Path $Dir | Out-Null

# Aset ini URL-nya .png tapi isinya JPEG -> simpan sebagai .jpg
$asJpg = @(
  'a1d9f55fba0c922f702df6312dfc730d481d9c46',
  '83fcae546fbfaec4e5b6e7980bb5365d0cf4c9e4',
  '1f81b734e8934189c58e15c350cf1556b1cf3ad0',
  'd41d5e0848924bc81706be83a6c9fe6a1e60c0e8'
)

foreach ($h in $asJpg) {
  $dest = Join-Path $Dir "$h.jpg"
  try {
    Invoke-WebRequest -Uri ($Base + $h + '.png') -OutFile $dest -UseBasicParsing
    $b = [System.IO.File]::ReadAllBytes($dest)
    if (-not ($b[0] -eq 0xFF -and $b[1] -eq 0xD8)) { throw 'bukan JPEG valid' }
    Write-Host "OK  $h.jpg  ($([math]::Round($b.Length/1KB,1)) KB)"
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
