import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      _showError(_thaiAuthError(e.code));
    } catch (_) {
      _showError('เกิดข้อผิดพลาด กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เข้าสู่ระบบไม่สำเร็จ'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  String _thaiAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'อีเมลไม่ถูกต้อง';
      case 'user-disabled':
        return 'บัญชีนี้ถูกปิดใช้งาน';
      case 'user-not-found':
        return 'ไม่พบบัญชีผู้ใช้นี้';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'invalid-credential':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'too-many-requests':
        return 'ลองบ่อยเกินไป กรุณารอสักครู่';
      default:
        return 'เกิดข้อผิดพลาด: $code';
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // ✅ Background gradient โทนเดียวกับแอป
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.primary.withValues(alpha: 0.16),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      // ✅ Logo badge โทนเดียว
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 18,
                              offset: Offset(0, 10),
                              color: Colors.black12,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.local_fire_department,
                                size: 30,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Calorie Scanner',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'เข้าสู่ระบบเพื่อสแกนอาหาร',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ✅ Card ใช้ Theme (ไม่ติดเขียว)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'ยินดีต้อนรับกลับมา 👋',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'กรอกอีเมลและรหัสผ่านเพื่อเข้าสู่ระบบ',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(height: 18),

                              // ✅ Email: ใช้ InputDecorationTheme จาก main.dart
                              TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // ✅ Password
                              TextField(
                                controller: _password,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _loading ? null : _login(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(_obscure
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _loading ? null : () {},
                                  child: const Text('ลืมรหัสผ่าน?'),
                                ),
                              ),

                              const SizedBox(height: 6),

                              // ✅ Login button: ไม่กำหนดสีเอง ให้ใช้ theme
                              SizedBox(
                                height: 50,
                                child: FilledButton(
                                  onPressed: _loading ? null : _login,
                                  child: _loading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // ✅ Create account: ใช้ outlined theme
                              SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: _loading
                                      ? null
                                      : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const RegisterPage(),
                                            ),
                                          ),
                                  child: const Text('Create account'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'By continuing you agree to our Terms & Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
