import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/constants.dart';
import 'utils/supabase_config.dart';
import 'widgets/responsive_wrapper.dart';
import 'screens/auth_wrapper.dart';
import 'screens/splash_screen.dart';
import 'screens/traveler/identity_verification_screen.dart';
import 'screens/traveler/traveler_main_page.dart';
import 'screens/requester/requester_main_page.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (guarded for Flutter Web)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      debugPrint("✅ Firebase initialized successfully!");
    } catch (e) {
      debugPrint("⚠️ Firebase initialization skipped or failed: $e");
    }
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  debugPrint("✅ Supabase successfully initialized for Main User App!");

  runApp(const MainUserApp());
}

class MainUserApp extends StatelessWidget {
  const MainUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pasabay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: AppConstants.fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          primary: AppConstants.primaryColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.defaultBorderRadius,
              ),
            ),
          ),
        ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final isDesktop =
            mediaQuery.size.width > AppConstants.maxContainerWidth;
        final mobileWidth =
            isDesktop ? AppConstants.maxContainerWidth : mediaQuery.size.width;

        return ResponsiveWrapper(
          child: MediaQuery(
            data: mediaQuery.copyWith(
              size: Size(mobileWidth, mediaQuery.size.height),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const SplashScreen(
        nextScreen: AuthWrapper(),
      ),
      routes: {
        '/identity_verification': (context) =>
            const IdentityVerificationScreen(),
        '/traveler_home': (context) => const TravelerMainPage(),
        '/requester_home': (context) => const RequesterMainPage(),
      },
    );
  }
}
