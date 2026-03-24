import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_treatment_screen.dart';
import 'doctor_selection_screen.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Inicializar sqflite_common_ffi para Windows
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _darkModePreferenceKey = 'dark_mode_enabled';
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkModeEnabled = prefs.getBool(_darkModePreferenceKey) ?? false;
    if (!mounted) return;
    setState(() {
      _themeMode = isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _setDarkMode(bool isDarkModeEnabled) {
    setState(() {
      _themeMode = isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_darkModePreferenceKey, isDarkModeEnabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightPalette = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B6E6E),
      brightness: Brightness.light,
    ).copyWith(
      secondary: const Color(0xFF0EA5A4),
      tertiary: const Color(0xFFF59E0B),
    );

    final darkPalette = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B6E6E),
      brightness: Brightness.dark,
    ).copyWith(
      secondary: const Color(0xFF2DD4BF),
      tertiary: const Color(0xFFFBBF24),
    );

    final base = ThemeData(
      colorScheme: lightPalette,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF1F5F7),
      fontFamily: 'Segoe UI',
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return MaterialApp(
      title: 'Clinicash',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: base.copyWith(
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shadowColor: const Color(0x1A0F172A),
          surfaceTintColor: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF0B6E6E), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 50),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            backgroundColor: lightPalette.secondary,
            foregroundColor: lightPalette.onSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: lightPalette.tertiary,
          foregroundColor: lightPalette.onTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        chipTheme: base.chipTheme.copyWith(
          side: const BorderSide(color: Color(0xFFD1DCE5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkPalette,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        fontFamily: 'Segoe UI',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ).copyWith(
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shadowColor: Colors.transparent,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF111827),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 50),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            backgroundColor: darkPalette.secondary,
            foregroundColor: darkPalette.onSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            side: const BorderSide(color: Color(0xFF334155)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: darkPalette.tertiary,
          foregroundColor: darkPalette.onTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        chipTheme: ChipThemeData(
          side: const BorderSide(color: Color(0xFF334155)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: const DoctorSelectionScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/add': (context) => AddTreatmentScreen(),
        '/history': (context) => HistoryScreen(),
        '/settings': (context) => SettingsScreen(onThemeChanged: _setDarkMode),
      },
    );
  }
}
