// ============================================================================
// login_page.dart — หน้า login (เปิดมาเป็นหน้าแรกถ้ายังไม่ login)
// ----------------------------------------------------------------------------
// 3 ปุ่ม:
//   - "เข้าสู่ระบบ"      → _login()  → FirebaseAuth.signInWithEmailAndPassword
//   - "ลืมรหัสผ่าน?"    → _forgotPassword() → sendPasswordResetEmail
//   - "สมัคร"           → push RegisterPage
//
// Auth state เปลี่ยน → AuthGate (main.dart) detect → เด้งไป AppShell อัตโนมัติ
// ============================================================================

import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'register_page.dart';
import 'widgets/cosmic_background.dart';
import 'widgets/hover_scale.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
    } catch (_) {
      _showSnack('เข้าสู่ระบบไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// ส่งอีเมล reset password ผ่าน Firebase Auth
  /// - email ว่าง → SnackBar เตือน
  /// - error แยกข้อความตาม code (invalid-email / user-not-found / อื่นๆ)
  /// template ปรับได้ที่ Firebase Console → Auth → Templates → Password reset
  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _showSnack('กรุณากรอกอีเมลก่อน');
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showSnack(
        'ส่งลิงก์รีเซ็ตรหัสผ่านไปที่ $email แล้ว กรุณาเช็คอีเมล',
        color: Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-email' => 'รูปแบบอีเมลไม่ถูกต้อง',
        'user-not-found' => 'ไม่พบบัญชีของอีเมลนี้',
        _ => 'ส่งอีเมลไม่สำเร็จ ลองใหม่อีกครั้ง',
      };
      _showSnack(msg);
    } catch (_) {
      _showSnack('ส่งอีเมลไม่สำเร็จ ลองใหม่อีกครั้ง');
    }
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: CosmicBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surface.withOpacity(0.78),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.14),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTopBadge(),
                              const SizedBox(height: 16),
                              Text(
                                'ยินดีต้อนรับกลับ',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'เข้าสู่ระบบเพื่อสแกนอาหาร\nและบันทึกแคลอรี่ของวันนี้',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  height: 1.5,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 28),
                              _buildInputLabel('อีเมล'),
                              const SizedBox(height: 8),
                              _buildEmailField(cs),
                              const SizedBox(height: 16),
                              _buildInputLabel('รหัสผ่าน'),
                              const SizedBox(height: 8),
                              _buildPasswordField(cs),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _loading ? null : _forgotPassword,
                                  child: const Text('ลืมรหัสผ่าน?'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              HoverScale(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _loading ? null : _login,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF7C5CFF),
                                          Color(0xFF5E8BFF),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF7C5CFF)
                                              .withOpacity(0.30),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: FilledButton(
                                      onPressed: _loading ? null : _login,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.login_rounded),
                                                SizedBox(width: 8),
                                                Text(
                                                  'เข้าสู่ระบบ',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                      child: Divider(color: cs.outlineVariant)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text('หรือ',
                                        style: TextStyle(
                                            color: cs.onSurfaceVariant)),
                                  ),
                                  Expanded(
                                      child: Divider(color: cs.outlineVariant)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              HoverScale(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterPage(),
                                    ),
                                  );
                                },
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterPage(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.person_add_alt_1),
                                    label: const Text(
                                      'สร้างบัญชีใหม่',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Calorie Scanner',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ไอคอนใหม่ (ไม่บัง background)
  Widget _buildTopBadge() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7C5CFF),
            Color(0xFF5E8BFF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C5CFF).withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildEmailField(ColorScheme cs) {
    return TextField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'กรอกอีเมล',
        prefixIcon: const Icon(Icons.mail_outline_rounded),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withOpacity(0.45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField(ColorScheme cs) {
    return TextField(
      controller: _passwordCtrl,
      obscureText: _obscure,
      decoration: InputDecoration(
        hintText: 'กรอกรหัสผ่าน',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withOpacity(0.45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
