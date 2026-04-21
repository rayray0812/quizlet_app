import 'package:recall_app/models/classroom.dart';

enum ClassAssignmentFilter { all, pending, completed, overdue }

class ClassDetailSummary {
  final int activeMemberCount;
  final int assignmentCount;
  final int setCount;
  final int completedCount;
  final int inProgressCount;
  final int pendingCount;
  final int overdueCount;
  final DateTime? nearestDue;
  final double averageAssignmentCompletionRate;
  final double averageScore;
  final List<ClassroomStudentReport> topStudents;
  final List<ClassroomStudentReport> riskStudents;

  const ClassDetailSummary({
    required this.activeMemberCount,
    required this.assignmentCount,
    required this.setCount,
    required this.completedCount,
    required this.inProgressCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.nearestDue,
    required this.averageAssignmentCompletionRate,
    required this.averageScore,
    required this.topStudents,
    required this.riskStudents,
  });

  double get studentCompletionRate {
    if (assignmentCount <= 0) return 0;
    return completedCount / assignmentCount;
  }
}

StudentAssignmentProgress? findAssignmentProgress(
  List<StudentAssignmentProgress> progresses,
  String assignmentId,
) {
  for (final progress in progresses) {
    if (progress.assignmentId == assignmentId) return progress;
  }
  return null;
}

ClassroomAssignmentReport? findAssignmentReport(
  List<ClassroomAssignmentReport> reports,
  String assignmentId,
) {
  for (final report in reports) {
    if (report.assignmentId == assignmentId) return report;
  }
  return null;
}

ClassroomStudentReport? findStudentReport(
  List<ClassroomStudentReport> reports,
  String studentId,
) {
  for (final report in reports) {
    if (report.studentId == studentId) return report;
  }
  return null;
}

List<ClassroomAssignment> filterAssignments({
  required List<ClassroomAssignment> assignments,
  required List<StudentAssignmentProgress> progresses,
  required ClassAssignmentFilter filter,
  DateTime? now,
}) {
  final comparisonTime = now ?? DateTime.now();
  return assignments.where((assignment) {
    final progress = findAssignmentProgress(progresses, assignment.id);
    final isCompleted = progress?.status == 'completed';
    final isOverdue =
        assignment.dueAt != null &&
        assignment.dueAt!.isBefore(comparisonTime) &&
        !isCompleted;

    switch (filter) {
      case ClassAssignmentFilter.pending:
        return !isCompleted;
      case ClassAssignmentFilter.completed:
        return isCompleted;
      case ClassAssignmentFilter.overdue:
        return isOverdue;
      case ClassAssignmentFilter.all:
        return true;
    }
  }).toList();
}

ClassDetailSummary buildClassDetailSummary({
  required List<ClassroomAssignment> assignments,
  required List<ClassroomSet> sets,
  required List<ClassroomMember> members,
  required List<StudentAssignmentProgress> progresses,
  required List<ClassroomAssignmentReport> assignmentReports,
  required List<ClassroomStudentReport> studentReports,
  DateTime? now,
}) {
  final comparisonTime = now ?? DateTime.now();
  var completedCount = 0;
  var inProgressCount = 0;
  var pendingCount = 0;
  var overdueCount = 0;
  DateTime? nearestDue;

  for (final assignment in assignments) {
    final progress = findAssignmentProgress(progresses, assignment.id);
    final status = progress?.status ?? 'not_started';
    final isCompleted = status == 'completed';
    final isInProgress = status == 'in_progress';
    final isOverdue =
        assignment.dueAt != null &&
        assignment.dueAt!.isBefore(comparisonTime) &&
        !isCompleted;

    if (isCompleted) {
      completedCount += 1;
    } else {
      pendingCount += 1;
      if (assignment.dueAt != null &&
          (nearestDue == null || assignment.dueAt!.isBefore(nearestDue))) {
        nearestDue = assignment.dueAt;
      }
    }

    if (isInProgress) {
      inProgressCount += 1;
    }
    if (isOverdue) {
      overdueCount += 1;
    }
  }

  var averageAssignmentCompletionRate = 0.0;
  if (assignmentReports.isNotEmpty) {
    final total = assignmentReports
        .map((report) => report.completionRate)
        .fold<double>(0, (sum, rate) => sum + rate);
    averageAssignmentCompletionRate = total / assignmentReports.length;
  }

  final scoredReports = assignmentReports
      .where((report) => report.studentCount > 0)
      .toList();
  var averageScore = 0.0;
  if (scoredReports.isNotEmpty) {
    final totalScore = scoredReports
        .map((report) => report.averageScore)
        .fold<double>(0, (sum, score) => sum + score);
    averageScore = totalScore / scoredReports.length;
  }

  final sortedStudents = [...studentReports]
    ..sort((a, b) {
      final completionCompare = b.completionRate.compareTo(a.completionRate);
      if (completionCompare != 0) return completionCompare;
      final scoreCompare = b.averageScore.compareTo(a.averageScore);
      if (scoreCompare != 0) return scoreCompare;
      return a.studentDisplayName.compareTo(b.studentDisplayName);
    });

  final riskStudents = [...studentReports]
    ..sort((a, b) {
      final completionCompare = a.completionRate.compareTo(b.completionRate);
      if (completionCompare != 0) return completionCompare;
      final notStartedCompare = b.notStartedCount.compareTo(a.notStartedCount);
      if (notStartedCompare != 0) return notStartedCompare;
      final scoreCompare = a.averageScore.compareTo(b.averageScore);
      if (scoreCompare != 0) return scoreCompare;
      return a.studentDisplayName.compareTo(b.studentDisplayName);
    });

  return ClassDetailSummary(
    activeMemberCount: members
        .where((member) => member.status == 'active')
        .length,
    assignmentCount: assignments.length,
    setCount: sets.length,
    completedCount: completedCount,
    inProgressCount: inProgressCount,
    pendingCount: pendingCount,
    overdueCount: overdueCount,
    nearestDue: nearestDue,
    averageAssignmentCompletionRate: averageAssignmentCompletionRate,
    averageScore: averageScore,
    topStudents: sortedStudents.take(3).toList(),
    riskStudents: riskStudents.take(3).toList(),
  );
}
