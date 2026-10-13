# Peta Aset

Berkas di `assets/` **bernama deskriptif** (kebab-case, mis.
`nav-home-active.svg`), bukan hash. Nama itu dipetakan dari **id aset Figma**
(SHA-1) lewat `tool/asset-names.json`; `tool/fetch_assets.ps1`,
`tool/optimize_assets.ps1`, dan `tool/fetch_images.ps1` memakai file itu untuk
mengunduh ulang tanpa kehilangan asal-usul.

Awalnya berkas dinamai id aset Figma apa adanya. Nama hash membuat dua hal
murah — **anti-duplikat** dan **anti-usang** — tetapi sulit dibaca; karena id
aset Figma ternyata *bukan* hash isi berkas (118/118 ikon beda, dan ada 4 grup
berkas byte-identik), jaminan itu memang tidak pernah berlaku penuh. Sekarang
keutuhan/keberadaan dijaga test: `test/asset_bundle_test.dart` mengunci
manifest, dan `test/asset_naming_test.dart` memastikan tiap berkas bernama
deskriptif, kebab-case, dan tanpa id SHA.

Widget tidak menyebut path literal. Semua path dikumpulkan di
`lib/core/assets/app_assets.dart` (`AppAssets`), lengkap dengan komentar
asal-usulnya. Pemetaan ikon → nama semantik aslinya (ikon Figma punya
`data-name`) dibuat `tool/figma_semantic_map.mjs` dan dicek visual lewat
`tool/icon_sheet_test.dart` (`build/icon_sheet.png`).

Tabel di bawah di-generate ulang dari registry + manifest lewat skrip kecil —
kalau aset baru ditambahkan, jalankan ulang supaya tabel tetap sinkron.

## Ikon & gambar yang dipakai kode

| Nama (`AppAssets`) | Berkas | Ukuran | Keterangan |
|---|---|---:|---|
| `addPlant` | icons/add-plant.svg | 1,262 B | Tombol tambah tanaman di menu FAB (#6D9C25) |
| `archive` | icons/archive.svg | 1,449 B | Kotak arsip â€” baris "Arsip tanaman" |
| `arrowDown` | icons/arrow-down.svg | 1,029 B | Panah bawah (dropdown), mis. pada field pilih |
| `arrowLeftWhite` | icons/arrow-left-white.svg | 333 B | Panah kiri putih di atas foto header |
| `bestMatchStar` | icons/best-match-star.svg | 1,415 B | Bintang kuning kecil (12x12,6) di chip "Pilihan Terbaik" (langkah 4) |
| `calendarFertilizer` | icons/calendar-fertilizer.svg | 2,321 B | Ikon kecil (12px) pemupukan di kalender perawatan |
| `calendarWatering` | icons/calendar-watering.svg | 1,067 B | Ikon kecil (12px) penyiraman di kalender perawatan |
| `cameraFill` | icons/camera-fill.svg | 1,674 B | Kamera putih â€” tombol ganti foto di drawer "Setelan Tanaman" |
| `careWaterDrops` | icons/care-water-drops.svg | 1,764 B | Ikon tugas penyiraman (biru) pada "Perawatan Hari Ini" |
| `careWateringCan` | icons/care-watering-can.svg | 2,096 B | Ikon tugas pemupukan (cokelat) pada "Perawatan Hari Ini" |
| `chatAi` | icons/chat-ai.svg | 3,003 B | Ikon obrolan AI di top bar (putih) untuk layar chat |
| `checkCircle` | icons/check-circle.svg | 1,123 B | Centang bulat hijau â€” status perawatan "Kondisi Aman" |
| `checkCircleSolid` | icons/check-circle-solid.svg | 1,007 B | Centang bulat solid hijau tua (#56810B) agar terbaca di atas pil hijau |
| `checkMarkGreen` | icons/check-mark-green.svg | 347 B | Centang hijau slot langkah 4, disembunyikan dengan `Opacity` |
| `chevronLeft` | icons/chevron-left.svg | 335 B | Panah kembali (opacity 0 â€” judul tetap tengah) |
| `chevronLeftThin` | icons/chevron-left-thin.svg | 345 B | Panah "<" bergaris (chevron tipis) â€” sisi kiri top bar varian 3 |
| `chevronRight` | icons/chevron-right.svg | 1,122 B | Panah ">" (chevron kanan) untuk baris yang bisa ditekan |
| `chevronRightSmall` | icons/chevron-right-small.svg | 283 B | Panah ">" kecil (7.4x12) untuk baris daftar |
| `chevronRightThin` | icons/chevron-right-thin.svg | 335 B | Panah ">" bergaris (chevron tipis) â€” sisi kanan top bar varian 4 |
| `closeLine` | icons/close-line.svg | 1,479 B | Silang tipis (close-line) â€” menutup layar kamera / menu |
| `closeMenu` | icons/close-menu.svg | 1,709 B | Ikon baris "Tutup" di menu FAB. Baris itu dibuang dari aplikasi (sheet bisa ditutup lewat gagang geser), ikon tinggal cadangan 1:1 dengan design |
| `diseaseDiagnosis` | icons/disease-diagnosis.svg | 6,052 B | Ikon "Diagnosis penyakit tanaman" di menu FAB (#6D9C25) |
| `diseaseScan` | icons/disease-scan.svg | 6,472 B | Ikon pindai kesehatan (putih) untuk kartu "Pindai Kesehatan" |
| `fabLogo` | icons/fab-logo.svg | 3,244 B | Logo Agronoma putih di tengah FAB (tombol hijau melayang) |
| `flashFill` | icons/flash-fill.svg | 911 B | Ikon kilat (flash) â€” tombol kanan di bawah layar kamera |
| `galleryFill` | icons/gallery-fill.svg | 745 B | Ikon galeri â€” tombol kiri di bawah layar kamera |
| `harvest` | icons/harvest.svg | 1,424 B | Salad/hasil panen â€” statistik "Dipanen" |
| `infoFill` | icons/info-fill.svg | 1,152 B | Ikon informasi bulat (biru) â€” pil petunjuk di layar kamera |
| `leafFill` | icons/leaf-fill.svg | 1,800 B | Daun â€” kartu "Skor perawatan" |
| `locationFill` | icons/location-fill.svg | 1,277 B | Penanda lokasi (type pin) â€” baris kota pada kartu tanaman |
| `locationFilled` | icons/location-filled.svg | 1,174 B | Penanda lokasi dengan lubang di tengah, di samping nama lokasi |
| `locationTag` | icons/location-tag.svg | 1,313 B | Lokasi terisi abu (#898B87) â€” awalan field "Lokasi Tanaman" |
| `logoMark` | icons/logo-mark.svg | 2,453 B | Logo "A" berdaun â€” dipakai di Login/Register dan sebagai ikon aplikasi |
| `logout` | icons/logout.svg | 1,342 B | Pintu keluar â€” tombol "Keluar" |
| `manualAddCircle` | icons/manual-add-circle.svg | 1,134 B | Tombol "tambah manual" (langkah 4 wizard) |
| `mapPointer` | icons/map-pointer.svg | 4,263 B | Penanda lokasi pada peta (langkah 1) |
| `mediaGround` | icons/media-ground.svg | 958 B | Ikon media tanam: tanah lapang (`Lahan terbuka`) |
| `mediaHouse` | icons/media-house.svg | 1,953 B | Rumah â€” pilihan "Pekarangan rumah" |
| `mediaPot` | icons/media-pot.svg | 1,597 B | Ikon media tanam: pot (`Pot tanaman`) |
| `navHomeActive` | icons/nav-home-active.svg | 1,046 B | Ikon tab "Beranda" saat aktif (putih, di dalam pil hijau) |
| `navHomeOutline` | icons/nav-home-outline.svg | 1,382 B | Ikon tab "Beranda" saat TIDAK aktif (#898B87) |
| `navProfileActive` | icons/nav-profile-active.svg | 990 B | Ikon tab "Profil" saat aktif (putih) |
| `navProfileOutline` | icons/nav-profile-outline.svg | 1,936 B | Ikon tab "Profil" saat TIDAK aktif (#898B87) |
| `phaseDotActive` | icons/phase-dot-active.svg | 2,755 B | Titik fase aktif (lingkaran hijau + cincin putih) |
| `phaseGenerative` | icons/phase-generative.svg | 1,294 B | Ikon fase: generatif |
| `phaseSeedling` | icons/phase-seedling.svg | 540 B | Ikon fase: semai biji |
| `phaseVegetativeEarly` | icons/phase-vegetative-early.svg | 1,282 B | Ikon fase: vegetatif awal |
| `phaseVegetativeLate` | icons/phase-vegetative-late.svg | 2,411 B | Ikon fase: vegetatif akhir (tinggi 25, dipakai apa adanya) |
| `photoCabaiKeriting` | images/photo-cabai-keriting.jpg | 204,646 B | Foto "Cabai Rawit Keriting" |
| `photoCabaiRawit` | images/photo-cabai-rawit.jpg | 364,017 B | Foto "Cabai Rawit" |
| `photoLidahMertua` | images/photo-lidah-mertua.jpg | 169,541 B | Foto "Lidah Mertua (Sansevieria)" â€” rekomendasi ke-2 di langkah 4 |
| `photoMap` | images/photo-map.jpg | 68,854 B | Foto peta lama langkah "Lokasi penanaman" — kini digantikan peta sungguhan `AgroMap`, berkasnya disimpan sebagai cadangan |
| `photoMulchStraw` | images/photo-mulch-straw.jpg | 421,352 B | Foto "Tanah gambut" di daftar jenis tanah (langkah 3) |
| `photoMulchWood` | images/photo-mulch-wood.jpg | 582,671 B | Foto "Media Tanam Campuran" di daftar jenis tanah (langkah 3) |
| `photoPlantDetection` | images/photo-plant-detection.jpg | 140,505 B | Foto hasil deteksi penyakit |
| `photoProfile` | images/photo-profile.jpg | 225,521 B | Foto profil pengguna |
| `photoSirihGading` | images/photo-sirih-gading.jpg | 56,079 B | Foto "Sirih Gading" â€” rekomendasi ke-3 di langkah 4 |
| `photoSoilBrown` | images/photo-soil-brown.jpg | 517,507 B | Foto "Tanah berpasir" di daftar jenis tanah (langkah 3) |
| `photoSoilCompost` | images/photo-soil-compost.jpg | 513,055 B | Foto "Tanah gembur" di daftar jenis tanah (langkah 3) |
| `photoSoilCracked` | images/photo-soil-cracked.jpg | 242,524 B | Foto "Tanah liat" di daftar jenis tanah (langkah 3) |
| `photoSoilDark` | images/photo-soil-dark.jpg | 367,207 B | Foto "Tanah vulkanik" di daftar jenis tanah (langkah 3) |
| `photoSoilGravel` | images/photo-soil-gravel.jpg | 468,593 B | Foto "Tanah kapur" di daftar jenis tanah (langkah 3) |
| `photoTomatCeri` | images/photo-tomat-ceri.jpg | 126,265 B | Foto "Tomat Ceri" |
| `pottedPlant` | icons/potted-plant.svg | 1,407 B | Pot tanaman â€” statistik "Tanaman" |
| `rainAlert` | icons/rain-alert.svg | 6,541 B | Peringatan hujan (FAB di atas tombol obrolan) |
| `settingsLineWhite` | icons/settings-line-white.svg | 3,670 B | Gir pengaturan (putih) di kanan atas header Detail Tanaman |
| `sheetHandle` | icons/sheet-handle.svg | 288 B | Gagang tarik drawer bawah |
| `soilListManual` | icons/soil-list-manual.svg | 516 B | Ikon daftar kartu "Saya Tahu Jenis Tanah" â€” digambar ulang dari trace piksel |
| `soilScan` | icons/soil-scan.svg | 3,538 B | Ikon kamera abu kartu "Bantu saya scan tanah" |
| `soilScanSelected` | icons/soil-scan-selected.svg | 3,536 B | Ikon kamera putih (terpilih), di dalam bulatan 60px digambar 32px |
| `tabUnderline` | icons/tab-underline.svg | 260 B | Garis bawah tab yang sedang aktif pada Detail Tanaman |
| `tag` | icons/tag.svg | 1,574 B | Ikon tag/label â€” prefix field nama tanaman |
| `taskCheckDone` | icons/task-check-done.svg | 479 B | Kotak centang tugas perawatan â€” sudah dikerjakan |
| `taskCheckEmpty` | icons/task-check-empty.svg | 272 B | Kotak centang tugas perawatan â€” belum dikerjakan |
| `warningFill` | icons/warning-fill.svg | 1,246 B | Ikon peringatan bulat (merah) â€” label "Penyakit terdeteksi" |
| `waterDrop` | icons/water-drop.svg | 1,048 B | Tetes air (biru) â€” chip "Pengingat Penyiraman" |
| `waterDrops` | icons/water-drops.svg | 1,981 B | Beberapa tetes air (biru) â€” status perawatan "Perlu Disiram" |
| `wateringCan` | icons/watering-can.svg | 2,323 B | Gembor / alat siram (kuning) â€” status perawatan "Perlu Pupuk" |
| `weatherClear` | icons/weather-clear.svg | 4,063 B | Matahari penuh â€” "Cerah" |
| `weatherPartlyCloudy` | icons/weather-partly-cloudy.svg | 1,496 B | Awan dengan matahari â€” "Sebagian Berawan" |
| `weatherRain` | icons/weather-rain.svg | 5,351 B | Hujan (varian abu-biru) â€” "Hujan" |
| `weatherRainAlt` | icons/weather-rain-alt.svg | 3,816 B | Hujan (varian kedua, tanpa tetes ringan) |
| `weatherRainHeavy` | icons/weather-rain-heavy.svg | 3,893 B | Hujan lebat |
| `weatherSunShower` | icons/weather-sun-shower.svg | 5,209 B | Cerah berawan (matahari + awan + tetes) |
| `wordmark` | icons/wordmark.svg | 8,846 B | Wordmark "Agronoma" (dipakai di top bar Home/Profile) |

## Aset cadangan (belum direferensikan kode)

Hasil ekspor Figma menyertakan elemen pendukung yang tidak dipakai layar
(ikon status bar, glyph splash, lingkaran/lengkung dekoratif) dan foto dalam
beberapa resolusi. Semuanya tetap di-bundle dengan nama deskriptif agar
struktur repo 1:1 dengan ekspor design:

| Berkas | Id aset | Ukuran |
|---|---|---:|
| `arc-beige.svg` | 901b8b3d | 1,317 B |
| `arc-brown-thick.svg` | 2681f967 | 508 B |
| `arc-brown-thin.svg` | e17f53b7 | 634 B |
| `arc-brown.svg` | 232621d7 | 585 B |
| `arc-green-2.svg` | 38f7dd19 | 832 B |
| `arc-green-bright.svg` | b2af88a3 | 832 B |
| `arc-green.svg` | 064950e4 | 832 B |
| `arrow-hidden-stroke.svg` | 94312fbf | 347 B |
| `arrow-hidden.svg` | 0c97f46d | 345 B |
| `check-mark-hidden.svg` | bb146b37 | 357 B |
| `chevron-right-grey.svg` | b8183879 | 818 B |
| `circle-dashed-2.svg` | e865fadf | 350 B |
| `circle-dashed-3.svg` | f8be6d49 | 350 B |
| `circle-dashed.svg` | 57920ea7 | 350 B |
| `dot-grey.svg` | 8463a5d6 | 229 B |
| `dot-yellow.svg` | e25b7a48 | 229 B |
| `eye-grey.svg` | 9e3e7ad6 | 1,358 B |
| `flask-green-bright-hidden.svg` | b4132284 | 1,555 B |
| `flask-green-hidden.svg` | 47969e0c | 1,555 B |
| `flower-dark.svg` | b3045c45 | 3,672 B |
| `leaf-sprout.svg` | 89e633c0 | 828 B |
| `leaf-white.svg` | d9987165 | 1,098 B |
| `line-dark.svg` | ae9c38a8 | 565 B |
| `line-hidden.svg` | 795eded9 | 274 B |
| `microphone-green.svg` | 88bffc6f | 1,774 B |
| `plus-dark.svg` | 6336823c | 841 B |
| `plus-green-small.svg` | b4c075c2 | 1,008 B |
| `plus-grey-small.svg` | d8af34bf | 1,039 B |
| `search-grey.svg` | b209a8b6 | 1,501 B |
| `spinner-green.svg` | 02130f48 | 1,197 B |
| `splash-glyph-a.svg` | 6a70a53d | 1,005 B |
| `splash-glyph-capital-a.svg` | 94bcff3f | 658 B |
| `splash-glyph-g.svg` | a0a7f93b | 1,054 B |
| `splash-glyph-m.svg` | 9a842c4b | 960 B |
| `splash-glyph-n.svg` | ba991d7e | 700 B |
| `splash-glyph-o.svg` | 8637549c | 662 B |
| `splash-glyph-r.svg` | 0f266937 | 574 B |
| `sprout-green.svg` | 8bcc67bd | 636 B |
| `statusbar-battery-alt.svg` | efadcb3d | 1,557 B |
| `statusbar-battery-filled.svg` | 770a02f4 | 1,563 B |
| `statusbar-battery.svg` | 82c379a7 | 1,557 B |
| `statusbar-cellular-alt-2.svg` | fd349978 | 1,171 B |
| `statusbar-cellular-alt.svg` | b6327159 | 1,173 B |
| `statusbar-cellular.svg` | 69cd7a79 | 1,171 B |
| `statusbar-wifi-alt.svg` | 3e8fa98f | 1,627 B |
| `statusbar-wifi-hidden.svg` | 3de30bfd | 1,625 B |
| `statusbar-wifi.svg` | 374e1449 | 1,625 B |
| `target-reticle.svg` | 9b5154c0 | 1,947 B |
| `avatar-placeholder.png` | 5fd926b6 | 9,156 B |
| `photo-cabai-rawit-alt.jpg` | 615dabec | 364,017 B |
| `photo-pot-soil.jpg` | 1f81b734 | 199,778 B |

> Foto tanah untuk daftar langkah 3 (`photo-mulch-wood`, `photo-mulch-straw`,
> `photo-soil-brown`, `-compost`, `-cracked`, `-dark`, `-gravel`) sempat ada di
> tabel ini; sekarang dipakai kode, jadi barisnya pindah ke tabel utama di atas.

## Kasus khusus

- **`soil-list-manual.svg`** — satu-satunya aset yang bukan hasil ekspor Figma.
  Ikon ini adalah *override* komponen pada kartu "Saya Tahu Jenis Tanah"
  (drawer langkah 3 wizard). Berkas SVG aslinya tidak tersedia di server aset
  MCP (hanya varian kamera `soil-scan.svg`), jadi ikonnya digambar ulang dari
  trace piksel render Figma. Geometrinya tercatat di komentar
  `AppAssets.soilListManual`.
- **Ikon dengan `opacity="0"`** (`chevron-left`, `chevron-left-thin`) — di Figma
  elemen ini sengaja tak terlihat (hanya penjaga layout). Tetap di-bundle
  supaya struktur kode 1:1 dengan design.
- **Berkas kembar identik** — `arc-green`/`arc-green-2`,
  `chevron-left`/`chevron-right-thin`, dan tiga `circle-dashed*` byte-identik
  tetapi muncul di node berbeda, jadi tetap diberi nama sendiri.
- **Manifest** (`tool/manifest.json`) menghitung 136 aset (118 ikon + 18
  gambar); `test/asset_bundle_test.dart` mengunci angka itu dan memverifikasi
  setiap berkas benar-benar ada di bundle.
