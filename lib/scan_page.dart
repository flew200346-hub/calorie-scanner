import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ScanPage extends StatefulWidget {
  final String initialMeal;
  const ScanPage({super.key, this.initialMeal = 'มื้อเที่ยง'});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _picker = ImagePicker();

  Uint8List? _bytes;
  late String _meal;

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'สแกนอาหาร',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'เลือกมื้อ + ถ่าย/เลือกรูป แล้วค่อยต่อ AI วิเคราะห์ทีหลัง',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<String>(
                value: _meal,
                items: const [
                  DropdownMenuItem(value: 'มื้อเช้า', child: Text('มื้อเช้า')),
                  DropdownMenuItem(
                      value: 'มื้อเที่ยง', child: Text('มื้อเที่ยง')),
                  DropdownMenuItem(value: 'มื้อเย็น', child: Text('มื้อเย็น')),
                  DropdownMenuItem(
                      value: 'มื้อทานเล่น', child: Text('มื้อทานเล่น')),
                ],
                onChanged: (v) => setState(() => _meal = v ?? _meal),
                decoration: const InputDecoration(
                  labelText: 'เลือกมื้อ',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AspectRatio(
                aspectRatio: 1.3,
                child: _bytes == null
                    ? Center(
                        child: Text(
                          'ยังไม่มีรูป\nกดปุ่มด้านล่างเพื่อถ่าย/เลือกรูป',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_bytes!, fit: BoxFit.cover),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('ถ่ายรูปอาหาร'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickImageFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('เลือกรูปจากคลัง'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('เลือกมื้อ: $_meal | พร้อมต่อ AI ทีหลัง')),
              );
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('เริ่มวิเคราะห์ (Mock)'),
          ),
        ],
      ),
    );
  }
}
