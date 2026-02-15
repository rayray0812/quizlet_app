import 'dart:convert';

import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/models/flashcard.dart';

class ShareCodec {
  /// Encode a StudySet to a Base64url string for QR sharing.
  static String encode(StudySet set) {
    final data = {
      'title': set.title,
      'description': set.description,
      'cards': set.cards
          .map((c) => {
                'term': c.term,
                'definition': c.definition,
              })
          .toList(),
    };
    final jsonStr = json.encode(data);
    return base64Url.encode(utf8.encode(jsonStr));
  }

  /// Decode a Base64url string back to a StudySet.
  /// Returns null if decoding fails.
  static StudySet? decode(String encoded) {
    try {
      final jsonStr = utf8.decode(base64Url.decode(encoded));
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final cards = (data['cards'] as List<dynamic>)
          .map((c) => Flashcard(
                id: DateTime.now().microsecondsSinceEpoch.toString() +
                    (c['term'] as String).hashCode.toString(),
                term: c['term'] as String? ?? '',
                definition: c['definition'] as String? ?? '',
              ))
          .toList();
      return StudySet(
        id: '', // Will be assigned on import
        title: data['title'] as String? ?? 'Shared Set',
        description: data['description'] as String? ?? '',
        createdAt: DateTime.now().toUtc(),
        cards: cards,
      );
    } catch (_) {
      return null;
    }
  }

  /// Build a deep link URI for sharing.
  static String toDeepLink(StudySet set) {
    final encoded = encode(set);
    return 'recall://import?data=$encoded';
  }
}
