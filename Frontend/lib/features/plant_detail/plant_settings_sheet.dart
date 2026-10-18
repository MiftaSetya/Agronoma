import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/soil_catalog.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/plant_location.dart';
import 'package:frontend/core/state/add_plant_controller.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_button.dart';
import 'package:frontend/core/widgets/agro_icon.dart';

enum PlantSettingsResult { closed, saved, archived, deleted }

class PlantSettingsSheet extends StatefulWidget {
  const PlantSettingsSheet({super.key, required this.plant});

  final Plant plant;

  static Future<PlantSettingsResult> show(
    BuildContext context,
    Plant plant,
  ) async {
    final result = await showModalBottomSheet<PlantSettingsResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => PlantSettingsSheet(plant: plant),
    );

    return result ?? PlantSettingsResult.closed;
  }

  @override
  State<PlantSettingsSheet> createState() => _PlantSettingsSheetState();
}

class _PlantSettingsSheetState extends State<PlantSettingsSheet> {
  late final TextEditingController _name;
  late int? _locationId;
  late String _location;
  late String _place;
  late String _soilName;
  late GrowthPhase _phase;

  bool _saving = false;
  bool _archiving = false;
  bool _deleting = false;
  List<PlantLocation> _locations = const [];
  String? _photoUrl;

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Hapus tanaman?'),
        content: Text(
          '${widget.plant.name} akan dihapus permanen beserta riwayat '
          'perawatannya. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final ok = await context.read<PlantController>().deletePlant(
      widget.plant.id,
    );
    if (!mounted) return;
    setState(() => _deleting = false);

    if (ok) {
      Navigator.of(context).pop(PlantSettingsResult.deleted);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gagal menghapus tanaman. Periksa koneksi Anda.'),
      ),
    );
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Arsipkan tanaman?'),
        content: Text(
          '${widget.plant.name} akan dipindahkan ke arsip dan tidak lagi '
          'muncul di daftar tanaman aktif.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _archiving = true);
    final ok = await context.read<PlantController>().archive(widget.plant.id);
    if (!mounted) return;
    setState(() => _archiving = false);

    if (ok) {
      Navigator.of(context).pop(PlantSettingsResult.archived);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gagal mengarsipkan tanaman. Periksa koneksi Anda.'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.plant.name);
    _locationId = widget.plant.locationId;
    _location = widget.plant.location;
    _place = widget.plant.place;
    _soilName = widget.plant.soilName;
    _phase = widget.plant.phase;
    _photoUrl = widget.plant.photoUrl;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocations());
  }

  Future<void> _loadLocations() async {
    final add = context.read<AddPlantController>();
    await add.loadLocations();
    if (!mounted) return;
    setState(() => _locations = add.locations);
  }

  Future<void> _pickLocation() async {
    final picked = await showModalBottomSheet<PlantLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _LocationPickSheet(
        locations: _locations,
        selectedId: _locationId,
      ),
    );

    if (!mounted || picked == null) return;
    setState(() {
      _locationId = picked.id;
      _location = picked.label;
    });
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
              _PhotoPicker(
                plantId: widget.plant.id,
                photoAsset: widget.plant.photoAsset,
                photoUrl: _photoUrl,
                onUploaded: () {
                  final updated = context.read<PlantController>().findById(
                    widget.plant.id,
                  );
                  if (updated != null && mounted) {
                    setState(() => _photoUrl = updated.photoUrl);
                  }
                },
              ),
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
                onTap: _pickLocation,

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
                  SoilCatalog.types.map((s) => s.name).toList(),
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
                    _phase = GrowthPhase.values.firstWhere((p) => p.label == v);
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
              _ArchiveAction(
                busy: _archiving,
                onTap: _archiving ? null : _archive,
              ),
              const SizedBox(height: AppSpacing.md),
              _DeleteAction(busy: _deleting, onTap: _deleting ? null : _delete),
              const SizedBox(height: AppSpacing.lg),
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
                      loading: _saving,
                      onPressed: _saving
                          ? null
                          : () async {
                              setState(() => _saving = true);

                              final ok = await context
                                  .read<PlantController>()
                                  .updatePlant(
                                    widget.plant.id,
                                    name: _name.text.trim(),
                                    locationId: _locationId,
                                    place: _place,
                                    phase: _phase,
                                    soilName: _soilName,
                                  );

                              if (!context.mounted) return;
                              setState(() => _saving = false);

                              if (ok) {
                                Navigator.of(context).pop(
                                  PlantSettingsResult.saved,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Perubahan gagal disimpan. Periksa koneksi lalu coba lagi.',
                                    ),
                                  ),
                                );
                              }
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

  Future<void> _pick(
    List<String> options,
    String current,
    void Function(String) onPick,
  ) {
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
                    color: option == current
                        ? AppColors.primary
                        : AppColors.darkGrey,
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

class _PhotoPicker extends StatefulWidget {
  const _PhotoPicker({
    required this.plantId,
    required this.photoAsset,
    this.photoUrl,
    this.onUploaded,
  });

  final String plantId;
  final String photoAsset;
  final String? photoUrl;
  final VoidCallback? onUploaded;

  @override
  State<_PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<_PhotoPicker> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    if (_uploading) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 960,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await context
        .read<PlantController>()
        .uploadPhoto(widget.plantId, picked.path);

    if (!mounted) return;
    setState(() => _uploading = false);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Foto tanaman berhasil diperbarui.'
              : 'Gagal mengunggah foto. Periksa koneksi lalu coba lagi.',
        ),
      ),
    );

    if (ok) widget.onUploaded?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _uploading ? null : _pickAndUpload,
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
          child: _uploading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: widget.photoUrl != null
                          ? Image.network(
                              widget.photoUrl!,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              errorBuilder: (_, _, _) => Image.asset(
                                widget.photoAsset,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                              ),
                            )
                          : Image.asset(
                              widget.photoAsset,
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
                    child: Align(alignment: Alignment.centerLeft, child: child),
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

class _LocationPickSheet extends StatelessWidget {
  const _LocationPickSheet({required this.locations, required this.selectedId});

  final List<PlantLocation> locations;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.page,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              'Pilih lokasi tanam',
              style: AppTextStyles.titleLarge.copyWith(height: 19 / 16),
            ),
          ),
          if (locations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'Belum ada lokasi tersimpan di akunmu.',
                style: AppTextStyles.bodyMuted,
              ),
            )
          else
            for (final location in locations)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  location.label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: location.id == selectedId
                        ? AppColors.primary
                        : AppColors.darkGrey,
                    fontWeight: location.id == selectedId
                        ? FontWeight.w600
                        : null,
                  ),
                ),
                subtitle: Text(location.region, style: AppTextStyles.bodySmall),
                onTap: () => Navigator.of(context).pop(location),
              ),
        ],
      ),
    );
  }
}

class _ArchiveAction extends StatelessWidget {
  const _ArchiveAction({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const AgroIcon(AppAssets.archive, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Arsipkan tanaman',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const AgroIcon(AppAssets.chevronRightThin, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAction extends StatelessWidget {
  const _DeleteAction({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dangerTint,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.danger, width: 1),
          ),
          child: Row(
            children: [
              const AgroIcon(
                AppAssets.closeLine,
                size: 20,
                color: AppColors.danger,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Hapus tanaman',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const AgroIcon(AppAssets.chevronRightThin, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
