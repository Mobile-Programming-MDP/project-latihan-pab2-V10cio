import 'dart:convert'; 
import 'package:http/http.dart' as http; 
 
class ApiService { 
  static const String baseUrl = "https://api.themoviedb.org/3"; 
  static const String apiKey = 'a6713fa28348e2b04400c46e2b4e1bab'; 
 
  Future<List<Map<String, dynamic>>> getAllMovies() async { 
    final response = await http.get(Uri.parse("$baseUrl/movie/now_playing?api_key=$apiKey")); 
    final data = json.decode(response.body); 
    return List<Map<String, dynamic>>.from(data['results']); 
  } 
 
  Future<List<Map<String, dynamic>>> getTrendingMovies() async { 
    final response = await http.get(Uri.parse("$baseUrl/trending/movie/week?api_key=$apiKey")); 
    final data = json.decode(response.body); 
    return List<Map<String, dynamic>>.from(data['results']); 
  } 
 
  Future<List<Map<String, dynamic>>> getPopularMovies() async { 
    final response = await http.get(Uri.parse("$baseUrl/movie/popular?api_key=$apiKey")); 
    final data = json.decode(response.body); 
    return List<Map<String, dynamic>>.from(data['results']); 
  } 
 
  Future<List<Map<String, dynamic>>> searchMovies(String query) async { 
    final response = await http.get(Uri.parse("$baseUrl/search/movie?query=$query&api_key=$apiKey")); 
    final data = json.decode(response.body); 
    return List<Map<String, dynamic>>.from(data['results']); 
  } 
}