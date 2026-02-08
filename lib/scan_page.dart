import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:calorie_scanner/food_result_page.dart';

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
  final _picker = ImagePicker();
  Uint8List? _bytes;
  String? _imagePath; 
  late String _meal;
  bool _isModelLoaded = false;

  Interpreter? _interpreter; 
  List<String>? _labels;

  final TextEditingController _foodNameCtrl = TextEditingController();

  final Map<String, Color> _mealColors = const {
    'มื้อเช้า': Color(0xFFFFC107),
    'มื้อเที่ยง': Color(0xFF4CAF50),
    'มื้อเย็น': Color(0xFF3F51B5),
    'มื้อทานเล่น': Color(0xFFE91E63),
  };

  Color _colorOf(String meal) => _mealColors[meal] ?? Colors.blueGrey;

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
    _loadModel();

    final initName = (widget.initialFoodName ?? '').trim();
    if (initName.isNotEmpty) {
      _foodNameCtrl.text = initName;
    }
  }

  // ✅ ฟังก์ชันโหลดโมเดล (ปรับปรุงให้รองรับการเช็ค Dimension)
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset("assets/best_float32.tflite");
      
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').where((s) => s.isNotEmpty).toList();

      debugPrint("Model Loaded: Input ${_interpreter!.getInputTensor(0).shape}");
      debugPrint("Model Loaded: Output ${_interpreter!.getOutputTensor(0).shape}");

      setState(() => _isModelLoaded = true);
    } catch (e) {
      debugPrint("Error loading model: $e");
    }
  }

  // ✅ ฟังก์ชันวิเคราะห์รูปภาพ (แก้ไข Logic AI ทั้งหมดตามที่คุยกัน)
  Future<void> _analyzeImage() async {
    if (_imagePath == null || !_isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกหรือถ่ายรูปภาพก่อน')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Preprocessing: Resize เป็น 640x640 เพื่อแก้ Error Dimensions Mismatch
      final imageData = File(_imagePath!).readAsBytesSync();
      img.Image? image = img.decodeImage(imageData);
      img.Image resizedImage = img.copyResize(image!, width: 640, height: 640);

      // 2. แปลงภาพเป็น Float32 [1, 640, 640, 3] และ Normalize (0.0 - 1.0)
      var input = List.generate(1, (index) => 
        List.generate(640, (y) => 
          List.generate(640, (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          }),
        ),
      );

      // 3. เตรียมที่ว่างสำหรับ Output [1, 16, 8400]
      var output = List.filled(1 * 16 * 8400, 0.0).reshape([1, 16, 8400]);

      // 4. รัน AI
      _interpreter!.run(input, output);

      // 5. Post-processing: วนลูป 8400 ครั้ง เพื่อหาค่าความมั่นใจสูงสุด
      double maxConfidence = 0;
      int bestClassIdx = -1;

      for (int i = 0; i < 8400; i++) {
        // บางโมเดล YOLOv8 ค่า Confidence จะไม่ได้แยกออกมา 
        // แต่จะใช้ค่าสูงสุดจาก Class Scores (แถวที่ 4 ถึง 15) ไปเลย
        double currentMaxScore = 0;
        int currentClass = -1;

        for (int c = 4; c < 16; c++) { // ตรวจสอบแถวที่ 4 ถึง 15
          double score = output[0][c][i];
          if (score > currentMaxScore) {
            currentMaxScore = score;
            currentClass = c - 4; // ปรับ Index ให้ตรงกับ Labels
          }
        }

        // ถ้าเจอค่าที่สูงกว่าเดิม ให้บันทึกไว้
        if (currentMaxScore > maxConfidence) {
          maxConfidence = currentMaxScore;
          bestClassIdx = currentClass; 
        }
      }

      print("DEBUG: Final Max Confidence: $maxConfidence");
      print("DEBUG: Best Class Index: $bestClassIdx");

      if (!mounted) return;
      Navigator.pop(context); // ปิด Loading

      if (bestClassIdx != -1 && maxConfidence > 0.25) {
        String englishName = _labels![bestClassIdx].trim();
        
        Map<String, String> thaiNames = {
          'BBQ Pork Rice': 'ข้าวหมูแดง',
          'Chicken Rice': 'ข้าวมันไก่',
          'Fried Egg': 'ไข่ดาว',
          'Fried Noodle in Gravy Sauce': 'ราดหน้า',
          'Omelet Rice': 'ข้าวไข่เจียว',
          'Pad_Kaprao': 'ผัดกะเพรา',
          'Papaya Salad': 'ส้มตำ',
          'Pork-with-Garlic': 'หมูกระเทียม',
          'Stewed Pork Leg Rice': 'ข้าวขาหมู',
          'Stir-fried Noodles in Soy Sauce': 'ผัดซีอิ๊ว',
          'Stir-fried-Kale-with-Crispy-Pork': 'คะน้าหมูกรอบ',
          'Thai Stir-fried Noodle': 'ผัดไทย',
        };

        String thaiDisplay = thaiNames[englishName] ?? englishName;

        setState(() {
          _foodNameCtrl.text = thaiDisplay;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodResultPage(
              foodName: englishName, // ส่งชื่ออังกฤษไปถาม API [cite: 30]
              thaiName: thaiDisplay,
              confidence: maxConfidence,
            ),
          ),
        );
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('วิเคราะห์เป็น: ${_foodNameCtrl.text} (${(maxConfidence * 100).toStringAsFixed(0)}%)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI ไม่มั่นใจว่าเป็นอาหารชนิดไหนครับ')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Analysis Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    final b = await x.readAsBytes();
    setState(() {
      _bytes = b;
      _imagePath = x.path;
    });
  }

  Future<void> _takePhoto() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x == null) return;
    final b = await x.readAsBytes();
    setState(() {
      _bytes = b;
      _imagePath = x.path;
    });
  }

  @override
  void dispose() {
    _foodNameCtrl.dispose();
    _interpreter?.close(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mealColor = _colorOf(_meal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan with AI'),
        backgroundColor: mealColor.withOpacity(0.08),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [mealColor.withOpacity(0.14), Colors.white],
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

            // --- Dropdown เลือกมื้อ ---
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: mealColor.withOpacity(0.25)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
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
                    prefixIcon: Icon(Icons.restaurant_menu, color: mealColor),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- TextField ชื่ออาหาร ---
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: mealColor.withOpacity(0.25)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _foodNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'ชื่ออาหาร (AI จะเติมให้)',
                    prefixIcon: Icon(Icons.fastfood_outlined, color: mealColor),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- ส่วนแสดงรูปภาพ ---
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: mealColor.withOpacity(0.25)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AspectRatio(
                  aspectRatio: 1.3,
                  child: _bytes == null
                      ? const Center(child: Text('ยังไม่มีรูป\nกดถ่ายรูปเพื่อเริ่มสแกน'))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(_bytes!, fit: BoxFit.cover),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- ปุ่มกดถ่ายรูป ---
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: mealColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('ถ่ายรูปอาหาร'),
            ),
            
            const SizedBox(height: 12),

            // --- ปุ่มสั่ง AI วิเคราะห์ ---
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _analyzeImage,
              icon: const Icon(Icons.auto_awesome),
              label: Text(_isModelLoaded ? 'เริ่มวิเคราะห์ด้วย AI' : 'กำลังโหลดโมเดล...'),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: mealColor,
                side: BorderSide(color: mealColor, width: 1.6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('เลือกรูปจากคลัง'),
            ),
          ],
        ),
      ),
    );
  }
}