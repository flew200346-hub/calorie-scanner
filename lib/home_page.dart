import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
          Text('สวัสดี ${user?.email ?? ""}',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),

          // Card calories summary (mock)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('ทานไปแล้ว', style: TextStyle(fontSize: 14)),
                        SizedBox(height: 6),
                        Text('0 / 1955 kcal',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {},
                    child: const Text('แนะนำอาหาร'),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Meal list mock
          const Text('สรุปแคลอรี่ (วันนี้)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          _mealTile(title: 'มื้อเช้า', icon: Icons.wb_sunny_outlined),
          _mealTile(title: 'มื้อเที่ยง', icon: Icons.sunny),
          _mealTile(title: 'มื้อเย็น', icon: Icons.nightlight_outlined),
          _mealTile(title: 'มื้อทานเล่น', icon: Icons.cake_outlined),

          const SizedBox(height: 12),
          _mealTile(title: 'การออกกำลังกาย', icon: Icons.directions_run),
        ],
      ),
    );
  }

  Widget _mealTile({required String title, required IconData icon}) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: const Text('0 kcal'),
        trailing: const Icon(Icons.add),
        onTap: () {},
      ),
    );
  }
}
