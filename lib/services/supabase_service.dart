import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quizlet_app/core/constants/supabase_constants.dart';
import 'package:quizlet_app/models/study_set.dart';
import 'package:quizlet_app/models/flashcard.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Auth
  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Data
  Future<void> upsertStudySet(StudySet studySet) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from(SupabaseConstants.studySetsTable).upsert({
      'id': studySet.id,
      'user_id': userId,
      'title': studySet.title,
      'description': studySet.description,
      'cards': studySet.cards.map((c) => c.toJson()).toList(),
      'created_at': studySet.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<StudySet>> fetchStudySets() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(SupabaseConstants.studySetsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((row) {
      final cardsJson = (row['cards'] as List?) ?? [];
      return StudySet(
        id: row['id'] as String,
        title: row['title'] as String,
        description: row['description'] as String? ?? '',
        createdAt: DateTime.parse(row['created_at'] as String),
        cards: cardsJson
            .map((c) => Flashcard.fromJson(Map<String, dynamic>.from(c)))
            .toList(),
        isSynced: true,
      );
    }).toList();
  }
}
