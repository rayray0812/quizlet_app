import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:recall_app/models/flashcard.dart';

part 'study_set.freezed.dart';
part 'study_set.g.dart';

@freezed
class StudySet with _$StudySet {
  const factory StudySet({
    required String id,
    required String title,
    @Default('') String description,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default([]) List<Flashcard> cards,
    @Default(false) bool isSynced,
  }) = _StudySet;

  factory StudySet.fromJson(Map<String, dynamic> json) =>
      _$StudySetFromJson(json);
}

