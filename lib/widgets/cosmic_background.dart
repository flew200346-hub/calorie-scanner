import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class CosmicBackground extends StatefulWidget {
  final Widget child;
  final bool useSafeArea;
  final bool showStars;

  const CosmicBackground({
    super.key,
    required this.child,
    this.useSafeArea = false,
    this.showStars = true,
  });

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _isNight {
    final h = DateTime.now().hour;
    return h >= 18 || h < 6;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNight = _isNight;

    return Stack(
      children: [
        RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isNight
                    ? const [
                        Color(0xFF171C35),
                        Color(0xFF273463),
                        Color(0xFF4656C9),
                      ]
                    : const [
                        Color(0xFF1D2A57),
                        Color(0xFF4967D6),
                        Color(0xFF89D8FF),
                      ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -50,
          left: -20,
          child: RepaintBoundary(
            child: _blurBlob(
              size: 190,
              color: isNight
                  ? const Color(0xFF8C7BFF).withOpacity(0.18)
                  : const Color(0xFFFFD36E).withOpacity(0.20),
            ),
          ),
        ),
        Positioned(
          top: 140,
          right: -60,
          child: RepaintBoundary(
            child: _blurBlob(
              size: 230,
              color: isNight
                  ? const Color(0xFF6BE0FF).withOpacity(0.14)
                  : const Color(0xFF7EE7FF).withOpacity(0.18),
            ),
          ),
        ),
        Positioned(
          bottom: -70,
          left: -30,
          child: RepaintBoundary(
            child: _blurBlob(
              size: 250,
              color: isNight
                  ? const Color(0xFFFF7AD9).withOpacity(0.12)
                  : const Color(0xFFFF9ACB).withOpacity(0.12),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _WavePainter(isNight: isNight),
              ),
            ),
          ),
        ),
        Positioned(
          top: 86,
          right: 10,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final floatY = lerpDouble(-4, 6, _controller.value) ?? 0;
                final glowScale =
                    lerpDouble(0.96, 1.06, _controller.value) ?? 1.0;
                return Transform.translate(
                  offset: Offset(0, floatY),
                  child: _CelestialOrb(
                    isNight: isNight,
                    glowScale: glowScale,
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.showStars && isNight)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final v = _controller.value;
                    return Stack(
                      children: [
                        _AnimatedStar(
                            top: 88, left: 34, size: 4, progress: v, phase: 0.15),
                        _AnimatedStar(
                            top: 130, left: 110, size: 3, progress: v, phase: 0.45),
                        _AnimatedStar(
                            top: 170, left: 62, size: 2.5, progress: v, phase: 0.75),
                        _AnimatedStar(
                            top: 220, right: 120, size: 3, progress: v, phase: 0.25),
                        _AnimatedStar(
                            top: 280, right: 42, size: 4, progress: v, phase: 0.60),
                        _AnimatedStar(
                            bottom: 180, left: 70, size: 3, progress: v, phase: 0.35),
                        _AnimatedStar(
                            bottom: 250, right: 95, size: 2.5, progress: v, phase: 0.85),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        if (widget.useSafeArea)
          SafeArea(child: widget.child)
        else
          widget.child,
      ],
    );
  }

  Widget _blurBlob({required double size, required Color color}) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _CelestialOrb extends StatelessWidget {
  final bool isNight;
  final double glowScale;

  const _CelestialOrb({
    required this.isNight,
    required this.glowScale,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: glowScale * 1.20,
      child: SizedBox(
        width: 130,
        height: 130,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isNight
                            ? const Color(0xFFDCE6FF)
                            : const Color(0xFFFFD35A))
                        .withOpacity(isNight ? 0.28 : 0.24),
                    blurRadius: isNight ? 30 : 36,
                    spreadRadius: isNight ? 4 : 6,
                  ),
                ],
              ),
            ),
            isNight ? const _PrettyMoon() : const _PrettySun(),
          ],
        ),
      ),
    );
  }
}

class _PrettyMoon extends StatelessWidget {
  const _PrettyMoon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDCE6FF).withOpacity(0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.25, -0.25),
                radius: 0.95,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF0F4FF),
                  Color(0xFFD8E2FF),
                  Color(0xFFC4D2FF),
                ],
              ),
            ),
          ),
          Positioned(
            top: 18,
            left: 20,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.30),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            top: 22,
            left: 24,
            child: _MoonCrater(size: 9, opacity: 0.20),
          ),
          const Positioned(
            top: 40,
            left: 18,
            child: _MoonCrater(size: 6, opacity: 0.16),
          ),
          const Positioned(
            right: 18,
            bottom: 20,
            child: _MoonCrater(size: 8, opacity: 0.14),
          ),
          const Positioned(
            right: 24,
            top: 30,
            child: _MoonCrater(size: 5, opacity: 0.12),
          ),
        ],
      ),
    );
  }
}

class _MoonCrater extends StatelessWidget {
  final double size;
  final double opacity;

  const _MoonCrater({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFAEBEEB).withOpacity(opacity),
        border: Border.all(
          color: Colors.white.withOpacity(opacity * 0.35),
          width: 0.6,
        ),
      ),
    );
  }
}

class _PrettySun extends StatelessWidget {
  const _PrettySun();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // glow ด้านนอก
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withOpacity(0.28),
                  blurRadius: 34,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),

          // หยักรอบนอก
          CustomPaint(
            size: const Size(110, 110),
            painter: _SunRaysPainter(),
          ),

          // วงกลมพระอาทิตย์
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.2, -0.2),
                radius: 0.95,
                colors: [
                  Color(0xFFFFE66D),
                  Color(0xFFFFB300),
                  Color(0xFFFF7A00),
                ],
              ),
            ),
          ),

          // แสงสะท้อน
          Positioned(
            top: 24,
            left: 28,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SunRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final outerRadius = size.width / 2;
    final innerRadius = size.width * 0.39;

    const rayCount = 24;
    final step = (math.pi * 2) / rayCount;

    final path = Path();

    for (int i = 0; i < rayCount * 2; i++) {
      final angle = i * (step / 2) - math.pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;

      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();

    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFF176),
          Color(0xFFFFC107),
          Color(0xFFFF8F00),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedStar extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final double progress;
  final double phase;

  const _AnimatedStar({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.progress,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final wave = (math.sin((progress + phase) * math.pi * 2) + 1) / 2;
    final opacity = lerpDouble(0.25, 0.95, wave) ?? 0.7;
    final scale = lerpDouble(0.85, 1.18, wave) ?? 1.0;

    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(opacity * 0.45),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final bool isNight;

  _WavePainter({required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(isNight ? 0.05 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path1 = Path()
      ..moveTo(-20, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.30,
        size.height * 0.12,
        size.width * 0.62,
        size.height * 0.20,
      )
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.26,
        size.width + 30,
        size.height * 0.18,
      );

    final path2 = Path()
      ..moveTo(-20, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.70,
        size.width * 0.50,
        size.height * 0.80,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.90,
        size.width + 30,
        size.height * 0.80,
      );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.isNight != isNight;
  }
}
