import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'profile_edit_page.dart';
import 'user_profile.dart';
import 'widgets/cosmic_background.dart';
import 'widgets/frosted_card.dart';
import 'widgets/hover_scale.dart';

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
    _profileStream =
        FirebaseFirestore.instance.collection('users').doc(_uid).snapshots();
    _historyStream = FirebaseFirestore.instance
        .collection('meals')
        .where('uid', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  void _goEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditPage()),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบใช่ไหม?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _confirmDeleteHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบประวัติทั้งหมด'),
        content: const Text('ข้อมูลมื้ออาหารทั้งหมดจะถูกลบ ดำเนินการต่อ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
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
        const SnackBar(
          content: Text('ลบประวัติทั้งหมดแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: HoverScale(
              borderRadius: BorderRadius.circular(999),
              onTap: _goEdit,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: 'แก้ไข',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _goEdit,
                ),
              ),
            ),
          ),
        ],
      ),
      body: CosmicBackground(
        useSafeArea: true,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _profileStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return const Center(
                child: Text(
                  'เกิดข้อผิดพลาดในการโหลดโปรไฟล์',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final data = snap.data?.data();
            if (data == null || data.isEmpty) {
              return _buildEmptyState(cs);
            }

            return _buildFullPage(cs, UserProfile.fromMap(data));
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: FrostedCard(
            borderRadius: BorderRadius.circular(28),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: cs.primary.withOpacity(0.12),
                  child: Icon(
                    Icons.person_outline,
                    size: 36,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'ยังไม่มีข้อมูลโปรไฟล์',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'สร้างโปรไฟล์เพื่อให้แอปคำนวณและบันทึกข้อมูลได้ดีขึ้น',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                HoverScale(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _goEdit,
                  child: FilledButton.icon(
                    onPressed: _goEdit,
                    icon: const Icon(Icons.add),
                    label: const Text('สร้างโปรไฟล์'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullPage(ColorScheme cs, UserProfile p) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _buildPageTitle(),
        const SizedBox(height: 16),
        _buildProfileHeader(cs, p),
        const SizedBox(height: 16),
        _buildInfoGrid(cs, p),
        const SizedBox(height: 24),
        _buildHistorySection(cs),
        const SizedBox(height: 24),
        _buildSettingsSection(cs),
      ],
    );
  }

  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'โปรไฟล์ของฉัน',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'ดูข้อมูลสุขภาพและจัดการบัญชีของคุณ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(ColorScheme cs, UserProfile p) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final displayLetter = p.nickName.isNotEmpty
        ? p.nickName[0].toUpperCase()
        : (p.firstName.isNotEmpty ? p.firstName[0].toUpperCase() : '?');

    return FrostedCard(
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: cs.primary.withOpacity(0.12),
            child: Text(
              displayLetter,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.firstName.isEmpty ? 'ไม่ระบุชื่อ' : p.firstName,
                  style: const TextStyle(
                    fontSize: 20,
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
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(ColorScheme cs, UserProfile p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ข้อมูลสุขภาพ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.28,
          children: [
            _statCard(
              cs,
              icon: Icons.cake_outlined,
              title: '${p.age}',
              subtitle: 'อายุ (ปี)',
            ),
            _statCard(
              cs,
              icon: Icons.height,
              title: p.heightCm.toStringAsFixed(0),
              subtitle: 'ส่วนสูง (cm)',
            ),
            _statCard(
              cs,
              icon: Icons.monitor_weight_outlined,
              title: p.weightKg.toStringAsFixed(0),
              subtitle: 'น้ำหนัก (kg)',
            ),
            _statCard(
              cs,
              icon: Icons.edit_note_rounded,
              title: 'จัดการ',
              subtitle: 'แก้ไขโปรไฟล์',
              onTap: _goEdit,
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return HoverScale(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: FrostedCard(
        borderRadius: BorderRadius.circular(22),
        padding: const EdgeInsets.all(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primary.withOpacity(0.12),
                child: Icon(icon, size: 18, color: cs.primary),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ประวัติมื้ออาหาร',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _historyStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const FrostedCard(
                child: SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return FrostedCard(
                borderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.all(22),
                child: Center(
                  child: Text(
                    'ยังไม่มีประวัติการบันทึก',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              );
            }

            return FrostedCard(
              borderRadius: BorderRadius.circular(24),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (int i = 0; i < docs.length; i++) ...[
                    _historyTile(cs, docs[i].data()),
                    if (i < docs.length - 1)
                      const Divider(height: 1, indent: 64, endIndent: 16),
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
    final cal =
        (data['calories'] is num) ? (data['calories'] as num).round() : 0;

    final ts = data['createdAt'];
    String dateStr = '';
    if (ts is Timestamp) {
      final d = ts.toDate();
      dateStr =
          '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    const mealIcons = {
      'มื้อเช้า': Icons.wb_sunny_outlined,
      'มื้อเที่ยง': Icons.sunny,
      'มื้อเย็น': Icons.nightlight_outlined,
      'มื้อทานเล่น': Icons.cake_outlined,
    };

    return HoverScale(
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: cs.primary.withOpacity(0.10),
          child: Icon(
            mealIcons[mealType] ?? Icons.restaurant,
            size: 18,
            color: cs.primary,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$mealType  •  $cal kcal',
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          dateStr,
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ตั้งค่า',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        FrostedCard(
          borderRadius: BorderRadius.circular(24),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _settingsTile(
                icon: Icons.edit_outlined,
                iconColor: cs.primary,
                title: 'แก้ไขโปรไฟล์',
                onTap: _goEdit,
              ),
              const Divider(height: 1, indent: 64, endIndent: 16),
              _settingsTile(
                icon: Icons.delete_outline,
                iconColor: Colors.red,
                title: 'ลบประวัติมื้ออาหารทั้งหมด',
                titleColor: Colors.red,
                onTap: _confirmDeleteHistory,
              ),
              const Divider(height: 1, indent: 64, endIndent: 16),
              _settingsTile(
                icon: Icons.logout_rounded,
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.70),
            ),
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
    return HoverScale(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: iconColor.withOpacity(0.10),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }
}
