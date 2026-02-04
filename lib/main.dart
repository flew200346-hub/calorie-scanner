import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'login_page.dart';
import 'app_shell.dart';

// ✅ เพิ่ม: ฉากตามเวลา (เช้า/เที่ยง/เย็น/ดึก)
import 'time_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

/// ✅ เปลี่ยนเป็น Stateful เพื่อฟังเวลาและเปลี่ยนธีม/ฉากอัตโนมัติ
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final TimeThemeController _time = TimeThemeController();

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _time,
      builder: (context, _) {
        final seed = TimeTheme.seed(_time.phase);

        final cs = ColorScheme.fromSeed(
          seedColor: seed,
          brightness: _time.phase == DayPhase.night
              ? Brightness.dark
              : Brightness.light,
        );

        return MaterialApp(
          title: 'Calorie Scanner',
          debugShowCheckedModeBanner: false,

          // ✅ ธีมทั้งแอปเปลี่ยนตามเวลา
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: cs,

            // สำคัญ: ต้องเป็น transparent เพื่อให้เห็นฉากหลัง
            scaffoldBackgroundColor: Colors.transparent,

            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              surfaceTintColor: Colors.transparent,
            ),

            cardTheme: CardThemeData(
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),

            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: cs.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
            ),

            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),

            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.primary, width: 1.5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),

            progressIndicatorTheme: ProgressIndicatorThemeData(
              color: cs.primary,
              linearTrackColor: cs.surfaceContainerHighest,
              circularTrackColor: cs.surfaceContainerHighest,
            ),

            chipTheme: ChipThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              selectedColor: cs.primary,
              checkmarkColor: cs.onPrimary,
              backgroundColor: cs.surface,
              side: BorderSide(color: cs.outlineVariant),
            ),

            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: cs.surface,
              selectedItemColor: cs.primary,
              unselectedItemColor: cs.onSurfaceVariant,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
            ),
          ),

          // ✅ ครอบทุกหน้าด้วยฉากหลัง (sun/moon)
          builder: (context, child) {
            return TimeTheme.background(
              phase: _time.phase,
              child: child ?? const SizedBox.shrink(),
            );
          },

          home: const AuthGate(),
        );
      },
    );
  }
}

/// ถ้า Login แล้ว -> เข้า AppShell
/// ถ้ายัง -> ไป LoginPage
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) return const LoginPage();
        return const AppShell();
      },
    );
  }
}
