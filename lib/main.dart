import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:municipal_e_challan/pages/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:municipal_e_challan/utils/payment_config.dart';
import 'package:municipal_e_challan/services/service_locator.dart';
import 'package:municipal_e_challan/cubits/challan_types_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Create this class (e.g., in your main.dart or a separate http_overrides.dart file)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              true; // <<< DANGER: Always trusts
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize HTTP overrides
  HttpOverrides.global = MyHttpOverrides();
  
  // Initialize payment configuration based on build flavor
  // This configures the vizpay plugin to use the correct ICICI payment app:
  // - Development: com.icici.viz.verifone
  // - Production: com.icici.viz.pax
  await PaymentConfig.initialize();
  
  // Initialize service locator
  await setupServiceLocator();
  
  // Load challan types at startup if user is already logged in
  // This ensures the data is ready when forms are opened
  await _initializeChallanTypes();
  
  runApp(const MyApp());
}

/// Initialize challan types if user has an access token
/// 
/// This loads challan types early during app startup to improve
/// performance when opening forms later. Uses unawaited to prevent
/// blocking app startup.
Future<void> _initializeChallanTypes() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    // Only load if user is logged in
    if (token != null && token.isNotEmpty) {
      final cubit = getIt<ChallanTypesCubit>();
      // Use unawaited to prevent blocking app startup
      unawaited(cubit.loadChallanTypes());
    }
  } catch (e) {
    // Don't block app startup if challan types fail to load
    // They can be retried later from the UI
    print('[main] Failed to preload challan types: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Municipal E-Challan',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFF00897B),
          tertiary: const Color(0xFF26A69A),
          background: const Color(0xFFF5F5F5),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
        ),
      ),
      home: SplashScreen(),
    );
  }
}
