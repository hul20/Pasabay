import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/constants.dart';
import 'utils/supabase_config.dart';
import 'widgets/responsive_wrapper.dart';
import 'screens/landing_page.dart';
import 'screens/traveler/identity_verification_screen.dart';
import 'screens/traveler_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  print("✅ Supabase successfully initialized!");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pasabay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: AppConstants.fontFamily,
      ),
      home: const ResponsiveWrapper(child: LandingPage()),
      routes: {
        '/identity_verification': (context) =>
            const IdentityVerificationScreen(),
        '/traveler_home': (context) => const TravelerHomePage(),
      },
    );
  }
}
