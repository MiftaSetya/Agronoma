import 'package:flutter/material.dart';

import 'package:frontend/core/widgets/app_shell.dart';
import 'package:frontend/features/home/home_screen.dart';
import 'package:frontend/features/profile/profile_screen.dart';

/// Host tab "dalam" aplikasi: Beranda dan Profil hidup berdampingan di dalam
/// satu `PageView`, sedangkan topbar dan navbar dimiliki [AppShell] di luar
/// `PageView`.
///
/// Kenapa begitu: kalau tiap tab adalah rute sendiri (`pushReplacementNamed`),
/// seluruh `Scaffold` — termasuk navbar — dibangun ulang setiap kali berpindah,
/// sehingga pil hijau berkedip dan isi tab kehilangan posisi gulirnya. Dengan
/// satu host, hanya isi tab yang bergeser.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  /// 0 = Beranda, 1 = Profil.
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _duration = Duration(milliseconds: 320);

  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _controller.animateToPage(
      index,
      duration: _duration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: _index,
      onTabSelected: _select,
      child: PageView(
        controller: _controller,
        onPageChanged: (index) => setState(() => _index = index),
        // Halaman dibungkus keep-alive: `PageView` membuang isi tab yang di
        // luar layar, dan itu akan mereset posisi gulir Beranda serta sakelar
        // di Profil setiap kali berpindah.
        children: const [
          _KeepAlivePage(child: HomeScreen()),
          _KeepAlivePage(child: ProfileScreen()),
        ],
      ),
    );
  }
}

/// Menjaga isi tab tetap hidup saat berada di luar layar `PageView`.
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
