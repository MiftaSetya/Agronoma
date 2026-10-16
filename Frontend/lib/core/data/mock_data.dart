import 'package:latlong2/latlong.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/soil_catalog.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/models/chat_message.dart';
import 'package:frontend/core/models/disease.dart';
import 'package:frontend/core/models/map_location.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/plant_recommendation.dart';
import 'package:frontend/core/models/soil_type.dart';
import 'package:frontend/core/models/weather.dart';

/// Data contoh untuk seluruh alur aplikasi. Isinya diambil dari teks asli
/// design Figma (nama tanaman, kota, angka statistik) supaya hasil render
/// bisa dibandingkan langsung dengan frame aslinya.
class MockData {
  MockData._();

  /// Titik acuan waktu supaya umur tanaman di data contoh stabil untuk
  /// screenshot (bukan berubah tiap hari).
  static DateTime _daysAgo(int days) =>
      DateTime.now().subtract(Duration(days: days));

  static final AppUser user = AppUser(
    id: 'u1',
    name: 'User',
    email: 'user@agronoma.id',
    photoAsset: AppAssets.photoProfile,
    totalPlants: 24,
    harvestedThisSeason: 12,
    careScore: 98,
    joinedAt: _daysAgo(180),
  );

  static final List<CareTask> _tasksWater = [
    CareTask(
      title: 'Siram Tanaman',
      description: 'Siram hingga tanah lembap secara merata.',
      date: 'Hari ini',
      done: false,
    ),
    CareTask(
      title: 'Pupuk Tanaman',
      description: 'Pupuk tanaman',
      date: 'Hari ini',
      done: false,
      kind: CareTaskKind.fertilizing,
    ),
  ];

  static final List<CareTask> _tasksFertilize = [
    CareTask(
      title: 'Pupuk Tanaman',
      description: 'Pupuk NPK 16-16-16, siram setelahnya.',
      date: 'Hari ini',
      done: false,
      kind: CareTaskKind.fertilizing,
    ),
    CareTask(
      title: 'Siram Tanaman',
      description: 'Siram hingga tanah lembap secara merata.',
      date: 'Besok',
      done: true,
      kind: CareTaskKind.watering,
    ),
  ];

  /// Empat titik pada "Fase Pertumbuhan", berurutan seperti [GrowthPhase].
  static const List<String> growthPhaseSteps = [
    'Semai Biji',
    'Vegetatif Awal',
    'Vegetatif Akhir',
    'Generatif',
  ];

  static final List<GrowthMilestone> _timeline = [
    GrowthMilestone(label: 'Semai', date: '1 Jun', reached: true),
    GrowthMilestone(label: 'Vegetatif', date: '14 Jun', reached: true),
    GrowthMilestone(label: 'Generatif', date: '2 Jul', reached: true),
    GrowthMilestone(label: 'Panen', date: 'Perkiraan 20 Jul', reached: false),
  ];

  static final List<Plant> plants = [
    Plant(
      id: 'p1',
      name: 'Cabai Rawit',
      scientificName: 'Capsicum frutescens',
      photoAsset: AppAssets.photoCabaiRawit,
      location: 'Surabaya',
      place: 'Pekarangan Rumah',
      media: PlantingMedia.pot,
      status: CareStatus.needsWater,
      secondaryStatus: CareStatus.needsFertilizer,
      phase: GrowthPhase.vegetativeEarly,
      plantedAt: _daysAgo(38),
      careScore: 96,
      description:
          'Sangat adaptif dengan suhu terik. Mudah ditanam di pekarangan dan '
          'bisa dipanen untuk kebutuhan dapur sehari-hari.',
      tags: const ['Indoor', 'Outdoor'],
      fertilizer: 'NPK Daun',
      soilName: 'Tanah gembur',
      tasks: _tasksWater,
      timeline: _timeline,
    ),
    Plant(
      id: 'p2',
      name: 'Tomat Ceri',
      scientificName: 'Solanum lycopersicum var. cerasiforme',
      photoAsset: AppAssets.photoTomatCeri,
      location: 'Surabaya',
      place: 'Pekarangan Rumah',
      media: PlantingMedia.pot,
      status: CareStatus.needsFertilizer,
      phase: GrowthPhase.generative,
      plantedAt: _daysAgo(52),
      careScore: 88,
      description:
          'Butuh sinar matahari penuh dan penyiraman teratur. Buahnya manis '
          'dan cocok untuk salad atau camilan segar.',
      tags: const ['Indoor', 'Outdoor'],
      fertilizer: 'NPK Buah',
      soilName: 'Tanah vulkanik',
      tasks: _tasksFertilize,
      timeline: _timeline,
    ),
    Plant(
      id: 'p3',
      name: 'Cabai Rawit Keriting',
      scientificName: 'Capsicum annuum',
      photoAsset: AppAssets.photoCabaiKeriting,
      location: 'Surabaya',
      place: 'Kebun Belakang',
      media: PlantingMedia.ground,
      status: CareStatus.safe,
      phase: GrowthPhase.vegetativeLate,
      plantedAt: _daysAgo(75),
      careScore: 99,
      description:
          'Sudah masuk masa panen. Petik buah merah secara berkala supaya '
          'tanaman terus memproduksi bunga baru.',
      tags: const ['Outdoor'],
      fertilizer: 'NPK Kandang',
      soilName: 'Tanah liat',
      tasks: const [],
      timeline: _timeline,
    ),
  ];

  static const Weather weather = Weather(
    city: 'Surabaya',
    condition: 'Sebagian Berawan',
    temperature: 28,
    iconAsset: AppAssets.weatherPartlyCloudy,
    humidity: 74,
    windSpeed: '12 km/j',
  );

  static const List<WeatherForecast> forecast = [
    WeatherForecast(
      day: 'Hari ini',
      condition: 'Hujan',
      high: 32,
      low: 24,
      iconAsset: AppAssets.weatherRain,
    ),
    WeatherForecast(
      day: 'Besok',
      condition: 'Hujan',
      high: 32,
      low: 24,
      iconAsset: AppAssets.weatherRainAlt,
    ),
    WeatherForecast(
      day: 'Rab',
      condition: 'Berawan',
      high: 32,
      low: 25,
      iconAsset: AppAssets.weatherPartlyCloudy,
    ),
    WeatherForecast(
      day: 'Kam',
      condition: 'Cerah',
      high: 32,
      low: 25,
      iconAsset: AppAssets.weatherClear,
    ),
    WeatherForecast(
      day: 'Jum',
      condition: 'Hujan lebat',
      high: 32,
      low: 24,
      iconAsset: AppAssets.weatherRainHeavy,
    ),
    WeatherForecast(
      day: 'Sab',
      condition: 'Cerah berawan',
      high: 32,
      low: 25,
      iconAsset: AppAssets.weatherSunShower,
    ),
  ];

  /// Tiga lokasi contoh di sekitar Surabaya. Nama dan alamatnya disalin dari
  /// design; koordinat diambil dari alamat aslinya supaya peta sungguhan
  /// ([AgroMap]) menunjuk tempat yang benar-benar ada.
  static const List<MapLocation> locations = [
    MapLocation(
      name: 'Politeknik Elektronika Negeri Surabaya',
      address:
          'Politeknik Elektronika Surabaya, Jl. Raya ITS, Keputih, Sukolilo, '
          'Surabaya, East Java 60111',
      position: LatLng(-7.28161, 112.79500),
      city: 'Surabaya',
      province: 'Jawa Timur',
    ),
    MapLocation(
      name: 'Kebun Bibit Wonorejo',
      address: 'Jl. Wonorejo Rungkut, Surabaya, East Java 60296',
      position: LatLng(-7.30814, 112.83417),
      city: 'Surabaya',
      province: 'Jawa Timur',
    ),
    MapLocation(
      name: 'Rumah Kaca Sukolilo',
      address: 'Jl. Teknik Kimia, Sukolilo, Surabaya, East Java 60111',
      position: LatLng(-7.28633, 112.79457),
      city: 'Surabaya',
      province: 'Jawa Timur',
    ),
  ];

  /// Tujuh jenis tanah pada daftar "Saya Tahu Jenis Tanah" (frame `113:765`).
  ///
  /// Katalognya sendiri ada di [SoilCatalog] karena jenis tanah bukan data
  /// contoh: backend tidak menyediakan endpoint daftarnya, jadi daftar yang
  /// sama dipakai mode contoh maupun mode sungguhan.
  static const List<SoilType> soilTypes = SoilCatalog.types;

  /// Teks kartu rekomendasi diambil persis dari frame
  /// `Add Plant 4 - AI Recommendation` (`336:2882`) untuk perbandingan
  /// render. Chip "Pilihan Terbaik" di design tampil pada dua kartu pertama,
  /// dan spasi nyasar di awal nama `' Lidah Mertua (Sansevieria)'` sengaja
  /// tidak disalin (kecelakaan pengetikan, bukan maksud design).
  static final List<PlantRecommendation> recommendations = [
    PlantRecommendation(
      id: 'r1',
      name: 'Cabai Rawit',
      photoAsset: AppAssets.photoCabaiRawit,
      description:
          'Sangat adaptif dengan suhu terik. Mudah ditanam di pekarangan dan '
          'bisa dipanen untuk kebutuhan dapur sehari-hari.',
      tags: ['Pilihan Terbaik', 'Indoor'],
    ),
    PlantRecommendation(
      id: 'r2',
      name: 'Lidah Mertua (Sansevieria)',
      photoAsset: AppAssets.photoLidahMertua,
      description:
          'Berfungsi sebagai pembersih udara alami yang minim perawatan. '
          'Mampu bertahan dengan sangat baik di dalam ruangan ber-AC maupun '
          'area minim cahaya.',
      tags: ['Pilihan Terbaik', 'Indoor'],
    ),
    PlantRecommendation(
      id: 'r3',
      name: 'Sirih Gading',
      photoAsset: AppAssets.photoSirihGading,
      description:
          'Tanaman hias rambat yang sangat adaptif. Tumbuh sama suburnya saat '
          'dijadikan penghias meja di dalam ruangan atau sebagai tanaman '
          'gantung di teras.',
      tags: ['Indoor', 'Outdoor'],
    ),
  ];

  /// Isi hasil diagnosa persis mengikuti frame `Disease Drawer` (`253:2575`)
  /// supaya render bisa dibandingkan langsung dengan design.
  static const Disease disease = Disease(
    name: 'Karat Daun',
    scientificName: 'Infeksi Jamur (Pucciniomycetes)',
    diseaseType: 'Jamur',
    cause:
        'Infeksi jamur Pucciniomycetes yang sporanya terbawa angin dan '
        'menempel pada daun yang lembap, diperparah oleh sirkulasi udara '
        'yang buruk.',
    symptoms: [
      'Bercak oranye kecoklatan di permukaan bawah daun',
      'Daun menguning lalu mengering',
      'Pertumbuhan tanaman terhambat',
    ],
    steps: [
      DiseaseStep(
        title: 'Karantina Tanaman',
        detail:
            'Segera jauhkan tanaman yang terinfeksi dari tanaman yang sehat '
            'untuk mencegah penyebaran spora melalui angin.',
      ),
      DiseaseStep(
        title: 'Pangkas Bagian yang Terinfeksi',
        detail:
            'Gunting dengan hati-hati daun yang menunjukkan bercak karat. '
            'Jangan jadikan potongan daun ini sebagai kompos; masukkan ke '
            'dalam kantong dan buang segera.',
      ),
      DiseaseStep(
        title: 'Berikan Perawatan',
        detail:
            'Semprot daun sehat yang tersisa dengan fungisida berbahan dasar '
            'tembaga atau larutan minyak mimba (neem oil) pada pagi hari.',
      ),
    ],
    confidence: 0.98,
    severity: 'Sedang',
    photoAsset: AppAssets.photoPlantDetection,
  );

  static const ChatMessage greeting = ChatMessage(
    author: ChatAuthor.bot,
    text: 'Halo! Ada yang bisa saya bantu terkait perawatan tanamanmu hari ini?',
  );

  static const List<String> chatSuggestions = [
    'Cabai rawit saya daunnya menggulung, kenapa ya?',
    'Berapa sering saya harus menyiram tomat ceri?',
    'Kapan waktu terbaik memupuk tanaman?',
  ];

  /// Jawaban dicocokkan dengan kata kunci sederhana supaya pertanyaan
  /// lanjutan tetap masuk akal tanpa backend.
  static String chatReply(String question) {
    final q = question.toLowerCase();
    if (q.contains('menggulung')) {
      return 'Daun menggulung pada Cabai Rawit biasanya disebabkan oleh hama '
          'seperti Aphids atau Thrips, atau kurangnya kelembapan tanah.';
    }
    if (q.contains('siram') || q.contains('air')) {
      return 'Untuk tomat ceri, siram 1-2 kali sehari pada pagi dan sore. '
          'Pastikan tanah lembap tetapi tidak tergenang.';
    }
    if (q.contains('pupuk')) {
      return 'Pupuk paling baik diberikan pagi hari saat cuaca sejuk, lalu '
          'siram ringan supaya nutrisinya meresap ke akar.';
    }
    if (q.contains('panen')) {
      return 'Panen cabai rawit biasanya mulai umur 70-80 hari. Petik buah '
          'yang sudah merah penuh supaya tanaman terus berbunga.';
    }
    return 'Terima kasih! Untuk kondisi seperti itu, periksa dulu kelembapan '
        'tanah dan warna daun. Kalau ada bercak atau daun menggulung, coba '
        'jalankan Diagnosis penyakit tanaman dari menu utama.';
  }
}
