import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'user_profile.dart';
import 'profile_edit_page.dart';

class ProfileViewPage extends StatefulWidget {
  const ProfileViewPage({super.key});

  @override
  State<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage> {
  late final String _uid;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _profileStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _historyStream;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _profileStream = FirebaseFirestore.instance.collection('users').doc(_uid).snapshots();
    _historyStream = FirebaseFirestore.instance
        .collection('meals')
        .where('uid', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  void _goEdit() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditPage()));
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบใช่ไหม?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ออกจากระบบ')),
        ],
      ),
    );
    if (ok == true) await FirebaseAuth.instance.signOut();
  }

  Future<void> _confirmDeleteHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบประวัติทั้งหมด'),
        content: const Text('ข้อมูลมื้ออาหารทั้งหมดจะถูกลบ ดำเนินการต่อ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบทั้งหมด'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final batch = FirebaseFirestore.instance.batch();
    final docs = await FirebaseFirestore.instance
        .collection('meals')
        .where('uid', isEqualTo: _uid)
        .get();
    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบประวัติทั้งหมดแล้ว'), backgroundColor: Colors.green),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(tooltip: 'แก้ไข', icon: const Icon(Icons.edit_outlined), onPressed: _goEdit),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _profileStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดโปรไฟล์'));
          }

          final data = snap.data?.data();
          if (data == null || data.isEmpty) return _buildEmptyState(cs);

          return _buildFullPage(cs, UserProfile.fromMap(data));
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ยังไม่มีโปรไฟล์
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: cs.primary.withValues(alpha: 0.12),
              child: Icon(Icons.person_outline, size: 36, color: cs.primary),
            ),
            const SizedBox(height: 10),
            const Text('ยังไม่มีข้อมูลโปรไฟล์', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'กดเพื่อสร้างโปรไฟล์สำหรับคำนวณ/บันทึกข้อมูล',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _goEdit,
              icon: const Icon(Icons.add),
              label: const Text('สร้างโปรไฟล์'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // หน้าเต็ม: โปรไฟล์ + ประวัติ + ตั้งค่า
  // ---------------------------------------------------------------------------
  Widget _buildFullPage(ColorScheme cs, UserProfile p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ===== ข้อมูลส่วนตัว =====
        _buildProfileHeader(cs, p),
        const SizedBox(height: 8),
        _infoTile(cs, icon: Icons.cake_outlined, title: '${p.age} ปี', subtitle: 'อายุ'),
        _infoTile(cs, icon: Icons.height, title: '${p.heightCm.toStringAsFixed(0)} cm', subtitle: 'ส่วนสูง'),
        _infoTile(cs, icon: Icons.monitor_weight_outlined, title: '${p.weightKg.toStringAsFixed(0)} kg', subtitle: 'น้ำหนัก'),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: _goEdit, icon: const Icon(Icons.edit), label: const Text('แก้ไขโปรไฟล์')),

        const SizedBox(height: 24),

        // ===== ประวัติมื้ออาหาร =====
        _buildHistorySection(cs),

        const SizedBox(height: 24),

        // ===== ตั้งค่า =====
        _buildSettingsSection(cs),

        const SizedBox(height: 20),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Profile header
  // ---------------------------------------------------------------------------
  Widget _buildProfileHeader(ColorScheme cs, UserProfile p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: cs.primary.withValues(alpha: 0.12),
              child: Text(
                p.nickName.isNotEmpty ? p.nickName[0].toUpperCase() : (p.firstName.isNotEmpty ? p.firstName[0].toUpperCase() : '?'),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: cs.primary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.firstName.isEmpty ? 'ไม่ระบุชื่อ' : p.firstName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.nickName.isEmpty ? 'ยังไม่มีชื่อเล่น' : 'ชื่อเล่น: ${p.nickName}',
                    style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? '',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ประวัติมื้ออาหาร
  // ---------------------------------------------------------------------------
  Widget _buildHistorySection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 20, color: cs.primary),
            const SizedBox(width: 6),
            const Text('ประวัติมื้ออาหาร', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _historyStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Card(child: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())));
            }

            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text('ยังไม่มีประวัติ', style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                ),
              );
            }

            return Card(
              child: Column(
                children: [
                  for (int i = 0; i < docs.length; i++) ...[
                    _historyTile(cs, docs[i].data()),
                    if (i < docs.length - 1) const Divider(height: 1, indent: 56, endIndent: 14),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _historyTile(ColorScheme cs, Map<String, dynamic> data) {
    final name = (data['foodName'] ?? '-').toString();
    final mealType = (data['mealType'] ?? '').toString();
    final cal = (data['calories'] is num) ? (data['calories'] as num).round() : 0;
    final ts = data['createdAt'];
    String dateStr = '';
    if (ts is Timestamp) {
      final d = ts.toDate();
      dateStr = '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    const mealIcons = {
      'มื้อเช้า': Icons.wb_sunny_outlined,
      'มื้อเที่ยง': Icons.sunny,
      'มื้อเย็น': Icons.nightlight_outlined,
      'มื้อทานเล่น': Icons.cake_outlined,
    };

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: cs.primary.withValues(alpha: 0.10),
        child: Icon(mealIcons[mealType] ?? Icons.restaurant, size: 18, color: cs.primary),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$mealType  •  $cal kcal', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      trailing: Text(dateStr, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
    );
  }

  // ---------------------------------------------------------------------------
  // ตั้งค่า
  // ---------------------------------------------------------------------------
  Widget _buildSettingsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.settings, size: 20, color: cs.primary),
            const SizedBox(width: 6),
            const Text('ตั้งค่า', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _settingsTile(
                icon: Icons.edit_outlined,
                iconColor: cs.primary,
                title: 'แก้ไขโปรไฟล์',
                onTap: _goEdit,
              ),
              const Divider(height: 1, indent: 56, endIndent: 14),
              _settingsTile(
                icon: Icons.delete_outline,
                iconColor: Colors.red,
                title: 'ลบประวัติมื้ออาหารทั้งหมด',
                titleColor: Colors.red,
                onTap: _confirmDeleteHistory,
              ),
              const Divider(height: 1, indent: 56, endIndent: 14),
              _settingsTile(
                icon: Icons.logout,
                iconColor: Colors.red,
                title: 'ออกจากระบบ',
                titleColor: Colors.red,
                onTap: _confirmLogout,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Center(
          child: Text(
            'Calorie Scanner v1.0.0',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: iconColor.withValues(alpha: 0.10),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: titleColor)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  // ---------------------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------------------
  Widget _infoTile(ColorScheme cs, {required IconData icon, required String title, required String subtitle}) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: cs.primary.withValues(alpha: 0.10),
          child: Icon(icon, color: cs.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant)),
      ),
    );
  }
}
