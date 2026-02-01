import 'package:freezed_annotation/freezed_annotation.dart';

part 'flashcard.freezed.dart';
part 'flashcard.g.dart';

@freezed
class Flashcard with _$Flashcard {
  const factory Flashcard({
    required String id,
    required String term,
    required String definition,
    @Default(0) int difficultyLevel,
    @Default('') String imageUrl,
    @Default([]) List<String> tags,
  }) = _Flashcard;

  factory Flashcard.fromJson(Map<String, dynamic> json) =>
      _$FlashcardFromJson(json);
}
