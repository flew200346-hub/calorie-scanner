import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey = "AIzaSyA3KrIPAic02ZuSwwi0vg8r5KTOz8x13lE"; // รหัสล่าสุดของคุณ

  Future<Map<String, dynamic>?> getNutrition(String thaiFoodName) async {
    // ใช้ URL แบบ v1 ตรงๆ เพื่อเลี่ยง Error v1beta
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey');

    final prompt = "บอกข้อมูลโภชนาการของ '$thaiFoodName' ต่อ 1 จาน ให้ตอบเป็น JSON เท่านั้นในรูปแบบนี้: "
                   "{\"energy-kcal_100g\": 0, \"proteins_100g\": 0, \"fat_100g\": 0, \"carbohydrates_100g\": 0} "
                   "ห้ามมีตัวอักษรอื่นนอกจาก JSON";

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": [{"text": prompt}]}]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        // ล้าง Markdown ออกเพื่อให้ได้ JSON ที่สะอาด
        final jsonString = text.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(jsonString);
      }
    } catch (e) {
      print("Gemini Manual Error: $e");
    }
    return null;
  }
}