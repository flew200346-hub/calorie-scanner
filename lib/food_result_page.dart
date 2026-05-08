// ============================================================================
// food_result_page.dart — แสดงผลวิเคราะห์อาหาร + ปรับ portion + บันทึก
// ----------------------------------------------------------------------------
// รับค่าจาก scan_page (หรือ home_page เมื่อกดอาหารที่เคยกิน)
// ฟีเจอร์หลัก:
//   - แสดงแคล/protein/fat/carbs ที่ scale ตาม _portion (½, 1, 1½, 2, 3 จาน)
//   - กด "บันทึก" → fire-and-forget Firestore (instant UX)
//     บันทึกค่าที่ scaled แล้ว (ตรงกับที่กินจริง) + portion + servingSize label
//   - หลังบันทึก disable chip portion + ปุ่ม save (กันบันทึกซ้ำ)
//
// Firestore collection: "meals"
// Schema: {uid, foodName, mealType, calories, protein_g, fat_total_g,
//          carbohydrates_total_g, confidence, servingSize, portion, createdAt}
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'widgets/cosmic_background.dart';
import 'widgets/frosted_card.dart';
import 'widgets/hover_scale.dart';

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
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final String servingSize;

  const FoodResultPage({
    super.key,
    required this.foodName,
    required this.thaiName,
    required this.confidence,
    this.mealType = 'มื้อเที่ยง',
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.servingSize = '1 จาน',
  });

  @override
  State<FoodResultPage> createState() => _FoodResultPageState();
}

class _FoodResultPageState extends State<FoodResultPage> {
  bool _saved = false;
  bool _saving = false;

  /// Serving multiplier — scale ค่าโภชนาการทุกตัวเมื่อ user เลือก chip
  /// ค่าเริ่มต้น 1.0 = 1 จาน (ตามที่ AI ประเมินมา)
  /// _calories, _protein, _fat, _carbs (getters) คูณ _portion ทุกครั้งที่ build
  double _portion = 1.0;

  Color get _accentColor =>
      _mealColors[widget.mealType] ?? const Color(0xFF4CAF50);

  double get _calories => widget.calories * _portion;
  double get _protein => widget.protein * _portion;
  double get _fat => widget.fat * _portion;
  double get _carbs => widget.carbs * _portion;

  String get _portionLabel {
    if (_portion == 0.5) return '½ จาน';
    if (_portion == 1.0) return '1 จาน';
    if (_portion == 1.5) return '1½ จาน';
    return '${_portion.toStringAsFixed(0)} จาน';
  }

  /// บันทึกมื้ออาหารแบบ fire-and-forget (UX instant)
  /// - ไม่ await Firestore → pop กลับทันที, sync เบื้องหลัง
  /// - error → SnackBar แดงในหน้าก่อนหน้า (capture messenger ก่อน pop)
  /// - guard `_saved || _saving` กันยิงซ้ำ
  Future<void> _saveMeal() async {
    if (_saved || _saving) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: 'บันทึกไม่สำเร็จ',
        content: 'ไม่พบผู้ใช้ที่ล็อกอินอยู่',
      );
      return;
    }

    setState(() {
      _saving = true;
      _saved = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    FirebaseFirestore.instance.collection('meals').add({
      'uid': uid,
      'foodName': widget.thaiName,
      'mealType': widget.mealType,
      'calories': _calories,
      'protein_g': _protein,
      'fat_total_g': _fat,
      'carbohydrates_total_g': _carbs,
      'confidence': widget.confidence,
      'servingSize': _portionLabel,
      'portion': _portion,
      'createdAt': Timestamp.now(),
    }).then(
      (_) {},
      onError: (_) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('บันทึกไม่สำเร็จ ลองใหม่อีกครั้ง'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text('บันทึก "${widget.thaiName}" เรียบร้อยแล้ว'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() => _saving = false);
  }

  void _showDialog({
    required Widget icon,
    required String title,
    required String content,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        icon: icon,
        title: Text(title),
        content: Text(content),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.thaiName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CosmicBackground(
        useSafeArea: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildPageTitle(),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    widget.thaiName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _accentColor.withOpacity(0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: _accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ความมั่นใจ ${(widget.confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(child: _buildCalorieCircle(_calories)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _macroCard(
                    'Protein',
                    _protein,
                    'g',
                    Colors.redAccent,
                    Icons.fitness_center,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _macroCard(
                    'Fat',
                    _fat,
                    'g',
                    Colors.orange,
                    Icons.water_drop,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _macroCard(
                    'Carbs',
                    _carbs,
                    'g',
                    Colors.blueAccent,
                    Icons.grain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPortionSelector(),
            const SizedBox(height: 20),
            FrostedCard(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'สรุปโภชนาการ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _nutritionRow('ขนาดจาน', _portionLabel),
                  _nutritionRow(
                      'พลังงาน', '${_calories.toStringAsFixed(0)} kcal'),
                  _nutritionRow('โปรตีน', '${_protein.toStringAsFixed(0)} g'),
                  _nutritionRow('ไขมัน', '${_fat.toStringAsFixed(0)} g'),
                  _nutritionRow(
                      'คาร์โบไฮเดรต', '${_carbs.toStringAsFixed(0)} g'),
                  _nutritionRow(
                    'ความมั่นใจ',
                    '${(widget.confidence * 100).toStringAsFixed(1)}%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            HoverScale(
              borderRadius: BorderRadius.circular(18),
              onTap: (_saved || _saving) ? null : _saveMeal,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _saved
                        ? const [Colors.green, Colors.green]
                        : const [Color(0xFF7C5CFF), Color(0xFF5E8BFF)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: (_saved ? Colors.green : const Color(0xFF7C5CFF))
                          .withOpacity(0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: (_saved || _saving) ? null : _saveMeal,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(_saved ? Icons.check : Icons.save),
                    label: Text(
                      _saving
                          ? 'กำลังบันทึก...'
                          : (_saved ? 'บันทึกแล้ว' : 'บันทึกมื้ออาหาร'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            HoverScale(
              borderRadius: BorderRadius.circular(18),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accentColor,
                  side: BorderSide(color: _accentColor, width: 1.6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('กลับสู่หน้าสแกน'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ผลลัพธ์การวิเคราะห์',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'ตรวจสอบข้อมูลก่อนบันทึกมื้ออาหาร',
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPortionSelector() {
    const options = [0.5, 1.0, 1.5, 2.0, 3.0];
    String label(double v) {
      if (v == 0.5) return '½';
      if (v == 1.0) return '1';
      if (v == 1.5) return '1½';
      return v.toStringAsFixed(0);
    }

    return FrostedCard(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _accentColor.withOpacity(0.15),
                child: Icon(Icons.restaurant, color: _accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mealType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'ขนาดจาน: $_portionLabel',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((v) {
              final selected = _portion == v;
              return ChoiceChip(
                selected: selected,
                showCheckmark: false,
                onSelected: (_) {
                  if (_saved) return;
                  setState(() => _portion = v);
                },
                label: Text(
                  '×${label(v)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : _accentColor,
                  ),
                ),
                backgroundColor: Colors.white.withOpacity(0.06),
                selectedColor: _accentColor,
                side: BorderSide(
                  color: _accentColor.withOpacity(selected ? 0 : 0.30),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieCircle(double cal) {
    return Container(
      width: 178,
      height: 178,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _accentColor.withOpacity(0.18),
            _accentColor.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: _accentColor, width: 5),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.22),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            cal.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: _accentColor,
            ),
          ),
          Text(
            'kcal',
            style: TextStyle(
              fontSize: 14,
              color: _accentColor.withOpacity(0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroCard(
    String label,
    double value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return FrostedCard(
      borderRadius: BorderRadius.circular(18),
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
            '${value.toStringAsFixed(0)}$unit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }

  Widget _nutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[300]),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
