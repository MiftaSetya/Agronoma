/// Peta aset Agronoma.
///
/// Berkas di `assets/icons` dan `assets/images` bernama SHA (mis.
/// `0984935e8e….svg`) karena diunduh apa adanya dari server aset Figma. Nama
/// seperti itu tidak memberi petunjuk apa pun, jadi seluruh pemakaian di kode
/// HARUS lewat konstanta bernama di sini — jangan pernah menulis path SHA
/// langsung di widget.
///
/// Cara memetakannya: `tool/icon_sheet_test.dart` menggambar semua ikon ke
/// `build/icon_sheet.png`, dan setiap ikon di Figma punya `data-name`
/// ("mingcute:location-fill", dst.) yang dipasangkan ke SHA-nya lewat
/// `tool/figma_semantic_map.mjs`. Hasilnya dicatat di [docs/asset-map.md] dan
/// diringkas di kelas ini.
///
/// Warna ikon sudah "dibakar" di dalam SVG-nya sesuai design, jadi ikon
/// dipakai apa adanya tanpa `colorFilter`.
class AppAssets {
  AppAssets._();

  static const String _icons = 'assets/icons';
  static const String _images = 'assets/images';

  // ─────────────────────────────────────────────────────────────────────────
  // Merek
  // ─────────────────────────────────────────────────────────────────────────

  /// Logo "A" berdaun — dipakai di Login/Register dan sebagai ikon aplikasi.
  static const String logoMark =
      '$_icons/0984935e8e6fa6f64e8c91c02ba3643a23e05f35.svg';

  /// Wordmark "Agronoma" (dipakai di top bar Home/Profile).
  static const String wordmark =
      '$_icons/b572431490cf3ccf3fb165bb477a21fafcdc703f.svg';

  // ─────────────────────────────────────────────────────────────────────────
  // Navigasi
  // ─────────────────────────────────────────────────────────────────────────

  /// Ikon tab "Beranda" saat TIDAK aktif (#898B87).
  static const String navHomeOutline =
      '$_icons/6f62cf306191c3a4566cde0b8c08a2c2bff60a80.svg';

  /// Ikon tab "Beranda" saat aktif (putih, dipakai di dalam pil hijau).
  static const String navHomeActive =
      '$_icons/2c51ffd1bf8dcd5ac3b37960817784fcdbffac42.svg';

  /// Ikon tab "Profil" saat TIDAK aktif (#898B87).
  static const String navProfileOutline =
      '$_icons/dcf9c6b62c5cb236e611a7732c2bbd8fa12cde37.svg';

  /// Ikon tab "Profil" saat aktif (putih).
  static const String navProfileActive =
      '$_icons/284d83d1607bcf4841f417f1e61535a592d60489.svg';

  /// Logo Agronoma putih di tengah FAB (tombol hijau melayang).
  static const String fabLogo =
      '$_icons/200d5ec8666be0da1473ff5b003f26fdc460de58.svg';

  /// Simbol tutup (garis) di menu FAB.
  static const String fabCloseLine =
      '$_icons/d4923294986d45c05f568a95865b2104835b6f1a.svg';

  /// Ikon "Tutup" (kotak dengan silang) di menu FAB.
  static const String closeMenu =
      '$_icons/bd49f2e97f904542a18c894beae4631902b5b775.svg';

  /// Panah ">" (chevron kanan) untuk baris yang bisa ditekan.
  static const String chevronRight =
      '$_icons/7c1bfeeab8abbce777d4a8167432ac79152b568f.svg';

  /// Panah "<" (chevron kiri) di top bar.
  static const String chevronLeft =
      '$_icons/94312fbfd7eb7a516ff388c59c4dafa9851503ba.svg';

  /// Panah bawah (dropdown), mis. pada field pilih.
  static const String arrowDown =
      '$_icons/c6991985d9ffa3d6fee95dd7897c9b90ecb93fc5.svg';

  /// Panah ">" bergaris (chevron tipis) — sisi kanan top bar varian 4.
  static const String chevronRightThin =
      '$_icons/a7ce4d8f5b3d6d8e199c650a5675b1ebd8ae3c7b.svg';

  /// Panah "<" bergaris (chevron tipis) — sisi kiri top bar varian 3.
  static const String chevronLeftThin =
      '$_icons/b0edba78cbc793858bc2a5725e002e56704df17b.svg';

  /// Silang tipis (close-line) — menutup layar kamera / menu.
  static const String closeLine =
      '$_icons/515651936e1841aad38808d964faa4c98b8bba0a.svg';

  // ─────────────────────────────────────────────────────────────────────────
  // Ikon aksi & status
  // ─────────────────────────────────────────────────────────────────────────

  /// Tombol tambah tanaman di menu FAB (#6D9C25).
  static const String addPlant =
      '$_icons/6fe50b8e12b3491cb364b67205a8656d1e9fc141.svg';

  /// Ikon "Diagnosis penyakit tanaman" di menu FAB (#6D9C25).
  static const String diseaseDiagnosis =
      '$_icons/bd5068fb86e5bb40e6d92e9ff619fc668f52e7a9.svg';

  /// Ikon obrolan AI di top bar (putih) untuk layar chat.
  static const String chatAi =
      '$_icons/58a5d2eac5ce61ecdcbfacb0c870c71abac51886.svg';

  /// Tetes air (biru) — chip "Pengingat Penyiraman".
  static const String waterDrop =
      '$_icons/d886046b2c60058e6f92f3b67da61fd8fc3a83e1.svg';

  /// Beberapa tetes air (biru) — status perawatan "Perlu Disiram".
  static const String waterDrops =
      '$_icons/dee016e42fc6a7eec95851cfbdbe0624c0b041af.svg';

  /// Gembor / alat siram (kuning) — status perawatan "Perlu Pupuk".
  static const String wateringCan =
      '$_icons/582a8ddb04f1242063e58741fe02c93560b55cc5.svg';

  /// Centang bulat hijau — status perawatan "Kondisi Aman".
  static const String checkCircle =
      '$_icons/4398fe693c8dac56de10c52c50bbbaa7e9b2a207.svg';

  /// Penanda lokasi (type pin) — baris kota pada kartu tanaman.
  static const String locationFill =
      '$_icons/e3efd504eaf63201af35fdce0d696bb38c53395f.svg';

  /// Label/harga (tag) — ikon pada salah satu varian field.
  ///
  /// Perhatikan: SHA-nya **berbeda satu karakter** dari
  /// [weatherPartlyCloudy], jadi mudah tertukar saat menyalin. Yang ini
  /// `16e0c83d…`, milik ikon tag; yang itu `1633b862…`, milik awan.
  static const String tag =
      '$_icons/16e0c83d12c6c41291f02c27fd2cd0019740595f.svg';

  /// Ikon informasi bulat (biru) — pil petunjuk di layar kamera.
  static const String infoFill =
      '$_icons/83fa194c6dbe83a4361e999218ba218625294047.svg';

  /// Ikon galeri — tombol kiri di bawah layar kamera.
  static const String galleryFill =
      '$_icons/17ff6b81d5a4ce835ab648a932a53a492539509c.svg';

  /// Ikon kilat (flash) — tombol kanan di bawah layar kamera.
  static const String flashFill =
      '$_icons/756880f66dbb2c1c46a221bcb89b919fa395b4fc.svg';

  // ─────────────────────────────────────────────────────────────────────────
  // Ikon Profile
  // ─────────────────────────────────────────────────────────────────────────

  /// Pot tanaman — statistik "Tanaman".
  static const String pottedPlant =
      '$_icons/93dee2dbdbb548c6edee280137d0d6248f66edd2.svg';

  /// Salad/hasil panen — statistik "Dipanen".
  static const String harvest =
      '$_icons/9d0d832e994ea5410e308af8f604666e8a837a1c.svg';

  /// Daun — kartu "Skor perawatan".
  static const String leafFill =
      '$_icons/d73e86bc3385251b71e62c490f2a0ad3ad443285.svg';

  /// Kotak arsip — baris "Arsip tanaman".
  static const String archive =
      '$_icons/2e6408ac1b3fac5f48f1b88828bb3fac7f8c00fc.svg';

  /// Pintu keluar — tombol "Keluar".
  static const String logout =
      '$_icons/f1f021666ca3890cc161dc24b3d319afd9542150.svg';

  // ─────────────────────────────────────────────────────────────────────────
  // Cuaca
  // ─────────────────────────────────────────────────────────────────────────

  /// Awan dengan matahari — "Sebagian Berawan".
  static const String weatherPartlyCloudy =
      '$_icons/1633b862dd265c0272284a2162ca7f0f56104f4c.svg';

  // ─────────────────────────────────────────────────────────────────────────
  // Wizard tambah tanaman
  // ─────────────────────────────────────────────────────────────────────────

  /// Ikon media tanam: pot.
  static const String mediaPot =
      '$_icons/61e410580a1154c9d0e46fe0bbc09d055ca75034.svg';

  /// Ikon media tanam: polybag.
  static const String mediaPolybag =
      '$_icons/3fc8a3bedb27a05d125fe5010a63fd9bd0783b43.svg';

  /// Ikon media tanam: tanah langsung.
  static const String mediaGround =
      '$_icons/f03253ccd9c730f318a31e8d54c5718364947c47.svg';

  /// Ikon fase: semai.
  static const String phaseSeedling =
      '$_icons/dd67902a30301086456de678d952b12db558ff3c.svg';

  /// Ikon fase: vegetatif.
  static const String phaseVegetative =
      '$_icons/b29cf6263f25e6b7d930eb277ced477bb23100db.svg';

  /// Ikon fase: generatif.
  static const String phaseGenerative =
      '$_icons/3484631a58aeb12eb4b1ca0859c14cdee65a5991.svg';

  /// Ikon fase: panen.
  static const String phaseHarvest =
      '$_icons/3ab2a16f06867678af0e9bf237ad440ece3141fa.svg';

  /// Penanda lokasi pada peta (langkah 1).
  static const String mapPointer =
      '$_icons/2fa8343d259af84d9bf2691f0331c1677b703040.svg';

  // ─────────────────────────────────────────────────────────────────────────
  // Foto
  // ─────────────────────────────────────────────────────────────────────────


  /// Foto "Cabai Rawit".
  static const String photoCabaiRawit =
      '$_images/83fcae546fbfaec4e5b6e7980bb5365d0cf4c9e4.jpg';

  /// Foto "Tomat Ceri".
  static const String photoTomatCeri =
      '$_images/a1d9f55fba0c922f702df6312dfc730d481d9c46.jpg';

  /// Foto "Cabai Rawit Keriting".
  static const String photoCabaiKeriting =
      '$_images/e1c380d0fe338c6467944659e846a0f9c64879df.jpg';

  /// Foto profil pengguna.
  static const String photoProfile =
      '$_images/e1af5d24963f1de953445cc053705d89d49130fd.jpg';
}
