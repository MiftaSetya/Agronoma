import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/models/chat_message.dart';
import 'package:frontend/core/models/disease.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/plant_recommendation.dart';
import 'package:frontend/core/models/soil_type.dart';
import 'package:frontend/core/models/weather.dart';

/// Data contoh untuk seluruh alur aplikasi.
///
/// Isinya diambil dari teks yang benar-benar ada di design Figma (nama tanaman,
/// kota, angka statistik) supaya tampilannya bisa dibandingkan langsung dengan
/// frame aslinya. Semua di sini hanya *contoh* — bagian yang menggantikannya
/// nanti adalah repositori, bukan widget-nya.
class MockData {
  MockData._();

  /// Titik acuan "sekarang" supaya tanggal di data contoh tetap masuk akal
  /// (kalau memakai `DateTime.now()` langsung, umur tanaman berubah tiap hari
  /// dan hasil tangkapan layar tidak bisa dibandingkan).
  static DateTime _daysAgo(int days) =>
      DateTime.now().subtract(Duration(days: days));

  // ─────────────────────────────────────────────────────────────────────────
  // Pengguna
  // ─────────────────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────────────────
  // Tanaman
  // ─────────────────────────────────────────────────────────────────────────

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
      media: PlantingMedia.polybag,
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
      soilName: 'Tanah Gembur',
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
      soilName: 'Tanah Humus',
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
      soilName: 'Tanah Liat',
      tasks: const [],
      timeline: _timeline,
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Cuaca
  // ─────────────────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────────────────
  // Lokasi (langkah 1 wizard tambah tanaman)
  // ─────────────────────────────────────────────────────────────────────────

  static const List<Map<String, String>> locations = [
    {
      'name': 'Politeknik Elektronika Negeri Surabaya',
      'address':
          'Politeknik Elektronika Surabaya, Jl. Raya ITS, Keputih, Sukolilo, '
          'Surabaya, East Java 60111',
    },
    {
      'name': 'Kebun Bibit Wonorejo',
      'address':
          'Jl. Wonorejo Rungkut, Surabaya, East Java 60296',
    },
    {
      'name': 'Rumah Kaca Sukolilo',
      'address': 'Jl. Teknik Kimia, Sukolilo, Surabaya, East Java 60111',
    },
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Jenis tanah (langkah 3)
  // ─────────────────────────────────────────────────────────────────────────

  static const List<SoilType> soilTypes = [
    SoilType(
      id: 's1',
      name: 'Tanah Humus',
      description: 'Paling subur, kaya bahan organik, cocok untuk kebanyakan '
          'tanaman pangan dan sayur.',
      iconAsset: AppAssets.photoCabaiRawit,
      phRange: '6.0 - 7.0',
      bestFor: ['Cabai', 'Tomat', 'Terung'],
    ),
    SoilType(
      id: 's2',
      name: 'Tanah Liat',
      description: 'Menahan air dengan baik tetapi berat dan mudah padat saat '
          'kering.',
      iconAsset: AppAssets.photoTomatCeri,
      phRange: '5.5 - 6.5',
      bestFor: ['Padi', 'Kangkung'],
    ),
    SoilType(
      id: 's3',
      name: 'Tanah Pasir',
      description: 'Cepat mengalirkan air, kurang menyimpan nutrisi sehingga '
          'perlu pemupukan lebih sering.',
      iconAsset: AppAssets.photoCabaiKeriting,
      phRange: '6.5 - 7.5',
      bestFor: ['Semangka', 'Kacang hijau'],
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Rekomendasi tanaman (langkah 4)
  // ─────────────────────────────────────────────────────────────────────────

  static final List<PlantRecommendation> recommendations = [
    PlantRecommendation(
      id: 'r1',
      name: 'Cabai Rawit',
      scientificName: 'Capsicum frutescens',
      photoAsset: AppAssets.photoCabaiRawit,
      description:
          'Sangat cocok dengan suhu kota ini dan tahan terhadap sinar matahari '
          'langsung. Bisa dipanen mulai umur 70 hari.',
      suitability: 95,
      bestFor: true,
      difficulty: 'Mudah',
      harvestAge: '70-80 hari',
    ),
    PlantRecommendation(
      id: 'r2',
      name: 'Tomat Ceri',
      scientificName: 'Solanum lycopersicum',
      photoAsset: AppAssets.photoTomatCeri,
      description:
          'Butuh penyiraman teratur dan sinar penuh. Hasil panen manis, cocok '
          'untuk pekarangan rumah.',
      suitability: 88,
      difficulty: 'Sedang',
      harvestAge: '60-70 hari',
    ),
    PlantRecommendation(
      id: 'r3',
      name: 'Cabai Rawit Keriting',
      scientificName: 'Capsicum annuum',
      photoAsset: AppAssets.photoCabaiKeriting,
      description:
          'Pertumbuhan cepat dan produksi banyak. Perlu pemupukan rutin saat '
          'masuk fase generatif.',
      suitability: 82,
      difficulty: 'Mudah',
      harvestAge: '75-90 hari',
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Penyakit (layar deteksi)
  // ─────────────────────────────────────────────────────────────────────────

  /// Isi hasil diagnosa mengikuti frame `Disease Drawer` (`253:2575`):
  /// nama, nama ilmiah, persentase cocok, dan tiga langkah penanganan.
  /// Dipakai untuk membandingkan hasil render dengan design, jadi teksnya
  /// sengaja sama persis.
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

  // ─────────────────────────────────────────────────────────────────────────
  // Chatbot
  // ─────────────────────────────────────────────────────────────────────────

  static const ChatMessage greeting = ChatMessage(
    author: ChatAuthor.bot,
    text: 'Halo! Ada yang bisa saya bantu terkait perawatan tanamanmu hari ini?',
  );

  static const List<String> chatSuggestions = [
    'Cabai rawit saya daunnya menggulung, kenapa ya?',
    'Berapa sering saya harus menyiram tomat ceri?',
    'Kapan waktu terbaik memupuk tanaman?',
  ];

  /// Jawaban contoh. Dicocokkan dengan kata kunci sederhana supaya
  /// pertanyaan lanjutan tetap terdengar masuk akal walau tanpa backend.
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
