import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  String get apiKey {
    final key = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';

    debugPrint('dotenv keys: ${dotenv.env.keys.toList()}');
    debugPrint('apiKey length: ${key.length}');
    debugPrint('apiKey startsWith AIza: ${key.startsWith('AIza')}');

    return key;
  }

  Future<Map<String, dynamic>?> detectFoodFromImage(
    Uint8List imageBytes,
  ) async {
    final key = apiKey;

    if (key.isEmpty) {
      debugPrint('GEMINI_API_KEY not found in .env');
      return null;
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$key',
    );

    final base64Image = base64Encode(imageBytes);

    const prompt = '''
วิเคราะห์ภาพอาหารนี้ แล้วตอบเป็น JSON เท่านั้น
ห้ามมีข้อความอื่น
ห้ามมี markdown
ห้ามมี ```json

รูปแบบ:
{
  "food_name": "ชื่ออาหารภาษาไทย",
  "serving_size": "1 จาน",
  "calories_kcal": 0,
  "protein_g": 0,
  "fat_g": 0,
  "carbs_g": 0,
  "confidence": 0.0
}
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image,
                  }
                }
              ]
            }
          ]
        }),
      );

      debugPrint('Gemini status: ${response.statusCode}');
      debugPrint('Gemini body: ${response.body}');

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (text == null || text.toString().trim().isEmpty) {
        return null;
      }

      final cleaned = text
          .toString()
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final decoded = jsonDecode(cleaned);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }

      return null;
    } catch (e) {
      debugPrint('Gemini detectFoodFromImage exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getNutrition(String thaiFoodName) async {
    final key = apiKey;

    if (key.isEmpty) {
      debugPrint('GEMINI_API_KEY not found in .env');
      return null;
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=$key',
    );

    final prompt = '''
ให้ประเมินข้อมูลโภชนาการของอาหารไทยชื่อ "$thaiFoodName" ต่อ 1 จาน
ตอบเป็น JSON เท่านั้น
ห้ามมีข้อความอื่น
ห้ามมี markdown
ห้ามมี ```json

รูปแบบ:
{
  "food_name": "$thaiFoodName",
  "serving_size": "1 จาน",
  "calories_kcal": 0,
  "protein_g": 0,
  "fat_g": 0,
  "carbs_g": 0,
  "confidence": 0.0
}
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      debugPrint('Gemini nutrition status: ${response.statusCode}');
      debugPrint('Gemini nutrition body: ${response.body}');

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (text == null || text.toString().trim().isEmpty) {
        return null;
      }

      final cleaned = text
          .toString()
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final decoded = jsonDecode(cleaned);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }

      return null;
    } catch (e) {
      debugPrint('Gemini getNutrition exception: $e');
      return null;
    }
  }
}
