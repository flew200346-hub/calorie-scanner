import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'exercise_page.dart';
import 'food_result_page.dart';
import 'scan_page.dart';
import 'user_profile.dart';
import 'widgets/cosmic_background.dart';
import 'widgets/frosted_card.dart';
import 'widgets/hover_scale.dart';

const Map<String, Color> _mealColors = {
  'มื้อเช้า': Color(0xFFFFC107),
  'มื้อเที่ยง': Color(0xFF4CAF50),
  'มื้อเย็น': Color(0xFF3F51B5),
  'มื้อทานเล่น': Color(0xFFE91E63),
  'การออกกำลังกาย': Color(0xFFFF5722),
};

Color _colorOf(String meal) => _mealColors[meal] ?? const Color(0xFF7BBFA1);

class _DailyTotals {
  final int calories;
  final int carbsG;
  final int proteinG;
  final int fatG;

  const _DailyTotals({
    required this.calories,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
  });

  static const empty = _DailyTotals(
    calories: 0,
    carbsG: 0,
    proteinG: 0,
    fatG: 0,
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();
  String _selectedMeal = 'มื้อเช้า';

  static const int _fallbackGoal = 2000;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> _userDoc() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _mealsCol() {
    return FirebaseFirestore.instance.collection('meals');
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  Stream<_DailyTotals> _todayTotalsStream() {
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
      double cal = 0, carbs = 0, protein = 0, fat = 0;
      for (final d in q.docs) {
        final m = d.data();
        cal += _num(m['calories']);
        carbs += _num(m['carbohydrates_total_g']);
        protein += _num(m['protein_g']);
        fat += _num(m['fat_total_g']);
      }
      return _DailyTotals(
        calories: cal.round(),
        carbsG: carbs.round(),
        proteinG: protein.round(),
        fatG: fat.round(),
      );
    });
  }

  static double _num(dynamic v) => v is num ? v.toDouble() : 0;

  Stream<List<Map<String, dynamic>>> _recentUniqueFoodsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _mealsCol()
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(40)
        .snapshots()
        .map((q) {
      final seen = <String>{};
      final result = <Map<String, dynamic>>[];
      for (final doc in q.docs) {
        final data = doc.data();
        final name = (data['foodName'] ?? '').toString().trim();
        if (name.isEmpty || seen.contains(name)) continue;
        seen.add(name);
        result.add(data);
        if (result.length >= 8) break;
      }
      return result;
    });
  }

  Stream<int> _mealCaloriesToday(String mealType) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();
    final start = Timestamp.fromDate(_startOfDay(now));
    final end = Timestamp.fromDate(_endOfDay(now));

    return _mealsCol()
        .where('uid', isEqualTo: uid)
        .where('mealType', isEqualTo: mealType)
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

  void _goMealScan(String mealType, {String? prefillFoodName}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(
          initialMeal: mealType,
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: HoverScale(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () => FirebaseAuth.instance.signOut(),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: HoverScale(
        borderRadius: BorderRadius.circular(999),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C5CFF), Color(0xFF5E8BFF)],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C5CFF).withOpacity(0.30),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.transparent,
            elevation: 0,
            onPressed: () => _goMealScan(_selectedMeal),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('สแกนอาหาร'),
          ),
        ),
      ),
      body: CosmicBackground(
        useSafeArea: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            _buildGreeting(cs),
            const SizedBox(height: 16),
            _buildTodayCard(cs),
            const SizedBox(height: 16),
            _buildSearchCard(cs),
            const SizedBox(height: 16),
            _buildMealSection(cs),
            const SizedBox(height: 24),
            _buildRecentFoodsSection(cs),
            const SizedBox(height: 24),
            _buildNutritionSection(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(ColorScheme cs) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDoc().snapshots(),
      builder: (context, snap) {
        final user = FirebaseAuth.instance.currentUser;
        String displayName = user?.email ?? '';

        final data = snap.data?.data();
        final nick = (data?['nickName'] ?? '').toString().trim();
        final first = (data?['firstName'] ?? '').toString().trim();

        if (nick.isNotEmpty) {
          displayName = nick;
        } else if (first.isNotEmpty) {
          displayName = first;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สวัสดี, $displayName',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'พร้อมเริ่มดูแลสุขภาพวันนี้แล้ว ✨',
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodayCard(ColorScheme cs) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDoc().snapshots(),
      builder: (context, profileSnap) {
        final profileData = profileSnap.data?.data();
        final profile =
            profileData == null ? null : UserProfile.fromMap(profileData);
        final goal = (profile?.dailyCalorieGoal ?? 0) > 0
            ? profile!.dailyCalorieGoal
            : _fallbackGoal;

        return StreamBuilder<_DailyTotals>(
          stream: _todayTotalsStream(),
          builder: (context, totalsSnap) {
            final eaten = (totalsSnap.data ?? _DailyTotals.empty).calories;
            final remain = (goal - eaten).clamp(0, 999999);
            final pct = goal <= 0 ? 0.0 : (eaten / goal).clamp(0.0, 1.0);

            return FrostedCard(
              borderRadius: BorderRadius.circular(30),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calories Today',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$eaten / $goal kcal',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (profile == null || profile.dailyCalorieGoal <= 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'กรอกโปรไฟล์เพื่อคำนวณเป้าหมายจริงของคุณ',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 16,
                      backgroundColor:
                          cs.surfaceContainerHighest.withOpacity(0.55),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF8B7CFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _miniInfo(cs, title: 'เหลือ', value: '$remain kcal'),
                      const SizedBox(width: 10),
                      _miniInfo(
                        cs,
                        title: 'สำเร็จ',
                        value: '${(pct * 100).round()}%',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _miniInfo(
    ColorScheme cs, {
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard(ColorScheme cs) {
    return FrostedCard(
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'พิมพ์ชื่ออาหารเพื่อไปหน้าสแกน',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (q) {
                final text = q.trim();
                if (text.isEmpty) return;
                _goMealScan(_selectedMeal, prefillFoodName: text);
              },
            ),
          ),
          HoverScale(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C5CFF), Color(0xFF5E8BFF)],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _goMealScan(_selectedMeal),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'มื้ออาหาร',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _buildMealChips(),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _mealCard('มื้อเช้า', Icons.wb_sunny_outlined),
            _mealCard('มื้อเที่ยง', Icons.sunny),
            _mealCard('มื้อเย็น', Icons.nightlight_outlined),
            _mealCard('มื้อทานเล่น', Icons.cake_outlined),
          ],
        ),
        const SizedBox(height: 12),
        _exerciseCard(),
      ],
    );
  }

  Widget _buildMealChips() {
    return SingleChildScrollView(
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
    );
  }

  Widget _chip(String meal, IconData icon) {
    final selected = _selectedMeal == meal;
    final c = _colorOf(meal);

    return HoverScale(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _selectedMeal = meal),
      child: ChoiceChip(
        showCheckmark: false,
        selected: selected,
        onSelected: (_) => setState(() => _selectedMeal = meal),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : c),
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
        backgroundColor: Colors.white.withOpacity(0.08),
        selectedColor: c,
        side: BorderSide(color: c.withOpacity(selected ? 0 : 0.30)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _mealCard(String mealType, IconData icon) {
    final c = _colorOf(mealType);

    return StreamBuilder<int>(
      stream: _mealCaloriesToday(mealType),
      builder: (context, snap) {
        final cal = snap.data ?? 0;

        return HoverScale(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _goMealScan(mealType),
          child: FrostedCard(
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _goMealScan(mealType),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: c.withOpacity(0.18),
                      child: Icon(icon, color: c, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      mealType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$cal kcal',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _exerciseCard() {
    final c = _colorOf('การออกกำลังกาย');

    return HoverScale(
      borderRadius: BorderRadius.circular(24),
      onTap: _goExercise,
      child: FrostedCard(
        borderRadius: BorderRadius.circular(24),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: c.withOpacity(0.18),
            child: Icon(Icons.directions_run_rounded, color: c),
          ),
          title: const Text(
            'การออกกำลังกาย',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            'เพิ่มกิจกรรมที่เผาผลาญในวันนี้',
            style: TextStyle(color: Colors.white.withOpacity(0.70)),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: c),
          onTap: _goExercise,
        ),
      ),
    );
  }

  Widget _buildRecentFoodsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'อาหารที่เคยกิน',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _recentUniqueFoodsStream(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const FrostedCard(
                child: SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final foods = snap.data ?? const [];
            if (foods.isEmpty) {
              return FrostedCard(
                child: Row(
                  children: [
                    const Icon(Icons.restaurant_outlined),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('ยังไม่มีรายการอาหาร ลองสแกนรายการแรกได้เลย'),
                    ),
                    HoverScale(
                      borderRadius: BorderRadius.circular(999),
                      child: FilledButton(
                        onPressed: () => _goMealScan(_selectedMeal),
                        child: const Text('สแกน'),
                      ),
                    ),
                  ],
                ),
              );
            }

            return FrostedCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (int i = 0; i < foods.length; i++) ...[
                    _recentFoodTile(foods[i]),
                    if (i != foods.length - 1)
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

  Widget _recentFoodTile(Map<String, dynamic> data) {
    final mealType = (data['mealType'] ?? _selectedMeal).toString();
    final foodName = (data['foodName'] ?? 'Food').toString();
    final calories =
        (data['calories'] is num) ? (data['calories'] as num).round() : 0;
    final c = _colorOf(mealType);

    return HoverScale(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _reuseFood(data),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: c.withOpacity(0.18),
          child: Text(
            foodName.trim().isEmpty
                ? '?'
                : foodName.trim().characters.first.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: c,
            ),
          ),
        ),
        title: Text(
          foodName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$mealType • $calories kcal',
          style: TextStyle(color: Colors.white.withOpacity(0.68)),
        ),
        trailing: IconButton(
          tooltip: 'บันทึกอีกครั้ง',
          icon: Icon(Icons.add_circle_outline_rounded, color: c),
          onPressed: () => _reuseFood(data),
        ),
      ),
    );
  }

  void _reuseFood(Map<String, dynamic> data) {
    double toD(dynamic v) => v is num ? v.toDouble() : 0.0;

    final foodName = (data['foodName'] ?? 'Food').toString();
    final mealType = (data['mealType'] ?? _selectedMeal).toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodResultPage(
          foodName: foodName,
          thaiName: foodName,
          confidence: toD(data['confidence']),
          mealType: mealType,
          calories: toD(data['calories']),
          protein: toD(data['protein_g']),
          fat: toD(data['fat_total_g']),
          carbs: toD(data['carbohydrates_total_g']),
          servingSize: (data['servingSize'] ?? '1 จาน').toString(),
        ),
      ),
    );
  }

  Widget _buildNutritionSection(ColorScheme cs) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDoc().snapshots(),
      builder: (context, profileSnap) {
        final pData = profileSnap.data?.data();
        final profile = pData == null ? null : UserProfile.fromMap(pData);

        return StreamBuilder<_DailyTotals>(
          stream: _todayTotalsStream(),
          builder: (context, totalsSnap) {
            final t = totalsSnap.data ?? _DailyTotals.empty;

            final carbsTarget = profile?.carbsTargetG ?? 0;
            final proteinTarget = profile?.proteinTargetG ?? 0;
            final fatTarget = profile?.fatTargetG ?? 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nutrition Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                FrostedCard(
                  child: Column(
                    children: [
                      _MacroRow(
                        label: 'Carbs',
                        leftText: '${t.carbsG}g',
                        rightText: carbsTarget > 0 ? '/ ${carbsTarget}g' : '/ -',
                        value: _safeRatio(t.carbsG, carbsTarget),
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _MacroRow(
                        label: 'Fats',
                        leftText: '${t.fatG}g',
                        rightText: fatTarget > 0 ? '/ ${fatTarget}g' : '/ -',
                        value: _safeRatio(t.fatG, fatTarget),
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 12),
                      _MacroRow(
                        label: 'Protein',
                        leftText: '${t.proteinG}g',
                        rightText:
                            proteinTarget > 0 ? '/ ${proteinTarget}g' : '/ -',
                        value: _safeRatio(t.proteinG, proteinTarget),
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static double _safeRatio(int actual, int target) {
    if (target <= 0) return 0;
    return (actual / target).clamp(0.0, 1.0);
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String leftText;
  final String rightText;
  final double value;
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
        SizedBox(
          width: 88,
          child: Text(
            '$label ($leftText)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: c.withOpacity(0.14),
              valueColor: AlwaysStoppedAnimation<Color>(c),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 42,
          child: Text('($rightText)'),
        ),
      ],
    );
  }
}
