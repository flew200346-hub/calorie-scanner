// ============================================================================
// gemini_service.dart — เรียก Google Gemini API (cloud AI)
// ----------------------------------------------------------------------------
// 2 endpoint หลัก:
//   1) detectFoodFromImage(bytes) — ส่งรูป → ได้ JSON {ชื่อ, แคล, P, F, C}
//      ใช้ตอน tflite ไม่รู้จักรูป (fallback) หรือ tflite ไม่พร้อม
//
//   2) getNutrition(thaiFoodName) — ส่งชื่ออาหาร → ได้ JSON เดียวกัน
//      ใช้คู่กับ tflite — tflite ระบุชื่อ → ถามโภชนาการ
//
// ทั้ง 2 endpoint ใช้ model "gemini-2.5-flash" (free tier 250 RPD)
// มี auto-retry สำหรับ 503/504 (server overload) สูงสุด 3 ครั้ง
// expose `lastError` เพื่อให้ scan_page แสดงข้อความที่ตรงกับสาเหตุ
// ============================================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// สาเหตุที่ Gemini call fail — ใช้ใน scan_page แสดง SnackBar ที่ตรงสาเหตุ
///   - quota   = 429 (ใช้เกิน 250 req/วันของ free tier)
///   - busy    = 503/504 (Google overload — retry แล้วยังไม่หาย)
///   - network = Exception ตอน HTTP (ไม่มีเน็ต/timeout)
///   - badResponse = 200 แต่ JSON parse ไม่ได้ / text ว่าง
enum GeminiErrorCode { none, noApiKey, quota, busy, network, badResponse }

class GeminiService {
  /// อ่านหลังเรียก method ใดก็ได้ — บอกว่าเพิ่งเกิดอะไรขึ้น (.none = สำเร็จ)
  GeminiErrorCode lastError = GeminiErrorCode.none;

  String get apiKey {
    final key = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';

    debugPrint('dotenv keys: ${dotenv.env.keys.toList()}');
    debugPrint('apiKey length: ${key.length}');
    debugPrint('apiKey startsWith AIza: ${key.startsWith('AIza')}');

    return key;
  }

  /// POST พร้อม retry สำหรับ 503/504 (Google ตอบช้า/overload ชั่วคราว)
  /// ลอง 3 ครั้ง: ทันที → +2s → +5s
  /// 503 มักจะหายเองใน 5-10 วินาที — retry ทำให้ user ไม่ต้องกดเอง
  Future<http.Response> _postWithRetry(
    Uri url,
    Map<String, String> headers,
    String body,
  ) async {
    const delays = [Duration(seconds: 2), Duration(seconds: 5)];
    http.Response response = await http.post(url, headers: headers, body: body);

    for (final delay in delays) {
      if (response.statusCode != 503 && response.statusCode != 504) break;
      debugPrint(
        'Gemini ${response.statusCode} — retrying in ${delay.inSeconds}s',
      );
      await Future.delayed(delay);
      response = await http.post(url, headers: headers, body: body);
    }

    return response;
  }

  /// วิเคราะห์รูปอาหาร → คืน JSON {food_name, calories_kcal, protein_g, fat_g, carbs_g, ...}
  /// ใช้เมื่อ tflite ไม่รู้จักรูป (label ไม่อยู่ใน 37 ที่เทรนไว้)
  /// คืน null ถ้า fail — เช็ค `lastError` เพื่อรู้สาเหตุ
  Future<Map<String, dynamic>?> detectFoodFromImage(
    Uint8List imageBytes,
  ) async {
    lastError = GeminiErrorCode.none;

    final key = apiKey;

    if (key.isEmpty) {
      debugPrint('GEMINI_API_KEY not found in .env');
      lastError = GeminiErrorCode.noApiKey;
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
      final response = await _postWithRetry(
        url,
        {'Content-Type': 'application/json'},
        jsonEncode({
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
        lastError = _errorFromStatus(response.statusCode);
        return null;
      }

      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (text == null || text.toString().trim().isEmpty) {
        lastError = GeminiErrorCode.badResponse;
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

      lastError = GeminiErrorCode.badResponse;
      return null;
    } catch (e) {
      debugPrint('Gemini detectFoodFromImage exception: $e');
      lastError = GeminiErrorCode.network;
      return null;
    }
  }

  GeminiErrorCode _errorFromStatus(int status) {
    if (status == 429) return GeminiErrorCode.quota;
    if (status == 503 || status == 504) return GeminiErrorCode.busy;
    return GeminiErrorCode.badResponse;
  }

  /// ขอข้อมูลโภชนาการจาก "ชื่ออาหาร" ภาษาไทย (ไม่ส่งรูป — ประหยัด token)
  /// ใช้คู่กับ tflite: tflite ระบุชื่อ → call นี้เติมโภชนาการให้
  /// คืน null ถ้า fail — เช็ค `lastError` เพื่อรู้สาเหตุ
  Future<Map<String, dynamic>?> getNutrition(String thaiFoodName) async {
    lastError = GeminiErrorCode.none;

    final key = apiKey;

    if (key.isEmpty) {
      debugPrint('GEMINI_API_KEY not found in .env');
      lastError = GeminiErrorCode.noApiKey;
      return null;
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$key',
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
      final response = await _postWithRetry(
        url,
        {'Content-Type': 'application/json'},
        jsonEncode({
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
        lastError = _errorFromStatus(response.statusCode);
        return null;
      }

      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (text == null || text.toString().trim().isEmpty) {
        lastError = GeminiErrorCode.badResponse;
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

      lastError = GeminiErrorCode.badResponse;
      return null;
    } catch (e) {
      debugPrint('Gemini getNutrition exception: $e');
      lastError = GeminiErrorCode.network;
      return null;
    }
  }
}
