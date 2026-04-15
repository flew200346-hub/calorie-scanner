import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'food_result_page.dart';
import 'services/gemini_service.dart';
import 'widgets/cosmic_background.dart';
import 'widgets/frosted_card.dart';
import 'widgets/hover_scale.dart';

const Map<String, Color> _mealColors = {
  'มื้อเช้า': Color(0xFFFFC107),
  'มื้อเที่ยง': Color(0xFF4CAF50),
  'มื้อเย็น': Color(0xFF3F51B5),
  'มื้อทานเล่น': Color(0xFFE91E63),
};

class ScanPage extends StatefulWidget {
  final String initialMeal;
  final String? initialFoodName;

  const ScanPage({
    super.key,
    this.initialMeal = 'มื้อเที่ยง',
    this.initialFoodName,
  });

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _foodNameCtrl = TextEditingController();
  final GeminiService _geminiService = GeminiService();

  Uint8List? _imageBytes;
  late String _meal;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _nutritionResult;

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;

    final initName = (widget.initialFoodName ?? '').trim();
    if (initName.isNotEmpty) {
      _foodNameCtrl.text = initName;
    }
  }

  @override
  void dispose() {
    _foodNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();

    setState(() {
      _imageBytes = bytes;
      _nutritionResult = null;
    });
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกหรือถ่ายรูปภาพก่อน')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await _geminiService.detectFoodFromImage(_imageBytes!);

      if (!mounted) return;
      Navigator.pop(context);

      setState(() => _isAnalyzing = false);

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gemini วิเคราะห์รูปไม่สำเร็จ')),
        );
        return;
      }

      final foodName = (result['food_name'] ?? 'ไม่ทราบ').toString();
      final confidence = _toDouble(result['confidence']);
      final calories = _toDouble(result['calories_kcal']);
      final protein = _toDouble(result['protein_g']);
      final fat = _toDouble(result['fat_g']);
      final carbs = _toDouble(result['carbs_g']);
      final servingSize = (result['serving_size'] ?? '1 จาน').toString();

      _foodNameCtrl.text = foodName;

      setState(() {
        _nutritionResult = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$foodName • ${calories.toStringAsFixed(0)} kcal | P:${protein.toStringAsFixed(0)} F:${fat.toStringAsFixed(0)} C:${carbs.toStringAsFixed(0)}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FoodResultPage(
            foodName: foodName,
            thaiName: foodName,
            confidence: confidence,
            mealType: _meal,
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs,
            servingSize: servingSize,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);
      setState(() => _isAnalyzing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  Color _colorOf(String meal) => _mealColors[meal] ?? Colors.blueGrey;

  @override
  Widget build(BuildContext context) {
    final color = _colorOf(_meal);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Scan'),
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
            FrostedCard(
              child: DropdownButtonFormField<String>(
                initialValue: _meal,
                items: const [
                  DropdownMenuItem(value: 'มื้อเช้า', child: Text('มื้อเช้า')),
                  DropdownMenuItem(
                    value: 'มื้อเที่ยง',
                    child: Text('มื้อเที่ยง'),
                  ),
                  DropdownMenuItem(value: 'มื้อเย็น', child: Text('มื้อเย็น')),
                  DropdownMenuItem(
                    value: 'มื้อทานเล่น',
                    child: Text('มื้อทานเล่น'),
                  ),
                ],
                onChanged: (v) => setState(() => _meal = v ?? _meal),
                decoration: InputDecoration(
                  labelText: 'เลือกมื้อ',
                  prefixIcon: Icon(Icons.restaurant_menu_rounded, color: color),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FrostedCard(
              child: TextField(
                controller: _foodNameCtrl,
                decoration: InputDecoration(
                  labelText: 'ชื่ออาหาร',
                  hintText: 'AI จะเติมให้หลังวิเคราะห์',
                  prefixIcon: Icon(Icons.fastfood_outlined, color: color),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FrostedCard(
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1.28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.outlineVariant.withOpacity(0.35),
                        ),
                      ),
                      child: _imageBytes == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 52,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'ยังไม่มีรูปภาพ',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'กดถ่ายรูปหรือเลือกรูปจากคลัง',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: HoverScale(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => _pickImage(ImageSource.camera),
                          child: FilledButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('ถ่ายรูป'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: HoverScale(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => _pickImage(ImageSource.gallery),
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('เลือกรูป'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            HoverScale(
              borderRadius: BorderRadius.circular(999),
              onTap: _isAnalyzing ? null : _analyzeImage,
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
                child: SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeImage,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      _isAnalyzing ? 'กำลังวิเคราะห์...' : 'เริ่มวิเคราะห์',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_nutritionResult != null)
              _buildNutritionCard(cs, _nutritionResult!),
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
          'สแกนอาหารด้วย AI',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'เลือกรูปหรือถ่ายภาพอาหาร แล้วให้ AI ช่วยวิเคราะห์',
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionCard(
    ColorScheme cs,
    Map<String, dynamic> data,
  ) {
    return FrostedCard(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['food_name']?.toString() ?? 'ไม่ทราบชื่ออาหาร',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _nutritionRow('ปริมาณ', '${data['serving_size'] ?? '-'}'),
          _nutritionRow('พลังงาน', '${data['calories_kcal'] ?? '-'} kcal'),
          _nutritionRow('โปรตีน', '${data['protein_g'] ?? '-'} g'),
          _nutritionRow('ไขมัน', '${data['fat_g'] ?? '-'} g'),
          _nutritionRow('คาร์บ', '${data['carbs_g'] ?? '-'} g'),
          _nutritionRow('ความมั่นใจ', '${data['confidence'] ?? '-'}'),
        ],
      ),
    );
  }

  Widget _nutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
