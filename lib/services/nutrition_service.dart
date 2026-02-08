import 'dart:convert';
import 'package:http/http.dart' as http;

class NutritionService {
  // ฟังก์ชันค้นหาข้อมูลด้วยชื่ออาหาร (Search API)
  static Future<Map<String, dynamic>?> searchFoodNutrition(String foodName) async {
    final url = Uri.parse(
      'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$foodName&search_simple=1&action=process&json=1'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['products'] != null && data['products'].isNotEmpty) {
          // ดึงสินค้าตัวแรกที่ตรงกับการค้นหา
          return data['products'][0];
        }
      }
    } catch (e) {
      print("API Error: $e");
    }
    return null;
  }
}