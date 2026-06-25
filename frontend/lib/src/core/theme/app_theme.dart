import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Background (legacy — prefer AppColorTokens in new code)
  static const Color background = Color(0xFF0D0F14);
  static const Color backgroundEnd = Color(0xFF16100A);

  static const Color white = Color(0xFF1C1C26);
  static const Color surface = Color(0xFF1C1C26);
  static const Color surfaceElevated = Color(0xFF252532);

  static const Color orange = Color(0xFFFF6B35);
  static const Color peach = Color(0xFFFFB347);
  static const Color softPeach = Color(0xFF2A1C10);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [orange, peach],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, backgroundEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient progressGradient = LinearGradient(
    colors: [orange, peach],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x4D000000), // black with 0.3 opacity
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const Color kakaoYellow = Color(0xFFFEE500);
  static const Color googleWhite = Color(0xFFFFFFFF);
  static const Color appleBlack = Color(0xFF000000);

  static const Color textPrimary = Color(0xFFF2F2F2);
  static const Color textSecondary = Color(0xFF9898B2);
  static const Color textTertiary = Color(0xFF8585A5);
  static const Color divider = Color(0xFF2A2A38);

  static const Color proteinColor = Color(0xFF7BD3FF);
  static const Color carbsColor = Color(0xFFFFB347);
  static const Color fatColor = Color(0xFFFF6B9D);

  static const Color surfaceDark = Color(0xFF1A1A22);
  static const Color iconDisabled = Color(0x66858585);
  static const Color masterGold = Color(0xFFFFD700);

  // Light Mode Colors
  static const Color lightBackground = Color(0xFFFDF8F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF2A1F15);
  static const Color lightTextSecondary = Color(0xA62A1F15);
  static const Color lightTextTertiary = Color(0x662A1F15);
  static const Color lightDivider = Color(0xFFE8DDD4);
  static const Color lightPrimaryBg = Color(0x1AFF7A3D);
  static const Color lightHeroBg = Color(0xFFFFE8D1);
  static const Color lightHeroBgEnd = Color(0xFFFFD1B3);
}

/// Per-variant design tokens. Access via Theme.of(context).extension<AppColorTokens>()!
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  final Color bg;
  final Color card;
  final Color listItemBg;
  final Color textPrimary;
  final Color textSub;
  final Color textMuted;
  final Color primary;
  final Color primarySoft;
  final Color primaryBg;
  // Text on the hero card (always a light background in both themes)
  final Color heroText;
  final Color heroTextSub;
  final Color paper;
  final Color paperLine;
  final Color divider;
  final Gradient bgGrad;
  final Gradient cardHeroGrad;
  final Gradient charBgNormal;
  final Gradient charBgHungry;
  final Gradient charBgStarving;
  final double rHero;
  final double rCard;
  final double rItem;

  const AppColorTokens({
    required this.bg,
    required this.card,
    required this.listItemBg,
    required this.textPrimary,
    required this.textSub,
    required this.textMuted,
    required this.primary,
    required this.primarySoft,
    required this.primaryBg,
    required this.heroText,
    required this.heroTextSub,
    required this.paper,
    required this.paperLine,
    required this.divider,
    required this.bgGrad,
    required this.cardHeroGrad,
    required this.charBgNormal,
    required this.charBgHungry,
    required this.charBgStarving,
    this.rHero = 32,
    this.rCard = 22,
    this.rItem = 14,
  });

  static const hybrid = AppColorTokens(
    bg: Color(0xFF14110E),
    card: Color(0xFF201A14),
    listItemBg: Color(0x0AFFDCB4),
    textPrimary: Color(0xFFFBF4E8),
    textSub: Color(0xA6FBF4E8),
    textMuted: Color(0x66FBF4E8),
    primary: Color(0xFFFF7A3D),
    primarySoft: Color(0xFFFFC26B),
    primaryBg: Color(0x24FF7A3D),
    heroText: Color(0xFF3A2010),
    heroTextSub: Color(0xA63A2010),
    paper: Color(0xFFFAFAFA),
    paperLine: Color(0x14000000),
    divider: Color(0x1FFBF4E8),
    bgGrad: LinearGradient(
      colors: [Color(0xFF14110E), Color(0xFF1C1611)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardHeroGrad: LinearGradient(
      colors: [Color(0xFFF5E6D3), Color(0xFFE8C89A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    charBgNormal: LinearGradient(
      colors: [Color(0xFFF5E6D3), Color(0xFFE8C89A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    charBgHungry: LinearGradient(
      colors: [Color(0xFFF5DFB8), Color(0xFFD9B272)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    charBgStarving: LinearGradient(
      colors: [Color(0xFFE6BDB0), Color(0xFFC98878)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const light = AppColorTokens(
    bg: AppColors.lightBackground,
    card: AppColors.lightSurface,
    listItemBg: Color(0x99FFE0C8),
    textPrimary: AppColors.lightTextPrimary,
    textSub: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextTertiary,
    primary: AppColors.orange,
    primarySoft: Color(0xFFFFB582),
    primaryBg: AppColors.lightPrimaryBg,
    heroText: AppColors.lightTextPrimary,
    heroTextSub: AppColors.lightTextSecondary,
    paper: Color(0xFFFAFAFA),
    paperLine: Color(0x14000000),
    divider: AppColors.lightDivider,
    bgGrad: LinearGradient(
      colors: [AppColors.lightBackground, Color(0xFFF8EFE3)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    cardHeroGrad: LinearGradient(
      colors: [AppColors.lightHeroBg, AppColors.lightHeroBgEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    charBgNormal: LinearGradient(
      colors: [AppColors.lightHeroBg, AppColors.lightHeroBgEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    charBgHungry: LinearGradient(
      colors: [Color(0xFFFFF0CC), Color(0xFFFFD980)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    charBgStarving: LinearGradient(
      colors: [Color(0xFFFFDDD5), Color(0xFFFFB0A0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  @override
  AppColorTokens copyWith({
    Color? bg,
    Color? card,
    Color? listItemBg,
    Color? textPrimary,
    Color? textSub,
    Color? textMuted,
    Color? primary,
    Color? primarySoft,
    Color? primaryBg,
    Color? heroText,
    Color? heroTextSub,
    Color? paper,
    Color? paperLine,
    Color? divider,
    Gradient? bgGrad,
    Gradient? cardHeroGrad,
    Gradient? charBgNormal,
    Gradient? charBgHungry,
    Gradient? charBgStarving,
    double? rHero,
    double? rCard,
    double? rItem,
  }) {
    return AppColorTokens(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      listItemBg: listItemBg ?? this.listItemBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSub: textSub ?? this.textSub,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryBg: primaryBg ?? this.primaryBg,
      heroText: heroText ?? this.heroText,
      heroTextSub: heroTextSub ?? this.heroTextSub,
      paper: paper ?? this.paper,
      paperLine: paperLine ?? this.paperLine,
      divider: divider ?? this.divider,
      bgGrad: bgGrad ?? this.bgGrad,
      cardHeroGrad: cardHeroGrad ?? this.cardHeroGrad,
      charBgNormal: charBgNormal ?? this.charBgNormal,
      charBgHungry: charBgHungry ?? this.charBgHungry,
      charBgStarving: charBgStarving ?? this.charBgStarving,
      rHero: rHero ?? this.rHero,
      rCard: rCard ?? this.rCard,
      rItem: rItem ?? this.rItem,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      listItemBg: Color.lerp(listItemBg, other.listItemBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSub: Color.lerp(textSub, other.textSub, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      primaryBg: Color.lerp(primaryBg, other.primaryBg, t)!,
      heroText: Color.lerp(heroText, other.heroText, t)!,
      heroTextSub: Color.lerp(heroTextSub, other.heroTextSub, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      paperLine: Color.lerp(paperLine, other.paperLine, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      // Gradient lerp across dark↔light is jarring; snap at midpoint
      bgGrad: t < 0.5 ? bgGrad : other.bgGrad,
      cardHeroGrad: t < 0.5 ? cardHeroGrad : other.cardHeroGrad,
      charBgNormal: t < 0.5 ? charBgNormal : other.charBgNormal,
      charBgHungry: t < 0.5 ? charBgHungry : other.charBgHungry,
      charBgStarving: t < 0.5 ? charBgStarving : other.charBgStarving,
      rHero: lerpDouble(rHero, other.rHero, t),
      rCard: lerpDouble(rCard, other.rCard, t),
      rItem: lerpDouble(rItem, other.rItem, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

class AppTheme {
  static final ThemeData hybridTheme = _buildTheme(AppColorTokens.hybrid, Brightness.dark);
  static final ThemeData lightTheme = _buildTheme(AppColorTokens.light, Brightness.light);
  static ThemeData get darkTheme => hybridTheme;

  static ThemeData _buildTheme(AppColorTokens tokens, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseTextTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

    final textTheme = GoogleFonts.notoSansKrTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.poppins(fontSize: 57, fontWeight: FontWeight.w800, color: tokens.textPrimary),
      displayMedium: GoogleFonts.poppins(fontSize: 45, fontWeight: FontWeight.w700, color: tokens.textPrimary),
      displaySmall: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w700, color: tokens.textPrimary),
      headlineLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: tokens.textPrimary),
      headlineMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: tokens.textPrimary),
      headlineSmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: tokens.textPrimary),
    ).apply(
      bodyColor: tokens.textPrimary,
      displayColor: tokens.textPrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tokens.primary,
        brightness: brightness,
      ).copyWith(
        surface: tokens.card,
        onSurface: tokens.textPrimary,
      ),
      textTheme: textTheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: tokens.bg,
      extensions: [tokens],

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.rCard)),
        color: tokens.card,
        shadowColor: Colors.transparent,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: tokens.textPrimary,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: tokens.textPrimary,
        ),
        iconTheme: IconThemeData(color: tokens.textSub),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.card,
        elevation: 0,
        indicatorColor: tokens.primaryBg,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            color: states.contains(WidgetState.selected) ? tokens.primary : tokens.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? tokens.primary : tokens.textMuted,
          ),
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: tokens.primary,
        thumbColor: tokens.primary,
        inactiveTrackColor: isDark ? AppColors.divider : const Color(0xFFE0D8D0),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.primary,
        linearMinHeight: 8,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceElevated : const Color(0xFFF0EAE2),
        hintStyle: TextStyle(color: tokens.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.divider : const Color(0xFFD8CCC0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.primary, width: 2),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: isDark ? AppColors.divider : const Color(0xFFD8CCC0)),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: tokens.primary,
        unselectedLabelColor: tokens.textSub,
        indicatorColor: tokens.primary,
      ),

      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.divider : const Color(0xFFE8DDD4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: tokens.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.card,
        contentTextStyle: TextStyle(color: tokens.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(tokens.card),
        ),
      ),
    );
  }
}
