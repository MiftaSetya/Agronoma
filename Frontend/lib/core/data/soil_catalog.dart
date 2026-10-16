import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/models/soil_type.dart';

/// Tujuh jenis tanah pada daftar "Saya Tahu Jenis Tanah" (frame `113:765`).
///
/// Ini **katalog design**, bukan data contoh: backend tidak punya endpoint
/// daftar jenis tanah (hanya menerima `soil_type` pada endpoint AI), dan
/// fotonya memang aset design. Karena itu daftar yang sama dipakai baik saat
/// mode contoh maupun saat tersambung ke backend.
///
/// Nama dan keterangannya disalin dari render design; pasangan foto ↔ jenis
/// dipastikan dengan membandingkan piksel kartu design terhadap tiap berkas —
/// dulu daftar ini meminjam foto tanaman cabai/tomat sehingga gambarnya sama
/// sekali tidak berhubungan.
class SoilCatalog {
  SoilCatalog._();

  static const List<SoilType> types = [
    SoilType(
      id: 's1',
      code: 'artificial_media',
      name: 'Media Tanam Campuran',
      description: 'Racikan buatan khusus yang biasanya terdiri dari pupuk '
          'kompos, sekam, atau sabut kelapa.',
      photoAsset: AppAssets.photoMulchWood,
    ),
    SoilType(
      id: 's2',
      code: 'fertile',
      name: 'Tanah gembur',
      description: 'Kaya nutrisi, bertekstur remah, dan subur. Pilihan '
          'terbaik untuk mayoritas tanaman.',
      photoAsset: AppAssets.photoSoilCompost,
    ),
    SoilType(
      id: 's3',
      code: 'clay',
      name: 'Tanah liat',
      description: 'Bertekstur padat, menggumpal, dan lengket saat basah. '
          'Mengikat air lebih lama.',
      photoAsset: AppAssets.photoSoilCracked,
    ),
    SoilType(
      id: 's4',
      code: 'sandy',
      name: 'Tanah berpasir',
      description: 'Berbutir kasar dan sangat cepat kering. Air mengalir ke '
          'bawah dengan sangat bebas.',
      photoAsset: AppAssets.photoSoilBrown,
    ),
    SoilType(
      id: 's5',
      code: 'chalky',
      name: 'Tanah kapur',
      description: 'Berwarna pucat dan sering bercampur kerikil atau serpihan '
          'batu. Cenderung cepat kering.',
      photoAsset: AppAssets.photoSoilGravel,
    ),
    SoilType(
      id: 's6',
      code: 'volcanic',
      name: 'Tanah vulkanik',
      description: 'Berwarna hitam pekat yang sangat subur. Kaya mineral '
          'alami dari abu pegunungan.',
      photoAsset: AppAssets.photoSoilDark,
    ),
    SoilType(
      id: 's7',
      code: 'peat',
      name: 'Tanah gambut',
      description: 'Terasa berserat dari sisa pelapukan tanaman. Sangat empuk '
          'dan menyimpan banyak air.',
      photoAsset: AppAssets.photoMulchStraw,
    ),
  ];

  /// Jenis tanah dari kode enum backend. Kode tak dikenal jatuh ke "Tanah
  /// gembur" (jenis paling umum) supaya wizard tidak pernah kehilangan pilihan
  /// hanya karena model AI mengirim nilai di luar enum.
  static SoilType byCode(String code) => types.firstWhere(
    (soil) => soil.code == code,
    orElse: () => types[1],
  );
}
