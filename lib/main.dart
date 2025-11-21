import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../utils/supabase_config.dart';
import '../widgets/responsive_wrapper.dart';
import '../screens/auth_wrapper.dart';
import '../screens/landing_page.dart';
import '../screens/traveler/identity_verification_screen.dart';
import '../screens/traveler_home_page.dart';
import '../screens/requester/requester_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  print("✅ Supabase successfully initialized for Main User App!");

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
      ),
      home: const ResponsiveWrapper(child: AuthWrapper()),
      routes: {
        '/identity_verification': (context) =>
            const IdentityVerificationScreen(),
        '/traveler_home': (context) => const TravelerHomePage(),
        '/requester_home': (context) => const RequesterHomePage(),
      },
    );
  }
}
