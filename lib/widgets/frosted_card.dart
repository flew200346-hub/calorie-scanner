// ============================================================================
// frosted_card.dart — การ์ดกระจกฝ้า (glass-morphism)
// ----------------------------------------------------------------------------
// ใช้ BackdropFilter blur sigma=14 + พื้นโปร่งใส 72% + เงาเบาๆ
// ใช้ทั่วทั้งแอป (info card, list tile, container ทุกที่)
// ระวัง: BackdropFilter หนัก GPU — อย่า nested กันลึกๆ
// ============================================================================

import 'dart:ui';

import 'package:flutter/material.dart';

class FrostedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const FrostedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(26);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.72),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
