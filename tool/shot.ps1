# Membangun, memasang, menjalankan, lalu memotret aplikasi di emulator.
#
#   powershell -File tool/shot.ps1 <nama> [-Route /home] [-Step 2] [-Wait 8] [-NoBuild]
#
# <nama>  nama berkas keluaran, sekaligus nama frame Figma di tool/compare.py
# -Route  rute preview (lihat lib/dev_preview.dart), default /login
# -Step   langkah/tab awal untuk layar yang punya beberapa keadaan
#
# Hasil: %TEMP%\agro-ref\run-<nama>.png
# Lalu:  python tool/compare.py <nama>
#
# Pemakaian pertama butuh `-NoBuild:$false`; setelah APK terpasang, panggilan
# berikutnya cukup `-NoBuild` supaya hanya ganti rute + potret.
#
# Emulator harus sudah disetel ke kanvas Figma:
#   adb shell wm size 1320x2868      # 440x956 @ 3x
#   adb shell wm density 480
param(
  [Parameter(Mandatory = $true)][string]$Name,
  [string]$Route = "/login",
  [int]$Step = 0,
  [int]$Wait = 8,
  [switch]$NoBuild
)

$ErrorActionPreference = "Continue"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$pkg = "com.agronoma.frontend"
$outDir = "$env:TEMP\agro-ref"
$root = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

if (-not $NoBuild) {
  Write-Host "=== build (dev_preview) ==="
  Push-Location $root
  # Tanpa `2>&1`: PowerShell 5.1 mengubah stderr proses native jadi error
  # record, dan itu membuat skrip berhenti walau build-nya sendiri berhasil.
  & flutter build apk --debug -t lib/dev_preview.dart |
    Select-String -Pattern "Built|Error|error:" | ForEach-Object { $_.Line }
  Pop-Location

  Write-Host "=== install ==="
  & $adb -s emulator-5554 install -r "$root\build\app\outputs\flutter-apk\app-debug.apk" |
    Select-String -Pattern "Success|Failure" | ForEach-Object { $_.Line }
}

Write-Host "=== rute: $Route  langkah: $Step ==="
& $adb -s emulator-5554 shell setprop debug.agronoma.rute "$Route"
& $adb -s emulator-5554 shell setprop debug.agronoma.langkah "$Step"

& $adb -s emulator-5554 shell am force-stop $pkg
Start-Sleep -Milliseconds 400
& $adb -s emulator-5554 shell am start -n "$pkg/.MainActivity" | Out-Null
Start-Sleep -Seconds $Wait

Write-Host "=== potret ==="
& $adb -s emulator-5554 shell screencap -p /sdcard/shot.png | Out-Null
& $adb -s emulator-5554 pull /sdcard/shot.png "$outDir\run-$Name.png" |
  Select-String -Pattern "pulled" | ForEach-Object { $_.Line }

python "$PSScriptRoot\compare.py" $Name
