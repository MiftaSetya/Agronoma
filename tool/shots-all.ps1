# Memotret seluruh layar sekaligus dari satu APK.
#
#   powershell -File tool/shots-all.ps1 [-Only login,home] [-NoBuild]
#
# Rute dibaca oleh lib/dev_preview.dart dari properti sistem
# `debug.agronoma.rute`, jadi satu build cukup untuk semua layar.
#
# Hasil: %TEMP%\agro-ref\run-<nama>.png untuk setiap baris di $screens,
# lalu tool/compare.py dijalankan untuk membandingkan dengan Figma.
param(
  [string[]]$Only,
  [switch]$NoBuild
)

$ErrorActionPreference = "Continue"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$pkg = "com.agronoma.frontend"
$outDir = "$env:TEMP\agro-ref"
$root = Split-Path -Parent $PSScriptRoot

# nama = berkas keluaran & nama frame Figma; route; step; tunggu (detik)
$screens = @(
  @{ name = "login";          route = "/login";           step = 0; wait = 7 }
  @{ name = "register";       route = "/register";        step = 0; wait = 7 }
  @{ name = "home";           route = "/home";            step = 0; wait = 7 }
  @{ name = "profile";        route = "/profile";         step = 0; wait = 7 }
  @{ name = "plant-detail";   route = "/plant-detail";    step = 0; wait = 8 }
  @{ name = "plant-care";     route = "/plant-detail";    step = 1; wait = 8 }
  @{ name = "plant-chat";     route = "/plant-chat";      step = 0; wait = 7 }
  @{ name = "disease-detect"; route = "/disease-detection"; step = 0; wait = 7 }
  @{ name = "add-1-location"; route = "/add-plant";       step = 0; wait = 8 }
  @{ name = "add-2-media";    route = "/add-plant";       step = 1; wait = 8 }
  @{ name = "add-3-soil";     route = "/add-plant";       step = 2; wait = 9 }
  @{ name = "add-4-reco";     route = "/add-plant";       step = 3; wait = 9 }
  @{ name = "add-5-phase";    route = "/add-plant";       step = 4; wait = 8 }
)

if ($Only) {
  # Saat skrip dipanggil lewat `powershell -File`, argumen diteruskan sebagai
  # string apa adanya sehingga `-Only a,b` datang sebagai satu string "a,b",
  # bukan array dua elemen. Pisahkan di sini supaya kedua cara pemanggilan
  # (`-File` maupun `-Command`) sama-sama bekerja.
  $names = @()
  foreach ($entry in $Only) { $names += $entry -split ',' }
  $names = $names | ForEach-Object { $_.Trim() } | Where-Object { $_ }

  $available = $screens | ForEach-Object { $_.name }
  $screens = $screens | Where-Object { $names -contains $_.name }
  if (-not $screens) {
    Write-Host "Tidak ada layar yang cocok dengan: $($names -join ', ')"
    Write-Host "Nama yang tersedia: $($available -join ', ')"
    exit 1
  }
}

if (-not $NoBuild) {
  Write-Host "=== build (dev_preview) ==="
  Push-Location $root
  & flutter build apk --debug -t lib/dev_preview.dart |
    Select-String -Pattern "Built|Error|error:" | ForEach-Object { $_.Line }
  Pop-Location

  Write-Host "=== install ==="
  & $adb -s emulator-5554 install -r "$root\build\app\outputs\flutter-apk\app-debug.apk" |
    Select-String -Pattern "Success|Failure" | ForEach-Object { $_.Line }
}

foreach ($s in $screens) {
  Write-Host ("--- {0}  ({1} step {2})" -f $s.name, $s.route, $s.step)
  & $adb -s emulator-5554 shell setprop debug.agronoma.rute $s.route
  & $adb -s emulator-5554 shell setprop debug.agronoma.langkah $s.step
  & $adb -s emulator-5554 shell am force-stop $pkg
  Start-Sleep -Milliseconds 300
  & $adb -s emulator-5554 shell am start -n "$pkg/.MainActivity" | Out-Null
  Start-Sleep -Seconds $s.wait
  & $adb -s emulator-5554 shell screencap -p /sdcard/shot.png | Out-Null
  & $adb -s emulator-5554 pull /sdcard/shot.png "$outDir\run-$($s.name).png" |
    Select-String -Pattern "pulled" | ForEach-Object { $_.Line }
}

Write-Host ""
python "$PSScriptRoot\compare.py" ($screens | ForEach-Object { $_.name })
