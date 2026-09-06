import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    // The UI remains available for preview before `flutterfire configure`.
    // AuthService shows a clear setup error instead of bypassing sign-in.
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const villageSage = Color(0xFF6D7C5A);
    const warmCream = Color(0xFFF7EFE1);
    const deepSlate = Color(0xFF2F3A2E);

    return MaterialApp(
      title: 'Ask the Village',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: villageSage,
          brightness: Brightness.light,
          primary: villageSage,
          onPrimary: Colors.white,
          surface: warmCream,
        ),
        scaffoldBackgroundColor: warmCream,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme.apply(
                bodyColor: deepSlate,
                displayColor: deepSlate,
              ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: warmCream,
          elevation: 0,
          foregroundColor: deepSlate,
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
