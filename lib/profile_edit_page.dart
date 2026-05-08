// ============================================================================
// profile_edit_page.dart — ฟอร์มแก้ไขโปรไฟล์
// ----------------------------------------------------------------------------
// Fields: ชื่อจริง, ชื่อเล่น, อายุ, ส่วนสูง, น้ำหนัก, เพศ, ระดับกิจกรรม
// (เพศ + กิจกรรม = ปัจจัยสำคัญในสูตร TDEE — ดู user_profile.dart)
//
// Save flow (instant UX):
//   1) Validate form → setState(_loading = true)
//   2) ยิง Firestore.set(merge:true) แบบไม่ await
//   3) Navigator.pop() กลับทันที
//   4) profile_view_page รีเฟรชเอง (ใช้ .snapshots() listener)
//   5) ถ้า fail → SnackBar แดงในหน้าก่อนหน้า (capture messenger ก่อน pop)
//
// บันทึก field "email" ด้วย เพื่อ link profile กับ auth account ชัดเจน
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'user_profile.dart';
import 'widgets/cosmic_background.dart';
import 'widgets/frosted_card.dart';
import 'widgets/hover_scale.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _nickName = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();

  String _gender = 'other';
  String _activityLevel = 'light';

  bool _loading = false;

  DocumentReference<Map<String, dynamic>> _doc() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snap = await _doc().get();
    final data = snap.data();
    if (data == null) return;

    _firstName.text = (data['firstName'] ?? '').toString();
    _nickName.text = (data['nickName'] ?? '').toString();
    _age.text = (data['age'] ?? '').toString();
    _height.text = (data['heightCm'] ?? '').toString();
    _weight.text = (data['weightKg'] ?? '').toString();

    final g = (data['gender'] ?? '').toString();
    if (genderLabels.containsKey(g)) _gender = g;

    final a = (data['activityLevel'] ?? '').toString();
    if (activityLabels.containsKey(a)) _activityLevel = a;

    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    final p = UserProfile(
      firstName: _firstName.text.trim(),
      nickName: _nickName.text.trim(),
      age: int.parse(_age.text.trim()),
      heightCm: double.parse(_height.text.trim()),
      weightKg: double.parse(_weight.text.trim()),
      gender: _gender,
      activityLevel: _activityLevel,
    );

    setState(() => _loading = true);

    final messenger = ScaffoldMessenger.of(context);
    final email = FirebaseAuth.instance.currentUser?.email;

    final payload = {
      ...p.toMap(),
      if (email != null) 'email': email,
    };

    _doc().set(payload, SetOptions(merge: true)).catchError((_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('บันทึกไม่สำเร็จ ลองใหม่อีกครั้ง'),
        ),
      );
    });

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _nickName.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CosmicBackground(
        useSafeArea: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _buildPageTitle(),
                const SizedBox(height: 16),
                FrostedCard(
                  borderRadius: BorderRadius.circular(28),
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'ข้อมูลส่วนตัว',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'กรอกข้อมูลเพื่อช่วยในการคำนวณและบันทึกแคลอรี่',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 18),
                        _buildInputField(
                          controller: _firstName,
                          label: 'ชื่อจริง',
                          icon: Icons.person_outline,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'กรอกชื่อจริง'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _nickName,
                          label: 'ชื่อเล่น',
                          icon: Icons.badge_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'กรอกชื่อเล่น'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _age,
                          label: 'อายุ (ปี)',
                          icon: Icons.cake_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = int.tryParse((v ?? '').trim());
                            if (n == null || n <= 0) {
                              return 'กรอกอายุให้ถูกต้อง';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _height,
                          label: 'ส่วนสูง (cm)',
                          icon: Icons.height,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = double.tryParse((v ?? '').trim());
                            if (n == null || n <= 0) {
                              return 'กรอกส่วนสูงให้ถูกต้อง';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _weight,
                          label: 'น้ำหนัก (kg)',
                          icon: Icons.monitor_weight_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = double.tryParse((v ?? '').trim());
                            if (n == null || n <= 0) {
                              return 'กรอกน้ำหนักให้ถูกต้อง';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown<String>(
                          value: _gender,
                          label: 'เพศ',
                          icon: Icons.wc_outlined,
                          items: genderLabels.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _gender = v ?? _gender),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown<String>(
                          value: _activityLevel,
                          label: 'ระดับการเคลื่อนไหว',
                          icon: Icons.directions_run_outlined,
                          items: activityLabels.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(
                                      e.value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _activityLevel = v ?? _activityLevel),
                        ),
                        const SizedBox(height: 20),
                        HoverScale(
                          borderRadius: BorderRadius.circular(18),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF7C5CFF),
                                  Color(0xFF5E8BFF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF7C5CFF).withOpacity(0.30),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              height: 54,
                              child: FilledButton(
                                onPressed: _loading ? null : _save,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'บันทึก',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'แก้ไขโปรไฟล์',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'อัปเดตข้อมูลส่วนตัวเพื่อให้ระบบคำนวณได้แม่นยำขึ้น',
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _decoration(label: label, icon: icon),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      decoration: _decoration(label: label, icon: icon),
    );
  }

  InputDecoration _decoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF7C5CFF),
          width: 1.4,
        ),
      ),
    );
  }
}
