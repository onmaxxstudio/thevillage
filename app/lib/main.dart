import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'navigation/village_app_shell.dart';
import 'screens/village_promise_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';

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
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
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
      home: Firebase.apps.isEmpty
          ? const WelcomeScreen()
          : const _AuthGate(),
    );
  }
}


class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      initialData: auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const WelcomeScreen();
        return _SignedInDestination(auth: auth);
      },
    );
  }
}

class _SignedInDestination extends StatefulWidget {
  const _SignedInDestination({required this.auth});

  final AuthService auth;

  @override
  State<_SignedInDestination> createState() => _SignedInDestinationState();
}

class _SignedInDestinationState extends State<_SignedInDestination> {
  late final Future<bool> acceptedPromise =
      widget.auth.hasAcceptedVillagePromise();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: acceptedPromise,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!
            ? const VillageAppShell()
            : const VillagePromiseScreen();
      },
    );
  }
}
