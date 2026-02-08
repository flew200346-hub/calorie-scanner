import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/gemini_service.dart';

class FoodResultPage extends StatelessWidget {
  final String foodName; // ชื่อภาษาอังกฤษสำหรับค้นหา API
  final String thaiName; // ชื่อภาษาไทยสำหรับแสดงผล
  final double confidence;

  const FoodResultPage({
    super.key,
    required this.foodName,
    required this.thaiName,
    required this.confidence,
  });

  // ฟังก์ชันดึงข้อมูลจาก OpenFoodFacts API 
  Future<Map<String, dynamic>?> _fetchNutrition() async {
    try {
      // 1. เรียกใช้ GeminiService ที่คุณใส่ API Key ตัวล่าสุด (...13IE) ไว้แล้ว
      final gemini = GeminiService(); 
      
      // 2. ส่งชื่อภาษาไทย (thaiName) ไปให้ Gemini วิเคราะห์โภชนาการ
      final data = await gemini.getNutrition(thaiName); 
      
      if (data != null) {
        debugPrint("Gemini API: วิเคราะห์สำเร็จ");
        return data; // ส่งค่าแคลอรี่และสารอาหารที่ AI คำนวณได้ไปแสดงบนหน้าจอ
      }
    } catch (e) {
      debugPrint("Gemini API Error: $e");
    }

    // 2. หาก API ติดขัดหรือหาไม่เจอ ให้ใช้ข้อมูล Local ที่เตรียมไว้ (Fallback)
    final localData = {
      'BBQ Pork Rice': {'energy-kcal_100g': 540, 'proteins_100g': 18, 'fat_100g': 15, 'carbohydrates_100g': 82},
      'Chicken Rice': {'energy-kcal_100g': 596, 'proteins_100g': 24, 'fat_100g': 28, 'carbohydrates_100g': 62},
      'Fried Egg': {'energy-kcal_100g': 117, 'proteins_100g': 7, 'fat_100g': 9, 'carbohydrates_100g': 1},
      'Fried Noodle in Gravy Sauce': {'energy-kcal_100g': 405, 'proteins_100g': 15, 'fat_100g': 12, 'carbohydrates_100g': 60},
      'Omelet Rice': {'energy-kcal_100g': 445, 'proteins_100g': 12, 'fat_100g': 28, 'carbohydrates_100g': 35},
      'Pad_Kaprao': {'energy-kcal_100g': 550, 'proteins_100g': 22, 'fat_100g': 25, 'carbohydrates_100g': 58},
      'Papaya Salad': {'energy-kcal_100g': 120, 'proteins_100g': 5, 'fat_100g': 2, 'carbohydrates_100g': 21},
      'Pork-with-Garlic': {'energy-kcal_100g': 520, 'proteins_100g': 25, 'fat_100g': 30, 'carbohydrates_100g': 38},
      'Stewed Pork Leg Rice': {'energy-kcal_100g': 650, 'proteins_100g': 20, 'fat_100g': 35, 'carbohydrates_100g': 65},
      'Stir-fried Noodles in Soy Sauce': {'energy-kcal_100g': 520, 'proteins_100g': 14, 'fat_100g': 24, 'carbohydrates_100g': 62},
      'Stir-fried-Kale-with-Crispy-Pork': {'energy-kcal_100g': 620, 'proteins_100g': 18, 'fat_100g': 38, 'carbohydrates_100g': 52},
      'Thai Stir-fried Noodle': {'energy-kcal_100g': 485, 'proteins_100g': 14, 'fat_100g': 15, 'carbohydrates_100g': 75},
    };

    return localData[foodName];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(thaiName)),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchNutrition(),
        builder: (context, snapshot) {
          // ระหว่างรอข้อมูลจาก API [cite: 29]
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final nutrients = snapshot.data;
          // แสดงผลค่าโภชนาการที่ดึงมา (หรือค่าเริ่มต้น 0) [cite: 27]
          final cal = nutrients?['energy-kcal_100g'] ?? 0;
          final protein = nutrients?['proteins_100g'] ?? 0;
          final fat = nutrients?['fat_100g'] ?? 0;
          final carb = nutrients?['carbohydrates_100g'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  Text(thaiName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}%'),
                  const Divider(height: 40),
                  _buildCalorieCircle(cal.toString()),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _nutrientInfo('Protein', '${protein}g', Colors.red),
                      _nutrientInfo('Fat', '${fat}g', Colors.orange),
                      _nutrientInfo('Carbs', '${carb}g', Colors.blue),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('กลับสู่หน้าสแกน'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalorieCircle(String kcal) {
    return Container(
      width: 150, height: 150,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.green, width: 5)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(kcal, style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
          const Text('kcal'),
        ],
      ),
    );
  }

  Widget _nutrientInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: color, fontSize: 18)),
      ],
    );
  }
}