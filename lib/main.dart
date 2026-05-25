import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/kids/home_screen.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Autism App',
          theme: ThemeData(useMaterial3: true),

          locale: localeController.locale,
          supportedLocales: AppLocalizations.supportedLocales,

          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          home: const InitializerScreen(),
        );
      },
    );
  }
}

class InitializerScreen extends StatefulWidget {
  const InitializerScreen({super.key});

  @override
  State<InitializerScreen> createState() => _InitializerScreenState();
}

class _InitializerScreenState extends State<InitializerScreen> {
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _bootApp();
  }

  Future<void> _bootApp() async {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 15));
      if (!mounted) return;

      await Future.delayed(const Duration(seconds: 1));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      debugPrint("Boot Error: $e");
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF1C1),
      body: Center(
        child: _error
            ? Text(t.t('firebase_error'))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF24324A)),
                  const SizedBox(height: 20),
                  Text(
                    t.t('loading_world'),
                    style: const TextStyle(
                      color: Color(0xFF24324A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
