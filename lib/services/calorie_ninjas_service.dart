// ============================================================================
// calorie_ninjas_service.dart —  DEAD CODE (ไม่ถูก import ที่ไหนเลย)
// ----------------------------------------------------------------------------
// service สำหรับเรียก CalorieNinjas API ดูโภชนาการจาก label ที่ tflite ระบุ
// มี _queryMap แม็ป label → English query (ใช้ตอนเรียก API)
//
// ทำไมไม่ใช้:
//   - ต้อง API key (ไม่ฟรีถ้าใช้เยอะ — 10k/เดือน)
//   - ปัจจุบัน Gemini.getNutrition ทำหน้าที่นี้ครบจบในตัว
//
// เก็บไว้ถ้าอยากย้ายไป hybrid (CalorieNinjas + Gemini) ในอนาคต — แม่นกว่าบางเคส
// ============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CalorieNinjasService {
  final String _apiKey = dotenv.env['CALORIE_NINJAS_API_KEY'] ?? '';

  /// Maps label names from labels.txt to CalorieNinjas-friendly English queries
  static const Map<String, String> _queryMap = {
    'BBQ-Pork-Rice': '1 plate bbq pork with rice',
    'Bitter-Melon-Soup': '1 bowl bitter melon soup',
    'Chicken-Biryani': '1 plate chicken biryani',
    'Chicken-Rice': '1 plate hainanese chicken rice',
    'Curried-Fish-Cake': '5 pieces thai fish cake',
    'Dipping-sauce': '2 tablespoons thai dipping sauce',
    'Dumpling': '5 pieces steamed dumpling',
    'Eggs-Stewed': '2 stewed eggs',
    'Fried-Chicken': '2 pieces fried chicken',
    'Fried-Egg': '1 fried egg',
    'Fried-Noodle-in-Gravy-Sauce': '1 plate fried noodles with gravy',
    'Fried-Oysters': '1 plate fried oysters',
    'Fried-Rice-with-Shrimp-Paste': '1 plate fried rice with shrimp paste',
    'Green-Curry': '1 bowl thai green curry with rice',
    'Grill-Shrimp': '5 grilled shrimp',
    'Grilled-Pork-Neck': '1 plate grilled pork neck',
    'Kai-look-khei': '2 son in law eggs',
    'Kai-Yang': '1 piece thai grilled chicken',
    'Kua-Jab-Nam-Khon': '1 bowl rolled noodle soup with pork',
    'Massaman-Curry': '1 bowl massaman curry with rice',
    'Omelet': '1 thai omelet with rice',
    'Pad-Kaprao': '1 plate stir fried basil pork with rice',
    'Pad-Thai': '1 plate pad thai',
    'Papaya-Salad': '1 plate green papaya salad',
    'Poo-Pad-Pongali': '1 plate stir fried crab with curry powder',
    'Pork Satay': '10 sticks pork satay',
    'Pork-porridge': '1 bowl pork congee',
    'Pork-with-Garlic': '1 plate garlic pork with rice',
    'Roast-fish': '1 roasted fish',
    'Spicy-Mincing-Pork-Salad': '1 plate thai larb pork',
    'Stewed-Pork-Leg-Rice': '1 plate braised pork leg with rice',
    'Stir-fried-Kale-with-Crispy-Pork': '1 plate stir fried kale with crispy pork and rice',
    'Stir-fried-Morning-Glory': '1 plate stir fried morning glory',
    'Stir-fried-Noodles-in-Soy-Sauce': '1 plate pad see ew',
    'Thai-clear-soup': '1 bowl thai clear soup',
    'Thai-Noodles-with-Pork-and-Blood-Soup': '1 bowl thai boat noodle soup',
    'Yum-Woon-Sen': '1 plate glass noodle salad',
  };

  /// Fetches nutrition data for a food label from labels.txt.
  /// Returns a map with keys: calories, protein_g, fat_total_g, carbohydrates_total_g
  Future<Map<String, dynamic>?> getNutrition(String labelName) async {
    final query = _queryMap[labelName] ?? labelName.replaceAll('-', ' ');

    final url = Uri.parse(
      'https://api.calorieninjas.com/v1/nutrition?query=${Uri.encodeComponent(query)}',
    );

    try {
      final response = await http.get(url, headers: {
        'X-Api-Key': _apiKey,
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List;
        if (items.isNotEmpty) {
          // Sum all items (API may return multiple items for compound queries)
          double calories = 0, protein = 0, fat = 0, carbs = 0;
          for (final item in items) {
            calories += (item['calories'] ?? 0).toDouble();
            protein += (item['protein_g'] ?? 0).toDouble();
            fat += (item['fat_total_g'] ?? 0).toDouble();
            carbs += (item['carbohydrates_total_g'] ?? 0).toDouble();
          }
          return {
            'calories': calories.round(),
            'protein_g': protein.round(),
            'fat_total_g': fat.round(),
            'carbohydrates_total_g': carbs.round(),
          };
        }
      }
    } catch (e) {
      print("CalorieNinjas Error: $e");
    }
    return null;
  }
}
