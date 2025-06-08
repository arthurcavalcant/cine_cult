import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';

class ApiService {
  final String _apiKey = 'd5935928';
  final String _baseUrl = 'http://www.omdbapi.com/';

  Future<List<MediaItem>> searchMedia(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl?s=${Uri.encodeComponent(query)}&apikey=$_apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['Response'] == 'True' && data['Search'] != null) {
        final List results = data['Search'];
        // Filter out items that don't have a valid imdbID, as they can't be used for details
        return results
            .where((itemData) => itemData['imdbID'] != null && itemData['imdbID'].startsWith('tt'))
            .map((itemData) => MediaItem.fromOMDbJson(itemData))
            .toList();
      } else {
        // Handle cases where 'Search' is null or Response is 'False' (e.g., "Movie not found!")
        print('API Error: ${data['Error'] ?? 'No results found'}');
        return []; // Return empty list for no results or error
      }
    } else {
      throw Exception('Failed to load media from OMDb. Status code: ${response.statusCode}');
    }
  }

  Future<MediaItem?> getMediaDetails(String imdbId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl?i=${Uri.encodeComponent(imdbId)}&apikey=$_apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['Response'] == 'True') {
        return MediaItem.fromOMDbDetailJson(data);
      } else {
        print('API Error for details: ${data['Error'] ?? 'Details not found'}');
        return null;
      }
    } else {
      throw Exception('Failed to load media details from OMDb. Status code: ${response.statusCode}');
    }
  }
}
