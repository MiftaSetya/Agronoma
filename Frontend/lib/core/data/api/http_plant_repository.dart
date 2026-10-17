import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/backend_codes.dart';
import 'package:frontend/core/data/api/plant_mapper.dart';
import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/models/plant.dart';

/// Sumber data tanaman yang berbicara ke backend sungguhan.
///
/// Dua keputusan bentuk:
///
/// 1. **Tugas perawatan dibaca per tanaman.** `GET /plants` tidak memuat
///    jadwal; `care-calendar` butuh satu permintaan per tanaman. Beranda hanya
///    butuh `badge_status` (sudah ada di daftar), jadi kalender baru dibaca saat
///    layar Detail Tanaman diminta — lihat [tasksFor].
/// 2. **Pemetaan dipakai bersama wizard.** [PlantMapper] dipakai di sini dan di
///    `HttpAddPlantRepository` supaya tanaman yang baru disimpan tidak "berubah
///    wujud" setelah Beranda memuat ulang dari `GET /plants`.
class HttpPlantRepository implements PlantRepository {
  HttpPlantRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Aksi perawatan yang boleh memakan waktu lebih lama dari permintaan biasa
  /// (backend menghitung ulang jadwal setelah log ditulis).
  static const Duration _actionTimeout = Duration(seconds: 20);

  @override
  Future<List<Plant>> getPlants() async {
    final body = await _api.get('plants');
    final raw = body is Map<String, dynamic> ? body['data'] : null;
    if (raw is! List) return const [];

    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) PlantMapper.fromBackend(item),
    ];
  }

  @override
  Future<Plant> getPlant(String id) async {
    final body = await _api.get('plants/$id');
    final raw = body is Map<String, dynamic> ? body['plant'] : null;
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Balasan tanaman tidak dikenali.');
    }
    return PlantMapper.fromBackend(raw);
  }

  /// Tugas "Perawatan Hari Ini" dari `GET /plants/{id}/care-calendar`.
  ///
  /// [dueFertilizer] diisi pemanggil dari `badge_status` tanaman (`Perlu Pupuk`),
  /// karena jadwal pupuk yang belum dikerjakan tidak muncul sebagai baris
  /// kalender — lihat catatan di [PlantSchedule.tasksForToday].
  /// Entri care-calendar bulan berjalan dari
  /// `GET /plants/{id}/care-calendar`.
  ///
  /// Seluruh bulan diminta sekali, lalu dipakai dua-duanya: tugas hari ini
  /// (lewat `PlantSchedule.tasksForToday` di controller) dan kartu "Kalender
  /// Perawatan". Status `need_water`/`watered` adalah satu-satunya cara
  /// mengetahui apa yang harus dikerjakan hari ini; `badge_status` pada
  /// `GET /plants` hanya ringkasannya.
  @override
  Future<List<CareDay>> careDays(
    Plant plant, {
    required DateTime today,
  }) async {
    final month = '${today.year}-${today.month.toString().padLeft(2, '0')}';
    final body = await _api.get(
      'plants/${plant.id}/care-calendar',
      query: {'month': month},
    );
    final raw = body is Map<String, dynamic> ? body['days'] : null;
    if (raw is! List) return const [];

    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) CareDay.fromJson(item),
    ];
  }

  /// Menandai satu jenis tugas selesai.
  ///
  /// Backend tidak punya endpoint "centang tugas": penyiraman dan pemupukan
  /// masing-masing punya endpoint sendiri yang mencatat log **hari ini**, jadi
  /// jenis tugas dipakai untuk memilih endpoint yang tepat.
  ///
  /// Yang dikirim adalah [CareTaskKind], bukan judul tugas: judul adalah teks
  /// tampilan yang boleh berubah kapan saja, dan menebak endpoint dari
  /// `title.contains('pupuk')` akan mengirim aksi pemupukan setiap kali sebuah
  /// tugas penyiraman kebetulan memuat kata itu.
  ///
  /// Membatalkan centang tidak punya padanan di API (log yang sudah tercatat
  /// tidak bisa dihapus lewat endpoint ini), jadi hanya "selesai" yang dikirim.
  /// Tanaman hasil muat ulang akan tetap menunjukkan tugas itu tercentang —
  /// jujur, karena backend memang mencatatnya.
  @override
  Future<Plant> setTaskDone(
    String plantId,
    CareTaskKind kind,
    bool done,
  ) async {
    if (done) {
      await _api.post(
        kind == CareTaskKind.fertilizing
            ? 'plants/$plantId/fertilizing/complete'
            : 'plants/$plantId/watering/complete',
        timeout: _actionTimeout,
      );
    }
    return getPlant(plantId);
  }

  /// Menyimpan hasil drawer "Setelan Tanaman".
  ///
  /// Backend hanya menerima `status` & `current_phase`; nama, tempat, dan jenis
  /// tanah adalah label design yang tidak punya kolomnya di `user_plants`.
  /// Perubahan itu karena itu tidak dikirim — dan memang tidak akan bertahan
  /// setelah muat ulang, bukan karena aplikasi lupa mengirimnya.
  @override
  Future<Plant> updatePlant(
    String plantId, {
    String? name,
    String? location,
    String? place,
    GrowthPhase? phase,
    String? soilName,
  }) async {
    if (phase != null) {
      await _api.patch(
        'plants/$plantId',
        body: {'current_phase': BackendCodes.phase(phase)},
      );
    }
    return getPlant(plantId);
  }
}
