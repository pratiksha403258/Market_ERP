import 'package:agr_market/features/auth/screens/language_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/colors.dart';
import 'core/splash/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
// import 'features/auth/screens/register_screen.dart';
import 'features/navigation/main_navigation_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MarketErpApp(),
    ),
  );
}

class MarketErpApp extends StatelessWidget {
  const MarketErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Market ERP',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: '/splash',
      routes: {
        '/splash':    (_) => const SplashScreen(),
        '/login':     (_) => const LoginScreen(),
        // '/register':  (_) => const RegisterScreen(),
        '/language':  (_) => const LanguageSelectionScreen(),  // ← NEW
        '/home':      (_) => const MainNavigationScreen(),      // ← Updated to full nav
      },
    );
  }

ThemeData _buildTheme() {
  const poppins = 'Poppins';

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),

    scaffoldBackgroundColor: AppColors.background,
    fontFamily: poppins,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: poppins,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: TextStyle(color: AppColors.textHint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
  );
}
}