import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_icon.dart';

/// Kerangka halaman "dalam" aplikasi: top bar (wordmark/chat atau judul),
/// daftar tab Beranda/Profil, dan FAB tambah di tengah bawah. Dipakai bersama
/// supaya jarak, bayangan, dan tinggi navbar konsisten.
///
/// Struktur dari Figma `Bottom Navigation` (node `13:1497`) dan `Top Header`
/// (node `24:884`): navbar 80, pil tab hijau `#6D9C25` radius 200, tombol
/// tengah naik 24 di atas navbar (luar 60 + padding 6).
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentIndex,
    required this.child,
    this.showTopBar = true,
    this.topBarTitle,
  });

/// 0 = Beranda, 1 = Profil (sesuai urutan tab di design).
  final int currentIndex;

  final Widget child;

  /// Sembunyikan top bar untuk halaman yang punya header sendiri.
  final bool showTopBar;

  /// Bila diisi, top bar berubah jadi panah kembali + judul (bukan wordmark).
  final String? topBarTitle;

  /// Tinggi navbar (tanpa area aman bawah).
  static const double navBarHeight = 80;

  /// Tinggi total area bawah: navbar + 24 ruang FAB yang menonjol.
  static const double bottomInset = navBarHeight + 24;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          if (showTopBar) AgroTopBar(title: topBarTitle),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: _AgroBottomNav(currentIndex: currentIndex),
    );
  }
}

/// Top bar: wordmark "Agronoma" + tombol obrolan AI, atau panah + judul.
class AgroTopBar extends StatelessWidget {
  const AgroTopBar({super.key, this.title, this.onBack});

  /// Kalau null → tampilkan wordmark; kalau diisi → tampilkan judul + back.
  final String? title;

  /// Aksi tombol panah. Bila null, panah menutup halaman lewat `maybePop` —
  /// wizard tambah tanaman memakai ini untuk mundur satu langkah, bukan menutup.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      padding: EdgeInsets.only(top: media.padding.top),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 0),
            blurRadius: 1.5,
          ),
        ],
      ),
      child: SizedBox(
        height: AppSizes.topBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: title == null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Wordmark asli dari design: 146.221 x 28.
                    const SizedBox(
                      height: 28,
                      child: _Wordmark(),
                    ),
                    _TopBarChatButton(),
                  ],
                )
              : Row(
                  children: [
                    _BackArrow(onTap: onBack),
                    Expanded(
                      child: Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineMedium,
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppAssets.wordmark,
      height: 28,
      semanticsLabel: 'Agronoma',
      alignment: Alignment.centerLeft,
    );
  }
}

class _TopBarChatButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(Routes.plantChat),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.smAll,
        ),
        child: const AgroIcon(AppAssets.chatAi, size: 24),
      ),
    );
  }
}

class _BackArrow extends StatelessWidget {
  const _BackArrow({this.onTap});

  /// Aksi khusus; bila null, panah menutup halaman lewat `maybePop`.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      child: SizedBox(
        width: 24,
        height: 24,
        child: const AgroIcon(AppAssets.chevronLeft, size: 24),
      ),
    );
  }
}

/// Navbar bawah: dua tab + tombol tambah melayang di tengah.
class _AgroBottomNav extends StatelessWidget {
  const _AgroBottomNav({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SizedBox(
      height: AppShell.navBarHeight + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: AppShell.navBarHeight + bottomInset,
            padding: const EdgeInsets.only(bottom: 0),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Color(0x40000000),
                  offset: Offset(0, 0),
                  blurRadius: 1.5,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Row(
                children: [
                  Expanded(
                    child: _NavTab(
                      label: 'Beranda',
                      activeIcon: AppAssets.navHomeActive,
                      inactiveIcon: AppAssets.navHomeOutline,
                      selected: currentIndex == 0,
                      onTap: () => _goTo(context, 0),
                    ),
                  ),
                  Expanded(
                    child: _NavTab(
                      label: 'Profil',
                      activeIcon: AppAssets.navProfileActive,
                      inactiveIcon: AppAssets.navProfileOutline,
                      selected: currentIndex == 1,
                      onTap: () => _goTo(context, 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: AppShell.navBarHeight - 36,
            child: _AddButton(),
          ),
        ],
      ),
    );
  }

  void _goTo(BuildContext context, int index) {
    if (index == currentIndex) return;
    Navigator.of(context).pushReplacementNamed(
      index == 0 ? Routes.home : Routes.profile,
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String activeIcon;
  final String inactiveIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.onPrimary : AppColors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.chipAll,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: AppRadius.chipAll,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AgroIcon(selected ? activeIcon : inactiveIcon, size: 24),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol tambah melayang: lingkaran hijau dengan cincin, memunculkan menu.
class _AddButton extends StatelessWidget {
  const _AddButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showAgroFabMenu(context),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xCC84C226),
              offset: Offset(0, 0),
              blurRadius: 4,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const AgroIcon(AppAssets.fabLogo, size: 32),
        ),
      ),
    );
  }
}

/// Menu yang muncul dari tombol tambah (FAB Menu Button, node `253:2576`).
Future<void> showAgroFabMenu(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FabMenuItem(
              icon: AppAssets.addPlant,
              label: 'Tambah tanaman',
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).pushNamed(Routes.addPlant);
              },
            ),
            _FabMenuItem(
              icon: AppAssets.diseaseDiagnosis,
              label: 'Diagnosis penyakit tanaman',
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).pushNamed(Routes.diseaseDetection);
              },
            ),
            _FabMenuItem(
              icon: AppAssets.closeMenu,
              label: 'Tutup',
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FabMenuItem extends StatelessWidget {
  const _FabMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            AgroIcon(icon, size: 24),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
