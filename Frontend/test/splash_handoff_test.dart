import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/splash/splash_handoff.dart';

void main() {
  testWidgets('handoff menyala setelah jeda', (tester) async {
    var count = 0;
    final handoff = SplashHandoff(() => count++);

    handoff.arm(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));
    expect(count, 0, reason: 'Belum boleh menyala sebelum jeda habis.');

    await tester.pump(const Duration(milliseconds: 200));
    expect(count, 1);

    handoff.cancel();
  });

  testWidgets('jadwal yang dipasang ulang membatalkan jadwal sebelumnya', (
    tester,
  ) async {
    var count = 0;
    final handoff = SplashHandoff(() => count++);

    handoff.arm(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 100));

    handoff.arm(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 350));
    expect(count, 1);

    await tester.pump(const Duration(seconds: 3));
    expect(count, 1);
  });

  testWidgets('cancel mencegah handoff', (tester) async {
    var count = 0;
    final handoff = SplashHandoff(() => count++);

    handoff.arm(const Duration(milliseconds: 200));
    handoff.cancel();

    await tester.pump(const Duration(seconds: 1));
    expect(count, 0);
  });
}
