$ErrorActionPreference = 'Stop'

$Root = 'C:\Project\Agronoma\Frontend'
$Dir  = Join-Path $Root 'assets\fonts'
New-Item -ItemType Directory -Force -Path $Dir | Out-Null

# Inter statis resmi (dipublikasikan ulang dari Google Fonts, lisensi OFL)
$interBase = 'https://cdn.jsdelivr.net/npm/@expo-google-fonts/inter@0.4.2'
# Poppins dari repo resmi Google Fonts
$gfBase    = 'https://raw.githubusercontent.com/google/fonts/main/ofl'

$jobs = @(
  @{ url = "$interBase/400Regular/Inter_400Regular.ttf"; name = 'Inter-Regular.ttf' },
  @{ url = "$interBase/500Medium/Inter_500Medium.ttf";   name = 'Inter-Medium.ttf' },
  @{ url = "$interBase/600SemiBold/Inter_600SemiBold.ttf"; name = 'Inter-SemiBold.ttf' },
  @{ url = "$interBase/700Bold/Inter_700Bold.ttf";       name = 'Inter-Bold.ttf' },
  @{ url = "$gfBase/poppins/Poppins-Bold.ttf";           name = 'Poppins-Bold.ttf' },
  @{ url = "$gfBase/inter/OFL.txt";                      name = 'OFL-Inter.txt' },
  @{ url = "$gfBase/poppins/OFL.txt";                    name = 'OFL-Poppins.txt' }
)

function Get-Magic([byte[]]$b) {
  if ($b.Length -ge 4 -and $b[0] -eq 0x00 -and $b[1] -eq 0x01 -and $b[2] -eq 0x00 -and $b[3] -eq 0x00) { return 'TTF' }
  if ($b.Length -ge 4 -and $b[0] -eq 0x4F -and $b[1] -eq 0x54 -and $b[2] -eq 0x54 -and $b[3] -eq 0x4F) { return 'OTF' }
  if ($b.Length -ge 4 -and $b[0] -eq 0x74 -and $b[1] -eq 0x72 -and $b[2] -eq 0x75 -and $b[3] -eq 0x65) { return 'TTF(true)' }
  return 'unknown'
}

$ok = 0; $fail = @()
foreach ($j in $jobs) {
  $dest = Join-Path $Dir $j.name
  try {
    Invoke-WebRequest -Uri $j.url -OutFile $dest -UseBasicParsing
    $b = [System.IO.File]::ReadAllBytes($dest)
    if ($b.Length -lt 1024) { throw "terlalu kecil ($($b.Length) byte)" }
    $magic = Get-Magic $b
    if ($j.name -like '*.ttf' -and $magic -eq 'unknown') { throw "magic bytes tidak dikenal" }
    if ($j.name -like '*.txt' -and $b[0] -ne 0x43) { throw "bukan teks" }
    Write-Host ("OK    {0,-24} {1,8:N1} KB  {2}" -f $j.name, ($b.Length/1KB), $magic)
    $ok++
  } catch {
    Write-Host ("GAGAL {0,-24} {1}" -f $j.name, $_.Exception.Message)
    Remove-Item $dest -ErrorAction SilentlyContinue
    $fail += $j.name
  }
}

Write-Host ''
Write-Host "Berhasil: $ok / $($jobs.Count)   Gagal: $($fail.Count)"
if ($fail.Count) { Write-Host ("Gagal: " + ($fail -join ', ')) }

# ---- sematkan sebagai aset di pubspec ----
$fonts = Get-ChildItem $Dir -Filter *.ttf | Sort-Object Name
Write-Host ''
Write-Host "Font terpasang ($($fonts.Count)):"
$fonts | ForEach-Object { Write-Host ("  assets/fonts/" + $_.Name) }
Write-Host ("Total font: {0:N1} KB" -f (($fonts | Measure-Object Length -Sum).Sum/1KB))
