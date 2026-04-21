import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/classroom/utils/class_detail_metrics.dart';
import 'package:recall_app/models/classroom.dart';

void main() {
  final now = DateTime.utc(2026, 3, 8, 12);

  ClassroomAssignment assignment({required String id, DateTime? dueAt}) {
    return ClassroomAssignment(
      id: id,
      classId: 'class-1',
      setId: 'set-$id',
      assignedBy: 'teacher-1',
      dueAt: dueAt,
      publishedAt: now,
      isPublished: true,
      createdAt: now,
      updatedAt: now,
      setTitle: 'Assignment $id',
      setCardCount: 12,
    );
  }

  StudentAssignmentProgress progress({
    required String assignmentId,
    required String status,
  }) {
    return StudentAssignmentProgress(
      assignmentId: assignmentId,
      studentId: 'student-1',
      status: status,
      score: status == 'completed' ? 92 : null,
      lastStudiedAt: now,
      completedAt: status == 'completed' ? now : null,
      updatedAt: now,
    );
  }

  ClassroomSet classroomSet(String id) => ClassroomSet(
    id: id,
    classId: 'class-1',
    ownerTeacherId: 'teacher-1',
    title: 'Set $id',
    description: '',
    cards: const <Map<String, dynamic>>[],
    createdAt: now,
    updatedAt: now,
  );

  ClassroomMember member(String id) => ClassroomMember(
    classId: 'class-1',
    studentId: id,
    joinedAt: now,
    status: 'active',
    displayName: 'Student $id',
  );

  test('filterAssignments returns expected buckets', () {
    final assignments = [
      assignment(id: 'a', dueAt: now.subtract(const Duration(days: 1))),
      assignment(id: 'b', dueAt: now.add(const Duration(days: 2))),
      assignment(id: 'c'),
    ];
    final progresses = [
      progress(assignmentId: 'a', status: 'in_progress'),
      progress(assignmentId: 'b', status: 'completed'),
    ];

    expect(
      filterAssignments(
        assignments: assignments,
        progresses: progresses,
        filter: ClassAssignmentFilter.all,
        now: now,
      ).map((item) => item.id),
      ['a', 'b', 'c'],
    );
    expect(
      filterAssignments(
        assignments: assignments,
        progresses: progresses,
        filter: ClassAssignmentFilter.pending,
        now: now,
      ).map((item) => item.id),
      ['a', 'c'],
    );
    expect(
      filterAssignments(
        assignments: assignments,
        progresses: progresses,
        filter: ClassAssignmentFilter.completed,
        now: now,
      ).map((item) => item.id),
      ['b'],
    );
    expect(
      filterAssignments(
        assignments: assignments,
        progresses: progresses,
        filter: ClassAssignmentFilter.overdue,
        now: now,
      ).map((item) => item.id),
      ['a'],
    );
  });

  test('buildClassDetailSummary computes student counts and nearest due', () {
    final assignments = [
      assignment(id: 'a', dueAt: now.add(const Duration(days: 3))),
      assignment(id: 'b', dueAt: now.add(const Duration(days: 1))),
      assignment(id: 'c', dueAt: now.subtract(const Duration(days: 1))),
    ];
    final summary = buildClassDetailSummary(
      assignments: assignments,
      sets: [classroomSet('1'), classroomSet('2')],
      members: [member('1'), member('2')],
      progresses: [
        progress(assignmentId: 'a', status: 'completed'),
        progress(assignmentId: 'b', status: 'in_progress'),
      ],
      assignmentReports: const [
        ClassroomAssignmentReport(
          assignmentId: 'a',
          assignmentTitle: 'A',
          studentCount: 2,
          completedCount: 2,
          inProgressCount: 0,
          notStartedCount: 0,
          averageScore: 95,
        ),
        ClassroomAssignmentReport(
          assignmentId: 'b',
          assignmentTitle: 'B',
          studentCount: 2,
          completedCount: 1,
          inProgressCount: 1,
          notStartedCount: 0,
          averageScore: 80,
        ),
      ],
      studentReports: const [],
      now: now,
    );

    expect(summary.assignmentCount, 3);
    expect(summary.setCount, 2);
    expect(summary.activeMemberCount, 2);
    expect(summary.completedCount, 1);
    expect(summary.inProgressCount, 1);
    expect(summary.pendingCount, 2);
    expect(summary.overdueCount, 1);
    expect(summary.nearestDue, now.subtract(const Duration(days: 1)));
    expect(summary.studentCompletionRate, closeTo(1 / 3, 0.0001));
    expect(summary.averageAssignmentCompletionRate, closeTo(0.75, 0.0001));
    expect(summary.averageScore, closeTo(87.5, 0.0001));
  });

  test('buildClassDetailSummary sorts top and risk students', () {
    final summary = buildClassDetailSummary(
      assignments: [assignment(id: 'a')],
      sets: const [],
      members: [member('1'), member('2'), member('3')],
      progresses: const [],
      assignmentReports: const [],
      studentReports: const [
        ClassroomStudentReport(
          studentId: '1',
          studentDisplayName: 'Ava',
          assignmentCount: 4,
          completedCount: 4,
          inProgressCount: 0,
          notStartedCount: 0,
          averageScore: 98,
        ),
        ClassroomStudentReport(
          studentId: '2',
          studentDisplayName: 'Ben',
          assignmentCount: 4,
          completedCount: 1,
          inProgressCount: 1,
          notStartedCount: 2,
          averageScore: 55,
        ),
        ClassroomStudentReport(
          studentId: '3',
          studentDisplayName: 'Cara',
          assignmentCount: 4,
          completedCount: 3,
          inProgressCount: 1,
          notStartedCount: 0,
          averageScore: 90,
        ),
      ],
      now: now,
    );

    expect(summary.topStudents.map((item) => item.studentId), ['1', '3', '2']);
    expect(summary.riskStudents.map((item) => item.studentId), ['2', '3', '1']);
  });
}
