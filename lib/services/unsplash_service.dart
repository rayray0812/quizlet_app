import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quizlet_app/core/constants/api_constants.dart';

class UnsplashService {
  /// Searches Unsplash for a photo matching [query] and returns the small image URL.
  /// Returns empty string if no result or API key is not configured.
  Future<String> searchPhoto(String query) async {
    if (ApiConstants.unsplashAccessKey == 'YOUR_UNSPLASH_ACCESS_KEY' ||
        query.trim().isEmpty) {
      return '';
    }

    try {
      final uri = Uri.parse(
          '${ApiConstants.unsplashBaseUrl}/search/photos?query=${Uri.encodeComponent(query)}&per_page=1&orientation=landscape');
      final response = await http.get(uri, headers: {
        'Authorization': 'Client-ID ${ApiConstants.unsplashAccessKey}',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final urls = results[0]['urls'] as Map<String, dynamic>?;
          return urls?['small'] as String? ?? '';
        }
      }
    } catch (_) {
      // Silently fail — auto-image is best-effort
    }
    return '';
  }
}
