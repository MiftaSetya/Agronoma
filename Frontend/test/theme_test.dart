import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:frontend/core/theme/theme.dart';

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
    // Ukuran px yang benar-benar muncul di 210 simpul teks design:
    // 10, 12, 14, 16, 18, 20, 24, 32.
    expect(AppTextStyles.labelSmall.fontSize, 10);
    expect(AppTextStyles.bodySmall.fontSize, 12);
    expect(AppTextStyles.labelMedium.fontSize, 12);
    expect(AppTextStyles.bodyLarge.fontSize, 14);
    expect(AppTextStyles.labelLarge.fontSize, 14);
    expect(AppTextStyles.titleMedium.fontSize, 14);
    expect(AppTextStyles.titleLarge.fontSize, 16);
    expect(AppTextStyles.titleWide.fontSize, 16);
    expect(AppTextStyles.menuRow.fontSize, 18);
    expect(AppTextStyles.headlineLarge.fontSize, 20);
    expect(AppTextStyles.headlineMedium.fontSize, 20);
    expect(AppTextStyles.displayLarge.fontSize, 32);
    expect(AppTextStyles.displayMedium.fontSize, 32);
  });

  test('tinggi baris AppTextStyles sama dengan leading di Figma', () {
    // Figma menulis tinggi baris dalam px (dari `leading-[Npx]`), bukan rasio;
    // rumusnya height = leading / size.
    expect(AppTextStyles.labelSmall.height, 15 / 10);
    expect(AppTextStyles.bodySmall.height, 16 / 12);
    expect(AppTextStyles.labelMedium.height, AppTextStyles.leadingNormal);
    expect(AppTextStyles.bodyLarge.height, 20 / 14);
    expect(AppTextStyles.titleMedium.height, 20 / 14);
    expect(AppTextStyles.titleLarge.height, 20 / 16);
    expect(AppTextStyles.headlineLarge.height, 28 / 20);
    expect(AppTextStyles.headlineMedium.height, 1);
    expect(AppTextStyles.displayLarge.height, 28 / 32);
    expect(AppTextStyles.displayMedium.height, 40 / 32);
  });

  test('token leading-normal memakai tinggi baris metrik hhea Inter', () {
    // Simpul `leading-[normal]` tidak boleh height: null — Flutter lalu memakai
    // metrik usWin Inter (1,4302 em) sedangkan Figma memakai hhea/typo
    // (1,21 em), dan selisih 0,22 em itu menumpuk di seluruh layar.
    const normal = AppTextStyles.leadingNormal;
    expect(normal, 1.21);

    final tokens = <String, TextStyle>{
      'sheetTitle': AppTextStyles.sheetTitle,
      'cardTitle': AppTextStyles.cardTitle,
      'cardTitleWide': AppTextStyles.cardTitleWide,
      'overline': AppTextStyles.overline,
      'overlineValue': AppTextStyles.overlineValue,
      'scanTitle': AppTextStyles.scanTitle,
      'legend': AppTextStyles.legend,
      'labelMedium': AppTextStyles.labelMedium,
    };
    tokens.forEach((name, style) {
      expect(style.height, normal, reason: '$name harus height: leadingNormal');
    });
  });

  test('setiap token AppTextStyles menuliskan letterSpacing sendiri', () {
    // letterSpacing kosong tetap mewarisi jarak dari Typography.englishLike2021
    // (+0,3px @14px) saat digabung textTheme Material, padahal Figma memakai 0 —
    // teks jadi ~2% lebih lebar dan bisa membungkus baris lebih awal. Daftar ini
    // ditulis manual agar token baru tanpa letterSpacing langsung ketahuan.
    final tokens = <String, TextStyle>{
      'greetingLarge': AppTextStyles.greetingLarge,
      'headlineSmall': AppTextStyles.headlineSmall,
      'displayMedium': AppTextStyles.displayMedium,
      'displayLarge': AppTextStyles.displayLarge,
      'displayName': AppTextStyles.displayName,
      'sheetTitle': AppTextStyles.sheetTitle,
      'headlineLarge': AppTextStyles.headlineLarge,
      'headlineMedium': AppTextStyles.headlineMedium,
      'headlineMediumOnDark': AppTextStyles.headlineMediumOnDark,
      'sectionTitle': AppTextStyles.sectionTitle,
      'cardTitle': AppTextStyles.cardTitle,
      'cardTitleWide': AppTextStyles.cardTitleWide,
      'overline': AppTextStyles.overline,
      'overlineValue': AppTextStyles.overlineValue,
      'phaseLabel': AppTextStyles.phaseLabel,
      'phaseLabelActive': AppTextStyles.phaseLabelActive,
      'forecastDay': AppTextStyles.forecastDay,
      'forecastTemp': AppTextStyles.forecastTemp,
      'scanTitle': AppTextStyles.scanTitle,
      'scanCaption': AppTextStyles.scanCaption,
      'calendarDay': AppTextStyles.calendarDay,
      'calendarDate': AppTextStyles.calendarDate,
      'legend': AppTextStyles.legend,
      'tagChip': AppTextStyles.tagChip,
      'sheetBody': AppTextStyles.sheetBody,
      'titleLarge': AppTextStyles.titleLarge,
      'titleWide': AppTextStyles.titleWide,
      'menuItem': AppTextStyles.menuItem,
      'menuRow': AppTextStyles.menuRow,
      'menuRowCaption': AppTextStyles.menuRowCaption,
      'tagline': AppTextStyles.tagline,
      'titleMedium': AppTextStyles.titleMedium,
      'bodyLarge': AppTextStyles.bodyLarge,
      'bodyMuted': AppTextStyles.bodyMuted,
      'bodySmall': AppTextStyles.bodySmall,
      'bodyCaption': AppTextStyles.bodyCaption,
      'labelLarge': AppTextStyles.labelLarge,
      'labelMedium': AppTextStyles.labelMedium,
      'labelSmall': AppTextStyles.labelSmall,
      'buttonLarge': AppTextStyles.buttonLarge,
      'buttonOutline': AppTextStyles.buttonOutline,
    };

    tokens.forEach((name, style) {
      expect(
        style.letterSpacing,
        isNotNull,
        reason: '$name harus menuliskan letterSpacing (0 bila design tidak '
            'menentukan tracking)',
      );
    });

    // Nilai tracking yang memang ada di design, sebagai anti-regresi.
    expect(AppTextStyles.bodyLarge.letterSpacing, 0);
    expect(AppTextStyles.titleLarge.letterSpacing, 0);
    expect(AppTextStyles.overlineValue.letterSpacing, 0.14);
    expect(AppTextStyles.overline.letterSpacing, 0.55);
    expect(AppTextStyles.greetingLarge.letterSpacing, -0.64);
  });

  test('AppTextStyles tidak memakai SF Pro', () {
    final families = {
      AppTextStyles.displayLarge.fontFamily,
      AppTextStyles.headlineLarge.fontFamily,
      AppTextStyles.titleLarge.fontFamily,
      AppTextStyles.bodyLarge.fontFamily,
      AppTextStyles.labelSmall.fontFamily,
      AppTextStyles.displayMedium.fontFamily,
      AppTextStyles.greetingLarge.fontFamily,
    };
    expect(families, containsAll(<String?>{'Inter', 'Poppins'}));
    expect(families.any((f) => f != null && f.contains('SF')), isFalse);
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
