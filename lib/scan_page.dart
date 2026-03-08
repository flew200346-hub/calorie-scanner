import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'food_result_page.dart';

// ---------------------------------------------------------------------------
// ชื่ออาหารไทย 37 รายการ (key ตรงกับ labels.txt)
// ---------------------------------------------------------------------------
const Map<String, String> _thaiNames = {
  'BBQ-Pork-Rice': 'ข้าวหมูแดง',
  'Bitter-Melon-Soup': 'ต้มจืดมะระ',
  'Chicken-Biryani': 'ข้าวหมกไก่',
  'Chicken-Rice': 'ข้าวมันไก่',
  'Curried-Fish-Cake': 'ทอดมันปลา',
  'Dipping-sauce': 'น้ำจิ้ม',
  'Dumpling': 'ขนมจีบ',
  'Eggs-Stewed': 'ไข่พะโล้',
  'Fried-Chicken': 'ไก่ทอด',
  'Fried-Egg': 'ไข่ดาว',
  'Fried-Noodle-in-Gravy-Sauce': 'ราดหน้า',
  'Fried-Oysters': 'หอยทอด',
  'Fried-Rice-with-Shrimp-Paste': 'ข้าวคลุกกะปิ',
  'Green-Curry': 'แกงเขียวหวาน',
  'Grill-Shrimp': 'กุ้งเผา',
  'Grilled-Pork-Neck': 'คอหมูย่าง',
  'Kai-look-khei': 'ไข่ลูกเขย',
  'Kai-Yang': 'ไก่ย่าง',
  'Kua-Jab-Nam-Khon': 'ก๋วยจั๊บน้ำข้น',
  'Massaman-Curry': 'แกงมัสมั่น',
  'Omelet': 'ไข่เจียว',
  'Pad-Kaprao': 'ผัดกะเพรา',
  'Pad-Thai': 'ผัดไทย',
  'Papaya-Salad': 'ส้มตำไทย',
  'Poo-Pad-Pongali': 'ปูผัดผงกะหรี่',
  'Pork Satay': 'หมูสะเต๊ะ',
  'Pork-porridge': 'โจ๊กหมู',
  'Pork-with-Garlic': 'หมูกระเทียม',
  'Roast-fish': 'ปลาเผา',
  'Spicy-Mincing-Pork-Salad': 'ลาบหมู',
  'Stewed-Pork-Leg-Rice': 'ข้าวขาหมู',
  'Stir-fried-Kale-with-Crispy-Pork': 'คะน้าหมูกรอบ',
  'Stir-fried-Morning-Glory': 'ผัดผักบุ้งไฟแดง',
  'Stir-fried-Noodles-in-Soy-Sauce': 'ผัดซีอิ๊ว',
  'Thai-clear-soup': 'ต้มจืด',
  'Thai-Noodles-with-Pork-and-Blood-Soup': 'ก๋วยเตี๋ยวเรือหมูน้ำตก',
  'Yum-Woon-Sen': 'ยำวุ้นเส้น',
};

// ---------------------------------------------------------------------------
// สีประจำมื้อ
// ---------------------------------------------------------------------------
const Map<String, Color> _mealColors = {
  'มื้อเช้า': Color(0xFFFFC107),
  'มื้อเที่ยง': Color(0xFF4CAF50),
  'มื้อเย็น': Color(0xFF3F51B5),
  'มื้อทานเล่น': Color(0xFFE91E63),
};

// ===========================================================================
// ScanPage
// ===========================================================================
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
  // --- State ---
  final _picker = ImagePicker();
  final _foodNameCtrl = TextEditingController();

  Uint8List? _imageBytes;
  String? _imagePath;
  late String _meal;
  bool _isModelLoaded = false;

  // --- TFLite ---
  Interpreter? _interpreter;
  List<String>? _labels;
  List<int>? _outputShape;
  int _inputSize = 640;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
    _loadModel();

    final initName = (widget.initialFoodName ?? '').trim();
    if (initName.isNotEmpty) _foodNameCtrl.text = initName;
  }

  @override
  void dispose() {
    _foodNameCtrl.dispose();
    _interpreter?.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // โหลดโมเดล + labels
  // ---------------------------------------------------------------------------
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/best_float32.tflite');

      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').where((s) => s.isNotEmpty).toList();

      _outputShape = _interpreter!.getOutputTensor(0).shape;
      final inputShape = _interpreter!.getInputTensor(0).shape;
      _inputSize = inputShape[1];

      debugPrint('Model loaded — input: $inputShape, output: $_outputShape');
      setState(() => _isModelLoaded = true);
    } catch (e) {
      debugPrint('Error loading model: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // เลือก / ถ่ายรูป
  // ---------------------------------------------------------------------------
  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imagePath = file.path;
    });
  }

  // ---------------------------------------------------------------------------
  // วิเคราะห์รูปด้วย YOLOv8
  // ---------------------------------------------------------------------------
  Future<void> _analyzeImage() async {
    if (_imagePath == null || !_isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกหรือถ่ายรูปภาพก่อน')),
      );
      return;
    }

    // แสดง loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = _runInference();
      if (!mounted) return;
      Navigator.pop(context); // ปิด loading

      if (result != null) {
        final englishName = result.$1;
        final confidence = result.$2;
        final thaiDisplay = _thaiNames[englishName] ?? englishName;

        _foodNameCtrl.text = thaiDisplay;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodResultPage(
              foodName: englishName,
              thaiName: thaiDisplay,
              confidence: confidence,
              mealType: _meal,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI ไม่มั่นใจว่าเป็นอาหารชนิดไหนครับ')),
        );
      }
    } catch (e) {
      debugPrint('Analysis Error: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// รัน inference แล้ว return (className, confidence) หรือ null ถ้าไม่มั่นใจ
  (String, double)? _runInference() {
    // 1. อ่านและ resize รูป
    final imageData = File(_imagePath!).readAsBytesSync();
    final decoded = img.decodeImage(imageData)!;
    final resized = img.copyResize(decoded, width: _inputSize, height: _inputSize);

    // 2. แปลงเป็น Float32 [1, H, W, 3] — normalize 0‑1
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final px = resized.getPixel(x, y);
          return [px.r / 255.0, px.g / 255.0, px.b / 255.0];
        }),
      ),
    );

    // 3. เตรียม output buffer
    final rows = _outputShape![1];
    final cols = _outputShape![2];
    final output = List.filled(1 * rows * cols, 0.0).reshape([1, rows, cols]);

    // 4. รัน model
    _interpreter!.run(input, output);

    // 5. หา class ที่มั่นใจสูงสุด (เฉพาะ class ที่อยู่ใน labels)
    double maxConf = 0;
    int bestIdx = -1;
    final maxC = 4 + _labels!.length;

    for (int i = 0; i < cols; i++) {
      for (int c = 4; c < maxC && c < rows; c++) {
        final score = output[0][c][i] as double;
        if (score > maxConf) {
          maxConf = score;
          bestIdx = c - 4;
        }
      }
    }

    debugPrint('Inference result — class: $bestIdx, confidence: $maxConf');

    if (bestIdx == -1 || maxConf <= 0.25) return null;
    return (_labels![bestIdx].trim(), maxConf);
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  Color _colorOf(String meal) => _mealColors[meal] ?? Colors.blueGrey;

  @override
  Widget build(BuildContext context) {
    final color = _colorOf(_meal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan with AI'),
        backgroundColor: color.withOpacity(0.08),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.14), Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'สแกนอาหารด้วย Local AI',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // เลือกมื้อ
            _buildCard(
              color,
              DropdownButtonFormField<String>(
                initialValue: _meal,
                items: const [
                  DropdownMenuItem(value: 'มื้อเช้า', child: Text('มื้อเช้า')),
                  DropdownMenuItem(value: 'มื้อเที่ยง', child: Text('มื้อเที่ยง')),
                  DropdownMenuItem(value: 'มื้อเย็น', child: Text('มื้อเย็น')),
                  DropdownMenuItem(value: 'มื้อทานเล่น', child: Text('มื้อทานเล่น')),
                ],
                onChanged: (v) => setState(() => _meal = v ?? _meal),
                decoration: InputDecoration(
                  labelText: 'เลือกมื้อ',
                  prefixIcon: Icon(Icons.restaurant_menu, color: color),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ชื่ออาหาร
            _buildCard(
              color,
              TextField(
                controller: _foodNameCtrl,
                decoration: InputDecoration(
                  labelText: 'ชื่ออาหาร (AI จะเติมให้)',
                  prefixIcon: Icon(Icons.fastfood_outlined, color: color),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // รูปภาพ
            _buildCard(
              color,
              AspectRatio(
                aspectRatio: 1.3,
                child: _imageBytes == null
                    ? const Center(child: Text('ยังไม่มีรูป\nกดถ่ายรูปเพื่อเริ่มสแกน'))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // ปุ่มถ่ายรูป
            _actionButton(
              color: color,
              icon: Icons.camera_alt_outlined,
              label: 'ถ่ายรูปอาหาร',
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 12),

            // ปุ่มวิเคราะห์
            _actionButton(
              color: Colors.black87,
              icon: Icons.auto_awesome,
              label: _isModelLoaded ? 'เริ่มวิเคราะห์ด้วย AI' : 'กำลังโหลดโมเดล...',
              onPressed: _analyzeImage,
            ),
            const SizedBox(height: 12),

            // ปุ่มเลือกจากคลัง
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 1.6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('เลือกรูปจากคลัง'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widget helpers
  // ---------------------------------------------------------------------------
  Widget _buildCard(Color borderColor, Widget child) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor.withOpacity(0.25)),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  Widget _actionButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
