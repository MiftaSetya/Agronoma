import 'package:frontend/core/models/plant.dart';

/// Satu entri `GET /plants/{id}/care-calendar`.
///
/// Backend mengirim **seluruh bulan** dengan status `none` untuk hari tanpa
/// jadwal, jadi tiap hari disimpan apa adanya lalu ditafsirkan oleh
/// [PlantSchedule] — bukan dibuang saat dibaca.
class CareDay {
  const CareDay({
    required this.date,
    required this.wateringStatus,
    required this.fertilizingStatus,
  });

  /// `YYYY-MM-DD` seperti yang dikirim backend.
  final String date;

  /// `none` | `need_water` | `watered` | `skip_rain` | `partial_rain`
  /// | `delayed_rain_expected`
  ///
  /// Empat status terakhir berasal dari mesin keputusan penyiraman di backend
  /// (`CareActionController` + `agronoma:daily-processing`).
  final String wateringStatus;

  /// Saat ini backend hanya menulis `fertilized` (dari
  /// `POST /plants/{id}/fertilizing/complete`); jadwal pupuk yang **belum**
  /// dikerjakan tidak punya baris log — lihat catatan di [PlantSchedule].
  final String fertilizingStatus;

  factory CareDay.fromJson(Map<String, dynamic> json) => CareDay(
    date: '${json['date']}',
    wateringStatus: json['watering_status'] as String? ?? 'none',
    fertilizingStatus: json['fertilizing_status'] as String? ?? 'none',
  );

  /// Hari ini jatuh tempo disiram.
  bool get needsWater => wateringStatus == 'need_water';

  /// Hujan diperkirakan cukup sehingga penyiraman ditunda/menunggu
  /// konfirmasi. Tetap ditampilkan sebagai tugas supaya pengguna bisa
  /// memutuskan sendiri.
  bool get waitsForRain =>
      wateringStatus == 'skip_rain' || wateringStatus == 'partial_rain';

  /// Sudah disiram hari ini.
  bool get watered => wateringStatus == 'watered';

  /// Sudah dipupuk hari ini.
  bool get fertilized => fertilizingStatus == 'fertilized';
}

/// Menyusun daftar tugas "Perawatan Hari Ini" dari care-calendar.
///
/// Sumbernya sengaja hanya bulan berjalan: layar Detail hanya menampilkan
/// "hari ini", jadi membaca bulan lain hanya menambah request.
class PlantSchedule {
  PlantSchedule._();

  /// Tanggal ISO (YYYY-MM-DD) untuk [date].
  ///
  /// Dibandingkan sebagai string di [tasksForToday] karena backend mengirim
  /// tanggal tanpa zona waktu; mengubahnya ke `DateTime` lalu membandingkan
  /// `isAtSameMomentAs` akan meleset beberapa jam.
  static String isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// [days] dari care-calendar → tugas untuk [today].
  ///
  /// **Pupuk yang belum dikerjakan tidak dibaca dari kalender**: backend hanya
  /// membuat baris `fertilizing_logs` saat pemupukan diselesaikan, sehingga
  /// "jadwal pupuk hari ini" tidak pernah muncul sebagai baris. Sumbernya
  /// `badge_status` tanaman (`perlu_pupuk`), yang dihitung backend dari
  /// `effectiveFertilizingDueDate()`; karena itu [dueFertilizer] dipakai untuk
  /// menambahkannya.
  ///
  /// Mengembalikan daftar kosong bila hari ini tidak punya jadwal — layar
  /// Detail sudah punya teks "Tidak ada jadwal perawatan untuk hari ini."
  static List<CareTask> tasksForToday(
    List<CareDay> days, {
    required DateTime today,
    bool dueFertilizer = false,
  }) {
    final key = isoDate(today);
    CareDay? entry;
    for (final candidate in days) {
      if (candidate.date == key) {
        entry = candidate;
        break;
      }
    }

    final tasks = <CareTask>[];

    final watering = entry == null ? null : _wateringTask(entry);
    if (watering != null) tasks.add(watering);

    if (entry != null && entry.fertilized) {
      tasks.add(
        CareTask(
          title: CareTaskKind.fertilizing.actionLabel,
          description: 'Sudah dipupuk hari ini.',
          date: 'Hari ini',
          done: true,
          kind: CareTaskKind.fertilizing,
        ),
      );
    } else if (dueFertilizer) {
      tasks.add(
        const CareTask(
          title: 'Pupuk Tanaman',
          description: 'Jadwal pemupukan hari ini.',
          date: 'Hari ini',
          done: false,
          kind: CareTaskKind.fertilizing,
        ),
      );
    }

    return tasks;
  }

  /// Status penyiraman hari ini → 0 atau 1 tugas.
  ///
  /// `delayed_rain_expected` sengaja tidak menghasilkan tugas: backend sudah
  /// memundurkan tanggalnya, jadi hari ini memang tidak perlu disiram.
  static CareTask? _wateringTask(CareDay entry) {
    if (entry.needsWater) {
      return CareTask(
        title: CareTaskKind.watering.actionLabel,
        description: 'Tanah sudah waktunya disiram hari ini.',
        date: 'Hari ini',
        done: false,
        kind: CareTaskKind.watering,
      );
    }
    if (entry.waitsForRain) {
      return CareTask(
        title: CareTaskKind.watering.actionLabel,
        description: 'Hujan diperkirakan turun; cek kondisi tanah lalu '
            'tandai bila tidak perlu disiram.',
        date: 'Hari ini',
        done: false,
        kind: CareTaskKind.watering,
      );
    }
    if (entry.watered) {
      return CareTask(
        title: CareTaskKind.watering.actionLabel,
        description: 'Sudah disiram hari ini.',
        date: 'Hari ini',
        done: true,
        kind: CareTaskKind.watering,
      );
    }
    return null;
  }
}
