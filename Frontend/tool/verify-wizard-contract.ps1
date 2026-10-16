# Verifikasi kontrak endpoint wizard "Tambah Tanaman" terhadap backend sungguhan.
# Membuktikan bentuk permintaan/balasan yang diandalkan HttpAddPlantRepository,
# memakai berkas contoh sebagai "foto" (backend hanya memvalidasi bahwa
# berkasnya berupa gambar, bukan isi gambarnya).

$base = "http://127.0.0.1:8000/api"
$stamp = Get-Date -Format "HHmmss"
$email = "wizard$stamp@agronoma.test"
$pass = "rahasia123"
$hasil = @()

$H = @{ Accept = "application/json"; "Content-Type" = "application/json" }

function Catat($nama, $script) {
  try {
    $script:hasil += [pscustomobject]@{ Uji = $nama; Hasil = (& $script) }
  } catch {
    $resp = $_.Exception.Response
    if ($resp) {
      $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
      $script:hasil += [pscustomobject]@{ Uji = $nama; Hasil = "HTTP $([int]$resp.StatusCode): $($sr.ReadToEnd())" }
    } else {
      $script:hasil += [pscustomobject]@{ Uji = $nama; Hasil = "ERR: $($_.Exception.Message)" }
    }
  }
}

# 0. Akun baru (token tidak boleh dari akun lain: lokasi & tanaman terikat pengguna).
$reg = Invoke-RestMethod -Uri "$base/register" -Method POST -Headers $H -Body (@{name="Verifikasi Wizard";email=$email;password=$pass;password_confirmation=$pass}|ConvertTo-Json -Compress)
$HA = @{ Accept = "application/json"; "Content-Type" = "application/json"; Authorization = "Bearer $($reg.token)" }
$hasil += [pscustomobject]@{ Uji = "register"; Hasil = "id=$($reg.user.id)" }

# 1. Lokasi: POST /locations memakai label + city + province (tanpa koordinat).
$lok = Invoke-RestMethod -Uri "$base/locations" -Method POST -Headers $HA -Body (@{label="Rumah Kaca Sukolilo";city="Surabaya";province="Jawa Timur"}|ConvertTo-Json -Compress)
$lokasiId = $lok.location.id
$hasil += [pscustomobject]@{ Uji = "POST /locations"; Hasil = "id=$lokasiId label='$($lok.location.label)' city='$($lok.location.city)'" }

# 2. Foto contoh: 1x1 PNG yang valid supaya lolos aturan `image`.
$png = [Convert]::FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8AAAwAB/AGt2Q0IAAAAAElFTkSuQmCC")
$foto = Join-Path $env:TEMP "agro-kontrak-$stamp.png"
[IO.File]::WriteAllBytes($foto, $png)

# 3. POST /soil-scan -> detected_soil_type (enum) + ai_confidence (0-100).
Catat "POST /soil-scan" {
  $r = curl.exe -s -X POST "$base/soil-scan" -H "Accept: application/json" -H "Authorization: Bearer $($reg.token)" -F "image=@$foto"
  $j = $r | ConvertFrom-Json
  if ($j.detected_soil_type) {
    "soil=$($j.detected_soil_type) confidence=$($j.ai_confidence)"
  } else { "BALASAN: $r" }
}

# 4. POST /plants -> plant{} lengkap dengan badge_status + location.
Catat "POST /plants" {
  $body = @{
    location_id    = $lokasiId
    plant_name     = "Cabai Rawit"
    planting_medium = "home_yard"
    soil_type      = "fertile"
    current_phase  = "seedling"
    planting_date  = (Get-Date -Format "yyyy-MM-dd")
  } | ConvertTo-Json -Compress
  $r = Invoke-RestMethod -Uri "$base/plants" -Method POST -Headers $HA -Body $body
  $p = $r.plant
  $script:tanamanId = $p.id
  "id=$($p.id) badge=$($p.badge_status) phase=$($p.current_phase) city='$($p.location.city)' id_lokasi=$($p.location.id)"
}

# 5. GET /plants/{id} -> bentuk resource yang sama (dipakai Plant.fromJson nanti).
Catat "GET /plants/{id}" {
  $p = (Invoke-RestMethod -Uri "$base/plants/$($script:tanamanId)" -Headers $HA).plant
  "plant_name='$($p.plant_name)' planting_medium=$($p.planting_medium) soil_type=$($p.soil_type)"
}

$hasil | Format-Table -AutoSize -Wrap
Remove-Item $foto -ErrorAction SilentlyContinue
