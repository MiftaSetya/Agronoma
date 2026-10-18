import 'package:flutter/material.dart';

import 'package:frontend/core/widgets/app_shell.dart';
import 'package:frontend/features/home/home_screen.dart';
import 'package:frontend/features/profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

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

        children: const [
          _KeepAlivePage(child: HomeScreen()),
          _KeepAlivePage(child: ProfileScreen()),
        ],
      ),
    );
  }
}

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
