import 'dart:async';
import 'package:flutter/material.dart';

enum DayPhase { morning, noon, evening, night }

DayPhase phaseFrom(DateTime now) {
  final h = now.hour;
  if (h >= 6 && h < 11) return DayPhase.morning; // 06-10
  if (h >= 11 && h < 16) return DayPhase.noon; // 11-15
  if (h >= 16 && h < 19) return DayPhase.evening; // 16-18
  return DayPhase.night; // 19-05
}

class TimeThemeController extends ChangeNotifier {
  DayPhase _phase = phaseFrom(DateTime.now());
  late final Timer _timer;

  TimeThemeController() {
    // อัปเดตทุก 1 นาที (พอสำหรับเปลี่ยนช่วงเวลา)
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

/// สี+ฉากหลังตามช่วงเวลา
class TimeTheme {
  static Color seed(DayPhase p) {
    switch (p) {
      case DayPhase.morning:
        return const Color(0xFFFFB74D); // อุ่นๆ
      case DayPhase.noon:
        return const Color(0xFF42A5F5); // ฟ้าใส
      case DayPhase.evening:
        return const Color(0xFFFF7043); // ส้มเย็น
      case DayPhase.night:
        return const Color(0xFF5C6BC0); // คราม
    }
  }

  static List<Color> backgroundGradient(DayPhase p) {
    switch (p) {
      case DayPhase.morning:
        return const [Color(0xFFFFF3E0), Color(0xFFF7F4FB)];
      case DayPhase.noon:
        return const [Color(0xFFE3F2FD), Color(0xFFF7F4FB)];
      case DayPhase.evening:
        return const [Color(0xFFFFE0B2), Color(0xFFF7F4FB)];
      case DayPhase.night:
        return const [Color(0xFF0D1B3D), Color(0xFF121B2D)];
    }
  }

  /// วงกลม “ดวงอาทิตย์/พระจันทร์” (ตำแหน่ง+สี)
  static _OrbStyle orb(DayPhase p) {
    switch (p) {
      case DayPhase.morning:
        return _OrbStyle(
          color: const Color(0xFFFFD54F),
          glow: const Color(0xFFFFF59D),
          alignment: const Alignment(0.75, -0.85),
        );
      case DayPhase.noon:
        return _OrbStyle(
          color: const Color(0xFFFFEB3B),
          glow: const Color(0xFFFFF9C4),
          alignment: const Alignment(0.60, -0.95),
        );
      case DayPhase.evening:
        return _OrbStyle(
          color: const Color(0xFFFF8A65),
          glow: const Color(0xFFFFCCBC),
          alignment: const Alignment(0.75, -0.80),
        );
      case DayPhase.night:
        return _OrbStyle(
          color: const Color(0xFFECEFF1),
          glow: const Color(0xFFB0BEC5),
          alignment: const Alignment(0.75, -0.88),
        );
    }
  }

  /// Widget ฉากหลังที่ใช้ได้ทุกหน้า
  static Widget background({
    required DayPhase phase,
    required Widget child,
  }) {
    final grad = backgroundGradient(phase);
    final orb = TimeTheme.orb(phase);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: grad,
        ),
      ),
      child: Stack(
        children: [
          // orb (sun/moon)
          Align(
            alignment: orb.alignment,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 70,
                    spreadRadius: 20,
                    color: orb.glow
                        .withOpacity(phase == DayPhase.night ? 0.18 : 0.22),
                  ),
                ],
                gradient: RadialGradient(
                  colors: [
                    orb.color.withOpacity(0.95),
                    orb.color.withOpacity(0.55),
                    orb.color.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // stars (เฉพาะกลางคืน)
          if (phase == DayPhase.night) ...[
            const _StarsLayer(),
          ],

          // เนื้อหาจริง
          child,
        ],
      ),
    );
  }
}

class _OrbStyle {
  final Color color;
  final Color glow;
  final Alignment alignment;
  const _OrbStyle(
      {required this.color, required this.glow, required this.alignment});
}

class _StarsLayer extends StatelessWidget {
  const _StarsLayer();

  @override
  Widget build(BuildContext context) {
    // ดาวแบบเบาๆ ไม่ใช้ asset
    return IgnorePointer(
      child: CustomPaint(
        painter: _StarsPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFECEFF1).withOpacity(0.25);
    final stars = <Offset>[
      Offset(size.width * 0.15, size.height * 0.12),
      Offset(size.width * 0.32, size.height * 0.18),
      Offset(size.width * 0.55, size.height * 0.10),
      Offset(size.width * 0.72, size.height * 0.22),
      Offset(size.width * 0.85, size.height * 0.14),
      Offset(size.width * 0.20, size.height * 0.28),
      Offset(size.width * 0.42, size.height * 0.30),
      Offset(size.width * 0.62, size.height * 0.28),
    ];
    for (final s in stars) {
      canvas.drawCircle(s, 1.6, paint);
      canvas.drawCircle(
          s.translate(8, 6), 1.1, paint..color = paint.color.withOpacity(0.18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
