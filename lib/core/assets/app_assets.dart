/// Peta aset Agronoma. Berkas di `assets/icons` dan `assets/images` diberi nama
/// deskriptif (kebab-case, mis. `nav-home-active.svg`), jadi seluruh pemakaian
/// di kode HARUS lewat konstanta bernama di sini — jangan pernah menulis path
/// literal di widget.
///
/// Aset diunduh dari server aset Figma dengan nama = id aset (SHA-1), lalu
/// dipetakan ke nama berkas di sini. Pemetaan id -> nama disimpan di
/// `tool/asset-names.json` (dipakai `tool/fetch_assets.ps1`) supaya penamaan
/// ulang tidak menghilangkan asal-usulnya. Nama semantik aslinya (ikon Figma
/// punya `data-name`) diambil `tool/figma_semantic_map.mjs` dan dicek visual
/// lewat `tool/icon_sheet_test.dart` (`build/icon_sheet.png`); hasilnya di
/// `docs/asset-map.md`.
///
/// Warna ikon sudah "dibakar" di dalam SVG-nya sesuai design, jadi ikon
/// dipakai apa adanya tanpa `colorFilter`.
class AppAssets {
  AppAssets._();

  static const String _icons = 'assets/icons';
  static const String _images = 'assets/images';

  // Merek

  /// Dipakai di Login/Register dan sebagai ikon aplikasi.
  static const String logoMark =
      '$_icons/logo-mark.svg';

  static const String wordmark =
      '$_icons/wordmark.svg';

  // Navigasi

  static const String navHomeOutline =
      '$_icons/nav-home-outline.svg';

  /// Aktif: putih, dipakai di dalam pil hijau.
  static const String navHomeActive =
      '$_icons/nav-home-active.svg';

  static const String navProfileOutline =
      '$_icons/nav-profile-outline.svg';

  static const String navProfileActive =
      '$_icons/nav-profile-active.svg';

  /// Logo Agronoma putih di tengah FAB.
  static const String fabLogo =
      '$_icons/fab-logo.svg';

  /// SVG-nya selebar kanvas (440x24) dengan garis sudah di posisi tengah —
  /// dipakai apa adanya dengan lebar penuh, jangan digambar sebagai garis
  /// kecil sendiri.
  static const String sheetHandle =
      '$_icons/sheet-handle.svg';

  /// Ikon baris "Tutup" di menu FAB pada design. Baris itu dibuang dari aplikasi
  /// (sheet sudah bisa ditutup lewat gagang geser / ketukan di luar), jadi
  /// ikonnya tinggal cadangan untuk menjaga struktur 1:1 dengan ekspor design.
  static const String closeMenu =
      '$_icons/close-menu.svg';

  static const String chevronRight =
      '$_icons/chevron-right.svg';

  static const String chevronRightSmall =
      '$_icons/chevron-right-small.svg';

  /// Hati-hati: design punya TIGA berkas panah dengan `path` identik.
  /// `chevron-left` (24x24, inilah yang dipakai) dan `chevron-right-thin`
  /// terlihat, sedang `arrow-hidden` dan `chevron-left-thin` (32x32) dibungkus
  /// `opacity="0"` — slot kanan/kiri kosong pada top bar. Memakai yang
  /// tersembunyi sebagai tombol kembali menghasilkan tombol tidak terlihat,
  /// dan itu pernah terjadi.
  static const String chevronLeft =
      '$_icons/chevron-left.svg';

  static const String arrowDown =
      '$_icons/arrow-down.svg';

  static const String chevronRightThin =
      '$_icons/chevron-right-thin.svg';

  /// Bergaris tipis, tapi tetap dibungkus `opacity="0"` (lihat [chevronLeft]).
  static const String chevronLeftThin =
      '$_icons/chevron-left-thin.svg';

  static const String closeLine =
      '$_icons/close-line.svg';

  static const String cameraFill =
      '$_icons/camera-fill.svg';

  static const String locationTag =
      '$_icons/location-tag.svg';

  // Ikon aksi & status

  static const String addPlant =
      '$_icons/add-plant.svg';

  static const String diseaseDiagnosis =
      '$_icons/disease-diagnosis.svg';

  static const String chatAi =
      '$_icons/chat-ai.svg';

  static const String waterDrop =
      '$_icons/water-drop.svg';

  static const String waterDrops =
      '$_icons/water-drops.svg';

  static const String wateringCan =
      '$_icons/watering-can.svg';

  static const String checkCircle =
      '$_icons/check-circle.svg';

  static const String locationFill =
      '$_icons/location-fill.svg';

  /// Bentuknya nyaris sama dengan [weatherPartlyCloudy] — mudah tertukar.
  static const String tag =
      '$_icons/tag.svg';

  static const String infoFill =
      '$_icons/info-fill.svg';

  static const String warningFill =
      '$_icons/warning-fill.svg';

  /// Hijau tua (#56810B) agar terbaca di atas pil hijau "98% Cocok"; beda dari
  /// [checkCircle] yang dipakai di kartu tanaman.
  static const String checkCircleSolid =
      '$_icons/check-circle-solid.svg';

  static const String galleryFill =
      '$_icons/gallery-fill.svg';

  static const String flashFill =
      '$_icons/flash-fill.svg';

  // Ikon Profile

  static const String pottedPlant =
      '$_icons/potted-plant.svg';

  static const String harvest =
      '$_icons/harvest.svg';

  static const String leafFill =
      '$_icons/leaf-fill.svg';

  static const String archive =
      '$_icons/archive.svg';

  static const String logout =
      '$_icons/logout.svg';

  // Cuaca

  static const String weatherPartlyCloudy =
      '$_icons/weather-partly-cloudy.svg';

  // Wizard tambah tanaman

  static const String mediaPot =
      '$_icons/media-pot.svg';

  /// Dulu bernama [mediaPolybag] — nama itu salah baca: bentuknya rumah
  /// beratap, dan design memakainya untuk pilihan "Pekarangan rumah".
  static const String mediaHouse =
      '$_icons/media-house.svg';

  static const String mediaGround =
      '$_icons/media-ground.svg';

  // -- Langkah 3: analisis tanah

  static const String soilScanSelected =
      '$_icons/soil-scan-selected.svg';

  static const String soilScan =
      '$_icons/soil-scan.svg';

  /// Tidak tersedia dari server aset Figma: ini *override* ikon komponen di
  /// kartu kedua dan hanya varian kamera ([soilScan]) yang bisa diunduh, jadi
  /// ikonnya digambar ulang dari trace piksel render Figma (dua kotak 9x7
  /// radius 2, dua pasang garis 13/6-8px, #898B87).
  static const String soilListManual = '$_icons/soil-list-manual.svg';

  static const String phaseSeedling =
      '$_icons/phase-seedling.svg';

  static const String phaseVegetativeEarly =
      '$_icons/phase-vegetative-early.svg';

  /// Memanjang ke atas: tinggi simpulnya di design 25px walau lebar kotaknya
  /// tetap 16px — bukan 16x16 yang diregangkan.
  static const String phaseVegetativeLate =
      '$_icons/phase-vegetative-late.svg';

  static const String phaseGenerative =
      '$_icons/phase-generative.svg';

  static const String mapPointer =
      '$_icons/map-pointer.svg';

  /// Bulat penuh berlubang (bukan pin peta seperti [mapPointer]); dipakai di
  /// samping nama lokasi terpilih.
  static const String locationFilled =
      '$_icons/location-filled.svg';

  /// Centang telanjang tanpa bulatan — BUKAN [checkCircleSolid].
  /// Ada berkas kembar `check-mark-hidden` yang identik tapi dibungkus
  /// `opacity="0"` (opsi belum dipilih); memakai berkas itu membuat slot
  /// centang kosong padahal tetap menggeser tata letak — lebih baik gambar
  /// ikon ini lalu sembunyikan dengan `Opacity`.
  static const String checkMarkGreen =
      '$_icons/check-mark-green.svg';

  static const String bestMatchStar =
      '$_icons/best-match-star.svg';

  static const String manualAddCircle =
      '$_icons/manual-add-circle.svg';

  // Detail tanaman

  static const String arrowLeftWhite =
      '$_icons/arrow-left-white.svg';

  static const String settingsLineWhite =
      '$_icons/settings-line-white.svg';

  static const String diseaseScan =
      '$_icons/disease-scan.svg';

  static const String phaseDotActive =
      '$_icons/phase-dot-active.svg';

  static const String taskCheckDone =
      '$_icons/task-check-done.svg';

  static const String taskCheckEmpty =
      '$_icons/task-check-empty.svg';

  static const String careWaterDrops =
      '$_icons/care-water-drops.svg';

  static const String careWateringCan =
      '$_icons/care-watering-can.svg';

  static const String calendarWatering =
      '$_icons/calendar-watering.svg';

  static const String calendarFertilizer =
      '$_icons/calendar-fertilizer.svg';

  static const String tabUnderline =
      '$_icons/tab-underline.svg';

  static const String rainAlert =
      '$_icons/rain-alert.svg';

  // Cuaca (ramalan)

  static const String weatherClear =
      '$_icons/weather-clear.svg';

  static const String weatherRain =
      '$_icons/weather-rain.svg';

  static const String weatherRainAlt =
      '$_icons/weather-rain-alt.svg';

  static const String weatherRainHeavy =
      '$_icons/weather-rain-heavy.svg';

  static const String weatherSunShower =
      '$_icons/weather-sun-shower.svg';

  // Foto

  static const String photoCabaiRawit =
      '$_images/photo-cabai-rawit.jpg';

  static const String photoTomatCeri =
      '$_images/photo-tomat-ceri.jpg';

  static const String photoCabaiKeriting =
      '$_images/photo-cabai-keriting.jpg';

  static const String photoLidahMertua =
      '$_images/photo-lidah-mertua.jpg';

  static const String photoSirihGading =
      '$_images/photo-sirih-gading.jpg';

  /// Bukan [photoCabaiRawit] — design memang memakai foto lain untuk layar
  /// kamera deteksi; memakai foto yang salah membuat seluruh layar terlihat
  /// berbeda walau tata letaknya sudah pas.
  static const String photoPlantDetection =
      '$_images/photo-plant-detection.jpg';

  /// Foto tanah untuk daftar "Saya Tahu Jenis Tanah" (frame `113:765`).
  /// Nama berkasnya sudah menunjukkan jenisnya, jadi tidak ada tebakan lagi
  /// soal pasangan nama ↔ gambar seperti sebelumnya (dulu daftar ini meminjam
  /// foto tanaman cabai/tomat sehingga kartunya tampak keliru).
  static const String photoSoilBrown = '$_images/photo-soil-brown.jpg';
  static const String photoSoilCompost = '$_images/photo-soil-compost.jpg';
  static const String photoSoilCracked = '$_images/photo-soil-cracked.jpg';
  static const String photoSoilDark = '$_images/photo-soil-dark.jpg';
  static const String photoSoilGravel = '$_images/photo-soil-gravel.jpg';
  static const String photoMulchStraw = '$_images/photo-mulch-straw.jpg';
  static const String photoMulchWood = '$_images/photo-mulch-wood.jpg';

  /// Latar contoh layar kamera "Deteksi Jenis Tanah" (frame `101:701`) saat
  /// kamera tidak dipakai. Bukan foto tanah pada daftar jenis tanah: frame itu
  /// memang memotret pot dengan tanah gembur.
  static const String photoPotSoil = '$_images/photo-pot-soil.jpg';

  static const String photoMap =
      '$_images/photo-map.jpg';

  static const String photoProfile =
      '$_images/photo-profile.jpg';
}
