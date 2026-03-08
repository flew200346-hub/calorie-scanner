import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ---------------------------------------------------------------------------
// สีประจำมื้อ
// ---------------------------------------------------------------------------
const Map<String, Color> _mealColors = {
  'มื้อเช้า': Color(0xFFFFC107),
  'มื้อเที่ยง': Color(0xFF4CAF50),
  'มื้อเย็น': Color(0xFF3F51B5),
  'มื้อทานเล่น': Color(0xFFE91E63),
};

class FoodResultPage extends StatefulWidget {
  final String foodName;
  final String thaiName;
  final double confidence;
  final String mealType;

  const FoodResultPage({
    super.key,
    required this.foodName,
    required this.thaiName,
    required this.confidence,
    this.mealType = 'มื้อเที่ยง',
  });

  @override
  State<FoodResultPage> createState() => _FoodResultPageState();
}

class _FoodResultPageState extends State<FoodResultPage> {
  late Future<Map<String, dynamic>?> _nutritionFuture;
  bool _saved = false;
  bool _saving = false;

  Color get _accentColor => _mealColors[widget.mealType] ?? const Color(0xFF4CAF50);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _nutritionFuture = _fetchNutrition();
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>?> _fetchNutrition() async {
    final localData = <String, Map<String, dynamic>>{
      'BBQ-Pork-Rice': {'calories': 540, 'protein_g': 18, 'fat_total_g': 15, 'carbohydrates_total_g': 82},
      'Bitter-Melon-Soup': {'calories': 85, 'protein_g': 6, 'fat_total_g': 2, 'carbohydrates_total_g': 10},
      'Chicken-Biryani': {'calories': 630, 'protein_g': 28, 'fat_total_g': 22, 'carbohydrates_total_g': 78},
      'Chicken-Rice': {'calories': 596, 'protein_g': 24, 'fat_total_g': 28, 'carbohydrates_total_g': 62},
      'Curried-Fish-Cake': {'calories': 270, 'protein_g': 14, 'fat_total_g': 16, 'carbohydrates_total_g': 18},
      'Dipping-sauce': {'calories': 45, 'protein_g': 1, 'fat_total_g': 1, 'carbohydrates_total_g': 9},
      'Dumpling': {'calories': 260, 'protein_g': 12, 'fat_total_g': 10, 'carbohydrates_total_g': 30},
      'Eggs-Stewed': {'calories': 180, 'protein_g': 12, 'fat_total_g': 12, 'carbohydrates_total_g': 6},
      'Fried-Chicken': {'calories': 480, 'protein_g': 32, 'fat_total_g': 28, 'carbohydrates_total_g': 22},
      'Fried-Egg': {'calories': 117, 'protein_g': 7, 'fat_total_g': 9, 'carbohydrates_total_g': 1},
      'Fried-Noodle-in-Gravy-Sauce': {'calories': 405, 'protein_g': 15, 'fat_total_g': 12, 'carbohydrates_total_g': 60},
      'Fried-Oysters': {'calories': 350, 'protein_g': 12, 'fat_total_g': 20, 'carbohydrates_total_g': 30},
      'Fried-Rice-with-Shrimp-Paste': {'calories': 520, 'protein_g': 16, 'fat_total_g': 22, 'carbohydrates_total_g': 65},
      'Green-Curry': {'calories': 480, 'protein_g': 20, 'fat_total_g': 28, 'carbohydrates_total_g': 38},
      'Grill-Shrimp': {'calories': 220, 'protein_g': 30, 'fat_total_g': 8, 'carbohydrates_total_g': 4},
      'Grilled-Pork-Neck': {'calories': 390, 'protein_g': 28, 'fat_total_g': 28, 'carbohydrates_total_g': 5},
      'Kai-look-khei': {'calories': 320, 'protein_g': 14, 'fat_total_g': 22, 'carbohydrates_total_g': 18},
      'Kai-Yang': {'calories': 350, 'protein_g': 35, 'fat_total_g': 18, 'carbohydrates_total_g': 8},
      'Kua-Jab-Nam-Khon': {'calories': 450, 'protein_g': 18, 'fat_total_g': 20, 'carbohydrates_total_g': 50},
      'Massaman-Curry': {'calories': 550, 'protein_g': 22, 'fat_total_g': 30, 'carbohydrates_total_g': 48},
      'Omelet': {'calories': 445, 'protein_g': 12, 'fat_total_g': 28, 'carbohydrates_total_g': 35},
      'Pad-Kaprao': {'calories': 550, 'protein_g': 22, 'fat_total_g': 25, 'carbohydrates_total_g': 58},
      'Pad-Thai': {'calories': 485, 'protein_g': 14, 'fat_total_g': 15, 'carbohydrates_total_g': 75},
      'Papaya-Salad': {'calories': 120, 'protein_g': 5, 'fat_total_g': 2, 'carbohydrates_total_g': 21},
      'Poo-Pad-Pongali': {'calories': 380, 'protein_g': 20, 'fat_total_g': 22, 'carbohydrates_total_g': 25},
      'Pork Satay': {'calories': 340, 'protein_g': 24, 'fat_total_g': 20, 'carbohydrates_total_g': 16},
      'Pork-porridge': {'calories': 280, 'protein_g': 15, 'fat_total_g': 8, 'carbohydrates_total_g': 38},
      'Pork-with-Garlic': {'calories': 520, 'protein_g': 25, 'fat_total_g': 30, 'carbohydrates_total_g': 38},
      'Roast-fish': {'calories': 300, 'protein_g': 35, 'fat_total_g': 14, 'carbohydrates_total_g': 5},
      'Spicy-Mincing-Pork-Salad': {'calories': 250, 'protein_g': 20, 'fat_total_g': 15, 'carbohydrates_total_g': 10},
      'Stewed-Pork-Leg-Rice': {'calories': 650, 'protein_g': 20, 'fat_total_g': 35, 'carbohydrates_total_g': 65},
      'Stir-fried-Kale-with-Crispy-Pork': {'calories': 620, 'protein_g': 18, 'fat_total_g': 38, 'carbohydrates_total_g': 52},
      'Stir-fried-Morning-Glory': {'calories': 150, 'protein_g': 5, 'fat_total_g': 8, 'carbohydrates_total_g': 14},
      'Stir-fried-Noodles-in-Soy-Sauce': {'calories': 520, 'protein_g': 14, 'fat_total_g': 24, 'carbohydrates_total_g': 62},
      'Thai-clear-soup': {'calories': 100, 'protein_g': 8, 'fat_total_g': 3, 'carbohydrates_total_g': 8},
      'Thai-Noodles-with-Pork-and-Blood-Soup': {'calories': 420, 'protein_g': 22, 'fat_total_g': 15, 'carbohydrates_total_g': 50},
      'Yum-Woon-Sen': {'calories': 200, 'protein_g': 10, 'fat_total_g': 6, 'carbohydrates_total_g': 28},
    };

    return localData[widget.foodName];
  }

  Future<void> _saveMeal(Map<String, dynamic> nutrients) async {
    setState(() => _saving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('Save failed: user not logged in');
      setState(() => _saving = false);
      return;
    }

    try {
      // เขียนลง local cache ทันที ไม่ต้องรอ server
      FirebaseFirestore.instance.collection('meals').add({
        'uid': uid,
        'foodName': widget.thaiName,
        'mealType': widget.mealType,
        'calories': nutrients['calories'] ?? 0,
        'protein_g': nutrients['protein_g'] ?? 0,
        'fat_total_g': nutrients['fat_total_g'] ?? 0,
        'carbohydrates_total_g': nutrients['carbohydrates_total_g'] ?? 0,
        'confidence': widget.confidence,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Save success!');
      if (mounted) {
        setState(() { _saved = true; _saving = false; });
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('บันทึกสำเร็จ'),
            content: Text('บันทึก "${widget.thaiName}" เรียบร้อยแล้ว'),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('ตกลง')),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        setState(() => _saving = false);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
            title: const Text('บันทึกไม่สำเร็จ'),
            content: Text('$e'),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('ตกลง')),
            ],
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(widget.thaiName),
        backgroundColor: _accentColor.withOpacity(0.08),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_accentColor.withOpacity(0.12), cs.surface],
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _nutritionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final nutrients = snapshot.data;
            final cal = nutrients?['calories'] ?? 0;
            final protein = nutrients?['protein_g'] ?? 0;
            final fat = nutrients?['fat_total_g'] ?? 0;
            final carb = nutrients?['carbohydrates_total_g'] ?? 0;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                const SizedBox(height: 8),

                // ชื่ออาหาร + confidence
                Center(
                  child: Column(
                    children: [
                      Text(
                        widget.thaiName,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        avatar: Icon(Icons.auto_awesome, size: 16, color: _accentColor),
                        label: Text(
                          'ความมั่นใจ ${(widget.confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(color: _accentColor, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: _accentColor.withOpacity(0.10),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // วงแคลอรี่
                Center(child: _buildCalorieCircle(cal)),

                const SizedBox(height: 28),

                // Macro cards
                Row(
                  children: [
                    Expanded(child: _macroCard('Protein', protein, 'g', Colors.redAccent, Icons.fitness_center)),
                    const SizedBox(width: 10),
                    Expanded(child: _macroCard('Fat', fat, 'g', Colors.orange, Icons.water_drop)),
                    const SizedBox(width: 10),
                    Expanded(child: _macroCard('Carbs', carb, 'g', Colors.blueAccent, Icons.grain)),
                  ],
                ),

                const SizedBox(height: 20),

                // มื้ออาหาร
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: _accentColor.withOpacity(0.25)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _accentColor.withOpacity(0.15),
                      child: Icon(Icons.restaurant, color: _accentColor),
                    ),
                    title: Text(widget.mealType, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('ประเภทมื้ออาหาร'),
                  ),
                ),

                const SizedBox(height: 24),

                // ปุ่มบันทึก
                if (nutrients != null)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _saved ? Colors.green : _accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: (_saved || _saving) ? null : () => _saveMeal(nutrients),
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(_saved ? Icons.check : Icons.save),
                    label: Text(_saving ? 'กำลังบันทึก...' : (_saved ? 'บันทึกแล้ว' : 'บันทึกมื้ออาหาร')),
                  ),

                const SizedBox(height: 12),

                // ปุ่มกลับ
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accentColor,
                    side: BorderSide(color: _accentColor, width: 1.6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('กลับสู่หน้าสแกน'),
                ),

                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widget helpers
  // ---------------------------------------------------------------------------
  Widget _buildCalorieCircle(dynamic cal) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [_accentColor.withOpacity(0.15), _accentColor.withOpacity(0.04)],
        ),
        border: Border.all(color: _accentColor, width: 5),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.20),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$cal',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: _accentColor,
            ),
          ),
          Text('kcal', style: TextStyle(fontSize: 14, color: _accentColor.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _macroCard(String label, dynamic value, String unit, Color color, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              '$value$unit',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
