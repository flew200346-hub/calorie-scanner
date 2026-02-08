import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<Map<String, dynamic>?> fetchNutrition(String foodName) async {
    // ใช้ Search API ของ OpenFoodFacts 
    final url = Uri.parse(
      'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$foodName&search_simple=1&action=process&json=1'
    );
    
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['products'] != null && data['products'].isNotEmpty) {
          // ดึงข้อมูล nutriments (แคลอรี่, โปรตีน ฯลฯ) จากสินค้าตัวแรกที่เจอ [cite: 27, 28]
          return data['products'][0]['nutriments'];
        }
      }
    } catch (e) {
      print("API Error: $e");
    }
    return null;
  }
}