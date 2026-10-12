import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Skala jarak. Design digambar pada kanvas 440px dengan padding halaman
/// **16px** (diukur dari `Home`, `Profile`, dan `Plant detail`).
///
/// Nilai-nilainya kelipatan 4 yang lazim dipakai di Figma.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Padding horizontal standar halaman (kiri-kanan).
  ///
  /// Diambil dari design: Home dan Profile memakai 16, sehingga lebar kartu
  /// 408 dari kanvas 440. Ada beberapa komponen yang memakai 20 di dalam
  /// dirinya sendiri (mis. isi kartu), tetapi **kerangka halaman** selalu 16.
  static const double page = 16;

  /// Jarak aman dari tepi bawah untuk konten di atas home indicator.
  static const double bottomGutter = 24;
}

/// Radius sudut. Diukur dari bentuk kartu, field, dan tombol pada design.
class AppRadius {
  AppRadius._();
  static const double chip = 999;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double sheet = 24;

  /// Radius lembar hasil deteksi penyakit — `Disease Drawer` di design memakai
  /// 32, lebih besar dari sheet biasa supaya terlihat seperti panel yang bisa
  /// ditarik naik.
  static const double sheetLarge = 32;

  static const BorderRadius chipAll = BorderRadius.all(Radius.circular(chip));
  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Tinggi komponen yang berulang di banyak screen.
class AppSizes {
  AppSizes._();
  static const double buttonHeight = 50;
  static const double fieldHeight = 44;
  static const double topBarHeight = 56;
  static const double navBarHeight = 64;
  static const double fabSize = 56;
  static const double listImage = 64;
  static const double hitTarget = 48;

  /// Lebar dan tinggi kanvas Figma. Semua jarak di design diukur pada frame
  /// 440x956 (iPhone 16 Pro Max), jadi angka-angka di tema ini juga.
  static const double designWidth = 440;
  static const double designHeight = 956;

  /// Tinggi area status bar pada kanvas Figma — status bar iPhone 16 Pro Max.
  ///
  /// Design menggambar seluruh isi layar **mulai dari baris 64**: status bar
  /// setinggi itu bukan sekadar gambar, ia turut menentukan posisi judul, kartu,
  /// dan tombol di bawahnya. Di Android status bar rata-rata hanya ~32px, jadi
  /// kalau dibiarkan setiap layar akan meleset 32px ke atas dengan arah yang
  /// sama dan hasilnya terlihat "mirip tapi bukan".
  ///
  /// Karena itu inset atas diseragamkan sekali di `app.dart`
  /// ([normalizeTopInset]), bukan ditambal satu per satu di tiap layar.
  static const double designStatusBar = 64;

  /// Menyamakan inset atas dengan area status bar pada design.
  ///
  /// Nilai yang dipakai adalah **nilai terbesar** antara inset sistem dan
  /// [designStatusBar]. Sengaja tidak pernah mengecilkan inset: pada perangkat
  /// berponi inset sistem bisa lebih tinggi dari 64, dan memaksanya jadi 64 akan
  /// membuat konten tertutup poni. Dengan mengambil yang terbesar, layout sama
  /// seperti design pada perangkat biasa, dan tetap aman pada perangkat berponi.
  static double normalizeTopInset(BuildContext context) {
    final systemInset = MediaQuery.of(context).padding.top;
    return systemInset < designStatusBar ? designStatusBar : systemInset;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryTint,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.careWater,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.careWaterTint,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.careFertilize,
      onTertiary: AppColors.onPrimary,
      tertiaryContainer: AppColors.careFertilizeTint,
      onTertiaryContainer: AppColors.ink,
      error: AppColors.danger,
      onError: AppColors.onPrimary,
      errorContainer: AppColors.dangerTint,
      onErrorContainer: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.surfaceMuted,
      surfaceContainer: AppColors.surfaceAlt,
      onSurfaceVariant: AppColors.inkSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderStrong,
      shadow: Color(0x0D000000),
      scrim: AppColors.scrim,
      inverseSurface: AppColors.ink,
      onInverseSurface: AppColors.surface,
    );

    final textTheme = const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyLarge,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppTextStyles.fontInter,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: AppSizes.topBarHeight,
        titleTextStyle: AppTextStyles.headlineMedium,
        iconTheme: IconThemeData(color: AppColors.ink, size: 24),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(color: AppColors.ink, size: 24),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        constraints: const BoxConstraints(minHeight: AppSizes.fieldHeight),
        hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.muted),
        labelStyle: AppTextStyles.labelLarge,
        floatingLabelStyle: AppTextStyles.labelLarge,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.muted),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.disabledFill,
          disabledForegroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          elevation: 0,
          textStyle: AppTextStyles.buttonLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          side: const BorderSide(color: AppColors.primary),
          textStyle: AppTextStyles.buttonOutline,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.muted,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
        titleTextStyle: AppTextStyles.titleLarge,
        contentTextStyle: AppTextStyles.bodyMuted,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryTint,
        height: AppSizes.navBarHeight,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppTextStyles.labelMedium.copyWith(color: AppColors.primary)
              : AppTextStyles.labelMedium,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.primaryTint,
        side: const BorderSide(color: AppColors.border),
        labelStyle: AppTextStyles.bodySmall,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.chipAll),
      ),

      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.border),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.inkSecondary,
        textColor: AppColors.ink,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.surface
              : AppColors.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.borderStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
        circularTrackColor: AppColors.border,
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primaryTint,
        selectionHandleColor: AppColors.primary,
      ),
    );
  }
}
