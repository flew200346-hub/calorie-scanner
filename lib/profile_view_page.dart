import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../user_profile.dart';
import 'profile_edit_page.dart';

class ProfileViewPage extends StatelessWidget {
  const ProfileViewPage({super.key});

  DocumentReference<Map<String, dynamic>> _doc() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'แก้ไข',
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileEditPage()),
            ),
          )
        ],
      ),
      body: StreamBuilder(
        stream: _doc().snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data();
          if (data == null || data.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline, size: 72),
                  const SizedBox(height: 8),
                  const Text('ยังไม่มีข้อมูลโปรไฟล์'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileEditPage()),
                    ),
                    child: const Text('สร้างโปรไฟล์'),
                  ),
                ],
              ),
            );
          }

          final p = UserProfile.fromMap(data);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text('${p.firstName} (${p.nickName})'),
                  subtitle: const Text('ชื่อจริง/ชื่อเล่น'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cake_outlined),
                  title: Text('${p.age} ปี'),
                  subtitle: const Text('อายุ'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.height),
                  title: Text('${p.heightCm} cm'),
                  subtitle: const Text('ส่วนสูง'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.monitor_weight_outlined),
                  title: Text('${p.weightKg} kg'),
                  subtitle: const Text('น้ำหนัก'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
