# Verifikasi Design

Cara memeriksa apakah layar Flutter benar-benar sama dengan frame Figma — tanpa
harus melihat gambarnya satu per satu.

## Ringkas alurnya

1. **Emulator disetel ke kanvas Figma.** Figma menggambar pada 440×956. Emulator
   dipaksa ke ukuran itu supaya tangkapannya bisa ditumpuk langsung:
   ```
   adb shell wm size 1320x2868
   adb shell wm density 480
   ```
   1320×2868 pada density 480 = 440×956 logical @3x. Override ini menempel, jadi
   cukup dijalankan sekali.

2. **Satu APK untuk semua layar.** `lib/dev_preview.dart` membaca properti
   sistem `debug.agronoma.rute` dan `debug.agronoma.langkah`, lalu membuka layar
   sesuai nilai itu. Jadi tidak perlu build ulang untuk memotret layar lain:
   ```
   adb shell setprop debug.agronoma.rute /plant-detail
   adb shell setprop debug.agronoma.langkah 1
   ```

3. **Ambil semua tangkapan sekaligus:**
   ```powershell
   powershell -File tool/shots-all.ps1                 # semua layar
   powershell -File tool/shots-all.ps1 -Only home      # satu layar
   powershell -File tool/shots-all.ps1 -Only home -NoBuild
   ```
   > Catatan: langkah *install* ada di dalam blok `if (-not $NoBuild)`, jadi
   > `-NoBuild` melewati install juga — bukan cuma build.

4. **Bandingkan dengan Figma.** `tool/shots-all.ps1` otomatis memanggil
   `tool/compare.py` di akhir. Hasilnya `%TEMP%\agro-ref\cmp-<nama>.png`
   (kiri Figma, kanan emulator) beserta selisih rata-rata 0–255.

### Status bar tidak dihitung

Kanvas Figma memakai status bar iPhone setinggi **64px**, sedangkan Android
memakai inset yang lebih pendek. Selisih itu diseragamkan sekali di `lib/app.dart`
(`AppSizes.normalizeTopInset`), dan `compare.py` memotong area isi di kedua
gambar supaya yang dibandingkan benar-benar layout, bukan tinggi status bar.
Karena itu `DEFAULT_RUN_TOP` bernilai **64**, bukan 52.

## Cara membaca selisihnya

Makin kecil makin mirip:

| Selisih | Artinya |
|---:|---|
| < 10 | sangat dekat; sisa bedanya biasanya ketajaman teks |
| 10 – 20 | layout pas, ada satu-dua elemen yang perlu disetel |
| 20 – 40 | ada blok yang bergeser atau berukuran beda |
| > 60 | biasanya tangkapannya gagal (layar belum termuat) atau fotonya berbeda |

Angka besar belum tentu berarti layoutnya salah. Tiga penyebab yang sudah
dipastikan lewat pengukuran, bukan dugaan:

- **Tangkapan terlalu cepat.** Kalau foto belum selesai didekode, kartunya
  tampil abu-abu. Selisihnya bisa naik-turun 3 poin hanya karena ini — potret
  ulang sebelum menyimpulkan ada masalah.
- **Foto.** Titik berat objek merah (cabai) pada foto Detail Tanaman cocok
  sampai **0,1px** antara Figma dan emulator, jadi crop-nya sudah benar. Sisa
  selisihnya artefak pengecilan 3x → 1x (`tool/split_diff.py`).
- **Layar gelap (Deteksi Penyakit).** Fotonya memang foto contoh yang lain.

## Tabel selisih

Diukur setelah perbaikan tinggi baris (`leading-[normal]`) dan tinggi kartu.
Angka wizard diperbarui setelah penataan ulang langkah 1-5 (koordinat absolut,
jarak kartu per langkah, tombol manual melayang, ikon daftar kartu tanah).

| Layar | Selisih |
|---|---:|
| Add plant — fase | 2.1 |
| Add plant — tanah | 1.9 |
| Add plant — media | 3.0 |
| Login | 6.5 |
| Profile | 6.8 |
| Register | 9.8 |
| Add plant — lokasi | 17.2 |
| Home | 7.4 |
| Plant detail | 11.7 |
| Add plant — rekomendasi | 3.3 |
| Plant chat | 18.7 |
| Deteksi Penyakit | 78.9 |

> Angka wizard diukur ulang setelah langkah 1-5 ditata sesuai frame Figma
> (kartu kepala langkah 1, kompensasi border `border-box`, perataan ikon fase
> dan media, serta daftar tujuh jenis tanah). Selisih rekomendasi (3.3) masih
> didominasi perbedaan kompresi JPEG foto tanaman, bukan layout.
>
> Selisih **lokasi 17.2** bukan lagi sisa layout: peta sungguhan memakai ubin
> OpenStreetMap, sedangkan Figma menampilkan tangkapan Google Maps (lihat
> "Penyimpangan yang disengaja: peta langkah 1"). Selisih 8.0 yang lama diukur
> saat langkah ini masih memakai `photo-map.jpg`. Karena ubin diambil dari
> jaringan, angka ini juga naik-turun beberapa poin antar-tangkapan.

## Penyimpangan yang disengaja: peta langkah 1

Langkah 1 memakai peta sungguhan (`lib/core/widgets/agro_map.dart`, ubin
OpenStreetMap lewat `flutter_map`), bukan `photo-map.jpg` yang lama. Frame Figma
`58:222`/`127:721` menampilkan **tangkapan Google Maps**, jadi gaya petanya
pasti berbeda dan selisih rata-rata layar itu tidak turun sampai regangan
peta lain. Alasannya:

- Ubin OSM tidak menuntut kunci API maupun akun penagihan; Google Maps
  mengharuskan keduanya (`google_maps_flutter` tanpa kunci hanya menampilkan
  kotak kosong). Fitur OSM juga dipakai di web tanpa biaya.
- Peta statis tidak bisa mengikuti lokasi yang dipilih pengguna, sedangkan
  langkah ini memang diminta "integrasikan dengan maps".
- Konsekuensinya aplikasi butuh internet saat langkah 1 dibuka
  (izin `android.permission.INTERNET` sudah ditambahkan). Kalau ubin gagal
  dimuat, `silenceExceptions: true` membuatnya jatuh jadi kotak kosong, bukan
  layar galat merah.

Pin `map-pointer.svg` tetap digambar **di tengah** seperti design: pada Figma
kotak pin memang terpusat di pita peta 380px (pusat peta-relatif 189,86 ≈ 190).
Titik yang dipilih = pusat peta, jadi menggeser peta memindahkan titik — pola
yang sama dipakai pemilih lokasi (`127:721`).

Pemilih lokasi (`_LocationPickerSheet`) menambahkan daftar tiga lokasi contoh
di bawah peta sebagai jalan pintas; frame Figma tidak memuat daftar itu
(barangkali karena hanya kotak peta + tombol yang digambar). Titik bebas hasil
menggeser peta tetap diizinkan dan disimpan di draft.

## Penyimpangan yang disengaja: daftar jenis tanah

Frame `113:765` mengganti kedua kartu besar langkah 3 dengan daftar tujuh jenis
tanah (bukan menumpuknya di bawah kartu: daftar mulai di baris 308, tepat di
bawah kartu kepala). Implementasinya mengikuti itu, tetapi tombol **"Kembali"**
di daftar lebih dulu menutup daftar (kembali ke dua kartu besar) baru mundur
satu langkah — design tidak menggambar jalan kembali, dan tanpa itu pilihan
"Bantu Saya Scan Tanah" tidak bisa dijangkau lagi setelah daftar dibuka.

Tiap baris memakai foto 80×80 dari berkas yang sudah ada
(`photo-mulch-wood`, `photo-soil-compost`, `-cracked`, `-brown`, `-gravel`,
`-dark`, `photo-mulch-straw`); pasangan nama ↔ gambar ditentukan dengan
membandingkan render kartu Figma terhadap tiap berkas piksel per piksel, bukan
ditebak dari namanya.


## Alat ukur

| Alat | Gunanya |
|---|---|
| `tool/compare.py` | tempel Figma & emulator berdampingan, hitung selisih |
| `tool/bands.py` | pindai **baris** ber-tinta, laporkan batas tiap pita + jaraknya |
| `tool/edges.py` | deteksi garis tepi kartu (untuk mengukur tinggi & jarak kartu) |
| `tool/crop_cmp.py` | potong `cmp-*.png` jadi ubin 2x supaya selisihnya terbaca mata |
| `tool/pair.py` | potong satu rentang baris dari kedua gambar, tampilkan berdampingan |
| `tool/split_diff.py` | pisahkan selisih jadi area foto vs area lembar putih |
| `tool/leadings.py` | kumpulkan pasangan "teks → `leading-[N]`" dari seluruh `ctx-*.txt` |
| `tool/measure.py` | ukur kotak pembatas elemen pada area isi |

### Kenapa `bands.py`, bukan sekadar melihat gambar

Mata bisa melihat "ada yang meleset", tetapi tidak bisa melihat *berapa* piksel
dan *di mana* mulai meleset. `bands.py` mencetak batas atas/bawah tiap pita teks
di kedua gambar; dari selisihnya terlihat bahwa kesalahannya **menumpuk** ke
bawah — petunjuk bahwa penyebabnya ada di atas, bukan di blok yang terlihat
meleset. Cara inilah yang akhirnya menemukan dua bug besar:

1. **Tinggi baris `leading-[normal]`.** Figma memakai metrik `hhea` Inter
   (1,21 em), Flutter memakai `usWinAscent/usWinDescent` (1,43 em). Selisihnya
   membuat setiap blok teks turun ~0,11 em dan menumpuk ke seluruh layar.
2. **Tinggi kartu 2px lebih tinggi.** Tailwind menghitung border **di dalam**
   padding (`border-box`), Flutter menambahkannya **di luar** — jadi `p-[17px]`
   harus ditulis `16px` di Flutter supaya kotaknya sama tinggi.

## Berkas pendukung

Referensi Figma dan hasil tangkapan semuanya di `%TEMP%\agro-ref\`:

| Pola | Isi |
|---|---|
| `<nama>.png` | ekspor frame Figma (referensi) |
| `run-<nama>.png` | tangkapan emulator |
| `cmp-<nama>.png` | perbandingan berdampingan |
| `cmp-<nama>-N.png` | ubin hasil `crop_cmp.py` |
| `ctx-<nama>.txt` | design context mentah dari Figma (UTF-16) |

> `ctx-*.txt` ber-encoding UTF-16. Kalau dibaca dengan PowerShell, pakai
> `Get-Content -Encoding UTF8`; kalau dengan Python, baca sebagai biner lalu
> didekode (`tool/leadings.py` sudah menangani ini otomatis).

## Mengambil data dari Figma

Figma Desktop harus terbuka (MCP di `http://127.0.0.1:3845/mcp`).

```powershell
node tool/figma.mjs metadata  461:6012          # pohon simpul + koordinat
node tool/figma.mjs context   461:6012          # JSX lengkap
node tool/figma.mjs screenshot 461:6012 out.png # ekspor PNG
```

> `get_design_context` mengembalikan **JSX mentah**, bukan JSON — jangan di-`JSON.parse`.

### Ketika server Figma lambat / rate-limit

`get_design_context` kadang hang atau kehabisan jatah permintaan. Kalau itu
terjadi, **`metadata` dan `screenshot` tetap merespons** dan keduanya sering
cukup:

- `screenshot <node>` adalah *ground truth* tampilan — dipakai misalnya saat
  mengonfirmasi bahwa ikon kartu "Saya Tahu Jenis Tanah" ternyata ikon daftar
  (override komponen), bukan kamera seperti di konteks cache.
- Konteks cache di `%TEMP%\agro-ref\decoded\ctx-*.txt` bisa **usang** bila
  design berubah setelah konteks itu diambil — selalu silang-cek dengan
  screenshot segar sebelum mempercayainya.
- Kalau berkas SVG ikon tidak tersedia di server aset (kasus ikon daftar
  itu), gambar ulang ikonnya dari trace piksel screenshot — lihat
  `assets/icons/soil-list-manual.svg` dan catatannya di
  `docs/asset-map.md`.
