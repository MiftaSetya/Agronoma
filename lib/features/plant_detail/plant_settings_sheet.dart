import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_button.dart';
import 'package:frontend/core/widgets/agro_icon.dart';

/// Drawer "Setelan Tanaman" (frame `EditPlant drawer`, node `291:2872`),
/// dibuka lewat tombol gir di kepala Detail Tanaman.
///
/// Ganti foto sengaja belum aktif: tombol kamera di [_PhotoPicker] hanya
/// menampilkan snackbar karena butuh plugin kamera/galeri.
class PlantSettingsSheet extends StatefulWidget {
  const PlantSettingsSheet({super.key, required this.plant});

  final Plant plant;

  static Future<void> show(BuildContext context, Plant plant) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => PlantSettingsSheet(plant: plant),
    );
  }

  @override
  State<PlantSettingsSheet> createState() => _PlantSettingsSheetState();
}

class _PlantSettingsSheetState extends State<PlantSettingsSheet> {
  late final TextEditingController _name;
  late String _location;
  late String _place;
  late String _soilName;
  late GrowthPhase _phase;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.plant.name);
    _location = widget.plant.location;
    _place = widget.plant.place;
    _soilName = widget.plant.soilName;
    _phase = widget.plant.phase;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxxl,
            AppSpacing.lg,
            AppSpacing.xxxl,
            AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gagang tarik (frame "Close" pada design).
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.chipAll,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Text(
                  'Setelan Tanaman',
                  style: AppTextStyles.titleLarge.copyWith(height: 19 / 16),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _PhotoPicker(photoAsset: widget.plant.photoAsset),
              const SizedBox(height: AppSpacing.xl),
              _LabeledField(
                label: 'Nama tanaman',
                leading: AgroIcon(AppAssets.tag, size: 20),
                child: TextField(
                  controller: _name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.darkGrey,
                  ),
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Nama tanaman',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _LabeledField(
                label: 'Lokasi Tanaman',
                leading: AgroIcon(AppAssets.locationTag, size: 20),
                trailing: const AgroIcon(AppAssets.chevronRightThin, size: 20),
                // Field lokasi bersifat baca: menekannya tidak melakukan aksi
                // (belum ada pemilih lokasi baru).
                child: Text(
                  _location,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _LabeledField(
                label: 'Media Tanam',
                trailing: const AgroIcon(AppAssets.arrowDown, size: 20),
                onTap: () => _pick(
                  PlantingMedia.values.map((m) => m.label).toList(),
                  _place,
                  (v) => setState(() => _place = v),
                ),
                child: Text(
                  _place,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _LabeledField(
                label: 'Jenis Tanah',
                trailing: const AgroIcon(AppAssets.arrowDown, size: 20),
                onTap: () => _pick(
                  MockData.soilTypes.map((s) => s.name).toList(),
                  _soilName,
                  (v) => setState(() => _soilName = v),
                ),
                child: Text(
                  _soilName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _LabeledField(
                label: 'Fase tanaman',
                trailing: const AgroIcon(AppAssets.arrowDown, size: 20),
                onTap: () => _pick(
                  GrowthPhase.values.map((p) => p.label).toList(),
                  _phase.label,
                  (v) => setState(() {
                    _phase = GrowthPhase.values.firstWhere(
                      (p) => p.label == v,
                    );
                  }),
                ),
                child: Text(
                  _phase.label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: AgroOutlineButton(
                      label: 'Batal',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AgroButton(
                      label: 'Simpan',
                      onPressed: () {
                        context.read<PlantController>().updatePlant(
                          widget.plant.id,
                          name: _name.text.trim(),
                          place: _place,
                          phase: _phase,
                          soilName: _soilName,
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pemilih sederhana berupa daftar pilihan dalam sheet baru — design tidak
  /// menggambar state "dropdown terbuka", jadi bentuknya sengaja minimal.
  Future<void> _pick(List<String> options, String current, void Function(String) onPick) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            for (final option in options)
              ListTile(
                title: Text(
                  option,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: option == current ? AppColors.primary : AppColors.darkGrey,
                    fontWeight: option == current ? FontWeight.w600 : null,
                  ),
                ),
                onTap: () {
                  onPick(option);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Foto tanaman 80px dengan tombol kamera menimpanya. Menekannya belum
/// mengganti foto — lihat catatan di kepala kelas.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photoAsset});

  final String photoAsset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mengganti foto belum tersedia di versi ini.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.smAll,
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.shadow1,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  photoAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              Container(
                color: const Color(0x2E000000),
                alignment: Alignment.center,
                child: const AgroIcon(AppAssets.cameraFill, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris "label + kotak isian" seperti komponen `textfield/with title` design,
/// dengan sekat vertikal abu di belakang ikon prefix.
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String label;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.titleMedium.copyWith(
            fontSize: 14,
            height: 20 / 14,
            color: AppColors.darkGrey,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.shadow1,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                      border: Border(
                        right: BorderSide(color: AppColors.border),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: leading!,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: leading == null ? AppSpacing.md : 0,
                      right: AppSpacing.sm,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: child,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  trailing!,
                  const SizedBox(width: AppSpacing.md),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
