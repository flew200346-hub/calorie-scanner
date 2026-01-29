import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'scan_page.dart';
import 'exercise_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  DocumentReference<Map<String, dynamic>> _userDoc() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // สวัสดี + ชื่อจาก Firestore (nickName > firstName > email)
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _userDoc().snapshots(),
            builder: (context, snap) {
              String displayName = user?.email ?? '';
              final data = snap.data?.data();

              final nick = (data?['nickName'] ?? '').toString().trim();
              final first = (data?['firstName'] ?? '').toString().trim();

              if (nick.isNotEmpty) {
                displayName = nick;
              } else if (first.isNotEmpty) {
                displayName = first;
              }

              return Text(
                'สวัสดี $displayName',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              );
            },
          ),

          const SizedBox(height: 12),

          // สรุปแคล (mock)
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ทานไปแล้ว', style: TextStyle(fontSize: 14)),
                        SizedBox(height: 6),
                        Text(
                          '0 / 1955 kcal',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {},
                    child: const Text('แนะนำอาหาร'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Text(
            'สรุปแคลอรี่ (วันนี้)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _mealTile(context,
              title: 'มื้อเช้า',
              icon: Icons.wb_sunny_outlined,
              type: 'meal',
              mealType: 'มื้อเช้า'),
          _mealTile(context,
              title: 'มื้อเที่ยง',
              icon: Icons.sunny,
              type: 'meal',
              mealType: 'มื้อเที่ยง'),
          _mealTile(context,
              title: 'มื้อเย็น',
              icon: Icons.nightlight_outlined,
              type: 'meal',
              mealType: 'มื้อเย็น'),
          _mealTile(context,
              title: 'มื้อทานเล่น',
              icon: Icons.cake_outlined,
              type: 'meal',
              mealType: 'มื้อทานเล่น'),

          const SizedBox(height: 12),

          _mealTile(
            context,
            title: 'การออกกำลังกาย',
            icon: Icons.directions_run,
            type: 'exercise',
            mealType: 'การออกกำลังกาย',
          ),
        ],
      ),
    );
  }

  Widget _mealTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String type, // 'meal' หรือ 'exercise'
    required String mealType,
  }) {
    void go() {
      if (type == 'exercise') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExercisePage()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ScanPage(initialMeal: mealType)),
        );
      }
    }

    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(type == 'exercise' ? 'เผาผลาญ 0 kcal' : '0 kcal'),
        trailing: IconButton(
          icon: const Icon(Icons.add),
          onPressed: go,
        ),
        onTap: go,
      ),
    );
  }
}
