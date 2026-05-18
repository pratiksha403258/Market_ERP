// // import 'package:flutter/material.dart';

// // /// 🌿 FINAL — SAGE GREEN UI THEME (MATCHES YOUR IMAGE)

// // class AppColors {
// //   AppColors._();

// //   // 🌿 PRIMARY (SAGE GREEN)
// //   static const Color primary        = Color(0xFF7FAF5F);
// //   static const Color primaryLight   = Color(0xFF9BCB7A);
// //   static const Color primaryDark    = Color(0xFF5F8F45);

// //   // 🌿 GRADIENT (MAIN UI)
// //   static const LinearGradient primaryGradient = LinearGradient(
// //     colors: [
// //       Color(0xFF9BCB7A),
// //       Color(0xFF7FAF5F),
// //     ],
// //     begin: Alignment.topLeft,
// //     end: Alignment.bottomRight,
// //   );

// //   // 🌿 BACKGROUND (LIGHT UI)
// //   static const Color background = Color(0xFFF4F8F2);
// //   static const Color surface    = Color(0xFFFFFFFF);

// //   // 🌿 TEXT
// //   static const Color textPrimary   = Color(0xFF1E2B1E);
// //   static const Color textSecondary = Color(0xFF6B7D6B);
// //   static const Color textTertiary  = Color(0xFF9AA79A);
// //   static const Color textOnPrimary = Colors.white;

// //   // 🌿 BORDER
// //   static const Color border = Color(0xFFE2E8E0);

// //   // 🌿 SHADOW
// //   static const Color shadow = Color(0x14000000);

// //   // ✅ FIXED (WERE NULL → CAUSED ERRORS)
// //   static const Color textHint = Color(0xFF9AA79A);
// //   static const Color surfaceVariant = Color(0xFFF9FBF7);
// //   static const Color error = Color(0xFFE53935);

// //   // ✅ REQUIRED (USED IN YOUR FILES)
// //   static const Color success = Color(0xFF4CAF50);
// //   static const Color warning = Color(0xFFFF9800);
// //   static const Color info    = Color(0xFF2196F3);
// //   static const Color infoSurface = Color(0xFFE3F2FD);

// //   // ✅ USED IN LOGIN DIVIDER
// //   static const Color divider = Color(0xFFE0E0E0);
  
// //   // ✅ ADD MISSING COLORS USED IN DASHBOARD
// //   static const Color secondary   = Color(0xFF9BCB7A);
// //   static const Color shadowLight = Color(0x0D000000);
// // }

// // /// TEXT STYLES
// // class AppTextStyles {
// //   AppTextStyles._();

// //   static const String font = 'Poppins';

// //   // Basic styles
// //   static const TextStyle heading = TextStyle(
// //     fontFamily: font,
// //     fontSize: 20,
// //     fontWeight: FontWeight.w600,
// //     color: AppColors.textPrimary,
// //   );

// //   static const TextStyle body = TextStyle(
// //     fontFamily: font,
// //     fontSize: 14,
// //     color: AppColors.textSecondary,
// //   );

// //   static const TextStyle button = TextStyle(
// //     fontFamily: font,
// //     fontSize: 15,
// //     fontWeight: FontWeight.w600,
// //     color: AppColors.textOnPrimary,
// //   );

// //   // ✅ Extended styles (moved from extension)
// //   static const TextStyle headingLarge = TextStyle(
// //     fontSize: 22,
// //     fontWeight: FontWeight.w700,
// //     color: AppColors.textPrimary,
// //   );

// //   static const TextStyle headingMedium = TextStyle(
// //     fontSize: 18,
// //     fontWeight: FontWeight.w600,
// //     color: AppColors.textPrimary,
// //   );

// //   static const TextStyle headingSmall = TextStyle(
// //     fontSize: 16,
// //     fontWeight: FontWeight.w600,
// //     color: AppColors.textPrimary,
// //   );

// //   static const TextStyle bodyMedium = TextStyle(
// //     fontSize: 14,
// //     color: AppColors.textSecondary,
// //   );

// //   static const TextStyle bodySmall = TextStyle(
// //     fontSize: 12,
// //     color: AppColors.textSecondary,
// //   );

// //   static const TextStyle labelLarge = TextStyle(
// //     fontSize: 14,
// //     fontWeight: FontWeight.w600,
// //     color: AppColors.textPrimary,
// //   );

// //   static const TextStyle labelSmall = TextStyle(
// //     fontSize: 11,
// //     color: AppColors.textSecondary,
// //   );

// //   static const TextStyle numberSmall = TextStyle(
// //     fontSize: 16,
// //     fontWeight: FontWeight.bold,
// //     color: AppColors.textPrimary,
// //   );
// // }

// // /// RADIUS
// // class AppRadius {
// //   AppRadius._();
  
// //   static const BorderRadius sm = BorderRadius.all(Radius.circular(8));
// //   static const BorderRadius md = BorderRadius.all(Radius.circular(12));
// //   static const BorderRadius lg = BorderRadius.all(Radius.circular(16));
// //   static const BorderRadius xl = BorderRadius.all(Radius.circular(20));
// //   static const BorderRadius full = BorderRadius.all(Radius.circular(100));
  
// //   static const BorderRadius radiusSM = BorderRadius.all(Radius.circular(8));
// //   static const BorderRadius radiusMD = BorderRadius.all(Radius.circular(12));
// //   static const BorderRadius radiusLG = BorderRadius.all(Radius.circular(16));
// //   static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(20));
// //   static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(100));
// // }

// // /// SHADOW
// // class AppShadows {
// //   static List<BoxShadow> card = [
// //     BoxShadow(
// //       color: AppColors.shadow,
// //       blurRadius: 10,
// //       offset: const Offset(0, 4),
// //     )
// //   ];
// // }

// // /// SPACING
// // class AppSpacing {
// //   static const double xxs = 2;
// //   static const double xs  = 4;
// //   static const double sm  = 8;
// //   static const double md  = 12;
// //   static const double lg  = 16;
// //   static const double xl  = 24;
// //   static const double xxl = 32;
// // }

// // /// 🌿 THEME (LIGHT)
// // class AppTheme {
// //   static ThemeData get light => ThemeData(
// //         useMaterial3: true,
// //         fontFamily: 'Poppins',

// //         scaffoldBackgroundColor: AppColors.background,

// //         colorScheme: ColorScheme.light(
// //           primary: AppColors.primary,
// //           surface: AppColors.surface,
// //         ),

// //         appBarTheme: const AppBarTheme(
// //           backgroundColor: Colors.transparent,
// //           elevation: 0,
// //           foregroundColor: AppColors.textPrimary,
// //           centerTitle: false,
// //         ),

// //         elevatedButtonTheme: ElevatedButtonThemeData(
// //           style: ElevatedButton.styleFrom(
// //             backgroundColor: AppColors.primary,
// //             shape: RoundedRectangleBorder(
// //               borderRadius: AppRadius.md,
// //             ),
// //             minimumSize: const Size(double.infinity, 50),
// //             textStyle: AppTextStyles.button,
// //           ),
// //         ),

// //         inputDecorationTheme: InputDecorationTheme(
// //           filled: true,
// //           fillColor: AppColors.surface,
// //           hintStyle: const TextStyle(color: AppColors.textTertiary),
// //           border: OutlineInputBorder(
// //             borderRadius: AppRadius.md,
// //             borderSide: const BorderSide(color: AppColors.border),
// //           ),
// //           enabledBorder: OutlineInputBorder(
// //             borderRadius: AppRadius.md,
// //             borderSide: const BorderSide(color: AppColors.border),
// //           ),
// //           focusedBorder: OutlineInputBorder(
// //             borderRadius: AppRadius.md,
// //             borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
// //           ),
// //         ),
// //       );
// // }

// import 'package:flutter/material.dart';

// // ─────────────────────────────────────────────────────────────
// //  MARKET ERP — LIGHT THEME
// //  Inspired by: Lime-green agriculture palette (like sample images)
// //  Primary: Fresh lime-green on white/cream backgrounds
// // ─────────────────────────────────────────────────────────────

// class AppColors {
//   AppColors._();

//   // ── Primary ──────────────────────────────────────────────────
//   static const Color primary        = Color(0xFF3A6B1A);
//   static const Color primaryLight   = Color(0xFF5A8F2E);
//   static const Color primaryDark    = Color(0xFF2A4F10);
//   static const Color primarySurface = Color(0xFFEDF3E6);

//   // ── Gradient ─────────────────────────────────────────────────
//   static const LinearGradient primaryGradient = LinearGradient(
//     colors: [Color(0xFF4A7C22), Color(0xFF2A4F10)],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );

//   static const LinearGradient heroGradient = LinearGradient(
//     colors: [Color(0xFF4A7C22), Color(0xFF2A4F10)],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );

//   // ── Background / Surface ─────────────────────────────────────
//   static const Color background     = Color(0xFFF8FAF4);
//   static const Color surface        = Color(0xFFFFFFFF);
//   static const Color surfaceVariant = Color(0xFFF3F7EC);
//   static const Color cardBackground = Color(0xFFFFFFFF);

//   // ── Text ─────────────────────────────────────────────────────
//   static const Color textPrimary   = Color(0xFF1C2A0E);   // ← was missing
//   static const Color textSecondary = Color(0xFF3A6B1A);
//   static const Color textHint      = Color(0xFF7A9B6A);
//   static const Color textOnPrimary = Color(0xFFFFFFFF);   // ← was missing

//   // ── Semantic ─────────────────────────────────────────────────
//   static const Color success        = Color(0xFF2E7D32);
//   static const Color successSurface = Color(0xFFE8F5E9);
//   static const Color error          = Color(0xFFD32F2F);
//   static const Color errorSurface   = Color(0xFFFFEBEE);
//   static const Color warning        = Color(0xFFF57F17);
//   static const Color warningSurface = Color(0xFFFFF8E1);
//   static const Color info           = Color(0xFF1565C0);
//   static const Color infoSurface    = Color(0xFFE3F2FD);

//   // ── Accent / Secondary ───────────────────────────────────────
//   static const Color secondary     = Color(0xFFE8A000);
//   static const Color secondarySurf = Color(0xFFFFF8E1);

//   // ── Border / Divider ─────────────────────────────────────────
//   static const Color border    = Color(0xFFC5D9A8);
//   static const Color borderFocus = Color(0xFF3A6B1A);
//   static const Color divider   = Color(0xFFDCEAC8);

//   // ── Shadow ───────────────────────────────────────────────────
//   static const Color shadowLight  = Color(0x143A6B1A);
//   static const Color shadowMedium = Color(0x203A6B1A);
// }

// // ─────────────────────────────────────────────────────────────
// //  TEXT STYLES
// // ─────────────────────────────────────────────────────────────
// class AppTextStyles {
//   AppTextStyles._();

//   static const String _font = 'Poppins';

//   static const TextStyle displayLarge = TextStyle(
//     fontFamily: _font, fontSize: 32, fontWeight: FontWeight.w700,
//     color: AppColors.textPrimary, letterSpacing: -0.5,
//   );
//   static const TextStyle headingLarge = TextStyle(
//     fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w700,
//     color: AppColors.textPrimary,
//   );
//   static const TextStyle headingMedium = TextStyle(
//     fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w600,
//     color: AppColors.textPrimary,
//   );
//   static const TextStyle headingSmall = TextStyle(
//     fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w600,
//     color: AppColors.textPrimary,
//   );
//   static const TextStyle bodyLarge = TextStyle(
//     fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w400,
//     color: AppColors.textPrimary,
//   );
//   static const TextStyle bodyMedium = TextStyle(
//     fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w400,
//     color: AppColors.textSecondary,
//   );
//   static const TextStyle bodySmall = TextStyle(
//     fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w400,
//     color: AppColors.textHint,
//   );
//   static const TextStyle labelLarge = TextStyle(
//     fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w600,
//     color: AppColors.textPrimary,
//   );
//   static const TextStyle labelSmall = TextStyle(
//     fontFamily: _font, fontSize:  12 , fontWeight: FontWeight.w500,
//     color: AppColors.textHint, letterSpacing: 0.4,
//   );
//   static const TextStyle buttonText = TextStyle(
//     fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w600,
//     color: AppColors.textOnPrimary, letterSpacing: 0.2,
//   );
//   static const TextStyle numberLarge = TextStyle(
//     fontFamily: _font, fontSize: 24, fontWeight: FontWeight.w700,
//     color: AppColors.textPrimary,
//   );
//   static const TextStyle numberSmall = TextStyle(
//     fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w700,
//     color: AppColors.textPrimary,
//   );
// }

// // ─────────────────────────────────────────────────────────────
// //  SPACING
// // ─────────────────────────────────────────────────────────────
// class AppSpacing {
//   AppSpacing._();
//   static const double xxs = 2.0;
//   static const double xs  = 4.0;
//   static const double sm  = 8.0;
//   static const double md  = 12.0;
//   static const double lg  = 16.0;
//   static const double xl  = 20.0;
//   static const double xxl = 24.0;
//   static const double h   = 32.0;
//   static const double xh  = 40.0;
// }

// // ─────────────────────────────────────────────────────────────
// //  BORDER RADIUS
// // ─────────────────────────────────────────────────────────────
// class AppRadius {
//   AppRadius._();
//   static const double sm  = 8.0;
//   static const double md  = 12.0;
//   static const double lg  = 16.0;
//   static const double xl  = 20.0;
//   static const double xxl = 28.0;
//   static const double full = 100.0;

//   static BorderRadius radiusSM  = BorderRadius.circular(sm);
//   static BorderRadius radiusMD  = BorderRadius.circular(md);
//   static BorderRadius radiusLG  = BorderRadius.circular(lg);
//   static BorderRadius radiusXL  = BorderRadius.circular(xl);
//   static BorderRadius radiusXXL = BorderRadius.circular(xxl);
//   static BorderRadius radiusFull= BorderRadius.circular(full);
// }

// // ─────────────────────────────────────────────────────────────
// //  APP THEME
// // ─────────────────────────────────────────────────────────────
// class AppTheme {
//   AppTheme._();

//   static ThemeData get light => ThemeData(
//     useMaterial3: true,
//     fontFamily: 'Poppins',
//     brightness: Brightness.light,
//     colorScheme: ColorScheme.fromSeed(
//       seedColor: AppColors.primary,
//       primary: AppColors.primary,
//       surface: AppColors.surface,
//       error: AppColors.error,
//     ),
//     scaffoldBackgroundColor: AppColors.background,
//     appBarTheme: const AppBarTheme(
//       backgroundColor: AppColors.surface,
//       foregroundColor: AppColors.textPrimary,
//       elevation: 0,
//       centerTitle: false,
//       titleTextStyle: TextStyle(
        
//         fontFamily: 'Poppins', fontSize: 18,
//         fontWeight: FontWeight.w600, color: AppColors.textPrimary,
//       ),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: AppColors.primary,
//         foregroundColor: AppColors.textOnPrimary,
//         elevation: 0,
//         minimumSize: const Size(double.infinity, 52),
//         shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
//         textStyle: AppTextStyles.buttonText,
//       ),
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       filled: true,
//       fillColor: AppColors.surfaceVariant,
//       hintStyle: AppTextStyles.bodyMedium,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       border: OutlineInputBorder(borderRadius: AppRadius.radiusMD,
//           borderSide: const BorderSide(color: AppColors.border)),
//       enabledBorder: OutlineInputBorder(borderRadius: AppRadius.radiusMD,
//           borderSide: const BorderSide(color: AppColors.border)),
//       focusedBorder: OutlineInputBorder(borderRadius: AppRadius.radiusMD,
//           borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
//       errorBorder: OutlineInputBorder(borderRadius: AppRadius.radiusMD,
//           borderSide: const BorderSide(color: AppColors.error)),
//       focusedErrorBorder: OutlineInputBorder(borderRadius: AppRadius.radiusMD,
//           borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
//     ),
//     dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
//     // cardTheme:CardTheme(
//     //   color: AppColors.surface,
//     //   elevation: 0,
//     //   shape: RoundedRectangleBorder(
//     //     borderRadius: AppRadius.radiusLG,
//     //     side: const BorderSide(color: AppColors.border),
//     //   ),
//     // ),
//   );
// }

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  APP THEME — GOGREEN PALETTE
//  Extracted from design reference (Image 2 color swatches)
//
//  FFFFFF  → White        (pure surface / cards)
//  888B80  → Grey-green   (secondary / muted text)
//  264131  → Forest dark  (headings / primary dark)
//  3C3C43  → Charcoal     (body text)
//  9EA199  → Sage grey    (hint / placeholder text)
//  2D6936  → Forest green (primary / icon accent)
//  F5F5F5  → Off-white    (scaffold background)
//  37623D  → Button green (primary button bg — 84%)
//  47734D  → Button light (button hover / variant — 85%)
//  E7E8E3  → Warm grey    (card / surface variant bg)
// ─────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Primary (Forest Greens) ───────────────────────────────────
  /// Deep forest green — headings, logo text, primary dark
  static const Color primaryDark    = Color(0xFF264131);

  /// Core forest green — primary actions, icons, active states
  static const Color primary        = Color(0xFF2D6936);

  /// Button green — ElevatedButton background (37623D @ 84%)
  static const Color primaryButton  = Color(0xFF37623D);

  /// Button variant — hover / secondary button (47734D @ 85%)
  static const Color primaryLight   = Color(0xFF47734D);

  /// Soft tint surface for primary — chips, badges, tag bg
  static const Color primarySurface = Color(0xFFE7E8E3);

  // ── Gradient ─────────────────────────────────────────────────
  /// Used on splash / hero screens (dark forest → medium forest)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2D6936), Color(0xFF264131)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF37623D), Color(0xFF264131)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Background / Surface ─────────────────────────────────────
  /// Scaffold / page background — F5F5F5 off-white
  static const Color background     = Color(0xFFF5F5F5);

  /// Pure white — card, modal, input fill
  static const Color surface        = Color(0xFFFFFFFF);

  /// Warm grey — card variant, section bg, list tile bg
  static const Color surfaceVariant = Color(0xFFE7E8E3);

  /// Same as surface — named alias for card bg
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ── Text ─────────────────────────────────────────────────────
  /// Headings / titles — deep forest green (264131)
  static const Color textPrimary    = Color(0xFF264131);

  /// Body text — dark charcoal (3C3C43)
  static const Color textSecondary  = Color(0xFF3C3C43);

  /// Muted / secondary labels — grey-green (888B80)
  static const Color textMuted      = Color(0xFF888B80);

  /// Hint / placeholder — sage grey (9EA199)
  static const Color textHint       = Color(0xFF9EA199);

  /// Text on primary colored surface (buttons, badges)
  static const Color textOnPrimary  = Color(0xFFFFFFFF);

  // ── Border / Divider ─────────────────────────────────────────
  /// Default border — muted sage grey
  static const Color border         = Color(0xFF9EA199);

  /// Subtle border — warm grey surface shade
  static const Color borderSubtle   = Color(0xFFE7E8E3);

  /// Focus border — primary green
  static const Color borderFocus    = Color(0xFF2D6936);

  /// Divider lines
  static const Color divider        = Color(0xFFE7E8E3);

  // ── Shadow ───────────────────────────────────────────────────
  static const Color shadowLight    = Color(0x14264131);
  static const Color shadowMedium   = Color(0x20264131);

  // ── Semantic ─────────────────────────────────────────────────
  static const Color success        = Color(0xFF2D6936);
  static const Color successSurface = Color(0xFFE7E8E3);
  static const Color error          = Color(0xFFD32F2F);
  static const Color errorSurface   = Color(0xFFFFEBEE);
  static const Color warning        = Color(0xFFF57F17);
  static const Color warningSurface = Color(0xFFFFF8E1);
  static const Color info           = Color(0xFF1565C0);
  static const Color infoSurface    = Color(0xFFE3F2FD);

  // ── Secondary / Accent ───────────────────────────────────────
  static const Color secondary      = Color(0xFF888B80);
  static const Color secondarySurf  = Color(0xFFE7E8E3);
}

// ─────────────────────────────────────────────────────────────
//  TEXT STYLES — GoGreen Typography
//  Headings   → textPrimary  (264131 deep forest)
//  Body       → textSecondary (3C3C43 charcoal)
//  Muted/hint → textHint     (9EA199 sage grey)
//  On-button  → white
// ─────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static const String _font = 'Poppins';

  /// Large display — splash / hero titles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  /// Page / section headings (large)
  static const TextStyle headingLarge = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Card / modal headings
  static const TextStyle headingMedium = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// List tile titles / small headings
  static const TextStyle headingSmall = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Large body — readable paragraphs
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Standard body — descriptions, captions
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Small body — footnotes, tags, timestamps
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  /// Form labels / chip labels
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Tiny labels — badge counts, overlines
  static const TextStyle labelSmall = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
    letterSpacing: 0.4,
  );

  /// Button text — always white on green button
  static const TextStyle buttonText = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.2,
  );

  /// Dashboard numbers / KPI values (large)
  static const TextStyle numberLarge = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Dashboard numbers / KPI values (small)
  static const TextStyle numberSmall = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}

// ─────────────────────────────────────────────────────────────
//  SPACING
// ─────────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
  static const double xxl = 24.0;
  static const double h   = 32.0;
  static const double xh  = 40.0;
}

// ─────────────────────────────────────────────────────────────
//  BORDER RADIUS
// ─────────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 28.0;
  static const double full = 100.0;

  static BorderRadius radiusSM   = BorderRadius.circular(sm);
  static BorderRadius radiusMD   = BorderRadius.circular(md);
  static BorderRadius radiusLG   = BorderRadius.circular(lg);
  static BorderRadius radiusXL   = BorderRadius.circular(xl);
  static BorderRadius radiusXXL  = BorderRadius.circular(xxl);
  static BorderRadius radiusFull = BorderRadius.circular(full);
}

// ─────────────────────────────────────────────────────────────
//  SHADOWS
// ─────────────────────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get button => [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────
//  APP THEME
// ─────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,

    // ── Color scheme ──────────────────────────────────────────
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.error,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: AppColors.background,

    // ── AppBar ────────────────────────────────────────────────
    // Clean white AppBar matching card surfaces
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),

    // ── Elevated Button ───────────────────────────────────────
    // Forest green button — matches 37623D from palette
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryButton,
        foregroundColor: AppColors.textOnPrimary,
        disabledBackgroundColor: AppColors.surfaceVariant,
        disabledForegroundColor: AppColors.textHint,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusFull, // pill shape like in image
        ),
        textStyle: AppTextStyles.buttonText,
      ),
    ),

    // ── Outlined Button ───────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusFull,
        ),
        textStyle: AppTextStyles.buttonText.copyWith(
          color: AppColors.primary,
        ),
      ),
    ),

    // ── Text Button ───────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.labelLarge,
      ),
    ),

    // ── Input / TextField ─────────────────────────────────────
    // Clean white fill with subtle border — matches design cards
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
      labelStyle: AppTextStyles.labelLarge,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AppRadius.radiusMD,
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusMD,
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusMD,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusMD,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusMD,
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),

    // ── Card ──────────────────────────────────────────────────
    // White card with very subtle border — like the image panels
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLG,
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
    ),

    // ── Divider ───────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),

    // ── Bottom NavBar ─────────────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    ),

    // ── NavigationBar (Material 3) ────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primarySurface,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary);
        }
        return const IconThemeData(color: AppColors.textHint);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          );
        }
        return const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.textHint,
        );
      }),
    ),

    // ── Chip ─────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primarySurface,
      labelStyle: AppTextStyles.labelSmall,
      side: const BorderSide(color: AppColors.borderSubtle),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusFull),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),

    // ── Switch ────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.surface
            : AppColors.textHint;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.surfaceVariant;
      }),
    ),

    // ── Checkbox ──────────────────────────────────────────────
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.primary
            : Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.surface),
      side: const BorderSide(color: AppColors.border, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSM),
    ),

    // ── ListTile ──────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      tileColor: AppColors.surface,
      iconColor: AppColors.primary,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        color: AppColors.textMuted,
      ),
    ),

    // ── Icon ──────────────────────────────────────────────────
    iconTheme: const IconThemeData(
      color: AppColors.primary,
      size: 22,
    ),
  );
}