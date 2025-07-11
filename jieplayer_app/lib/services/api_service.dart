import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api.yzzy-api.com/inc/apijson.php';
  
  // 获取分类列表
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?ac=list'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // 获取影片详情列表
  static Future<Map<String, dynamic>> getMovies({
    String? typeId,
    int page = 1,
    String? keyword,
  }) async {
    try {
      final Map<String, String> params = {
        'ac': 'detail',
        'pg': page.toString(),
      };
      
      if (typeId != null && typeId != '0') {
        params['t'] = typeId;
      }
      
      if (keyword != null && keyword.isNotEmpty) {
        params['wd'] = keyword;
      }
      
      final uri = Uri.parse(baseUrl).replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}