import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/models/classroom.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/services/classroom_service.dart';

final classroomServiceProvider = Provider<ClassroomService>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return ClassroomService(supabaseService: supabase);
});

final myRoleProvider = FutureProvider<String>((ref) async {
  ref.watch(currentUserProvider);
  final service = ref.watch(classroomServiceProvider);
  return service.getOrCreateMyRole();
});

final myClassesProvider = FutureProvider<List<Classroom>>((ref) async {
  ref.watch(currentUserProvider);
  final service = ref.watch(classroomServiceProvider);
  return service.fetchMyClasses();
});

final classByIdProvider = FutureProvider.family<Classroom?, String>((
  ref,
  classId,
) async {
  ref.watch(currentUserProvider);
  final service = ref.watch(classroomServiceProvider);
  return service.fetchClassById(classId);
});

final classMembersProvider = FutureProvider.family<List<ClassroomMember>, String>((
  ref,
  classId,
) async {
  ref.watch(currentUserProvider);
  final service = ref.watch(classroomServiceProvider);
  return service.fetchClassMembers(classId);
});

final classroomSetsProvider = FutureProvider.family<List<ClassroomSet>, String>((
  ref,
  classId,
) async {
  ref.watch(currentUserProvider);
  final service = ref.watch(classroomServiceProvider);
  return service.fetchClassSets(classId);
});

final classAssignmentsProvider =
    FutureProvider.family<List<ClassroomAssignment>, String>((ref, classId) async {
      ref.watch(currentUserProvider);
      final service = ref.watch(classroomServiceProvider);
      return service.fetchAssignments(classId);
    });

final myClassProgressProvider =
    FutureProvider.family<List<StudentAssignmentProgress>, String>((ref, classId) async {
      ref.watch(currentUserProvider);
      final service = ref.watch(classroomServiceProvider);
      return service.fetchMyProgressForClass(classId);
    });

final classProgressRowsProvider =
    FutureProvider.family<List<ClassroomProgressRow>, String>((ref, classId) async {
      ref.watch(currentUserProvider);
      final service = ref.watch(classroomServiceProvider);
      return service.fetchClassProgressRows(classId);
    });

final classAssignmentReportsProvider =
    FutureProvider.family<List<ClassroomAssignmentReport>, String>((ref, classId) async {
      ref.watch(currentUserProvider);
      final service = ref.watch(classroomServiceProvider);
      return service.fetchClassAssignmentReports(classId);
    });

final classStudentReportsProvider =
    FutureProvider.family<List<ClassroomStudentReport>, String>((ref, classId) async {
      ref.watch(currentUserProvider);
      final service = ref.watch(classroomServiceProvider);
      return service.fetchClassStudentReports(classId);
    });

class StudentDetailQuery {
  final String classId;
  final String studentId;

  const StudentDetailQuery({
    required this.classId,
    required this.studentId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentDetailQuery &&
          runtimeType == other.runtimeType &&
          classId == other.classId &&
          studentId == other.studentId;

  @override
  int get hashCode => Object.hash(classId, studentId);
}

final studentAssignmentDetailsProvider =
    FutureProvider.family<List<ClassroomStudentAssignmentDetail>, StudentDetailQuery>((
      ref,
      query,
    ) async {
      ref.watch(currentUserProvider);
      final service = ref.watch(classroomServiceProvider);
      return service.fetchStudentAssignmentDetails(
        classId: query.classId,
        studentId: query.studentId,
      );
    });

final matchingLeaderboardForLocalSetProvider =
    FutureProvider.family<List<ClassroomMatchLeaderboardEntry>, String>((
      ref,
      localSetId,
    ) async {
      ref.watch(currentUserProvider);
      final service = ref.watch(classroomServiceProvider);
      return service.fetchMatchLeaderboardForLocalSetId(localSetId);
    });
