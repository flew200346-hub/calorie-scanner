// ============================================================================
// time_theme.dart — ธีมที่เปลี่ยนตามช่วงเวลาจริง (เช้า/เที่ยง/เย็น/กลางคืน)
// ----------------------------------------------------------------------------
// TimeThemeController = ChangeNotifier ที่ Timer.periodic(1 นาที)
//   → ถ้า phase เปลี่ยน → notifyListeners() → MaterialApp rebuild
//   → seed color + brightness เปลี่ยนตามช่วงเวลา
//
// TimeTheme.background() — ปัจจุบันไม่ถูกใช้แล้ว (CosmicBackground แทน)
// แต่ TimeTheme.seed() ยังใช้ใน main.dart สร้าง ColorScheme
//
// Phase mapping:
//   morning 6:00-10:59 / noon 11:00-15:59 / evening 16:00-18:59 / night ที่เหลือ
// ============================================================================

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum DayPhase { morning, noon, evening, night }

DayPhase phaseFrom(DateTime now) {
  final h = now.hour;
  if (h >= 6 && h < 11) return DayPhase.morning;
  if (h >= 11 && h < 16) return DayPhase.noon;
  if (h >= 16 && h < 19) return DayPhase.evening;
  return DayPhase.night;
}

class TimeThemeController extends ChangeNotifier {
  DayPhase _phase = phaseFrom(DateTime.now());
  late final Timer _timer;

  TimeThemeController() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
  }

  DayPhase get phase => _phase;

  void _tick() {
    final p = phaseFrom(DateTime.now());
    if (p != _phase) {
      _phase = p;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

class TimeTheme {
  static Color seed(DayPhase p) {
    switch (p) {
      case DayPhase.morning:
        return const Color(0xFF8BC6A2);
      case DayPhase.noon:
        return const Color(0xFF6CB6E8);
      case DayPhase.evening:
        return const Color(0xFFF29B7A);
      case DayPhase.night:
        return const Color(0xFF7E8BC7);
    }
  }

  static List<Color> backgroundGradient(DayPhase p) {
    switch (p) {
      case DayPhase.morning:
        return const [
          Color(0xFFFFF6E9),
          Color(0xFFF9F7FF),
          Color(0xFFF6FBF8),
        ];
      case DayPhase.noon:
        return const [
          Color(0xFFE8F5FF),
          Color(0xFFF6FAFF),
          Color(0xFFF7FBFF),
        ];
      case DayPhase.evening:
        return const [
          Color(0xFFFFE8DC),
          Color(0xFFFFF4EE),
          Color(0xFFF9F7FF),
        ];
      case DayPhase.night:
        return const [
          Color(0xFF16213A),
          Color(0xFF1D2946),
          Color(0xFF243459),
        ];
    }
  }

  static Widget background({
    required DayPhase phase,
    required Widget child,
  }) {
    final grad = backgroundGradient(phase);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: grad,
            ),
          ),
        ),

        // ลายพื้นหลังโค้ง ๆ เบา ๆ
        const Positioned.fill(
          child: IgnorePointer(
            child: _SoftPatternLayer(),
          ),
        ),

        // เมฆ/หมอกบาง ๆ
        if (phase != DayPhase.night)
          const Positioned.fill(
            child: IgnorePointer(
              child: _CloudLayer(),
            ),
          ),

        // ดวงอาทิตย์
        if (phase == DayPhase.morning || phase == DayPhase.noon)
          Align(
            alignment: phase == DayPhase.morning
                ? const Alignment(0.72, -0.82)
                : const Alignment(0.62, -0.92),
            child: const _SunOrb(),
          ),

        // แสงเย็น
        if (phase == DayPhase.evening)
          const Align(
            alignment: Alignment(0.78, -0.83),
            child: _EveningOrb(),
          ),

        // ดวงจันทร์
        if (phase == DayPhase.night)
          const Align(
            alignment: Alignment(0.72, -0.85),
            child: _MoonOrb(),
          ),

        // ดาว
        if (phase == DayPhase.night)
          const Positioned.fill(
            child: IgnorePointer(
              child: _StarsLayer(),
            ),
          ),

        // layer บาง ๆ ให้ดูฟุ้ง
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: phase == DayPhase.night
                    ? Colors.white.withOpacity(0.02)
                    : Colors.white.withOpacity(0.05),
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }
}

class _SoftPatternLayer extends StatelessWidget {
  const _SoftPatternLayer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SoftPatternPainter(),
      size: Size.infinite,
    );
  }
}

class _SoftPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = Colors.white.withOpacity(0.10);
    final p2 = Paint()..color = Colors.white.withOpacity(0.06);

    final path1 = Path()
      ..moveTo(-40, size.height * 0.16)
      ..quadraticBezierTo(
        size.width * 0.30,
        size.height * 0.05,
        size.width * 0.62,
        size.height * 0.18,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.28,
        size.width + 60,
        size.height * 0.14,
      )
      ..lineTo(size.width + 60, -20)
      ..lineTo(-40, -20)
      ..close();

    final path2 = Path()
      ..moveTo(-50, size.height * 0.30)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.22,
        size.width * 0.45,
        size.height * 0.34,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.48,
        size.width + 40,
        size.height * 0.28,
      )
      ..lineTo(size.width + 40, -20)
      ..lineTo(-50, -20)
      ..close();

    canvas.drawPath(path1, p1);
    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SunOrb extends StatefulWidget {
  const _SunOrb();

  @override
  State<_SunOrb> createState() => _SunOrbState();
}

class _SunOrbState extends State<_SunOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
      lowerBound: 0.96,
      upperBound: 1.04,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Color(0xFFFFF176),
              Color(0xFFFFD54F),
              Color(0xFFFFB300),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 70,
              spreadRadius: 12,
              color: Colors.amber.withOpacity(0.36),
            ),
          ],
        ),
      ),
    );
  }
}

class _EveningOrb extends StatefulWidget {
  const _EveningOrb();

  @override
  State<_EveningOrb> createState() => _EveningOrbState();
}

class _EveningOrbState extends State<_EveningOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
      lowerBound: 0.97,
      upperBound: 1.03,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Color(0xFFFFCC80),
              Color(0xFFFF8A65),
              Color(0xFFFF7043),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 70,
              spreadRadius: 14,
              color: const Color(0xFFFF8A65).withOpacity(0.34),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoonOrb extends StatelessWidget {
  const _MoonOrb();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF4F7FB),
              boxShadow: [
                BoxShadow(
                  blurRadius: 60,
                  spreadRadius: 12,
                  color: Colors.white.withOpacity(0.18),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            top: 8,
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF243459),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudLayer extends StatelessWidget {
  const _CloudLayer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CloudPainter(),
      size: Size.infinite,
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.18);

    void cloud(double x, double y, double scale) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 130 * scale,
          height: 46 * scale,
        ),
        paint,
      );
      canvas.drawCircle(
          Offset(x - 34 * scale, y - 4 * scale), 24 * scale, paint);
      canvas.drawCircle(Offset(x, y - 12 * scale), 28 * scale, paint);
      canvas.drawCircle(
          Offset(x + 34 * scale, y - 5 * scale), 20 * scale, paint);
    }

    cloud(size.width * 0.20, size.height * 0.16, 0.9);
    cloud(size.width * 0.82, size.height * 0.22, 0.75);
    cloud(size.width * 0.40, size.height * 0.26, 0.65);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarsLayer extends StatelessWidget {
  const _StarsLayer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarsPainter(),
      size: Size.infinite,
    );
  }
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF5F7FF).withOpacity(0.35);

    final stars = <Offset>[
      Offset(size.width * 0.12, size.height * 0.10),
      Offset(size.width * 0.20, size.height * 0.18),
      Offset(size.width * 0.33, size.height * 0.12),
      Offset(size.width * 0.46, size.height * 0.08),
      Offset(size.width * 0.58, size.height * 0.16),
      Offset(size.width * 0.70, size.height * 0.11),
      Offset(size.width * 0.82, size.height * 0.19),
      Offset(size.width * 0.90, size.height * 0.10),
      Offset(size.width * 0.28, size.height * 0.26),
      Offset(size.width * 0.62, size.height * 0.27),
    ];

    for (final s in stars) {
      canvas.drawCircle(s, 1.7, paint);
      canvas.drawCircle(
        s.translate(7, 5),
        1.0,
        Paint()..color = const Color(0xFFF5F7FF).withOpacity(0.18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
