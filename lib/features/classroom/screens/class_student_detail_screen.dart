import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/providers/classroom_provider.dart';

class ClassStudentDetailScreen extends ConsumerWidget {
  final String classId;
  final String studentId;
  final String studentName;

  const ClassStudentDetailScreen({
    super.key,
    required this.classId,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(
      studentAssignmentDetailsProvider(
        StudentDetailQuery(classId: classId, studentId: studentId),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(studentName),
      ),
      body: detailsAsync.when(
        data: (items) {
          final assignmentCount = items.length;
          final completedCount = items.where((e) => e.status == 'completed').length;
          final inProgressCount =
              items.where((e) => e.status == 'in_progress').length;
          final notStartedCount =
              items.where((e) => e.status == 'not_started').length;
          final scored = items.where((e) => e.score != null).toList();
          final averageScore = scored.isEmpty
              ? 0.0
              : scored.map((e) => e.score!).reduce((a, b) => a + b) /
                    scored.length;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                studentAssignmentDetailsProvider(
                  StudentDetailQuery(classId: classId, studentId: studentId),
                ),
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.analytics_outlined),
                    title: const Text('Student Summary'),
                    subtitle: Text(
                      'Assignments: $assignmentCount | Completed: $completedCount | In progress: $inProgressCount | Not started: $notStartedCount'
                      '\nAverage score: ${averageScore.toStringAsFixed(1)}',
                    ),
                    isThreeLine: true,
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Card(
                    child: ListTile(title: Text('No assignments found')),
                  ),
                ...items.map(
                  (item) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.assignment_turned_in_outlined),
                      title: Text(item.assignmentTitle),
                      subtitle: Text(
                        'Status: ${item.status} | Score: ${item.score?.toStringAsFixed(1) ?? '-'}'
                        '\nDue: ${item.dueAt?.toLocal().toString().split(' ').first ?? 'No due date'} | Published: ${item.isPublished ? 'Yes' : 'No'}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        error: (e, _) => Center(
          child: Text('Failed to load student details: $e'),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
