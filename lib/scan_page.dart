import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ScanPage extends StatefulWidget {
  final String initialMeal;

  /// ✅ ส่งชื่ออาหารมาตั้งค่าเริ่มต้นได้
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
  late String _meal;

  final TextEditingController _foodNameCtrl = TextEditingController();

  // ===== สีประจำแต่ละมื้อ (แก้ตรงนี้จุดเดียว) =====
  final Map<String, Color> _mealColors = const {
    'มื้อเช้า': Color(0xFFFFC107), // เหลือง
    'มื้อเที่ยง': Color(0xFF4CAF50), // เขียว
    'มื้อเย็น': Color(0xFF3F51B5), // น้ำเงิน
    'มื้อทานเล่น': Color(0xFFE91E63), // ชมพู
  };

  Color _colorOf(String meal) => _mealColors[meal] ?? Colors.blueGrey;

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;

    final initName = (widget.initialFoodName ?? '').trim();
    if (initName.isNotEmpty) {
      _foodNameCtrl.text = initName;
    }
  }

  Future<void> _pickImageFromGallery() async {
    final x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    final b = await x.readAsBytes();
    setState(() => _bytes = b);
  }

  Future<void> _takePhoto() async {
    final x =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x == null) return;
    final b = await x.readAsBytes();
    setState(() => _bytes = b);
  }

  @override
  void dispose() {
    _foodNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foodName = _foodNameCtrl.text.trim();
    final mealColor = _colorOf(_meal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
        backgroundColor: mealColor.withOpacity(0.08),
        elevation: 0,
      ),
      body: Container(
        // ✅ พื้นหลังไล่สีตามมื้อ
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              mealColor.withOpacity(0.14),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'สแกนอาหาร',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'เลือกมื้อ + ใส่ชื่ออาหาร (ถ้ามี) + ถ่าย/เลือกรูป แล้วค่อยต่อ AI วิเคราะห์ทีหลัง',
              style: TextStyle(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // ✅ เลือกมื้อ
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: mealColor.withOpacity(0.25)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  value: _meal,
                  items: const [
                    DropdownMenuItem(
                        value: 'มื้อเช้า', child: Text('มื้อเช้า')),
                    DropdownMenuItem(
                        value: 'มื้อเที่ยง', child: Text('มื้อเที่ยง')),
                    DropdownMenuItem(
                        value: 'มื้อเย็น', child: Text('มื้อเย็น')),
                    DropdownMenuItem(
                        value: 'มื้อทานเล่น', child: Text('มื้อทานเล่น')),
                  ],
                  onChanged: (v) => setState(() => _meal = v ?? _meal),
                  decoration: InputDecoration(
                    labelText: 'เลือกมื้อ',
                    prefixIcon: Icon(Icons.restaurant_menu, color: mealColor),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: mealColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ ชื่ออาหาร
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
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'ชื่ออาหาร (ถ้ามี)',
                    hintText: 'เช่น ข้าวกะเพราหมู, สลัดอกไก่...',
                    prefixIcon: Icon(Icons.fastfood_outlined, color: mealColor),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: mealColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ รูปภาพ
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
                      ? Center(
                          child: Text(
                            'ยังไม่มีรูป\nกดปุ่มด้านล่างเพื่อถ่าย/เลือกรูป',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(_bytes!, fit: BoxFit.cover),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ ปุ่มหลัก โทนตามมื้อ
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: mealColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('ถ่ายรูปอาหาร'),
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: mealColor,
                side: BorderSide(color: mealColor, width: 1.6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('เลือกรูปจากคลัง'),
            ),
            const SizedBox(height: 10),

            // ✅ Mock analyze
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: mealColor,
                side:
                    BorderSide(color: mealColor.withOpacity(0.75), width: 1.6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'เลือกมื้อ: $_meal'
                      '${foodName.isEmpty ? '' : ' | อาหาร: $foodName'}'
                      ' | พร้อมต่อ AI ทีหลัง',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('เริ่มวิเคราะห์ (Mock)'),
            ),
          ],
        ),
      ),
    );
  }
}
