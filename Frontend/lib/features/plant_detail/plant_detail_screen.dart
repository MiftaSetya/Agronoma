import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/weather.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_common.dart';
import 'package:frontend/core/widgets/agro_icon.dart';
import 'package:frontend/features/plant_detail/plant_settings_sheet.dart';

/// Layar Plant Detail — frame `Plant detail v3` (node `461:6012`).
///
/// Susunannya dari atas ke bawah: foto penuh selebar layar dengan gradasi gelap
/// di bagian atas (supaya judul putih terbaca), lalu lembar putih ber-radius 16
/// yang **naik menutupi 35px foto**, berisi nama, deskripsi, dan chip
/// Indoor/Outdoor. Di bawahnya baris tab Ringkasan/Perawatan dengan garis bawah
/// hijau, baru isi tabnya.
///
/// Angka 35px itu bukan tebakan: di design foto tingginya 287 dan lembar putih
/// mulai di baris 252, jadi selisihnya 35.
class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({
    super.key,
    required this.plantId,
    this.initialTab = 0,
  });

  final String plantId;

  /// 0 = Ringkasan, 1 = Perawatan.
  final int initialTab;

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen>
    with SingleTickerProviderStateMixin {
  static const double _photoHeight = 287;

  /// Baris tempat lembar putih mulai pada kanvas Figma. Fotonya 287px, jadi
  /// selisih 35px itu bagian yang tertutup.
  static const double _sheetTop = 252;

  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab,
  );

  Plant? _plant;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final controller = context.read<PlantController>();
      // Selalu pastikan daftar tanaman + cuaca sudah dimuat: kartu "Perkiraan
      // Cuaca" di tab Ringkasan mengambil ramalan dari controller yang sama,
      // dan `load()` tidak melakukan apa-apa kalau datanya sudah ada.
      await controller.load();

      // Tanaman pertama dipakai bila id kosong. Ini berguna saat membuka layar
      // dari deep link / preview pengembangan yang tidak membawa argumen, dan
      // tetap aman karena `fetch` memanggil repositori hanya bila id tidak ada.
      var id = widget.plantId;
      if (id.isEmpty) id = controller.plants.isEmpty ? '' : controller.plants.first.id;
      if (id.isEmpty) return;
      final plant = await controller.fetch(id);
      if (mounted) setState(() => _plant = plant);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plant = _plant;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : plant == null
          ? const EmptyState(
              icon: AppAssets.pottedPlant,
              title: 'Tanaman tidak ditemukan',
              message: 'Data tanaman ini sudah tersedia.',
            )
          : Stack(
              children: [
                // Foto digambar penuh setinggi 287px, termasuk 35px bagian
                // bawahnya yang nanti ditutup lembar putih.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _photoHeight,
                  child: _PhotoHeader(plant: plant),
                ),
                // Lembar putih mulai 35px sebelum foto habis, sehingga
                // menutupi bagian bawahnya — persis seperti `Section - Header`
                // yang berada di baris 252 sementara fotonya setinggi 287.
                Padding(
                  padding: const EdgeInsets.only(top: _sheetTop),
                  child: Column(
                    children: [
                      _SheetHeader(plant: plant, tabs: _tabs),
                      Expanded(
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            _RingkasanTab(plant: plant),
                            _PerawatanTab(plant: plant),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _DetailFabs(plant: plant),
              ],
            ),
    );
  }
}

/// Foto tanaman + gradasi gelap + bilah atas ("Detail Tanaman").
class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(plant.photoAsset, fit: BoxFit.cover),
        // Gradasi 152px dari atas: hitam 50% di puncak → 30% di 61% → bening.
        DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x80050505), Color(0x4D000000), Color(0x00000000)],
              stops: [0, 0.61, 1],
            ),
          ),
          child: const SizedBox(height: 152),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppSpacing.sm,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: SizedBox(
              height: 46,
              child: Row(
                children: [
                  _HeaderBackButton(),
                  Expanded(
                    child: Text(
                      'Detail Tanaman',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineMediumOnDark,
                    ),
                  ),
                  // Design memakai gir pengaturan yang membuka panel "Setelan
                  // Tanaman" (frame `EditPlant drawer`, node `291:2872`).
                  GestureDetector(
                    onTap: () => PlantSettingsSheet.show(context, plant),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: AgroIcon(AppAssets.settingsLineWhite, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).maybePop(),
      child: const SizedBox(
        width: 24,
        height: 24,
        child: AgroIcon(AppAssets.arrowLeftWhite, size: 24),
      ),
    );
  }
}

/// Lembar putih yang menutupi bagian bawah foto: nama, deskripsi, chip, tab,
/// dan isi tab.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.plant, required this.tabs});

  final Plant plant;
  final TabController tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, -1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          _SheetHeading(plant: plant),
          _TabRow(tabs: tabs),
        ],
      ),
    );
  }
}

/// Nama, deskripsi, dan chip Indoor/Outdoor di atas lembar putih.
class _SheetHeading extends StatelessWidget {
  const _SheetHeading({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plant.name, style: AppTextStyles.sheetTitle),
          const SizedBox(height: 14),
          Text(plant.description, style: AppTextStyles.sheetBody),
          if (plant.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (final tag in plant.tags) ...[
                  _TagChip(label: tag),
                  if (tag != plant.tags.last) const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip kecil abu di bawah deskripsi (`Indoor` / `Outdoor`).
class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 21,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.border,
        borderRadius: AppRadius.chipAll,
      ),
      child: Text(label, style: AppTextStyles.tagChip),
    );
  }
}

/// Baris tab dengan garis bawah hijau pada tab yang aktif.
///
/// Garisnya ditaruh tepat di bawah teks (lebar 55) dan bukan selebar tab,
/// persis seperti `Line 3` di design.
///
/// Satu hal yang mudah salah: di Figma `Line 3` itu kotak **setinggi 0** dengan
/// gambar 2px yang meluber keluar (`inset-[-1px]`), jadi garisnya menumpuk
/// border bawah baris dan **tidak menambah tinggi layout** sama sekali. Kalau
/// garisnya diberi tinggi 2px, seluruh isi tab di bawahnya ikut turun 2px.
/// Karena itu ruangnya dibuat tetap 8px ([AppSpacing.sm]) dan garisnya digambar
/// meluber 1px ke bawah lewat [Transform].
class _TabRow extends StatelessWidget {
  const _TabRow({required this.tabs});

  final TabController tabs;

  /// Lebar garis bawah di design (`Line 3`).
  static const double _underlineWidth = 55;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: AnimatedBuilder(
        animation: tabs,
        builder: (context, _) {
          // Nilai animasi bisa 0.4 di tengah transisi; dibulatkan supaya hanya
          // underline yang bergerak, bukan warnanya ikut pudar.
          final index = tabs.index;
          return Row(
            children: [
              for (var i = 0; i < 2; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => tabs.animateTo(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            i == 0 ? 'Ringkasan' : 'Perawatan',
                            textAlign: TextAlign.center,
                            // Tinggi barisnya `normal` di design, bukan 20px
                            // seperti [AppTextStyles.titleLarge] yang default.
                            style: AppTextStyles.titleLarge.copyWith(
                              height: AppTextStyles.leadingNormal,
                              color: index == i
                                  ? AppColors.primary
                                  : AppColors.grey,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: AppSpacing.sm,
                          width: _underlineWidth,
                          child: index == i
                              ? Align(
                                  alignment: Alignment.bottomCenter,
                                  // Turun 1px supaya garis 2px-nya menutupi
                                  // border 1px di bawah baris tab, bukan
                                  // menambah tinggi baris.
                                  child: Transform.translate(
                                    offset: Offset(0, 1),
                                    child: SizedBox(
                                      height: 2,
                                      width: _underlineWidth,
                                      child: ColoredBox(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Ringkasan
// ─────────────────────────────────────────────────────────────────────────────

class _RingkasanTab extends StatelessWidget {
  const _RingkasanTab({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final forecast = context.read<PlantController>().forecast;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxxl,
        AppSpacing.lg,
        AppShellBottom.gutter,
      ),
      children: [
        Text('Ringkasan', style: AppTextStyles.sectionTitle),
        const SizedBox(height: AppSpacing.lg),
        _DetailTanamCard(plant: plant),
        const SizedBox(height: AppSpacing.lg),
        _GrowthPhaseCard(plant: plant),
        if (forecast.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _WeatherForecastCard(forecast: forecast),
        ],
      ],
    );
  }
}

/// Kartu "Detail Tanam" — empat kotak abu berisi lokasi, media, pupuk, tanah.
class _DetailTanamCard extends StatelessWidget {
  const _DetailTanamCard({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detail Tanam', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _OverviewTile(
                  label: 'LOKASI TANAM',
                  value: plant.location,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _OverviewTile(
                  label: 'MEDIA TANAM',
                  value: plant.place,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _OverviewTile(
                  label: 'JENIS PUPUK',
                  value: plant.fertilizer,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _OverviewTile(
                  label: 'JENIS TANAH',
                  value: plant.soilName,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.overline),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.overlineValue),
        ],
      ),
    );
  }
}

/// Kartu "Fase Pertumbuhan" — garis waktu mendatar dengan empat titik.
class _GrowthPhaseCard extends StatelessWidget {
  const _GrowthPhaseCard({required this.plant});

  final Plant plant;

  /// Lebar tiap titik, diambil dari lebar labelnya di design. Dipakai sebagai
  /// lebar kolom supaya jarak antar-titik (space-between) menghasilkan posisi
  /// yang sama seperti frame aslinya.
  static const List<double> _columnWidths = [41, 73, 54, 48];

  @override
  Widget build(BuildContext context) {
    final activeIndex = plant.phaseIndex;
    const trackWidth = 334.0;

    return _DetailCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Fase Pertumbuhan', style: AppTextStyles.cardTitle),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: SizedBox(
              width: trackWidth,
              height: 64,
              child: Stack(
                children: [
                  // Garis dasar, lalu bagian yang sudah dilalui berwarna hijau.
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 14,
                    child: _Track(),
                  ),
                  Positioned(
                    left: 0,
                    top: 14,
                    width: _activeTrackWidth(activeIndex, trackWidth),
                    child: const _Track(color: AppColors.primary),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < MockData.growthPhaseSteps.length; i++)
                        SizedBox(
                          width: _columnWidths[i],
                          child: _PhaseNode(
                            label: MockData.growthPhaseSteps[i],
                            index: i,
                            activeIndex: activeIndex,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Panjang garis hijau: 0 untuk fase pertama, lalu bertambah seperempat
  /// bagian. Titik aktifnya sendiri tidak dihitung karena garis berhenti tepat
  /// di tengah titik itu.
  static double _activeTrackWidth(int activeIndex, double trackWidth) {
    if (activeIndex <= 0) return trackWidth * 0.34;
    return trackWidth * (0.34 + 0.32 * (activeIndex - 1));
  }
}

class _Track extends StatelessWidget {
  const _Track({this.color = AppColors.border});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.chipAll,
      ),
    );
  }
}

/// Satu titik pada garis waktu fase pertumbuhan.
class _PhaseNode extends StatelessWidget {
  const _PhaseNode({
    required this.label,
    required this.index,
    required this.activeIndex,
  });

  final String label;
  final int index;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final isActive = index == activeIndex;
    final isDone = index < activeIndex;

    return Column(
      children: [
        // Semua titik duduk di tengah baris setinggi 32 supaya sejajar walau
        // diameternya berbeda (24 vs 32 saat aktif).
        SizedBox(
          height: 32,
          child: Center(
            child: isActive
                ? const AgroIcon(AppAssets.phaseDotActive, size: 32)
                : Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.primary : AppColors.border,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 4),
                    ),
                    child: isDone
                        ? const Center(
                            child: SizedBox(
                              width: 8,
                              height: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
          ),
        ),
        // Jarak 4px diambil dari design: kotak titik selalu 32px dan labelnya
        // menempel 4px di bawahnya, jadi 32 + 4 + 28 (dua baris) = 64px pas.
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          textAlign: TextAlign.center,
          style: isActive
              ? AppTextStyles.phaseLabelActive
              : AppTextStyles.phaseLabel.copyWith(
                  color: isDone ? AppColors.darkGrey : AppColors.grey,
                ),
        ),
      ],
    );
  }
}

/// Kartu "Perkiraan Cuaca" — enam kartu kecil, yang pertama ditandai hijau.
class _WeatherForecastCard extends StatelessWidget {
  const _WeatherForecastCard({required this.forecast});

  final List<WeatherForecast> forecast;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Perkiraan Cuaca', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: forecast.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) => _ForecastTile(
                forecast: forecast[i],
                selected: i == 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastTile extends StatelessWidget {
  const _ForecastTile({required this.forecast, required this.selected});

  final WeatherForecast forecast;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: selected ? 20 : AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySurface : AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            forecast.day,
            style: AppTextStyles.forecastDay.copyWith(
              color: selected ? AppColors.primary : AppColors.darkGrey,
            ),
          ),
          AgroIcon(forecast.iconAsset ?? AppAssets.weatherPartlyCloudy, size: 24),
          Text('${forecast.high}°C', style: AppTextStyles.forecastTemp),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Perawatan
// ─────────────────────────────────────────────────────────────────────────────

class _PerawatanTab extends StatelessWidget {
  const _PerawatanTab({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlantController>();
    final tasks = controller.findById(plant.id)?.tasks ?? plant.tasks;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxxl,
        AppSpacing.lg,
        AppShellBottom.gutter,
      ),
      children: [
        Text('Perawatan', style: AppTextStyles.sectionTitle),
        const SizedBox(height: AppSpacing.lg),
        _ScanCard(
          onTap: () =>
              Navigator.of(context).pushNamed(Routes.diseaseDetection),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _CareCalendarCard(),
        const SizedBox(height: AppSpacing.lg),
        _CareListCard(plant: plant, tasks: tasks),
      ],
    );
  }
}

/// Kartu hijau "Pindai Kesehatan" — jalan pintas ke Deteksi Penyakit.
class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            // Bayangan hijau, bukan hitam: di design warnanya ikut hijau.
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A416600),
                offset: Offset(0, 10),
                blurRadius: 15,
                spreadRadius: -3,
              ),
              BoxShadow(
                color: Color(0x1A416600),
                offset: Offset(0, 4),
                blurRadius: 6,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  // Kaca buram: putih 30% di atas latar hijau.
                  color: const Color(0x4DFFFFFF),
                  borderRadius: AppRadius.mdAll,
                ),
                child: const AgroIcon(AppAssets.diseaseScan, size: 32),
              ),
              const SizedBox(width: AppSpacing.lg),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pindai Kesehatan', style: AppTextStyles.scanTitle),
                    SizedBox(height: AppSpacing.xs),
                    // Di design keterangannya memang dipotong dua baris tepat
                    // setelah "penyakit" (dua simpul `<p>` terpisah), bukan
                    // dibiarkan membungkus sendiri oleh lebar kartu.
                    Text(
                      'Deteksi dini hama & penyakit\ndengan AI',
                      style: AppTextStyles.scanCaption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const SizedBox(
                width: 24,
                height: 24,
                child: AgroIcon(AppAssets.chevronRight, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu "Kalender Perawatan" — tujuh kolom tanggal + keterangan ikon.
class _CareCalendarCard extends StatelessWidget {
  const _CareCalendarCard();

  /// Sen–Min dengan nomor tanggal dan tugas yang jatuh pada hari itu.
  static const List<({String day, String date, bool active, bool fertilizer})>
  _days = [
    (day: 'Sen', date: '10', active: true, fertilizer: false),
    (day: 'Sel', date: '11', active: false, fertilizer: false),
    (day: 'Rab', date: '12', active: false, fertilizer: true),
    (day: 'Kam', date: '13', active: false, fertilizer: false),
    (day: 'Jum', date: '14', active: false, fertilizer: false),
    (day: 'Sab', date: '15', active: false, fertilizer: false),
    (day: 'Min', date: '15', active: false, fertilizer: false),
  ];

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kalender Perawatan', style: AppTextStyles.cardTitleWide),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final d = _days[i];
                return Container(
                  constraints: const BoxConstraints(minWidth: 56),
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: d.active
                        ? const Color(0x14C2F573)
                        : AppColors.surface,
                    borderRadius: AppRadius.lgAll,
                    border: Border.all(
                      color: d.active ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        d.day,
                        style: AppTextStyles.calendarDay.copyWith(
                          color: d.active
                              ? AppColors.primary
                              : AppColors.darkGrey,
                        ),
                      ),
                      Text(d.date, style: AppTextStyles.calendarDate),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AgroIcon(
                            AppAssets.calendarWatering,
                            size: 12,
                          ),
                          if (d.fertilizer) ...[
                            const SizedBox(width: AppSpacing.xs),
                            const AgroIcon(
                              AppAssets.calendarFertilizer,
                              size: 12,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            children: [
              _Legend(
                icon: AppAssets.calendarWatering,
                label: 'Siram',
              ),
              SizedBox(width: AppSpacing.lg),
              _Legend(
                icon: AppAssets.calendarFertilizer,
                label: 'Pupuk',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AgroIcon(icon, size: 12),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.legend),
      ],
    );
  }
}

/// Kartu "Perawatan Hari Ini" — daftar tugas yang bisa dicentang.
class _CareListCard extends StatelessWidget {
  const _CareListCard({required this.plant, required this.tasks});

  final Plant plant;
  final List<CareTask> tasks;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Perawatan Hari Ini', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.lg),
          if (tasks.isEmpty)
            Text(
              'Tidak ada jadwal perawatan untuk hari ini.',
              style: AppTextStyles.bodyMuted,
            )
          else
            for (final task in tasks) ...[
              _TaskRow(
                task: task,
                onToggle: () => context
                    .read<PlantController>()
                    .toggleTask(plant.id, task.title, !task.done),
              ),
              if (task != tasks.last) const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.onToggle});

  final CareTask task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isWatering = task.kind == CareTaskKind.watering;
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        onTap: onToggle,
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isWatering
                      ? AppColors.careWaterTint
                      : AppColors.careFertilizeTint,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.shadow1,
                ),
                alignment: Alignment.center,
                child: AgroIcon(
                  isWatering
                      ? AppAssets.careWaterDrops
                      : AppAssets.careWateringCan,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.ink,
                        letterSpacing: 0.14,
                        decoration: task.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      task.description.isEmpty ? task.date : task.description,
                      style: AppTextStyles.bodyMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              SizedBox(
                width: 24,
                height: 24,
                child: AgroIcon(
                  task.done ? AppAssets.taskCheckDone : AppAssets.taskCheckEmpty,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bagian bersama
// ─────────────────────────────────────────────────────────────────────────────

/// Kartu putih ber-border dengan bayangan `shadow` (bukan `shadow1`).
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadowRaisedSoft,
      ),
      child: child,
    );
  }
}

/// Dua tombol bulat di kanan bawah: peringatan hujan dan obrolan AI.
///
/// Di design kolomnya mulai di baris 764 dan berakhir di 892, jadi jaraknya
/// 64px dari dasar kanvas 956 — bukan 16px dari navbar seperti kartu biasa.
class _DetailFabs extends StatelessWidget {
  const _DetailFabs({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: AppSpacing.lg,
      top: 764,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: AppColors.surface,
            shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
            child: InkWell(
              onTap: () {},
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: AgroIcon(AppAssets.rainAlert, size: 24),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.of(context).pushNamed(
                Routes.plantChat,
                arguments: PlantDetailArgs(plantId: plant.id),
              ),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: AgroIcon(AppAssets.chatAi, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Jarak bawah standar untuk halaman tanpa navbar.
class AppShellBottom {
  AppShellBottom._();
  static const double gutter = 32;
}
