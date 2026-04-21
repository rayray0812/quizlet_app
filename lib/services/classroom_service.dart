import 'dart:math';

import 'package:recall_app/core/constants/supabase_constants.dart';
import 'package:recall_app/models/classroom.dart';
import 'package:recall_app/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ClassroomService {
  final SupabaseService _supabaseService;

  ClassroomService({required SupabaseService supabaseService})
    : _supabaseService = supabaseService;

  String? get currentUserId => _supabaseService.currentUser?.id;

  bool get isAvailable => _supabaseService.clientOrNull != null;

  Future<String> getOrCreateMyRole() async {
    final client = _supabaseService.clientOrNull;
    final userId = currentUserId;
    if (client == null || userId == null) return 'student';

    final rows = await client
        .from(SupabaseConstants.profilesTable)
        .select('role')
        .eq('user_id', userId)
        .limit(1);
    if ((rows as List).isNotEmpty) {
      return rows.first['role'] as String? ?? 'student';
    }

    await client.from(SupabaseConstants.profilesTable).upsert({
      'user_id': userId,
      'display_name': _supabaseService.preferredDisplayName(),
      'role': 'student',
    });
    return 'student';
  }

  Future<void> updateMyRole(String role) async {
    final client = _supabaseService.clientOrNull;
    final userId = currentUserId;
    if (client == null || userId == null) return;
    final normalized = role == 'teacher' ? 'teacher' : 'student';
    await client.from(SupabaseConstants.profilesTable).upsert({
      'user_id': userId,
      'display_name': _supabaseService.preferredDisplayName(),
      'role': normalized,
    });
  }

  Future<List<Classroom>> fetchMyClasses() async {
    final client = _supabaseService.clientOrNull;
    final userId = currentUserId;
    if (client == null || userId == null) return const [];

    final teacherRows = await client
        .from(SupabaseConstants.classesTable)
        .select('*')
        .eq('teacher_id', userId)
        .order('created_at', ascending: false);

    final memberRows = await client
        .from(SupabaseConstants.classMembersTable)
        .select('class_id')
        .eq('student_id', userId)
        .eq('status', 'active');

    final classIds = (memberRows as List)
        .map((row) => row['class_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final studentRows = classIds.isEmpty
        ? const <dynamic>[]
        : await client
              .from(SupabaseConstants.classesTable)
              .select('*')
              .inFilter('id', classIds)
              .order('created_at', ascending: false);

    final byId = <String, Classroom>{};
    for (final row in [...teacherRows, ...studentRows]) {
      final classroom = Classroom.fromMap(
        Map<String, dynamic>.from(row as Map),
      );
      byId[classroom.id] = classroom;
    }

    final values = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  Future<Classroom?> fetchClassById(String classId) async {
    final client = _supabaseService.clientOrNull;
    if (client == null) return null;
    final rows = await client
        .from(SupabaseConstants.classesTable)
        .select('*')
        .eq('id', classId)
        .limit(1);
    if ((rows as List).isEmpty) return null;
    return Classroom.fromMap(Map<String, dynamic>.from(rows.first as Map));
  }

  Future<Classroom> createClass({
    required String name,
    String subject = '',
    String grade = '',
  }) async {
    final client = _requireClient();
    final userId = _requireUserId();
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _generateInviteCode();
      final classId = const Uuid().v4();
      final now = DateTime.now().toUtc();
      try {
        await client.from(SupabaseConstants.classesTable).insert({
          'id': classId,
          'teacher_id': userId,
          'name': name.trim(),
          'subject': subject.trim(),
          'grade': grade.trim(),
          'invite_code': code,
        });
        return Classroom(
          id: classId,
          teacherId: userId,
          name: name.trim(),
          subject: subject.trim(),
          grade: grade.trim(),
          inviteCode: code,
          isArchived: false,
          createdAt: now,
          updatedAt: now,
        );
      } catch (_) {
        if (attempt == 4) rethrow;
      }
    }
    throw StateError('Create class failed.');
  }

  Future<void> joinClassByInviteCode(String inviteCode) async {
    final client = _requireClient();
    final code = inviteCode.trim().toUpperCase();
    if (code.isEmpty) return;
    await client.rpc('join_class_by_invite_code', params: {'code': code});
  }

  Future<void> updateClassArchiveStatus({
    required String classId,
    required bool isArchived,
  }) async {
    final client = _requireClient();
    await client
        .from(SupabaseConstants.classesTable)
        .update({'is_archived': isArchived})
        .eq('id', classId);
  }

  Future<void> leaveClass(String classId) async {
    final client = _requireClient();
    final userId = _requireUserId();
    await client
        .from(SupabaseConstants.classMembersTable)
        .update({'status': 'left'})
        .eq('class_id', classId)
        .eq('student_id', userId);
  }

  Future<List<ClassroomMember>> fetchClassMembers(String classId) async {
    final client = _supabaseService.clientOrNull;
    if (client == null) return const [];

    final rows = await client
        .from(SupabaseConstants.classMembersTable)
        .select('class_id, student_id, joined_at, status')
        .eq('class_id', classId)
        .order('joined_at', ascending: true);

    final studentIds = (rows as List)
        .map((row) => row['student_id'] as String?)
        .whereType<String>()
        .toList();
    final profileRows = studentIds.isEmpty
        ? const <dynamic>[]
        : await client
              .from(SupabaseConstants.profilesTable)
              .select('user_id, display_name')
              .inFilter('user_id', studentIds);
    final profileMap = <String, String>{
      for (final row in profileRows)
        (row['user_id'] as String? ?? ''): _normalizeDisplayName(
          row['display_name'] as String?,
        ),
    };

    return rows.map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final studentId = map['student_id'] as String? ?? '';
      return ClassroomMember(
        classId: map['class_id'] as String? ?? '',
        studentId: studentId,
        joinedAt:
            DateTime.tryParse(map['joined_at'] as String? ?? '') ??
            DateTime.now().toUtc(),
        status: map['status'] as String? ?? 'active',
        displayName: profileMap[studentId]?.trim().isNotEmpty == true
            ? profileMap[studentId]!
            : studentId,
      );
    }).toList();
  }

  Future<List<ClassroomSet>> fetchClassSets(String classId) async {
    final client = _supabaseService.clientOrNull;
    if (client == null) return const [];

    final rows = await client
        .from(SupabaseConstants.classSetsTable)
        .select('*')
        .eq('class_id', classId)
        .order('updated_at', ascending: false);
    return (rows as List)
        .map(
          (row) => ClassroomSet.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<ClassroomSet> createClassSet({
    required String classId,
    required String title,
    String description = '',
    required List<Map<String, dynamic>> cards,
  }) async {
    final client = _requireClient();
    final userId = _requireUserId();
    final rows = await client
        .from(SupabaseConstants.classSetsTable)
        .insert({
          'class_id': classId,
          'owner_teacher_id': userId,
          'title': title.trim(),
          'description': description.trim(),
          'cards': cards,
        })
        .select('*')
        .limit(1);
    return ClassroomSet.fromMap(
      Map<String, dynamic>.from((rows as List).first),
    );
  }

  Future<List<ClassroomAssignment>> fetchAssignments(String classId) async {
    final client = _supabaseService.clientOrNull;
    if (client == null) return const [];

    final assignmentRows = await client
        .from(SupabaseConstants.classAssignmentsTable)
        .select('*')
        .eq('class_id', classId)
        .order('published_at', ascending: false);
    final assignments = (assignmentRows as List)
        .map(
          (row) => ClassroomAssignment.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
    if (assignments.isEmpty) return assignments;

    final setIds = assignments.map((item) => item.setId).toSet().toList();
    final setRows = await client
        .from(SupabaseConstants.classSetsTable)
        .select('id, title, cards')
        .inFilter('id', setIds);
    final setTitleMap = <String, String>{};
    final setCardCountMap = <String, int>{};
    for (final row in (setRows as List)) {
      final id = row['id'] as String? ?? '';
      final cards = row['cards'] as List<dynamic>? ?? const <dynamic>[];
      setTitleMap[id] = row['title'] as String? ?? '';
      setCardCountMap[id] = cards.length;
    }
    return assignments
        .map(
          (item) => item.copyWith(
            setTitle: setTitleMap[item.setId] ?? item.setId,
            setCardCount: setCardCountMap[item.setId] ?? 0,
          ),
        )
        .toList();
  }

  Future<ClassroomAssignment> createAssignment({
    required String classId,
    required String setId,
    DateTime? dueAt,
    bool isPublished = true,
  }) async {
    final client = _requireClient();
    final userId = _requireUserId();
    final rows = await client
        .from(SupabaseConstants.classAssignmentsTable)
        .insert({
          'class_id': classId,
          'set_id': setId,
          'assigned_by': userId,
          'due_at': dueAt?.toUtc().toIso8601String(),
          'is_published': isPublished,
        })
        .select('*')
        .limit(1);
    final raw = ClassroomAssignment.fromMap(
      Map<String, dynamic>.from((rows as List).first),
    );
    final sets = await fetchClassSets(classId);
    final linkedSet = sets.where((set) => set.id == raw.setId).firstOrNull;
    return raw.copyWith(
      setTitle: linkedSet?.title ?? raw.setId,
      setCardCount: linkedSet?.cards.length ?? 0,
    );
  }

  Future<List<StudentAssignmentProgress>> fetchMyProgressForClass(
    String classId,
  ) async {
    final client = _supabaseService.clientOrNull;
    final userId = currentUserId;
    if (client == null || userId == null) return const [];

    final assignments = await fetchAssignments(classId);
    final assignmentIds = assignments.map((a) => a.id).toList();
    if (assignmentIds.isEmpty) return const [];
    final rows = await client
        .from(SupabaseConstants.studentAssignmentProgressTable)
        .select('*')
        .eq('student_id', userId)
        .inFilter('assignment_id', assignmentIds);
    return (rows as List)
        .map(
          (row) => StudentAssignmentProgress.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<void> upsertMyProgress({
    required String assignmentId,
    required String status,
    double? score,
  }) async {
    final client = _requireClient();
    final userId = _requireUserId();
    final now = DateTime.now().toUtc();
    final normalizedStatus = switch (status) {
      'in_progress' => 'in_progress',
      'completed' => 'completed',
      _ => 'not_started',
    };
    await client.from(SupabaseConstants.studentAssignmentProgressTable).upsert({
      'assignment_id': assignmentId,
      'student_id': userId,
      'status': normalizedStatus,
      'score': score,
      'last_studied_at': now.toIso8601String(),
      'completed_at': normalizedStatus == 'completed'
          ? now.toIso8601String()
          : null,
    });
  }

  Future<bool> markCompletedFromLocalSetId({
    required String localSetId,
    required double score,
  }) async {
    final context = _parseLocalClassSetId(localSetId);
    if (context == null) return false;
    final assignmentId = await _resolveAssignmentId(
      classId: context.classId,
      classSetId: context.classSetId,
    );
    if (assignmentId == null) return false;
    final normalizedScore = score.clamp(0, 100).toDouble();
    await upsertMyProgress(
      assignmentId: assignmentId,
      status: 'completed',
      score: normalizedScore,
    );
    return true;
  }

  Future<bool> upsertMatchingResultFromLocalSetId({
    required String localSetId,
    required int elapsedSeconds,
    required int accuracy,
    required int attempts,
  }) async {
    final context = _parseLocalClassSetId(localSetId);
    final client = _supabaseService.clientOrNull;
    final userId = currentUserId;
    if (context == null || client == null || userId == null) return false;
    final assignmentId = await _resolveAssignmentId(
      classId: context.classId,
      classSetId: context.classSetId,
    );
    if (assignmentId == null) return false;

    final existingRows = await client
        .from(SupabaseConstants.classMatchingResultsTable)
        .select('best_time_seconds')
        .eq('assignment_id', assignmentId)
        .eq('student_id', userId)
        .limit(1);
    final existingBest = (existingRows as List).isEmpty
        ? null
        : (existingRows.first['best_time_seconds'] as num?)?.toInt();
    final normalizedElapsed = elapsedSeconds <= 0 ? 1 : elapsedSeconds;
    final bestTime = existingBest == null
        ? normalizedElapsed
        : min(existingBest, normalizedElapsed);

    await client.from(SupabaseConstants.classMatchingResultsTable).upsert({
      'assignment_id': assignmentId,
      'class_id': context.classId,
      'student_id': userId,
      'best_time_seconds': bestTime,
      'latest_time_seconds': normalizedElapsed,
      'accuracy': accuracy.clamp(0, 100),
      'attempts': attempts < 0 ? 0 : attempts,
    });
    return true;
  }

  Future<List<ClassroomMatchLeaderboardEntry>>
  fetchMatchLeaderboardForLocalSetId(
    String localSetId, {
    int limit = 10,
  }) async {
    final context = _parseLocalClassSetId(localSetId);
    if (context == null) return const [];
    final assignmentId = await _resolveAssignmentId(
      classId: context.classId,
      classSetId: context.classSetId,
    );
    if (assignmentId == null) return const [];
    return fetchMatchLeaderboardForAssignment(
      classId: context.classId,
      assignmentId: assignmentId,
      limit: limit,
    );
  }

  Future<List<ClassroomMatchLeaderboardEntry>>
  fetchMatchLeaderboardForAssignment({
    required String classId,
    required String assignmentId,
    int limit = 10,
  }) async {
    final client = _supabaseService.clientOrNull;
    if (client == null) return const [];

    final rows = await client
        .from(SupabaseConstants.classMatchingResultsTable)
        .select('*')
        .eq('class_id', classId)
        .eq('assignment_id', assignmentId)
        .order('best_time_seconds', ascending: true)
        .order('accuracy', ascending: false)
        .order('updated_at', ascending: true)
        .limit(limit);
    if ((rows as List).isEmpty) return const [];

    final studentIds = rows
        .map((row) => row['student_id'] as String?)
        .whereType<String>()
        .toList();
    final profileRows = studentIds.isEmpty
        ? const <dynamic>[]
        : await client
              .from(SupabaseConstants.profilesTable)
              .select('user_id, display_name')
              .inFilter('user_id', studentIds);
    final displayNameById = <String, String>{
      for (final row in profileRows)
        (row['user_id'] as String? ?? ''): _normalizeDisplayName(
          row['display_name'] as String?,
        ),
    };

    return rows.map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final studentId = map['student_id'] as String? ?? '';
      return ClassroomMatchLeaderboardEntry(
        assignmentId: map['assignment_id'] as String? ?? '',
        classId: map['class_id'] as String? ?? '',
        studentId: studentId,
        studentDisplayName:
            displayNameById[studentId]?.trim().isNotEmpty == true
            ? displayNameById[studentId]!
            : studentId,
        bestTimeSeconds: (map['best_time_seconds'] as num?)?.toInt() ?? 0,
        latestTimeSeconds: (map['latest_time_seconds'] as num?)?.toInt() ?? 0,
        accuracy: (map['accuracy'] as num?)?.toInt() ?? 0,
        attempts: (map['attempts'] as num?)?.toInt() ?? 0,
        updatedAt:
            DateTime.tryParse(map['updated_at'] as String? ?? '') ??
            DateTime.now().toUtc(),
      );
    }).toList();
  }

  Future<bool> markInProgressFromLocalSetId({
    required String localSetId,
  }) async {
    final context = _parseLocalClassSetId(localSetId);
    if (context == null) return false;
    final assignmentId = await _resolveAssignmentId(
      classId: context.classId,
      classSetId: context.classSetId,
    );
    if (assignmentId == null) return false;
    await upsertMyProgress(assignmentId: assignmentId, status: 'in_progress');
    return true;
  }

  Future<List<ClassroomProgressRow>> fetchClassProgressRows(
    String classId,
  ) async {
    final client = _supabaseService.clientOrNull;
    if (client == null) return const [];

    final assignments = await fetchAssignments(classId);
    if (assignments.isEmpty) return const [];
    final assignmentById = <String, ClassroomAssignment>{
      for (final assignment in assignments) assignment.id: assignment,
    };
    final assignmentIds = assignmentById.keys.toList();

    final progressRows = await client
        .from(SupabaseConstants.studentAssignmentProgressTable)
        .select('assignment_id, student_id, status, score, updated_at')
        .inFilter('assignment_id', assignmentIds)
        .order('updated_at', ascending: false);

    final members = await fetchClassMembers(classId);
    final displayNameByStudentId = <String, String>{
      for (final member in members) member.studentId: member.displayName,
    };

    return (progressRows as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final studentId = map['student_id'] as String? ?? '';
      final assignmentId = map['assignment_id'] as String? ?? '';
      final assignment = assignmentById[assignmentId];
      return ClassroomProgressRow(
        assignmentId: assignmentId,
        assignmentTitle: assignment?.setTitle ?? assignmentId,
        studentId: studentId,
        studentDisplayName: displayNameByStudentId[studentId] ?? studentId,
        status: map['status'] as String? ?? 'not_started',
        score: (map['score'] as num?)?.toDouble(),
        updatedAt:
            DateTime.tryParse(map['updated_at'] as String? ?? '') ??
            DateTime.now().toUtc(),
      );
    }).toList();
  }

  Future<List<ClassroomAssignmentReport>> fetchClassAssignmentReports(
    String classId,
  ) async {
    final assignments = await fetchAssignments(classId);
    if (assignments.isEmpty) return const [];
    final members = await fetchClassMembers(classId);
    final activeStudents = members
        .where((member) => member.status == 'active')
        .map((member) => member.studentId)
        .toSet();
    final rows = await fetchClassProgressRows(classId);
    final rowsByAssignment = <String, List<ClassroomProgressRow>>{};
    for (final row in rows) {
      rowsByAssignment
          .putIfAbsent(row.assignmentId, () => <ClassroomProgressRow>[])
          .add(row);
    }

    final reports = <ClassroomAssignmentReport>[];
    for (final assignment in assignments) {
      final assignmentRows =
          rowsByAssignment[assignment.id] ?? const <ClassroomProgressRow>[];
      var completed = 0;
      var inProgress = 0;
      final progressedStudents = <String>{};
      var scoreTotal = 0.0;
      var scoreCount = 0;
      for (final row in assignmentRows) {
        if (!activeStudents.contains(row.studentId)) continue;
        progressedStudents.add(row.studentId);
        if (row.status == 'completed') completed++;
        if (row.status == 'in_progress') inProgress++;
        if (row.score != null) {
          scoreTotal += row.score!;
          scoreCount++;
        }
      }
      final notStarted = (activeStudents.length - progressedStudents.length)
          .clamp(0, activeStudents.length)
          .toInt();
      reports.add(
        ClassroomAssignmentReport(
          assignmentId: assignment.id,
          assignmentTitle: assignment.setTitle,
          studentCount: activeStudents.length,
          completedCount: completed,
          inProgressCount: inProgress,
          notStartedCount: notStarted,
          averageScore: scoreCount == 0 ? 0 : (scoreTotal / scoreCount),
        ),
      );
    }

    return reports;
  }

  Future<List<ClassroomStudentReport>> fetchClassStudentReports(
    String classId,
  ) async {
    final assignments = await fetchAssignments(classId);
    if (assignments.isEmpty) return const [];
    final members = await fetchClassMembers(classId);
    final activeMembers = members
        .where((member) => member.status == 'active')
        .toList();
    if (activeMembers.isEmpty) return const [];
    final rows = await fetchClassProgressRows(classId);
    final rowByStudentAndAssignment = <String, ClassroomProgressRow>{};
    for (final row in rows) {
      rowByStudentAndAssignment['${row.studentId}:${row.assignmentId}'] = row;
    }

    final reports = <ClassroomStudentReport>[];
    for (final member in activeMembers) {
      var completed = 0;
      var inProgress = 0;
      var notStarted = 0;
      var scoreTotal = 0.0;
      var scoreCount = 0;

      for (final assignment in assignments) {
        final row =
            rowByStudentAndAssignment['${member.studentId}:${assignment.id}'];
        if (row == null) {
          notStarted++;
          continue;
        }
        if (row.status == 'completed') completed++;
        if (row.status == 'in_progress') inProgress++;
        if (row.status == 'not_started') notStarted++;
        if (row.score != null) {
          scoreTotal += row.score!;
          scoreCount++;
        }
      }

      reports.add(
        ClassroomStudentReport(
          studentId: member.studentId,
          studentDisplayName: member.displayName,
          assignmentCount: assignments.length,
          completedCount: completed,
          inProgressCount: inProgress,
          notStartedCount: notStarted,
          averageScore: scoreCount == 0 ? 0 : (scoreTotal / scoreCount),
        ),
      );
    }

    reports.sort((a, b) {
      final byCompletion = b.completionRate.compareTo(a.completionRate);
      if (byCompletion != 0) return byCompletion;
      return b.averageScore.compareTo(a.averageScore);
    });
    return reports;
  }

  Future<List<ClassroomStudentAssignmentDetail>> fetchStudentAssignmentDetails({
    required String classId,
    required String studentId,
  }) async {
    final assignments = await fetchAssignments(classId);
    if (assignments.isEmpty) return const [];
    final progressRows = await fetchClassProgressRows(classId);
    final byAssignmentId = <String, ClassroomProgressRow>{};
    for (final row in progressRows) {
      if (row.studentId == studentId) {
        byAssignmentId[row.assignmentId] = row;
      }
    }

    return assignments.map((assignment) {
      final row = byAssignmentId[assignment.id];
      return ClassroomStudentAssignmentDetail(
        assignmentId: assignment.id,
        assignmentTitle: assignment.setTitle,
        dueAt: assignment.dueAt,
        isPublished: assignment.isPublished,
        status: row?.status ?? 'not_started',
        score: row?.score,
        updatedAt: row?.updatedAt,
      );
    }).toList();
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  SupabaseClient _requireClient() {
    final client = _supabaseService.clientOrNull;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }
    return client;
  }

  String _requireUserId() {
    final id = currentUserId;
    if (id == null) throw StateError('No signed-in user.');
    return id;
  }

  Future<String?> _resolveAssignmentId({
    required String classId,
    required String classSetId,
  }) async {
    final client = _supabaseService.clientOrNull;
    if (client == null) return null;
    final rows = await client
        .from(SupabaseConstants.classAssignmentsTable)
        .select('id')
        .eq('class_id', classId)
        .eq('set_id', classSetId)
        .limit(1);
    if ((rows as List).isEmpty) return null;
    return rows.first['id'] as String?;
  }

  _LocalClassContext? _parseLocalClassSetId(String localSetId) {
    final parts = localSetId.split('_');
    if (parts.length != 3) return null;
    if (parts.first != 'class') return null;
    final classId = parts[1].trim();
    final classSetId = parts[2].trim();
    if (classId.isEmpty || classSetId.isEmpty) return null;
    return _LocalClassContext(classId: classId, classSetId: classSetId);
  }
}

class _LocalClassContext {
  final String classId;
  final String classSetId;

  const _LocalClassContext({required this.classId, required this.classSetId});
}

String _normalizeDisplayName(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return '';
  if (!trimmed.contains('@')) return trimmed;
  final localPart = trimmed.split('@').first.trim();
  return localPart.isEmpty ? trimmed : localPart;
}
