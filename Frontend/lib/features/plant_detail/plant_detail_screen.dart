import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/api/weather_codes.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/weather.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_common.dart';
import 'package:frontend/core/widgets/agro_icon.dart';
import 'package:frontend/features/plant_detail/plant_settings_sheet.dart';

/// Layar Plant Detail — frame `Plant detail v3` (node `461:6012`): satu layar
/// dua tab (Ringkasan/Perawatan); lembar putihnya menutupi 35px bagian bawah
/// foto karena di kanvas Figma foto setinggi 287 dan lembar mulai baris 252.
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

  /// Baris lembar putih di kanvas Figma; 287 (foto) − 252 = 35px tertutup.
  static const double _sheetTop = 252;

  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab,
  );

  Plant? _plant;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Ditunda satu frame. `PlantController.load()` memberi tahu pendengarnya
    // sebelum `await` pertama, dan memanggilnya dari `initState` berarti
    // `notifyListeners()` terjadi saat fase build rute ini berjalan — melanggar
    // "setState() called during build" bila daftar tanaman belum termuat
    // (mis. deep link langsung ke Detail, atau kota tanpa cache cuaca sehingga
    // `load()` tidak berhenti lebih awal).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    try {
      final controller = context.read<PlantController>();
      // Kartu "Perkiraan Cuaca" di tab Ringkasan mengambil ramalan dari
      // controller ini; `load()` tidak melakukan apa-apa jika sudah ada.
      await controller.load();

      // Fallback tanaman pertama untuk deep link / preview tanpa argumen.
      var id = widget.plantId;
      if (id.isEmpty) id = controller.plants.isEmpty ? '' : controller.plants.first.id;
      if (id.isEmpty) return;
      final plant = await controller.fetch(id);
      if (mounted) setState(() => _plant = plant);
    } catch (e) {
      // Tanpa ini, kegagalan fetch (mis. backend fase berikutnya) bocor sebagai
      // layar galat; di sini ditangkap agar bisa ditawari "Coba lagi".
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Membuka "Setelan Tanaman" lalu menyegarkan salinan tanaman milik layar ini.
  ///
  /// Detail memegang `_plant` sendiri, sedangkan `PlantController` menyimpan
  /// daftar tanaman yang sudah diperbarui. Tanpa memungut ulang di sini, header,
  /// "Media Tanam", dan "Jenis Tanah" tetap menampilkan nilai sebelum disimpan
  /// sampai halaman dibuka ulang — persis yang terjadi saat uji di emulator
  /// meski `PATCH` sudah berhasil di backend.
  Future<void> _openSettings() async {
    final plant = _plant;
    if (plant == null) return;

    final saved = await PlantSettingsSheet.show(context, plant);

    if (!saved || !mounted) return;

    final updated = context.read<PlantController>().findById(plant.id);

    if (updated != null) setState(() => _plant = updated);
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
          : _error != null
          ? EmptyState(
              icon: AppAssets.pottedPlant,
              title: 'Gagal memuat tanaman',
              message: 'Periksa koneksi lalu coba lagi.',
              actionLabel: 'Coba lagi',
              onAction: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _load();
              },
            )
          : plant == null
          ? const EmptyState(
              icon: AppAssets.pottedPlant,
              title: 'Tanaman tidak ditemukan',
              message: 'Tanaman ini belum ada di daftarmu.',
            )
          : Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _photoHeight,
                  child: _PhotoHeader(plant: plant, onOpenSettings: _openSettings),
                ),
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

/// Foto tanaman + gradasi gelap + bilah atas "Detail Tanaman".
class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.plant, required this.onOpenSettings});

  final Plant plant;

  /// Membuka "Setelan Tanaman". Diteruskan dari layar karena hanya layar itu
  /// yang boleh memperbarui salinan `_plant` miliknya setelah penyimpanan
  /// berhasil — tanpa itu header tetap menampilkan nama/media lama.
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(plant.photoAsset, fit: BoxFit.cover),
        // Gradasi 152px: hitam 50% → 30% (pada 61%) → bening.
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
                  // Membuka panel "Setelan Tanaman" (frame `EditPlant drawer`,
                  // node `291:2872`).
                  GestureDetector(
                    onTap: onOpenSettings,
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

/// Lembar putih ber-radius 16 yang menutupi bagian bawah foto.
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

/// Nama, deskripsi, dan chip Indoor/Outdoor.
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

/// Chip kecil abu (`Indoor` / `Outdoor`), tinggi 21 di design.
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

/// Baris tab dengan garis bawah hijau pada tab aktif.
///
/// Di Figma `Line 3` adalah kotak setinggi 0 dengan gambar 2px yang meluber
/// (`inset-[-1px]`), jadi garis digambar meluber 1px lewat [Transform] agar
/// tidak menambah tinggi layout (garis 2px biasa akan menggeser isi tab 2px).
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
          // Bulatkan nilai animasi (bisa 0.4 saat transisi) agar hanya
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
                            // `height: normal` di design, bukan default
                            // [AppTextStyles.titleLarge].
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

class _RingkasanTab extends StatelessWidget {
  const _RingkasanTab({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    // Ramalan mengikuti kota tanaman ini, bukan satu kota tetap: tanaman bisa
    // berada di lokasi berbeda, dan cuaca yang ditampilkan harus cuaca tempat
    // tanaman itu tumbuh.
    final forecast = context.watch<PlantController>().forecastFor(plant.location);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxxl,
        AppSpacing.lg,
        // Bukan `gutter`: daftar ini bergulir di belakang kolom tombol bulat,
        // jadi ujungnya harus berhenti di atas tombol.
        AppShellBottom.gutterUnderFabs,
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

/// Kartu "Detail Tanam" — empat kotak berisi lokasi, media, pupuk, tanah.
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

  /// Lebar tiap kolom = lebar labelnya di design, agar jarak antar-titik
  /// (space-between) sama seperti frame aslinya.
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

  /// Panjang garis hijau: berhenti tepat di tengah titik aktif, jadi titik
  /// aktifnya sendiri tidak dihitung.
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
        // Titik sejajar walau diameternya berbeda (24 vs 32 saat aktif).
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
        // 32px kotak titik + 4px + 28px label (dua baris) = 64px total,
        // sesuai design.
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

/// Kartu "Perkiraan Cuaca" — tile pertama ditandai hijau (terpilih).
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

class _PerawatanTab extends StatefulWidget {
  const _PerawatanTab({required this.plant});

  final Plant plant;

  @override
  State<_PerawatanTab> createState() => _PerawatanTabState();
}

class _PerawatanTabState extends State<_PerawatanTab> {
  @override
  void initState() {
    super.initState();
    // Jadwal perawatan butuh satu permintaan sendiri (`care-calendar`), jadi
    // baru diambil saat tab ini benar-benar dibuka — Beranda tidak ikut
    // menunggunya, dan tanaman yang tidak pernah dibuka tidak memakan request.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PlantController>().loadTasks(widget.plant.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;
    final controller = context.watch<PlantController>();
    // Dihitung dari kalender bulan berjalan, bukan dari `Plant.tasks`: resource
    // tanaman dari backend tidak memuat jadwal.
    final tasks = controller.tasksFor(plant.id);
    final careDays = controller.careDaysFor(plant.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxxl,
        AppSpacing.lg,
        // Sama seperti tab Ringkasan: sisakan tinggi kolom tombol bulat supaya
        // baris tugas terakhir bisa digulir keluar dari baliknya.
        AppShellBottom.gutterUnderFabs,
      ),
      children: [
        Text('Perawatan', style: AppTextStyles.sectionTitle),
        const SizedBox(height: AppSpacing.lg),
        _ScanCard(
          onTap: () => Navigator.of(
            context,
          ).pushNamed(Routes.diseaseDetection, arguments: plant.id),
        ),
        const SizedBox(height: AppSpacing.lg),
        _CareCalendarCard(days: careDays),
        const SizedBox(height: AppSpacing.lg),
        _CareListCard(plant: plant, tasks: tasks),
      ],
    );
  }
}

/// Kartu hijau "Pindai Kesehatan" — pintasan ke Deteksi Penyakit.
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
            // Warna wajib ada; kalau tidak, bayangan hijau di bawah ini ikut
            // melukis seluruh badan kartu.
            color: AppColors.primary,
            borderRadius: AppRadius.lgAll,
            // Bayangan hijau (bukan hitam) sesuai design.
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
                  // Kaca buram: putih 30% di atas hijau.
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
                    // Di design caption ini dipotong dua baris (dua simpul
                    // `<p>` terpisah), bukan membungkus sendiri.
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

/// Kartu "Kalender Perawatan" — tujuh kolom tanggal + legenda ikon.
///
/// Datanya dari `GET /plants/{id}/care-calendar` (bulan berjalan), bukan lagi
/// daftar contoh: kartu ini menampilkan **hari ini dan enam hari berikutnya**,
/// dengan ikon siram/pupuk hanya pada hari yang memang punya jadwal.
class _CareCalendarCard extends StatelessWidget {
  const _CareCalendarCard({required this.days});

  final List<CareDay> days;

  @override
  Widget build(BuildContext context) {
    final weeks = _weekFrom(days);

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
              itemCount: weeks.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final d = weeks[i];
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
                          if (d.watering) ...[
                            const AgroIcon(
                              AppAssets.calendarWatering,
                              size: 12,
                            ),
                          ],
                          if (d.fertilizer) ...[
                            if (d.watering) const SizedBox(width: AppSpacing.xs),
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

  /// Tujuh hari mulai hari ini → data tampilan kartu.
  ///
  /// Backend mengirim sebulan penuh; kartu ini hanya selebar tujuh kolom dan
  /// design-nya menandai satu hari sebagai "aktif" (hari ini), jadi yang
  /// ditampilkan adalah pekan berjalan. Hari tanpa baris kalender tetap muncul
  /// sebagai kolom kosong supaya tanggalnya tidak melompat.
  static List<
    ({String day, String date, bool active, bool watering, bool fertilizer})
  >
  _weekFrom(List<CareDay> days) {
    final today = DateTime.now();
    final byDate = {for (final day in days) day.date: day};

    return [
      for (var offset = 0; offset < 7; offset++)
        () {
          final date = today.add(Duration(days: offset));
          final entry = byDate[PlantSchedule.isoDate(date)];
          return (
            day: WeatherCodes.dayLabel(PlantSchedule.isoDate(date)),
            date: '${date.day}',
            active: offset == 0,
            watering:
                entry != null &&
                (entry.needsWater ||
                    entry.waitsForRain ||
                    entry.watered),
            fertilizer: entry != null && entry.fertilized,
          );
        }(),
    ];
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
                    .toggleTask(plant.id, task.kind, !task.done),
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

/// Kunci dua tombol bulat di layar Detail.
///
/// Dipakai tes untuk mengukur geometrinya: kolom tombol tidak boleh menutupi
/// isi daftar dan tidak boleh keluar layar.
const Key plantDetailChatFabKey = Key('plant-detail-chat-fab');
const Key plantDetailRainFabKey = Key('plant-detail-rain-fab');

/// Dua tombol bulat di kanan bawah: peringatan hujan dan obrolan AI.
///
/// Di design kolomnya berada di `top: 764` pada kanvas 956 — yaitu berakhir
/// 64px di atas dasar. Yang dipakai di sini `bottom`, bukan `top`: pada layar
/// yang tidak setinggi kanvas (ponsel pendek, tablet), `top` membuat kolom
/// tombol melayang di tengah atau keluar dari layar.
class _DetailFabs extends StatelessWidget {
  const _DetailFabs({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: AppSpacing.lg,
      bottom: AppShellBottom.fabInset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            key: plantDetailRainFabKey,
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
            key: plantDetailChatFabKey,
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

  /// Tinggi kolom dua tombol bulat di layar Detail: 2×56 + 16 jarak antar.
  static const double fabStackHeight = AppSizes.fabSize * 2 + AppSpacing.lg;

  /// Jarak dasar kolom tombol dari tepi bawah layar.
  ///
  /// Diukur dari design: kolom mulai `top: 764` pada kanvas 956 dan berakhir
  /// 64px di atas dasar. Dipakai sebagai `bottom` — bukan `top` — supaya kolom
  /// tetap di tempatnya di layar yang lebih pendek/tinggi dari kanvas.
  static const double fabInset = 64;

  /// Ruang bawah untuk daftar yang **digulir di bawah** kolom tombol.
  ///
  /// Tanpa ini, kartu terakhir berhenti tepat di belakang tombol: isinya
  /// tertutup dan area centangnya tidak bisa disentuh.
  static const double gutterUnderFabs =
      fabInset + fabStackHeight + AppSpacing.sm;
}
