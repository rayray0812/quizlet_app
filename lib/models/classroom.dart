class Classroom {
  final String id;
  final String teacherId;
  final String name;
  final String subject;
  final String grade;
  final String inviteCode;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Classroom({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.subject,
    required this.grade,
    required this.inviteCode,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Classroom.fromMap(Map<String, dynamic> row) {
    return Classroom(
      id: row['id'] as String? ?? '',
      teacherId: row['teacher_id'] as String? ?? '',
      name: row['name'] as String? ?? '',
      subject: row['subject'] as String? ?? '',
      grade: row['grade'] as String? ?? '',
      inviteCode: row['invite_code'] as String? ?? '',
      isArchived: row['is_archived'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
      updatedAt:
          DateTime.tryParse(row['updated_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

class ClassroomMember {
  final String classId;
  final String studentId;
  final DateTime joinedAt;
  final String status;
  final String displayName;

  const ClassroomMember({
    required this.classId,
    required this.studentId,
    required this.joinedAt,
    required this.status,
    required this.displayName,
  });
}

class ClassroomSet {
  final String id;
  final String classId;
  final String ownerTeacherId;
  final String title;
  final String description;
  final List<Map<String, dynamic>> cards;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassroomSet({
    required this.id,
    required this.classId,
    required this.ownerTeacherId,
    required this.title,
    required this.description,
    required this.cards,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClassroomSet.fromMap(Map<String, dynamic> row) {
    final rawCards = (row['cards'] as List<dynamic>? ?? const <dynamic>[]);
    return ClassroomSet(
      id: row['id'] as String? ?? '',
      classId: row['class_id'] as String? ?? '',
      ownerTeacherId: row['owner_teacher_id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      cards: rawCards
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
      updatedAt:
          DateTime.tryParse(row['updated_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

class ClassroomAssignment {
  final String id;
  final String classId;
  final String setId;
  final String assignedBy;
  final DateTime? dueAt;
  final DateTime publishedAt;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String setTitle;
  final int setCardCount;

  const ClassroomAssignment({
    required this.id,
    required this.classId,
    required this.setId,
    required this.assignedBy,
    required this.dueAt,
    required this.publishedAt,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    required this.setTitle,
    required this.setCardCount,
  });

  ClassroomAssignment copyWith({
    String? setTitle,
    int? setCardCount,
  }) {
    return ClassroomAssignment(
      id: id,
      classId: classId,
      setId: setId,
      assignedBy: assignedBy,
      dueAt: dueAt,
      publishedAt: publishedAt,
      isPublished: isPublished,
      createdAt: createdAt,
      updatedAt: updatedAt,
      setTitle: setTitle ?? this.setTitle,
      setCardCount: setCardCount ?? this.setCardCount,
    );
  }

  factory ClassroomAssignment.fromMap(Map<String, dynamic> row) {
    return ClassroomAssignment(
      id: row['id'] as String? ?? '',
      classId: row['class_id'] as String? ?? '',
      setId: row['set_id'] as String? ?? '',
      assignedBy: row['assigned_by'] as String? ?? '',
      dueAt: DateTime.tryParse(row['due_at'] as String? ?? ''),
      publishedAt:
          DateTime.tryParse(row['published_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
      isPublished: row['is_published'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
      updatedAt:
          DateTime.tryParse(row['updated_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
      setTitle: '',
      setCardCount: 0,
    );
  }
}

class StudentAssignmentProgress {
  final String assignmentId;
  final String studentId;
  final String status;
  final double? score;
  final DateTime? lastStudiedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  const StudentAssignmentProgress({
    required this.assignmentId,
    required this.studentId,
    required this.status,
    required this.score,
    required this.lastStudiedAt,
    required this.completedAt,
    required this.updatedAt,
  });

  factory StudentAssignmentProgress.fromMap(Map<String, dynamic> row) {
    return StudentAssignmentProgress(
      assignmentId: row['assignment_id'] as String? ?? '',
      studentId: row['student_id'] as String? ?? '',
      status: row['status'] as String? ?? 'not_started',
      score: (row['score'] as num?)?.toDouble(),
      lastStudiedAt: DateTime.tryParse(row['last_studied_at'] as String? ?? ''),
      completedAt: DateTime.tryParse(row['completed_at'] as String? ?? ''),
      updatedAt:
          DateTime.tryParse(row['updated_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

class ClassroomProgressRow {
  final String assignmentId;
  final String assignmentTitle;
  final String studentId;
  final String studentDisplayName;
  final String status;
  final double? score;
  final DateTime updatedAt;

  const ClassroomProgressRow({
    required this.assignmentId,
    required this.assignmentTitle,
    required this.studentId,
    required this.studentDisplayName,
    required this.status,
    required this.score,
    required this.updatedAt,
  });
}

class ClassroomAssignmentReport {
  final String assignmentId;
  final String assignmentTitle;
  final int studentCount;
  final int completedCount;
  final int inProgressCount;
  final int notStartedCount;
  final double averageScore;

  const ClassroomAssignmentReport({
    required this.assignmentId,
    required this.assignmentTitle,
    required this.studentCount,
    required this.completedCount,
    required this.inProgressCount,
    required this.notStartedCount,
    required this.averageScore,
  });

  double get completionRate {
    if (studentCount <= 0) return 0;
    return completedCount / studentCount;
  }
}

class ClassroomStudentReport {
  final String studentId;
  final String studentDisplayName;
  final int assignmentCount;
  final int completedCount;
  final int inProgressCount;
  final int notStartedCount;
  final double averageScore;

  const ClassroomStudentReport({
    required this.studentId,
    required this.studentDisplayName,
    required this.assignmentCount,
    required this.completedCount,
    required this.inProgressCount,
    required this.notStartedCount,
    required this.averageScore,
  });

  double get completionRate {
    if (assignmentCount <= 0) return 0;
    return completedCount / assignmentCount;
  }
}

class ClassroomStudentAssignmentDetail {
  final String assignmentId;
  final String assignmentTitle;
  final DateTime? dueAt;
  final bool isPublished;
  final String status;
  final double? score;
  final DateTime? updatedAt;

  const ClassroomStudentAssignmentDetail({
    required this.assignmentId,
    required this.assignmentTitle,
    required this.dueAt,
    required this.isPublished,
    required this.status,
    required this.score,
    required this.updatedAt,
  });
}
