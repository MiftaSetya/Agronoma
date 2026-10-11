import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/features/theme_preview/theme_preview_screen.dart';

void main() {
  test('AppColors memuat token resmi sesuai Figma Variables', () {
    expect(AppColors.primary.toARGB32(), 0xFF6D9C25);
    expect(AppColors.grey.toARGB32(), 0xFF898B87);
    expect(AppColors.darkGrey.toARGB32(), 0xFF454545);
    expect(AppColors.mainWhite.toARGB32(), 0xFFFFFFFF);
    expect(AppColors.lightGrey.toARGB32(), 0xFFE7E9E7);
    expect(AppColors.labelPrimary.toARGB32(), 0xFF000000);
  });

  test('shadow1 sesuai spesifikasi Figma', () {
    expect(AppColors.shadow1, hasLength(1));
    final s = AppColors.shadow1.first;
    expect(s.color.toARGB32(), 0x0D000000);
    expect(s.offset, const Offset(0, 1));
    expect(s.blurRadius, 2);
    expect(s.spreadRadius, 0);
  });

  test('AppTheme.light memakai Inter dan skema warna primary', () {
    final theme = AppTheme.light;
    expect(theme.textTheme.bodyLarge?.fontFamily, 'Inter');
    expect(theme.colorScheme.primary.toARGB32(), 0xFF6D9C25);
    expect(theme.scaffoldBackgroundColor.toARGB32(), 0xFFFFFFFF);
    expect(theme.textTheme.bodyLarge?.fontSize, 14);
    expect(theme.textTheme.headlineLarge?.fontSize, 20);
  });

  test('AppTextStyles memakai ukuran yang ada di design', () {
    // Ukuran px yang benar-benar muncul di design: 10, 12, 14, 16, 17, 20, 32.
    expect(AppTextStyles.labelSmall.fontSize, 10);
    expect(AppTextStyles.bodySmall.fontSize, 12);
    expect(AppTextStyles.labelMedium.fontSize, 12);
    expect(AppTextStyles.bodyLarge.fontSize, 14);
    expect(AppTextStyles.labelLarge.fontSize, 14);
    expect(AppTextStyles.titleLarge.fontSize, 16);
    expect(AppTextStyles.headlineMedium.fontSize, 17);
    expect(AppTextStyles.headlineLarge.fontSize, 20);
    expect(AppTextStyles.displayLarge.fontSize, 32);
    expect(AppTextStyles.displayMedium.fontSize, 32);
  });

  test('AppTextStyles tidak memakai SF Pro', () {
    final families = {
      AppTextStyles.displayLarge.fontFamily,
      AppTextStyles.headlineLarge.fontFamily,
      AppTextStyles.titleLarge.fontFamily,
      AppTextStyles.bodyLarge.fontFamily,
      AppTextStyles.labelSmall.fontFamily,
      AppTextStyles.displayMedium.fontFamily,
    };
    expect(families, containsAll(<String?>{'Inter', 'Poppins'}));
    expect(families.any((f) => f != null && f.contains('SF')), isFalse);
  });

  testWidgets('preview screen merender tanpa error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ThemePreviewScreen()),
    );
    expect(find.text('Verifikasi Fase 1'), findsOneWidget);
    expect(find.text('Warna resmi (Figma Variables)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('aset SVG benar-benar ter-render oleh flutter_svg', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SvgPicture.asset(
              'assets/icons/ef737f2fd5f77ee8b2373bcd192ef31ba14d492b.svg',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
