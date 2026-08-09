import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/welcome_screen.dart';

void main() {
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
      title: 'The Village',
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
