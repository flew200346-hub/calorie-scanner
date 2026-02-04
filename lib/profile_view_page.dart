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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'แก้ไข',
            icon: const Icon(Icons.edit_outlined),
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: cs.primary.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.person_outline,
                        size: 36,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ยังไม่มีข้อมูลโปรไฟล์',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'กดเพื่อสร้างโปรไฟล์สำหรับคำนวณ/บันทึกข้อมูล',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileEditPage()),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('สร้างโปรไฟล์'),
                    ),
                  ],
                ),
              ),
            );
          }

          final p = UserProfile.fromMap(data);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header card (ปรับให้ดูแพงขึ้น + ใช้สีธีม)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: cs.primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.firstName.isEmpty ? 'ไม่ระบุชื่อ' : p.firstName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.nickName.isEmpty
                                  ? 'ยังไม่มีชื่อเล่น'
                                  : 'ชื่อเล่น: ${p.nickName}',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _infoTile(
                context,
                icon: Icons.cake_outlined,
                title: Text('${p.age} ปี'),
                subtitle: const Text('อายุ'),
              ),
              _infoTile(
                context,
                icon: Icons.height,
                title: Text('${p.heightCm.toStringAsFixed(0)} cm'),
                subtitle: const Text('ส่วนสูง'),
              ),
              _infoTile(
                context,
                icon: Icons.monitor_weight_outlined,
                title: Text('${p.weightKg.toStringAsFixed(0)} kg'),
                subtitle: const Text('น้ำหนัก'),
              ),

              const SizedBox(height: 18),

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

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required Widget title,
    required Widget subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: cs.primary.withValues(alpha: 0.10),
          child: Icon(icon, color: cs.primary, size: 20),
        ),
        title: DefaultTextStyle.merge(
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          child: title,
        ),
        subtitle: DefaultTextStyle.merge(
          style: TextStyle(color: cs.onSurfaceVariant),
          child: subtitle,
        ),
      ),
    );
  }
}
