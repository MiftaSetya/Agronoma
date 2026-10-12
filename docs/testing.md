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
| Add plant — fase | 5.5 |
| Add plant — tanah | 4.2 |
| Add plant — media | 5.8 |
| Login | 6.5 |
| Profile | 6.8 |
| Register | 9.8 |
| Add plant — lokasi | 8.0 |
| Home | 11.1 |
| Plant detail | 12.2 |
| Add plant — rekomendasi | 9.4 |
| Plant chat | 18.7 |
| Deteksi Penyakit | 78.9 |

> Angka wizard terakhir diukur setelah ikon daftar kartu "Saya Tahu Jenis
> Tanah" digambar ulang. Selisih rekomendasi (9.4) didominasi perbedaan
> kompresi JPEG foto tanaman, bukan layout.

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

