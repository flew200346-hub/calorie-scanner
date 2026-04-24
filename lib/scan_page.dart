import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'food_result_page.dart';
import 'services/gemini_service.dart';
import 'services/thai_food_names.dart';
import 'services/tflite_service.dart';
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
  final TfliteService _tflite = TfliteService();

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

    _tflite.init();
  }

  @override
  void dispose() {
    _foodNameCtrl.dispose();
    _tflite.dispose();
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

  Future<Map<String, dynamic>?> _runAnalysis(Uint8List bytes) async {
    // 1) Try on-device tflite first
    if (_tflite.isReady) {
      final tf = await _tflite.classify(bytes, minConfidence: 0.5);
      if (tf != null) {
        final thaiName = labelToThai(tf.label);
        debugPrint(
          '[Scan] tflite hit: ${tf.label} -> $thaiName (conf=${tf.confidence.toStringAsFixed(2)})',
        );

        // 2a) Check cache — if this user has saved this food before, reuse
        final cached = await _fetchCachedNutrition(thaiName);
        if (cached != null) {
          debugPrint('[Scan] cache hit for "$thaiName" — skipping Gemini');
          return {
            ...cached,
            'food_name': thaiName,
            'confidence': tf.confidence,
            'source': 'cache',
          };
        }

        // 2b) No cache → ask Gemini for nutrition
        final nutrition = await _geminiService.getNutrition(thaiName);
        if (nutrition != null) {
          return {
            ...nutrition,
            'food_name': thaiName,
            'confidence': tf.confidence,
            'source': 'tflite',
          };
        }
        debugPrint('[Scan] Gemini.getNutrition failed — falling back to vision');
      } else {
        debugPrint('[Scan] tflite returned null or low confidence');
      }
    } else {
      debugPrint('[Scan] tflite not ready — using Gemini vision');
    }

    // 3) Fallback: full Gemini vision
    final visionResult = await _geminiService.detectFoodFromImage(bytes);
    if (visionResult != null) {
      return {...visionResult, 'source': 'gemini'};
    }
    return null;
  }

  /// Look up previously-saved nutrition for this user+food.
  /// Uses only single-field indexes (no composite index setup needed).
  /// Returns null if not found. Converts storage keys back to Gemini format.
  Future<Map<String, dynamic>?> _fetchCachedNutrition(String thaiName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    try {
      final q = await FirebaseFirestore.instance
          .collection('meals')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      for (final doc in q.docs) {
        final d = doc.data();
        if ((d['foodName'] ?? '').toString().trim() != thaiName) continue;
        return {
          'food_name': thaiName,
          'serving_size': (d['servingSize'] ?? '1 จาน').toString(),
          'calories_kcal': _toDouble(d['calories']),
          'protein_g': _toDouble(d['protein_g']),
          'fat_g': _toDouble(d['fat_total_g']),
          'carbs_g': _toDouble(d['carbohydrates_total_g']),
        };
      }
      return null;
    } catch (e) {
      debugPrint('[Scan] cache lookup error: $e');
      return null;
    }
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
      final result = await _runAnalysis(_imageBytes!);

      if (!mounted) return;
      Navigator.pop(context);

      setState(() => _isAnalyzing = false);

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
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
    } catch (_) {
      if (!mounted) return;

      Navigator.pop(context);
      setState(() => _isAnalyzing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('วิเคราะห์ไม่สำเร็จ กรุณาลองใหม่'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String _errorMessage() {
    switch (_geminiService.lastError) {
      case GeminiErrorCode.quota:
        return 'ใช้งาน AI ถึงโควต้าของวันแล้ว ลองใหม่ตอน 16:00';
      case GeminiErrorCode.busy:
        return 'AI กำลังไม่ว่าง ลองใหม่อีกสักครู่';
      case GeminiErrorCode.network:
        return 'เชื่อมต่ออินเทอร์เน็ตไม่ได้ ตรวจสอบสัญญาณ';
      case GeminiErrorCode.noApiKey:
        return 'ยังไม่ได้ตั้งค่า API key';
      case GeminiErrorCode.badResponse:
        return 'AI ตอบกลับผิดรูปแบบ ลองถ่ายใหม่ หรือเลือกรูปอื่น';
      case GeminiErrorCode.none:
        return 'AI วิเคราะห์รูปไม่สำเร็จ';
    }
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
                          child: FilledButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, size: 20),
                            label: const Text(
                              'ถ่ายรูป',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: HoverScale(
                          borderRadius: BorderRadius.circular(999),
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(Icons.photo_library_outlined, size: 20),
                            label: const Text(
                              'เลือกรูป',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
