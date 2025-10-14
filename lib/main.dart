import 'package:flutter/material.dart';
import 'utils/constants.dart';
import 'widgets/responsive_wrapper.dart';
import 'screens/landing_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    );
  }
}
