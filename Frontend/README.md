# Agronoma — Frontend

Aplikasi pendamping tanaman hias & sayuran: deteksi penyakit lewat foto,
rekomendasi tanaman sesuai kondisi lingkungan, dan jadwal perawatan otomatis
per fase pertumbuhan.

Dibangun dengan Flutter, mengikuti design Figma secara piksel demi piksel
(dievaluasi lewat perbandingan tangkapan layar otomatis — lihat
`docs/testing.md`).

## Struktur

```
lib/
├── app.dart                  # komposisi aplikasi: provider, repositori, rute awal
├── core/
│   ├── assets/               # registry aset (AppAssets) — satu tempat semua path
│   ├── data/                 # repositori + data contoh (MockData)
│   ├── models/               # model: Plant, SoilType, PlantRecommendation, ...
│   ├── routing/              # daftar rute (app_router.dart)
│   ├── state/                # controller (ChangeNotifier + provider)
│   ├── theme/                # token warna, radius, spacing, tipografi dari Figma
│   └── widgets/              # komponen bersama (AgroButton, AgroTopBar, ...)
└── features/                 # satu folder per layar: auth, home, add_plant, ...
```

Prinsip yang dipegang kode ini:

- **Enum jadi sumber teks design.** Label yang tampil di UI (media tanam,
  fase tumbuh) hidup di enum-nya, bukan tersebar di widget — wizard dan layar
  lain tidak bisa berbeda.
- **Setiap token punya komentar asal-usulnya.** Bila sebuah angka menyimpang
  dari yang terlihat di Figma (mis. `leading-[normal]`), alasannya tertulis
  di tempat angka itu didefinisikan.
- **Repositori sebagai antarmuka.** Data contoh bisa ditukar backend sungguhan
  tanpa menyentuh widget.

## Menjalankan

```bash
flutter pub get
flutter run            # atau: flutter run -t lib/dev_preview.dart untuk mode potret
```

Mode preview pengembangan (`lib/dev_preview.dart`) membuka layar mana pun
langsung lewat properti sistem — dipakai pipeline tangkapan layar di
`docs/testing.md`.

## Dokumentasi lain

| Berkas | Isi |
|---|---|
| `docs/testing.md` | cara membandingkan layar dengan Figma + tabel selisih |
| `docs/design-tokens.md` | token warna/spacing/typografi yang dipakai theme |
