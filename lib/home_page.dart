import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'scan_page.dart';
import 'exercise_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();
  String _selectedMeal = 'มื้อเช้า';

  // เป้าหมายต่อวัน (ค่อยเปลี่ยนไปคำนวณจากโปรไฟล์ได้ทีหลัง)
  final int _dailyGoal = 1955;

  // ===== สีประจำแต่ละมื้อ (แก้ตรงนี้จุดเดียว สีจะเปลี่ยนทั้งหน้า) =====
  final Map<String, Color> _mealColors = const {
    'มื้อเช้า': Color(0xFFFFC107), // เหลือง
    'มื้อเที่ยง': Color(0xFF4CAF50), // เขียว
    'มื้อเย็น': Color(0xFF3F51B5), // น้ำเงิน
    'มื้อทานเล่น': Color(0xFFE91E63), // ชมพู
    'การออกกำลังกาย': Color(0xFFFF5722), // ส้ม
  };

  Color _colorOf(String meal) =>
      _mealColors[meal] ?? const Color.fromARGB(255, 245, 190, 10);

  DocumentReference<Map<String, dynamic>> _userDoc() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _mealsCol() {
    // ชื่อ collection meals ของคุณ
    return FirebaseFirestore.instance.collection('meals');
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  Stream<int> _todayCaloriesStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();
    final start = Timestamp.fromDate(_startOfDay(now));
    final end = Timestamp.fromDate(_endOfDay(now));

    return _mealsCol()
        .where('uid', isEqualTo: uid)
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .snapshots()
        .map((q) {
      int sum = 0;
      for (final d in q.docs) {
        final c = d.data()['calories'];
        if (c is num) sum += c.round();
      }
      return sum;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _recentFoodsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _mealsCol()
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(6)
        .snapshots();
  }

  void _goMealScan(String mealType, {String? prefillFoodName}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          initialMeal: mealType,
          // ถ้า ScanPage คุณยังไม่มีพารามิเตอร์นี้ ให้ลบบรรทัดนี้ออก
          initialFoodName: prefillFoodName,
        ),
      ),
    );
  }

  void _goExercise() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExercisePage()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Scanner'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(0, 4, 195, 248),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          children: [
            // ===== Greeting =====
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

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'สวัสดี $displayName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'สแกน',
                      onPressed: () => _goMealScan(_selectedMeal),
                      icon: const Icon(Icons.qr_code_scanner),
                    )
                  ],
                );
              },
            ),

            const SizedBox(height: 10),

            // ===== Summary (วงเปอร์เซ็นต์) =====
            StreamBuilder<int>(
              stream: _todayCaloriesStream(),
              builder: (context, snap) {
                final eaten = snap.data ?? 0;
                final pct = _dailyGoal <= 0
                    ? 0.0
                    : (eaten / _dailyGoal).clamp(0.0, 1.0);

                final mealColor = _colorOf(_selectedMeal);

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: pct,
                                strokeWidth: 10,
                                backgroundColor: cs.surfaceContainerHighest,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(mealColor),
                              ),
                              Text(
                                '${(pct * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'วันนี้',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$eaten / $_dailyGoal kcal',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              FilledButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'เดี๋ยวค่อยต่อระบบแนะนำอาหารนะ 😊',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('แนะนำอาหาร'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // ===== Search bar =====
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.search),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'ค้นหาอาหาร หรือพิมพ์ชื่อแล้วกดค้นหา…',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (q) {
                          final text = q.trim();
                          if (text.isEmpty) return;
                          _goMealScan(_selectedMeal, prefillFoodName: text);
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'สแกน',
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () => _goMealScan(_selectedMeal),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ===== Meal tabs =====
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('มื้อเช้า', Icons.wb_sunny_outlined),
                  const SizedBox(width: 8),
                  _chip('มื้อเที่ยง', Icons.sunny),
                  const SizedBox(width: 8),
                  _chip('มื้อเย็น', Icons.nightlight_outlined),
                  const SizedBox(width: 8),
                  _chip('มื้อทานเล่น', Icons.cake_outlined),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ===== สรุปแคลอรี่ (วันนี้) แบบกดเข้า scan ได้ =====
            const Text(
              'สรุปแคลอรี่ (วันนี้)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _mealTile(
              context,
              title: 'มื้อเช้า',
              icon: Icons.wb_sunny_outlined,
              type: 'meal',
              mealType: 'มื้อเช้า',
            ),
            _mealTile(
              context,
              title: 'มื้อเที่ยง',
              icon: Icons.sunny,
              type: 'meal',
              mealType: 'มื้อเที่ยง',
            ),
            _mealTile(
              context,
              title: 'มื้อเย็น',
              icon: Icons.nightlight_outlined,
              type: 'meal',
              mealType: 'มื้อเย็น',
            ),
            _mealTile(
              context,
              title: 'มื้อทานเล่น',
              icon: Icons.cake_outlined,
              type: 'meal',
              mealType: 'มื้อทานเล่น',
            ),

            const SizedBox(height: 12),

            _mealTile(
              context,
              title: 'การออกกำลังกาย',
              icon: Icons.directions_run,
              type: 'exercise',
              mealType: 'การออกกำลังกาย',
            ),

            const SizedBox(height: 16),

            // ===== Recent foods =====
            Row(
              children: [
                const Text(
                  'RECENT FOODS',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  'ล่าสุด',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _recentFoodsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant_outlined),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'ยังไม่มีรายการอาหาร\nลองสแกนเพื่อเพิ่มรายการแรกได้เลย',
                            ),
                          ),
                          FilledButton(
                            onPressed: () => _goMealScan(_selectedMeal),
                            child: const Text('สแกน'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < docs.length; i++) ...[
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _colorOf(
                                    (docs[i].data()['mealType'] ??
                                            _selectedMeal)
                                        .toString())
                                .withOpacity(0.15),
                            child: Text(
                              ((docs[i].data()['foodName'] ?? 'F').toString())
                                  .trim()
                                  .characters
                                  .first
                                  .toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _colorOf((docs[i].data()['mealType'] ??
                                        _selectedMeal)
                                    .toString()),
                              ),
                            ),
                          ),
                          title: Text(
                            (docs[i].data()['foodName'] ?? 'Food').toString(),
                          ),
                          subtitle: Text(
                            '${(docs[i].data()['mealType'] ?? '').toString()} • '
                            '${(docs[i].data()['calories'] is num) ? (docs[i].data()['calories'] as num).round() : 0} cal',
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: _colorOf(
                                  (docs[i].data()['mealType'] ?? _selectedMeal)
                                      .toString()),
                            ),
                            onPressed: () => _goMealScan(
                              (docs[i].data()['mealType'] ?? _selectedMeal)
                                  .toString(),
                              prefillFoodName:
                                  (docs[i].data()['foodName'] ?? '').toString(),
                            ),
                          ),
                        ),
                        if (i != docs.length - 1)
                          const Divider(height: 1, indent: 14, endIndent: 14),
                      ],
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ===== Nutrition breakdown (placeholder) =====
            const Text(
              'NUTRITION BREAKDOWN',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  children: [
                    _MacroRow(
                      label: 'Carbs',
                      leftText: '40%',
                      rightText: '30%',
                      value: 0.40,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 10),
                    _MacroRow(
                      label: 'Fats',
                      leftText: '30%',
                      rightText: '30%',
                      value: 0.30,
                      color: Colors.purple,
                    ),
                    SizedBox(height: 10),
                    _MacroRow(
                      label: 'Protein',
                      leftText: '30%',
                      rightText: '40%',
                      value: 0.30,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Chip ที่เปลี่ยนสีได้ =====
  Widget _chip(String meal, IconData icon) {
    final selected = _selectedMeal == meal;
    final c = _colorOf(meal);

    return ChoiceChip(
      showCheckmark: false,
      selected: selected,
      onSelected: (_) => setState(() => _selectedMeal = meal),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: selected ? Colors.white : c,
          ),
          const SizedBox(width: 6),
          Text(
            meal,
            style: TextStyle(
              color: selected ? Colors.white : c,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      backgroundColor: c.withOpacity(0.10),
      selectedColor: c,
      side: BorderSide(color: c.withOpacity(selected ? 0 : 0.45)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  // ===== Tile ที่เปลี่ยนสีไอคอน/ปุ่มได้ =====
  Widget _mealTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String type, // 'meal' หรือ 'exercise'
    required String mealType,
  }) {
    final c = _colorOf(mealType);

    void go() {
      if (type == 'exercise') {
        _goExercise();
      } else {
        _goMealScan(mealType);
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: c.withOpacity(0.15),
          child: Icon(icon, color: c),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(type == 'exercise' ? 'เผาผลาญ 0 kcal' : '0 kcal'),
        trailing: IconButton(
          icon: Icon(Icons.add_circle, color: c),
          onPressed: go,
        ),
        onTap: go,
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String leftText;
  final String rightText;
  final double value; // 0..1
  final Color? color;

  const _MacroRow({
    required this.label,
    required this.leftText,
    required this.rightText,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        SizedBox(width: 80, child: Text('$label ($leftText)')),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: c.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(c),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 40, child: Text('($rightText)')),
      ],
    );
  }
}
