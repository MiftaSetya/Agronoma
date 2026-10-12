# Peta Aset

Setiap aset di `assets/` dinamai **SHA-1 kontennya** (hasil ekspor Figma via
`tool/fetch_assets.ps1`, dioptimalkan `tool/optimize_assets.ps1`, dan
dicatat `tool/manifest.json`). Nama berkas yang berisi hash membuat dua hal
jadi murah:

- **anti-duplikat** — berkas yang sama tidak pernah tersimpan dua kali, dan
- **anti-usang** — bila design mengganti ikon, SHA-nya berubah, sehingga kode
  yang masih menunjuk hash lama langsung gagal memuat alih-alih diam-diam
  menampilkan ikon yang salah.

Widget tidak menyebut hash itu langsung. Semua path dikumpulkan di
`lib/core/assets/app_assets.dart` (`AppAssets`), lengkap dengan komentar
asal-usulnya. Pemetaan ikon → nama semantik dibuat oleh
`tool/figma_semantic_map.mjs`; hasilnya tabel di bawah.

Tabel di-generate dari registry + manifest dengan skrip kecil — kalau aset
baru ditambahkan, jalankan ulang skripnya supaya tabel tetap sinkron.

## Ikon & gambar yang dipakai kode

| Nama (`AppAssets`) | Berkas | Ukuran | Keterangan |
|---|---|---:|---|
| `addPlant` | icons/6fe50b8e.svg | 1,262 B | Tombol tambah tanaman di menu FAB (#6D9C25) |
| `archive` | icons/39e90148.svg | 1,449 B | Kotak arsip — baris "Arsip tanaman" |
| `arrowDown` | icons/c6991985.svg | 1,029 B | Panah bawah (dropdown), mis. pada field pilih |
| `arrowLeftWhite` | icons/ef737f2f.svg | 333 B | Panah kiri putih di atas foto header |
| `bestMatchStar` | icons/86fcf618.svg | 1,415 B | Bintang kuning kecil (12x12,6) di chip "Pilihan Terbaik" (langkah 4) |
| `calendarFertilizer` | icons/fce7e399.svg | 2,321 B | Ikon kecil (12px) pemupukan di kalender perawatan |
| `calendarWatering` | icons/1bc17606.svg | 1,067 B | Ikon kecil (12px) penyiraman di kalender perawatan |
| `cameraFill` | icons/8936dfb0.svg | 1,674 B | Kamera putih — tombol ganti foto di drawer "Setelan Tanaman" |
| `careWaterDrops` | icons/13655dc5.svg | 1,764 B | Ikon tugas penyiraman (biru) pada "Perawatan Hari Ini" |
| `careWateringCan` | icons/cc68dec2.svg | 2,096 B | Ikon tugas pemupukan (cokelat) pada "Perawatan Hari Ini" |
| `chatAi` | icons/58a5d2ea.svg | 3,003 B | Ikon obrolan AI di top bar (putih) untuk layar chat |
| `checkCircle` | icons/4398fe69.svg | 1,123 B | Centang bulat hijau — status perawatan "Kondisi Aman" |
| `checkCircleSolid` | icons/63bd523e.svg | 1,007 B | Centang bulat solid hijau tua (#56810B) agar terbaca di atas pil hijau |
| `checkMarkGreen` | icons/e49bbb9c.svg | 347 B | Centang hijau slot langkah 4, disembunyikan dengan `Opacity` |
| `chevronLeft` | icons/1422e538.svg | 335 B | Panah kembali (opacity 0 — judul tetap tengah) |
| `chevronLeftThin` | icons/b0edba78.svg | 345 B | Panah "<" bergaris (chevron tipis) — sisi kiri top bar varian 3 |
| `chevronRight` | icons/7c1bfeea.svg | 1,122 B | Panah ">" (chevron kanan) untuk baris yang bisa ditekan |
| `chevronRightSmall` | icons/2e6408ac.svg | 283 B | Panah ">" kecil (7.4x12) untuk baris daftar |
| `chevronRightThin` | icons/a7ce4d8f.svg | 335 B | Panah ">" bergaris (chevron tipis) — sisi kanan top bar varian 4 |
| `closeLine` | icons/51565193.svg | 1,479 B | Silang tipis (close-line) — menutup layar kamera / menu |
| `closeMenu` | icons/bd49f2e9.svg | 1,709 B | Ikon "Tutup" (kotak dengan silang) di menu FAB |
| `diseaseDiagnosis` | icons/bd5068fb.svg | 6,052 B | Ikon "Diagnosis penyakit tanaman" di menu FAB (#6D9C25) |
| `diseaseScan` | icons/3c4a1631.svg | 6,472 B | Ikon pindai kesehatan (putih) untuk kartu "Pindai Kesehatan" |
| `fabLogo` | icons/200d5ec8.svg | 3,244 B | Logo Agronoma putih di tengah FAB (tombol hijau melayang) |
| `flashFill` | icons/756880f6.svg | 911 B | Ikon kilat (flash) — tombol kanan di bawah layar kamera |
| `galleryFill` | icons/17ff6b81.svg | 745 B | Ikon galeri — tombol kiri di bawah layar kamera |
| `harvest` | icons/9d0d832e.svg | 1,424 B | Salad/hasil panen — statistik "Dipanen" |
| `infoFill` | icons/83fa194c.svg | 1,152 B | Ikon informasi bulat (biru) — pil petunjuk di layar kamera |
| `leafFill` | icons/d73e86bc.svg | 1,800 B | Daun — kartu "Skor perawatan" |
| `locationFill` | icons/e3efd504.svg | 1,277 B | Penanda lokasi (type pin) — baris kota pada kartu tanaman |
| `locationFilled` | icons/091d3ab2.svg | 1,174 B | Penanda lokasi dengan lubang di tengah, di samping nama lokasi |
| `locationTag` | icons/e49f3918.svg | 1,313 B | Lokasi terisi abu (#898B87) — awalan field "Lokasi Tanaman" |
| `logoMark` | icons/0984935e.svg | 2,453 B | Logo "A" berdaun — dipakai di Login/Register dan sebagai ikon aplikasi |
| `logout` | icons/f1f02166.svg | 1,342 B | Pintu keluar — tombol "Keluar" |
| `manualAddCircle` | icons/6e06a745.svg | 1,134 B | Tombol "tambah manual" (langkah 4 wizard) |
| `mapPointer` | icons/2fa8343d.svg | 4,263 B | Penanda lokasi pada peta (langkah 1) |
| `mediaGround` | icons/f03253cc.svg | 958 B | Ikon media tanam: tanah lapang (`Lahan terbuka`) |
| `mediaHouse` | icons/3fc8a3be.svg | 1,953 B | Rumah — pilihan "Pekarangan rumah" |
| `mediaPot` | icons/61e41058.svg | 1,597 B | Ikon media tanam: pot (`Pot tanaman`) |
| `navHomeActive` | icons/2c51ffd1.svg | 990 B | Ikon tab "Beranda" saat aktif (putih, di dalam pil hijau) |
| `navHomeOutline` | icons/6f62cf30.svg | 1,382 B | Ikon tab "Beranda" saat TIDAK aktif (#898B87) |
| `navProfileActive` | icons/284d83d1.svg | 1,046 B | Ikon tab "Profil" saat aktif (putih) |
| `navProfileOutline` | icons/dcf9c6b6.svg | 1,936 B | Ikon tab "Profil" saat TIDAK aktif (#898B87) |
| `phaseDotActive` | icons/69aded84.svg | 2,755 B | Titik fase aktif (lingkaran hijau + cincin putih) |
| `phaseGenerative` | icons/3ab2a16f.svg | 1,294 B | Ikon fase: generatif |
| `phaseSeedling` | icons/dd67902a.svg | 540 B | Ikon fase: semai biji |
| `phaseVegetativeEarly` | icons/b29cf626.svg | 1,282 B | Ikon fase: vegetatif awal |
| `phaseVegetativeLate` | icons/3484631a.svg | 2,411 B | Ikon fase: vegetatif akhir (tinggi 25, dipakai apa adanya) |
| `photoCabaiKeriting` | images/e1c380d0.jpg | 204,646 B | Foto "Cabai Rawit Keriting" |
| `photoCabaiRawit` | images/83fcae54.jpg | 364,017 B | Foto "Cabai Rawit" |
| `photoLidahMertua` | images/ad9f407e.jpg | 169,541 B | Foto "Lidah Mertua (Sansevieria)" — rekomendasi ke-2 di langkah 4 |
| `photoMap` | images/0b2e0f5b.jpg | 68,854 B | Foto peta (ubin jalan) untuk langkah "Lokasi penanaman" |
| `photoPlantDetection` | images/d41d5e08.jpg | 140,505 B | Foto hasil deteksi penyakit |
| `photoProfile` | images/e1af5d24.jpg | 225,521 B | Foto profil pengguna |
| `photoSirihGading` | images/5aee8982.jpg | 56,079 B | Foto "Sirih Gading" — rekomendasi ke-3 di langkah 4 |
| `photoTomatCeri` | images/a1d9f55f.jpg | 126,265 B | Foto "Tomat Ceri" |
| `pottedPlant` | icons/93dee2db.svg | 1,407 B | Pot tanaman — statistik "Tanaman" |
| `rainAlert` | icons/277e53b5.svg | 6,541 B | Peringatan hujan (FAB di atas tombol obrolan) |
| `settingsLineWhite` | icons/5aaaa51f.svg | 3,670 B | Gir pengaturan (putih) di kanan atas header Detail Tanaman |
| `sheetHandle` | icons/d4923294.svg | 288 B | Gagang tarik drawer bawah |
| `soilListManual` | icons/soil-list-manual.svg | 516 B | Ikon daftar kartu "Saya Tahu Jenis Tanah" — digambar ulang dari trace piksel |
| `soilScan` | icons/eff00ba5.svg | 3,538 B | Ikon kamera abu kartu "Bantu saya scan tanah" |
| `soilScanSelected` | icons/3cc16617.svg | 3,536 B | Ikon kamera putih (terpilih), di dalam bulatan 60px digambar 32px |
| `tabUnderline` | icons/8832c9f7.svg | 260 B | Garis bawah tab yang sedang aktif pada Detail Tanaman |
| `tag` | icons/16e0c83d.svg | 1,574 B | Ikon tag/label — prefix field nama tanaman |
| `taskCheckDone` | icons/31a2dc7c.svg | 479 B | Kotak centang tugas perawatan — sudah dikerjakan |
| `taskCheckEmpty` | icons/7360fdf6.svg | 272 B | Kotak centang tugas perawatan — belum dikerjakan |
| `warningFill` | icons/042357eb.svg | 1,246 B | Ikon peringatan bulat (merah) — label "Penyakit terdeteksi" |
| `waterDrop` | icons/d886046b.svg | 1,048 B | Tetes air (biru) — chip "Pengingat Penyiraman" |
| `waterDrops` | icons/dee016e4.svg | 1,981 B | Beberapa tetes air (biru) — status perawatan "Perlu Disiram" |
| `wateringCan` | icons/582a8ddb.svg | 2,323 B | Gembor / alat siram (kuning) — status perawatan "Perlu Pupuk" |
| `weatherClear` | icons/fe532cf4.svg | 4,063 B | Matahari penuh — "Cerah" |
| `weatherPartlyCloudy` | icons/1633b862.svg | 1,496 B | Awan dengan matahari — "Sebagian Berawan" |
| `weatherRain` | icons/746c5a17.svg | 5,351 B | Hujan (varian abu-biru) — "Hujan" |
| `weatherRainAlt` | icons/98832cea.svg | 3,816 B | Hujan (varian kedua, tanpa tetes ringan) |
| `weatherRainHeavy` | icons/a6f91e88.svg | 3,893 B | Hujan lebat |
| `weatherSunShower` | icons/9b2be4d4.svg | 5,209 B | Cerah berawan (matahari + awan + tetes) |
| `wordmark` | icons/b5724314.svg | 8,846 B | Wordmark "Agronoma" (dipakai di top bar Home/Profile) |

## Gambar cadangan (belum direferensikan kode)

Hasil ekspor Figma menyertakan foto dalam beberapa resolusi. Yang dipakai
kode hanya resolusi finalnya (tabel atas); sisanya disimpan sebagai cadangan
bila suatu layar butuh foto resolusi lebih tinggi:

| Nama berkas | Dimensi | Ukuran |
|---|---|---:|
| `1f81b734…jpg` | 720x1280 | 199,778 B |
| `23f81969…jpg` | 1024x1024 | 367,207 B |
| `4ea7e0d8…jpg` | 1024x1024 | 468,593 B |
| `5a06f9d9…jpg` | 1024x1024 | 517,507 B |
| `5fd926b6…png` | 522x522 | 9,156 B |
| `615dabec…jpg` | 1200x1200 | 364,017 B |
| `680c6f3c…jpg` | 1024x1024 | 582,671 B |
| `8bffd861…jpg` | 1024x1024 | 513,055 B |
| `916ce803…jpg` | 1024x559 | 242,524 B |
| `be6aadfe…jpg` | 1024x1024 | 421,352 B |

## Kasus khusus

- **`soilListManual.svg`** — satu-satunya aset yang bukan hasil ekspor Figma.
  Ikon ini adalah *override* komponen pada kartu "Saya Tahu Jenis Tanah"
  (drawer langkah 3 wizard). Berkas SVG aslinya tidak tersedia di server
  aset MCP (hanya varian kamera `eff00ba5…`), jadi ikonnya digambar ulang
  dari trace piksel render Figma. Geometrinya tercatat di komentar
  `AppAssets.soilListManual`.
- **Ikon dengan `opacity="0"`** (`chevronLeft`, `chevronLeftThin`) — di Figma
  elemen ini sengaja tak terlihat (hanya penjaga layout). Tetap di-bundle
  supaya struktur kode 1:1 dengan design.
- **Manifest** (`tool/manifest.json`) menghitung 136 aset (118 ikon + 18
  gambar); `test/asset_bundle_test.dart` mengunci angka itu dan memverifikasi
  setiap berkas benar-benar ada di bundle.
