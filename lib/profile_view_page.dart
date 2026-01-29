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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _doc().snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดโปรไฟล์'));
          }

          final data = snap.data?.data();

          // ยังไม่มีเอกสารหรือยังไม่มีข้อมูล
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
              // Header card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        child: Icon(Icons.person, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.firstName.isEmpty ? 'ไม่ระบุชื่อ' : p.firstName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.nickName.isEmpty
                                  ? 'ยังไม่มีชื่อเล่น'
                                  : 'ชื่อเล่น: ${p.nickName}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              _infoTile(
                icon: Icons.cake_outlined,
                title: Text('${p.age} ปี'),
                subtitle: const Text('อายุ'),
              ),
              _infoTile(
                icon: Icons.height,
                title: Text('${p.heightCm.toStringAsFixed(0)} cm'),
                subtitle: const Text('ส่วนสูง'),
              ),
              _infoTile(
                icon: Icons.monitor_weight_outlined,
                title: Text('${p.weightKg.toStringAsFixed(0)} kg'),
                subtitle: const Text('น้ำหนัก'),
              ),

              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileEditPage()),
                ),
                icon: const Icon(Icons.edit),
                label: const Text('แก้ไขโปรไฟล์'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Widget title,
    required Widget subtitle,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: title, // ✅ ต้องเป็น Widget เช่น Text(...)
        subtitle: subtitle,
      ),
    );
  }
}
