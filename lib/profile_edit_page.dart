import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'user_profile.dart';

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
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final p = UserProfile(
      firstName: _firstName.text.trim(),
      nickName: _nickName.text.trim(),
      age: int.parse(_age.text.trim()),
      heightCm: double.parse(_height.text.trim()),
      weightKg: double.parse(_weight.text.trim()),
    );

    setState(() => _loading = true);
    try {
      await _doc().set(p.toMap(), SetOptions(merge: true));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกไม่สำเร็จ ลองใหม่อีกครั้ง')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'ให้ตะโก้รู้จักคุณหน่อยนะ 😊',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'กรอกข้อมูลเพื่อช่วยในการคำนวณ/บันทึก',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstName,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อจริง',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'กรอกชื่อจริง' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nickName,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อเล่น',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag_faces),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'กรอกชื่อเล่น' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'อายุ (ปี)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null || n <= 0) return 'กรอกอายุให้ถูกต้อง';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _height,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ส่วนสูง (cm)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.height),
                    ),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').trim());
                      if (n == null || n <= 0) return 'กรอกส่วนสูงให้ถูกต้อง';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _weight,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'น้ำหนัก (kg)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').trim());
                      if (n == null || n <= 0) return 'กรอกน้ำหนักให้ถูกต้อง';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('บันทึก'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
