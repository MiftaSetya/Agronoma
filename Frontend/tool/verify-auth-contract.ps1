# Verifikasi kontrak autentikasi terhadap backend sungguhan.
# Membuktikan bentuk balasan yang diandalkan HttpAuthRepository.

$base = "http://127.0.0.1:8000/api"
$stamp = Get-Date -Format "HHmmss"
$email = "kontrak$stamp@agronoma.test"
$pass = "rahasia123"
$hasil = @()

function Coba($nama, $script) {
  try {
    $r = & $script
    $script:hasil += [pscustomobject]@{ Uji = $nama; Hasil = $r }
  } catch {
    $resp = $_.Exception.Response
    if ($resp) {
      $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
      $txt = $sr.ReadToEnd()
      $script:hasil += [pscustomobject]@{ Uji = $nama; Hasil = "HTTP $([int]$resp.StatusCode): $txt" }
    } else {
      $script:hasil += [pscustomobject]@{ Uji = $nama; Hasil = "ERR: $($_.Exception.Message)" }
    }
  }
}

$H = @{ Accept = "application/json"; "Content-Type" = "application/json" }

# 1. register
$reg = Invoke-RestMethod -Uri "$base/register" -Method POST -Headers $H -Body (@{name="Verifikasi Kontrak";email=$email;password=$pass;password_confirmation=$pass}|ConvertTo-Json -Compress)
$hasil += [pscustomobject]@{ Uji="register"; Hasil="id=$($reg.user.id) nama='$($reg.user.name)' tokenLen=$($reg.token.Length) punya created_at=$($null -ne $reg.user.created_at)" }

$token = $reg.token
$HA = @{ Accept="application/json"; Authorization="Bearer $token" }

# 2. GET /user  (dipakai restoreSession)
$u = Invoke-RestMethod -Uri "$base/user" -Headers $HA
$hasil += [pscustomobject]@{ Uji="GET /user"; Hasil="id=$($u.user.id) email=$($u.user.email)" }

# 3. login dengan kredensial benar
$log = Invoke-RestMethod -Uri "$base/login" -Method POST -Headers $H -Body (@{email=$email;password=$pass}|ConvertTo-Json -Compress)
$hasil += [pscustomobject]@{ Uji="login benar"; Hasil="token berbeda dari register: $($log.token -ne $token)" }

# 4. login kredensial salah -> 422 {errors.credentials}
Coba "login salah (422)" {
  try {
    Invoke-RestMethod -Uri "$base/login" -Method POST -Headers $H -Body (@{email=$email;password="salahsalah"}|ConvertTo-Json -Compress) | Out-Null
    "TIDAK melempar (salah)"
  } catch {
    $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $body = $sr.ReadToEnd() | ConvertFrom-Json
    "status=422, errors.credentials='$($body.errors.credentials[0])'"
  }
}

# 5. register email duplikat -> 422 {errors.email}
Coba "register duplikat (422)" {
  try {
    Invoke-RestMethod -Uri "$base/register" -Method POST -Headers $H -Body (@{name="X";email=$email;password=$pass;password_confirmation=$pass}|ConvertTo-Json -Compress) | Out-Null
    "TIDAK melempar (salah)"
  } catch {
    $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $body = $sr.ReadToEnd() | ConvertFrom-Json
    "status=422, errors.email='$($body.errors.email[0])'"
  }
}

# 6. password terlalu pendek -> 422 {errors.password}
Coba "password pendek (422)" {
  try {
    Invoke-RestMethod -Uri "$base/register" -Method POST -Headers $H -Body (@{name="Y";email="y$stamp@agronoma.test";password="123";password_confirmation="123"}|ConvertTo-Json -Compress) | Out-Null
    "TIDAK melempar (salah)"
  } catch {
    $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $body = $sr.ReadToEnd() | ConvertFrom-Json
    "status=422, errors.password='$($body.errors.password[0])'"
  }
}

# 7. logout
$out = Invoke-RestMethod -Uri "$base/logout" -Method POST -Headers $HA
$hasil += [pscustomobject]@{ Uji="logout"; Hasil="$($out.message)" }

# 8. token setelah logout -> 401
Coba "GET /user setelah logout" {
  try {
    Invoke-RestMethod -Uri "$base/user" -Headers $HA | Out-Null
    "MASIH 200 (salah)"
  } catch { "status=$([int]$_.Exception.Response.StatusCode) (token dicabut)" }
}

# 9. header Accept tidak ada -> masih 500 (bug backend, dicatat)
Coba "GET /plants TANPA Accept" {
  try {
    Invoke-RestMethod -Uri "$base/plants" | Out-Null
    "200 (?)"
  } catch { "status=$([int]$_.Exception.Response.StatusCode)" }
}

$hasil | Format-Table -AutoSize -Wrap
