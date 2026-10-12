import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/plant_recommendation.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/add_plant_controller.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_button.dart';
import 'package:frontend/core/widgets/agro_icon.dart';
import 'package:frontend/core/widgets/agro_text_field.dart';
import 'package:frontend/core/widgets/app_shell.dart';

/// Alur "Tambah Tanaman" — lima langkah pada design:
///
/// 1. `Add Plant 1 - Location` (`58:222`, `127:721`) — izin & pilih lokasi
/// 2. `Add Plant 2 - Planting Media` (`70:411`) — media tanam
/// 3. `Add Plant 3 - Soil Types` (`88:361`, `113:765`) & `Detect Soil` (`101:701`)
/// 4. `Add Plant 4 - AI Recommendation` (`336:2882`) + tambah manual
/// 5. `Add Plant 5 - Plant phase` (`145:1624`)
///
/// Di Figma setiap langkah adalah frame tersendiri. Di kode, semuanya dijadikan
/// **satu** alur dengan indeks langkah supaya data yang dipilih bisa dibawa
/// antar langkah dan pengguna bisa menekan "Kembali" tanpa kehilangan isian.
///
/// Penataan isinya mengikuti kanvas Figma apa adanya: kartu kepala menempel di
/// baris 120, daftar pilihan mulai baris 312, dan baris tombol Kembali/Lanjut
/// di baris 830. Karena ada langkah yang elemennya **saling menimpa** (peta dan
/// kartu konfirmasi di langkah 1), isi digambar dengan koordinat absolut
/// ([Stack] + [Positioned]) — bukan [Column] yang tidak bisa saling menumpuk.
class AddPlantFlow extends StatefulWidget {
  const AddPlantFlow({super.key, this.initialStep = 0});

  /// Langkah yang langsung dibuka (0..4). Dipakai preview pengembangan untuk
  /// memotret langkah tertentu tanpa menjawab langkah sebelumnya.
  final int initialStep;

  /// Judul top bar. Di design kelima langkah memakai judul yang sama.
  static const String topBarTitle = 'Tambah tanaman';

  /// Label langkah pada indikator kemajuan, dalam huruf kecil seperti design
  /// (mis. "Lokasi penanaman"), bukan judul yang dikapitalkan.
  static const List<String> stepLabels = [
    'Lokasi penanaman',
    'Media tanam',
    'Analisis tanah',
    'Rekomendasi tanaman',
    'Fase tumbuh tanaman',
  ];

  @override
  State<AddPlantFlow> createState() => _AddPlantFlowState();
}

class _AddPlantFlowState extends State<AddPlantFlow> {
  late int _step = widget.initialStep.clamp(0, 4);

  /// Sedang menyimpan tanaman di langkah terakhir; menyalakan pemintal tombol.
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AddPlantController>().reset();
    });
  }

  bool get _canContinue {
    final draft = context.read<AddPlantController>().draft;
    return switch (_step) {
      0 => draft.hasLocation,
      1 => draft.hasMedia,
      2 => draft.hasSoil,
      3 => draft.hasPlant,
      4 => draft.phase != null,
      _ => false,
    };
  }

  Future<void> _next() async {
    if (_step < 4) {
      setState(() => _step++);
      return;
    }
    await _save();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final add = context.read<AddPlantController>();
    final plants = context.read<PlantController>();
    try {
      final draft = add.draft;
      final plant = await plants.addPlant(
        name: draft.resolvedName,
        scientificName: draft.manualScientificName,
        location: draft.locationName ?? 'Surabaya',
        soil: draft.soil ?? MockData.soilTypes.first,
        phase: draft.phase,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        Routes.plantDetail,
        arguments: PlantDetailArgs(plantId: plant.id),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan draft supaya tombol di bawah ikut hidup/mati.
    context.watch<AddPlantController>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      // Tombol kembali perangkat dipakai untuk mundur satu langkah, bukan
      // menutup wizard. `canPop` hanya benar di langkah pertama supaya
      // "Kembali" dari situ benar-benar keluar dari alur ini.
      body: PopScope(
        canPop: _step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _step > 0) setState(() => _step--);
        },
        child: Column(
          children: [
            AgroTopBar(title: AddPlantFlow.topBarTitle, onBack: _back),
            Expanded(
              // Isi langkah digambar pada baris 120..932 kanvas Figma. Sisa
              // 932..956 di design dipakai `Bottom/Home Bar`, dan di Android
              // ruang itu setara dengan inset sistem bawah — jadi dikurangi di
              // sini. Tanpa ini semua isi yang menempel ke bawah (tombol
              // "Lanjut", kartu lokasi) tampak 24px terlalu rendah.
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: switch (_step) {
                      0 => _LocationStep(
                        onNext: _next,
                        enabled: _canContinue,
                      ),
                      1 => _MediaStep(
                        onBack: _back,
                        onNext: _next,
                        enabled: _canContinue,
                      ),
                      2 => _SoilStep(
                        onBack: _back,
                        onNext: _next,
                        enabled: _canContinue,
                      ),
                      3 => _RecommendationStep(
                        onBack: _back,
                        onNext: _next,
                        enabled: _canContinue,
                      ),
                      _ => _PhaseStep(
                        onBack: _back,
                        onNext: _next,
                        enabled: _canContinue,
                        saving: _saving,
                      ),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu kepala yang sama di kelima langkah: indikator kemajuan, judul, dan
/// satu paragraf pengantar.
///
/// Di design kartunya menempel penuh dari tepi kiri ke tepi kanan (`left-0
/// w-[440px]`) dengan `pt-24 pb-16 px-16`, jadi **tanpa** lekuk sudut — yang
/// terlihat hanya garis tipis di kanan-kiri dan satu garis pemisah di bawahnya.
///
/// Tingginya tidak dipatok: Figma juga tidak mematoknya, tinggi itu hasil dari
/// isi (`gap-24` + paragraf yang jumlah barisnya berbeda tiap langkah). Yang
/// dijaga adalah **tinggi tiap baris** — label 16px, judul 20px, keterangan
/// 20px — karena salah satu saja membuat seluruh isi di bawahnya bergeser.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.step,
    required this.title,
    required this.description,
  });

  /// Indeks langkah 0..4 untuk indikator kemajuan.
  final int step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xxl,
        AppSpacing.page,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressStepIndicator(
            current: step,
            total: 5,
            label: AddPlantFlow.stepLabels[step],
          ),
          const SizedBox(height: AppSpacing.xxl),
          // Judul di design `text-[20px] leading-[20px]`, jadi
          // [AppTextStyles.sectionTitle] (20/20) — bukan [headlineLarge] (20/28)
          // yang membuat kartunya 8px lebih tinggi dari design.
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.lg),
          Text(
            description,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

/// Indikator langkah — bagian "Linear Progress Bar" dari `Progress Step`
/// (node `66:647`).
///
/// Di design komponennya menumpuk satu label dan satu baris segmen:
/// "Langkah 1 dari 5: Lokasi penanaman" di atas, lalu **lima** batang 6px
/// (bukan dua seperti yang terlihat sekilas di beberapa varian). Batang yang
/// sudah dilewati berwarna hijau tua, yang sedang dibuka hijau muda, sisanya
/// abu-abu.
class ProgressStepIndicator extends StatelessWidget {
  const ProgressStepIndicator({
    super.key,
    required this.current,
    required this.total,
    this.label,
  });

  final int current;
  final int total;

  /// Label di atas baris batang, mis. "Langkah 1 dari 5: Lokasi penanaman".
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Langkah ${current + 1} dari $total:',
                  // Di design baris ini `text-[14px] leading-[16px]`, bukan
                  // leading-20 seperti isi biasa: memakai [bodyLarge] apa adanya
                  // membuat kartu kepala 4px lebih tinggi dari design.
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.darkGrey,
                    fontWeight: FontWeight.w500,
                    height: 16 / 14,
                  ),
                ),
                TextSpan(
                  text: ' ${label!}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.darkGrey,
                    height: 16 / 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < current
                        ? AppColors.primary
                        : i == current
                        ? AppColors.primaryLight
                        : AppColors.lightGrey,
                    borderRadius: AppRadius.chipAll,
                  ),
                ),
              ),
              if (i < total - 1) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ],
    );
  }
}

/// Baris tombol "Kembali"/"Lanjut" yang menempel di baris 830 pada design.
///
/// Dipakai langkah 2-5. Tinggi tombol 54px, jarak antar tombol 16px, dan kartu
/// pembungkusnya `pt-16 pb-32`.
class _StepActions extends StatelessWidget {
  const _StepActions({
    required this.onBack,
    required this.onNext,
    required this.enabled,
    this.saving = false,
    this.nextLabel = 'Lanjut',
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool enabled;
  final bool saving;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.page,
        AppSpacing.xxxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AgroOutlineButton(label: 'Kembali', onPressed: onBack),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: AgroButton(
              label: nextLabel,
              loading: saving,
              onPressed: enabled ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Langkah 1 — lokasi
// ─────────────────────────────────────────────────────────────────────────────

/// Langkah 1 — peta dan kartu konfirmasi yang menimpa peta.
///
/// Geometri pada design (`Add Plant 1 - Location`, node `58:222`):
/// - peta: baris 296..676 (tinggi 380), selebar kanvas;
/// - kartu bawah: baris 662..932 — jadi **menimpa** 14px bagian bawah peta;
/// - penanda peta: tengah horizontal, 169px dari atas peta.
///
/// Karena saling menimpa, keduanya disusun dengan koordinat absolut
/// ([Positioned]) terhadap area isi (yang mulai di baris 120): peta di 176,
/// kartu di 542. Di dalam kartu, ruang antara alamat dan tombol mengembang
/// ([Spacer]) — kartunya di-pinch dari atas dan bawah, bukan dihitung.
class _LocationStep extends StatelessWidget {
  const _LocationStep({required this.onNext, required this.enabled});

  /// Tinggi peta pada design (296..676).
  static const double _mapHeight = 380;

  /// Peta mulai di baris 296 = 176 di dalam area isi (yang mulai di 120).
  static const double _mapTop = 176;

  /// Kartu konfirmasi mulai di baris 662 = 542 di dalam area isi.
  static const double _cardTop = 542;

  final VoidCallback onNext;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final location = MockData.locations.first;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Peta menempel di bawah kartu kepala dan berhenti di baris 676.
        Positioned(
          top: _mapTop,
          left: 0,
          right: 0,
          height: _mapHeight,
          child: const _LocationMap(),
        ),
        // Kartu bawah: dari baris 662 sampai bawah, menimpa 14px peta.
        Positioned(
          top: _cardTop,
          left: 0,
          right: 0,
          bottom: 0,
          child: _LocationConfirmCard(
            name: location['name']!,
            address: location['address']!,
            onConfirm: () {
              context.read<AddPlantController>().setLocation(
                location['name']!,
                location['address']!,
              );
              onNext();
            },
            onChange: () => _showLocationPicker(context),
          ),
        ),
      ],
    );
  }

  /// "Ubah Lokasi" membuka daftar lokasi contoh dalam sheet.
  ///
  /// Designnya belum punya frame untuk sheet ini, jadi bentuknya sengaja
  /// sederhana dan memakai komponen yang sudah ada. Tanpa ini tombolnya jadi
  /// hiasan yang tidak melakukan apa pun.
  void _showLocationPicker(BuildContext context) {
    final add = context.read<AddPlantController>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ubah Lokasi', style: AppTextStyles.headlineLarge),
              const SizedBox(height: AppSpacing.lg),
              for (final loc in MockData.locations)
                _LocationOption(
                  name: loc['name']!,
                  address: loc['address']!,
                  selected: loc['name'] == add.draft.locationName,
                  onTap: () {
                    context.read<AddPlantController>().setLocation(
                      loc['name']!,
                      loc['address']!,
                    );
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: AppSpacing.sm),
              AgroButton(
                label: 'Tutup',
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu konfirmasi lokasi (node `70:280`) — bagian yang menimpa peta.
///
/// Paddingnya `pt-24 px-16 pb-32` dengan `gap-32` antara blok alamat dan blok
/// tombol. Di design tingginya 270px dan isinya pas; di perangkat nyata inset
/// bawah bisa berbeda, jadi gap tengah dibuat [Spacer] — teks tetap di atas,
/// tombol tetap menempel di bawah.
class _LocationConfirmCard extends StatelessWidget {
  const _LocationConfirmCard({
    required this.name,
    required this.address,
    required this.onConfirm,
    required this.onChange,
  });

  final String name;
  final String address;
  final VoidCallback onConfirm;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xxl,
        AppSpacing.page,
        AppSpacing.xxxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AgroIcon(AppAssets.locationFilled, size: 24),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _TrimmedText(
                  text: name,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.darkGrey,
                    fontWeight: FontWeight.w700,
                    height: 29 / 20,
                  ),
                  // Design menulis `leading-[29px]` untuk teks 20px, dan
                  // simpulnya di-trim `cap_alphabetic` — tanpa kompensasi judul
                  // tampak ~4px terlalu rendah.
                  trimAdjust: _capTrimAdjust(20, 29),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _TrimmedText(
            text: address,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
              height: 16 / 14,
            ),
            // Alamat ini dua baris; trim-nya menjadikan tinggi blok
            // (2-1)*16 + capHeight.
            trimAdjust: _capTrimAdjust(14, 16),
            maxLines: 2,
          ),
          const Spacer(),
          AgroButton(label: 'Konfirmasi Lokasi', onPressed: onConfirm),
          const SizedBox(height: AppSpacing.sm),
          AgroOutlineButton(label: 'Ubah Lokasi', onPressed: onChange),
        ],
      ),
    );
  }

  /// Pergeseran ke atas untuk meniru `text-box-trim: cap_alphabetic`.
  ///
  /// CSS memotong ruang kosong di atas huruf kapital dan di bawah baseline;
  /// Flutter selalu menggambar kotak baris penuh. Setengah kelebihan itu ada di
  /// atas teks, jadi teksnya perlu digeser ke atas sebanyak itu. Perhitungan
  /// lengkapnya didokumentasikan di [AppTextStyles.leadingNormal].
  static double _capTrimAdjust(double fontSize, double lineHeight) {
    // Metrik usWin Inter yang dipakai Flutter: ascent 2269, descent 660 (per
    // 2048 unit). Cap height 1490.
    const ascent = 2269 / 2048;
    const descent = 660 / 2048;
    const capHeight = 1490 / 2048;
    final halfLeading = (lineHeight - (ascent + descent) * fontSize) / 2;
    // Jarak dari tepi atas kotak baris sampai puncak huruf kapital.
    final capTop = halfLeading + (ascent - capHeight) * fontSize;
    // Setengah bagian bawah (dari baseline sampai bawah kotak) juga hilang,
    // tetapi karena blok sesudahnya menghitung dari bawah kotak penuh, hanya
    // bagian atas yang perlu dikompensasi agar pusat optikalnya pas.
    return capTop - (lineHeight - fontSize * (ascent + descent)) / 2 - (capHeight * fontSize - fontSize * (ascent + descent)) / 2;
  }
}

/// Teks yang digeser sedikit untuk meniru pemotongan `cap_alphabetic`.
class _TrimmedText extends StatelessWidget {
  const _TrimmedText({
    required this.text,
    required this.style,
    required this.trimAdjust,
    this.maxLines,
  });

  final String text;
  final TextStyle style;
  final double trimAdjust;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -trimAdjust),
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Peta statis dengan penanda lokasi.
///
/// Designnya memakai gambar ubin peta, bukan peta sungguhan. Mengganti ini
/// dengan plugin peta berarti menambah kunci API dan izin akses; fotonya
/// sudah cukup untuk mencocokkan tampilan.
///
/// Gambar peta aslinya 428x679 dipasang `w-full h-[183.69%] top-[-41.78%]` —
/// artinya `BoxFit.cover` yang dipusatkan.
class _LocationMap extends StatelessWidget {
  const _LocationMap();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Image.asset(AppAssets.photoMap, fit: BoxFit.cover),
        // Penanda: 34,3x41,7 px, tengah horizontal, 169px dari atas peta
        // (baris 465 kanvas).
        const Positioned(
          top: 169,
          left: 0,
          right: 0,
          child: Center(
            child: AgroIcon(
              AppAssets.mapPointer,
              size: 34.286,
              height: 41.714,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationOption extends StatelessWidget {
  const _LocationOption({
    required this.name,
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            const AgroIcon(AppAssets.locationFill, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Langkah 2 — media tanam
// ─────────────────────────────────────────────────────────────────────────────

/// Langkah 2 — memilih media tanam (`70:411`).
///
/// Urutan dan teksnya mengikuti [PlantingMedia] langsung: enum itulah sumber
/// kebenaran label design ("Pot tanaman", "Pekarangan rumah", "Lahan
/// terbuka"), sehingga wizard dan tempat lain tidak bisa berbeda.
class _MediaStep extends StatelessWidget {
  const _MediaStep({
    required this.onBack,
    required this.onNext,
    required this.enabled,
  });

  /// Ikon media tanam pada bulatan 40px. Ukurannya diambil dari ukuran asli
  /// berkas SVG-nya, bukan dipaksa 16x16 — pot aslinya 18x19,9, rumah 20x20,
  /// dan lahan 20x19,9; memaksa sama akan meregangkan bentuknya.
  static const List<(PlantingMedia, String, double, double)> _options = [
    (PlantingMedia.pot, AppAssets.mediaPot, 18, 19.908),
    (PlantingMedia.ground, AppAssets.mediaHouse, 20, 20),
    (PlantingMedia.openField, AppAssets.mediaGround, 20, 19.908),
  ];

  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<AddPlantController>().draft;

    return Column(
      children: [
        const _HeaderCard(
          step: 1,
          title: 'Pilih Media Tanam',
          // Teks pengantar di design dibungkus manual menjadi tiga baris
          // (`mb-0` beruntun pada tiga `<p>`), bukan dibungkus otomatis. Yang
          // ketiga tanpa `mb-0` menandai akhir paragraf.
          description:
              'Pilih di mana Anda akan menanam tanaman ini\n'
              'agar kami dapat memberikan panduan\n'
              'perawatan yang tepat.',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xxl,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            children: [
              for (final (media, icon, w, h) in _options)
                _OptionCard(
                  icon: icon,
                  iconWidth: w,
                  iconHeight: h,
                  title: media.label,
                  subtitle: media.description,
                  selected: draft.media == media.name,
                  onTap: () =>
                      context.read<AddPlantController>().setMedia(media.name),
                ),
            ],
          ),
        ),
        _StepActions(onBack: onBack, onNext: onNext, enabled: enabled),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Langkah 3 — analisis tanah
// ─────────────────────────────────────────────────────────────────────────────

/// Langkah 3 — analisis tanah atau pilih jenis tanah sendiri (`88:361`).
///
/// Di design langkahnya menampilkan dua kartu **besar berisi di tengah**:
/// "Bantu saya scan tanah" dan "Saya Tahu Jenis Tanah". Daftar jenis tanah
/// baru muncul setelah pilihan kedua ditekan.
class _SoilStep extends StatefulWidget {
  const _SoilStep({
    required this.onBack,
    required this.onNext,
    required this.enabled,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool enabled;

  @override
  State<_SoilStep> createState() => _SoilStepState();
}

class _SoilStepState extends State<_SoilStep> {
  /// Pemakai memilih "Saya Tahu Jenis Tanah" sehingga daftarnya dibuka.
  bool _manual = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AddPlantController>().loadSoilTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final add = context.watch<AddPlantController>();
    final draft = add.draft;
    // Daftar manual hanya dibuka lewat tombol kedua. Kalau tanah sudah
    // terdeteksi lewat kamera, kartunya tetap dua — sesuai design.
    final openList = _manual;

    return Column(
      children: [
        const _HeaderCard(
          step: 2,
          title: 'Analisis tanah',
          description:
              'Pilih di mana Anda akan menanam tanaman ini\n'
              'agar kami dapat memberikan panduan\n'
              'perawatan yang tepat.',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xxl,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            children: [
              // Kartu besar "Bantu saya scan tanah" — isi di tengah, bulatan
              // 60px, `py-32 px-24`. Saat terpilih garis + bayangan hijau.
              _BigOptionCard(
                icon: draft.soilDetected
                    ? AppAssets.soilScanSelected
                    : AppAssets.soilScan,
                iconSize: 32,
                title: draft.soilDetected
                    ? 'Tanah sudah dianalisis'
                    : 'Bantu Saya Scan Tanah',
                subtitle: draft.soilDetected
                    ? 'Hasil analisis kamera sudah tersimpan.'
                    : 'Gunakan kamera untuk analisis otomatis',
                selected: draft.soilDetected,
                onTap: draft.soilDetected
                    ? null
                    : () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const _DetectSoilSheet(),
                      ),
              ),
              _BigOptionCard(
                icon: AppAssets.soilScan,
                iconSize: 32,
                title: 'Saya Tahu Jenis Tanah',
                subtitle: 'Pilih dari daftar jenis tanah secara manual',
                selected: openList && draft.soil != null,
                onTap: () => setState(() => _manual = !_manual),
              ),
              if (openList) ...[
                const SizedBox(height: AppSpacing.sm),
                if (add.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  for (final soil in add.soilTypes)
                    _OptionCard(
                      icon: soil.iconAsset,
                      title: soil.name,
                      subtitle: soil.description,
                      trailing: Text(
                        'pH ${soil.phRange}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                      selected: draft.soil?.id == soil.id,
                      onTap: () =>
                          context.read<AddPlantController>().selectSoil(soil),
                    ),
              ],
            ],
          ),
        ),
        _StepActions(
          onBack: widget.onBack,
          onNext: widget.onNext,
          enabled: widget.enabled,
        ),
      ],
    );
  }
}

/// Tiruan layar "Arahkan kamera ke permukaan tanah" (`101:701`).
///
/// Design memakai layar kamera sungguhan; di sini disederhanakan jadi sheet
/// dengan pratinjau statis, karena alur intinya (analisis → hasil tersimpan)
/// tetap bisa dicoba tanpa plugin kamera.
class _DetectSoilSheet extends StatefulWidget {
  const _DetectSoilSheet();

  @override
  State<_DetectSoilSheet> createState() => _DetectSoilSheetState();
}

class _DetectSoilSheetState extends State<_DetectSoilSheet> {
  bool _analyzing = false;

  Future<void> _analyze() async {
    setState(() => _analyzing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    context.read<AddPlantController>().markSoilDetected();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Arahkan kamera ke permukaan tanah',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: _analyzing
                ? const CircularProgressIndicator()
                : const AgroIcon(AppAssets.soilScan, size: 64),
          ),
          const SizedBox(height: AppSpacing.xl),
          AgroButton(
            label: _analyzing ? 'Menganalisis…' : 'Ambil Gambar',
            loading: _analyzing,
            onPressed: _analyze,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Langkah 4 — rekomendasi tanaman
// ─────────────────────────────────────────────────────────────────────────────

/// Langkah 4 — rekomendasi tanaman (`336:2882`).
///
/// Strukturnya berbeda dari langkah lain: daftar kartunya **ditarik sampai di
/// atas baris tombol** (mulai baris 288), sementara tombol "Tambah manual
/// tanaman" melayang **menimpa** daftar itu (menempel di atas baris 830).
/// Karena itu daftar diberi ruang atas 96px dan tombolnya diletakkan dalam
/// [Stack], bukan di dalam daftar.
class _RecommendationStep extends StatefulWidget {
  const _RecommendationStep({
    required this.onBack,
    required this.onNext,
    required this.enabled,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool enabled;

  @override
  State<_RecommendationStep> createState() => _RecommendationStepState();
}

class _RecommendationStepState extends State<_RecommendationStep> {
  var _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AddPlantController>().loadRecommendations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final add = context.watch<AddPlantController>();
    final draft = add.draft;

    return Column(
      children: [
        const _HeaderCard(
          step: 3,
          title: 'Hasil rekomendasi',
          // Satu baris saja di design — tidak dibungkus manual.
          description:
              'Pilihan tanaman terbaik yang sesuai dengan kondisi lingkunganmu.',
        ),
        Expanded(
          child: Stack(
            children: [
              // Daftar kartu mulai baris 384 = 264 di dalam area isi; container
              // designnya `top-288 pt-96` dengan header menutup 120..288.
              Positioned.fill(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    264 - 120,
                    AppSpacing.page,
                    AppSpacing.xxl,
                  ),
                  children: [
                    if (add.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 64),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: AppSpacing.lg),
                            Text('Menganalisis tanaman…'),
                          ],
                        ),
                      )
                    else if (draft.manualName != null &&
                        add.recommendations.isEmpty)
                      _OptionCard(
                        icon: AppAssets.pottedPlant,
                        title: draft.manualName!,
                        subtitle: 'Ditambahkan manual',
                        selected: true,
                        onTap: () {},
                      )
                    else
                      for (final r in add.recommendations)
                        _RecommendationCard(
                          recommendation: r,
                          selected: draft.recommendation?.id == r.id,
                          onTap: () => context
                              .read<AddPlantController>()
                              .selectRecommendation(r),
                        ),
                  ],
                ),
              ),
              // Tombol "Tambah manual tanaman" menimpa daftar: blok
              // `pt-24 + tombol 56 + pb-16` menempel di atas baris tombol.
              Positioned(
                left: 0,
                right: 0,
                bottom: 102,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.xxl,
                    AppSpacing.page,
                    AppSpacing.lg,
                  ),
                  child: _ManualAddButton(
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const _ManualPlantSheet(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _StepActions(
          onBack: widget.onBack,
          onNext: widget.onNext,
          enabled: widget.enabled,
          nextLabel: add.isLoading ? 'Menganalisis…' : 'Lanjut',
        ),
      ],
    );
  }
}

/// Tombol "Tambah manual tanaman" (node `338:2988`).
///
/// Bukan [AgroOutlineButton]: designnya latar putih dengan garis hijau penuh,
/// ikon tambah di bulatan 24px di kiri, dan teks 16px SemiBold hijau. Padding
/// vertikalnya membuat tinggi totalnya 56px.
class _ManualAddButton extends StatelessWidget {
  const _ManualAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.primary),
          boxShadow: AppColors.shadow1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AgroIcon(AppAssets.manualAddCircle, size: 24, height: 26.2),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Tambah manual tanaman',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                height: 24 / 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu rekomendasi tanaman (node `144:1250`).
///
/// Tata letaknya: foto 80px di kiri, kolom teks **255px tetap** di tengah, dan
/// slot centang 32px di kanan. Lebar kolom yang dipatok membuat deskripsi
/// membungkus di titik yang sama dengan design — memakai `Expanded` justru
/// membuat teksnya mengisi sisa ruang yang tidak sama.
class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.selected,
    required this.onTap,
  });

  final PlantRecommendation recommendation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0xC7A1D650),
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ]
              : AppColors.shadow1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppRadius.smAll,
              child: Image.asset(
                recommendation.photoAsset,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Kolom teks tetap 255px: 408 - 32(padding) - 12 - 80 - 12 - 32(slot)
            // meleset 17px dari design karena slot centangnya overflow; 255
            // adalah nilai yang benar-benar tertulis di design.
            SizedBox(
              width: 255,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.name,
                    style: AppTextStyles.titleLarge.copyWith(
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      for (var i = 0; i < recommendation.tags.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        _RecommendationChip(
                          label: recommendation.tags[i],
                          highlighted:
                              recommendation.tags[i] ==
                              PlantRecommendation.bestForTag,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    recommendation.description,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.grey,
                      height: 18 / 14,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Slot centang selalu ada supaya lebar kolom teks stabil; pada
            // kartu yang belum dipilih digambar transparan seperti di design
            // (berkas `bb146b37…` yang opacity-0).
            Opacity(
              opacity: selected ? 1 : 0,
              child: const AgroIcon(AppAssets.checkMarkGreen, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip di bawah nama tanaman (`Chips`, node `141:923` dan `141:967`).
///
/// Dua varian: "Pilihan Terbaik" berlatar kuning dengan bintang, dan
/// `Indoor`/`Outdoor` berlatar abu muda. Tingginya 21px (12px teks + 4px
/// padding atas bawah + sisa dari tinggi baris 18).
class _RecommendationChip extends StatelessWidget {
  const _RecommendationChip({
    required this.label,
    required this.highlighted,
  });

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 21,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.careFertilizeSurface : AppColors.lightGrey,
        borderRadius: AppRadius.chipAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (highlighted) ...[
            // Bintang 12x12,6 asli — dipaksa 12 membuatnya agak gepeng.
            const AgroIcon(AppAssets.bestMatchStar, size: 12, height: 12.581),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.bodyCaption.copyWith(
              height: 18 / 12,
              letterSpacing: -0.5,
              color: highlighted ? AppColors.careFertilize : AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet "Tambah manual tanaman" (`Plant Manual Input`, node `338:3070`).
class _ManualPlantSheet extends StatefulWidget {
  const _ManualPlantSheet();

  @override
  State<_ManualPlantSheet> createState() => _ManualPlantSheetState();
}

class _ManualPlantSheetState extends State<_ManualPlantSheet> {
  final _name = TextEditingController();
  final _scientific = TextEditingController();
  bool _showValidation = false;

  @override
  void dispose() {
    _name.dispose();
    _scientific.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      setState(() => _showValidation = true);
      return;
    }
    context.read<AddPlantController>().setManualPlant(
      _name.text,
      _scientific.text.isEmpty ? null : _scientific.text,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tambah manual tanaman', style: AppTextStyles.headlineLarge),
          const SizedBox(height: AppSpacing.xl),
          AgroTextField(
            label: 'Nama tanaman',
            hint: 'Contoh: Cabai Rawit',
            controller: _name,
            textInputAction: TextInputAction.next,
            errorText: _showValidation && _name.text.trim().isEmpty
                ? 'Nama tanaman tidak boleh kosong'
                : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          AgroTextField(
            label: 'Nama ilmiah (opsional)',
            hint: 'Contoh: Capsicum frutescens',
            controller: _scientific,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AgroButton(label: 'Tambah Tanaman', onPressed: _save),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Langkah 5 — fase pertumbuhan
// ─────────────────────────────────────────────────────────────────────────────

/// Langkah 5 — memilih fase pertumbuhan (`145:1624`).
///
/// Sumber ikon dan keterangannya adalah [GrowthPhase] sendiri; wizard hanya
/// menampilkannya berurutan.
class _PhaseStep extends StatelessWidget {
  const _PhaseStep({
    required this.onBack,
    required this.onNext,
    required this.enabled,
    required this.saving,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool enabled;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<AddPlantController>().draft;

    return Column(
      children: [
        const _HeaderCard(
          step: 4,
          title: 'Pilih fase pertumbuhan',
          description:
              'Sesuaikan jadwal perawatan berdasarkan usia\n'
              'tanamanmu saat ini.',
        ),
        Expanded(
          child: ListView(
            // Design memakai `py-24` dengan jarak antar kartu 10px — lebih
            // rapat daripada langkah 2/3 yang memakai 24.
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.page,
              vertical: AppSpacing.xxl,
            ),
            children: [
              for (final phase in GrowthPhase.values)
                _OptionCard(
                  icon: phase.iconAsset,
                  iconWidth: phase.iconWidth,
                  iconHeight: phase.iconHeight,
                  title: phase.label,
                  subtitle: phase.description,
                  selected: draft.phase == phase.name,
                  onTap: () =>
                      context.read<AddPlantController>().setPhase(phase.name),
                ),
            ],
          ),
        ),
        _StepActions(
          onBack: onBack,
          onNext: onNext,
          enabled: enabled,
          saving: saving,
          nextLabel: 'Simpan Tanaman',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu pilihan bersama
// ─────────────────────────────────────────────────────────────────────────────

/// Kartu pilihan kecil yang dipakai langkah 2 dan daftar manual langkah 3/4.
///
/// Bentuknya dari design: `p-16 gap-12 rounded-16`, ikon dalam bulatan 40px
/// (hijau penuh saat terpilih, abu muda saat belum), judul 16px SemiBold
/// (`tracking-[-1px]`), dan keterangan 14px (`tracking-[-0.5px]`).
///
/// Slot centang 32px **selalu ada**: di design kartu yang belum dipilih tetap
/// menampung berkas `bb146b37…` yang `opacity="0"`, jadi lebar kolom teksnya
/// tidak berubah saat kartu terpilih. Menghilangkan slot sama sekali membuat
/// teks melompat 32px ke kanan saat kartu dipilih.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.iconWidth,
    this.iconHeight,
    this.trailing,
  });

  final String icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// Ukuran asli ikon di dalam bulatan 40px. Kosong berarti persegi 18px
  /// (ukuran yang paling umum di design).
  final double? iconWidth;
  final double? iconHeight;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0xC7A1D650),
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ]
              : AppColors.shadow1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _IconCircle(
              icon: icon,
              width: iconWidth ?? 18,
              height: iconHeight ?? 19.908,
              selected: selected,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleLarge.copyWith(
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.grey,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
            const SizedBox(width: AppSpacing.sm),
            // Centang hijau saat terpilih, transparan saat belum — slotnya
            // selalu 32px.
            Opacity(
              opacity: selected ? 1 : 0,
              child: const AgroIcon(AppAssets.checkMarkGreen, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu pilihan besar langkah 3 (`88:533` dan `88:540`).
///
/// Berbeda dari [_OptionCard]: isi di tengah (teks dan ikon di tengah kartu),
/// bulatan ikonnya 60px, dan padding vertikalnya 32px sehingga tingginya 184px.
class _BigOptionCard extends StatelessWidget {
  const _BigOptionCard({
    required this.icon,
    required this.iconSize,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final double iconSize;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xxxl,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x806D9C25),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ]
              : AppColors.shadow1,
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.lightGrey,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: AgroIcon(icon, size: iconSize),
            ),
            const SizedBox(height: AppSpacing.lg),
            Column(
              children: [
                // Design menulis `capitalize` di simpul judulnya, sehingga
                // kalimat biasa tampil dengan huruf kapital di tiap kata.
                Text(
                  _capitalize(title),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.grey,
                    height: 16 / 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Meniru CSS `capitalize`: huruf pertama tiap kata jadi kapital.
  static String _capitalize(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Bulatan ikon pada kartu pilihan — hijau saat terpilih, abu saat belum.
class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.icon,
    required this.width,
    required this.height,
    required this.selected,
  });

  final String icon;
  final double width;
  final double height;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.lightGrey,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: AgroIcon(icon, size: width, height: height),
    );
  }
}
