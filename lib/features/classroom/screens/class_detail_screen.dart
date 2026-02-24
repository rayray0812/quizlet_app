import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/models/classroom.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/providers/classroom_provider.dart';
import 'package:recall_app/providers/study_set_provider.dart';

class ClassDetailScreen extends ConsumerWidget {
  final String classId;

  const ClassDetailScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classAsync = ref.watch(classByIdProvider(classId));
    final setsAsync = ref.watch(classroomSetsProvider(classId));
    final assignmentsAsync = ref.watch(classAssignmentsProvider(classId));
    final membersAsync = ref.watch(classMembersProvider(classId));
    final progressAsync = ref.watch(myClassProgressProvider(classId));
    final classProgressAsync = ref.watch(classProgressRowsProvider(classId));
    final reportAsync = ref.watch(classAssignmentReportsProvider(classId));
    final studentReportAsync = ref.watch(classStudentReportsProvider(classId));
    final userId = ref.watch(currentUserProvider)?.id ?? '';
    final myStudySets = ref.watch(studySetsProvider);
    final messenger = ScaffoldMessenger.of(context);

    return classAsync.when(
      data: (classroom) {
        if (classroom == null) {
          return const Scaffold(
            body: Center(child: Text('Class not found')),
          );
        }
        final isTeacher = classroom.teacherId == userId;
        return Scaffold(
          appBar: AppBar(
            title: Text(classroom.name),
            actions: [
              IconButton(
                tooltip: 'Copy invite code',
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: classroom.inviteCode),
                  );
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Invite code copied')),
                  );
                },
                icon: const Icon(Icons.key_rounded),
              ),
            ],
          ),
          floatingActionButton: isTeacher
              ? FloatingActionButton(
                  onPressed: () => _showCreateSetDialog(context, ref, classId),
                  child: const Icon(Icons.library_add_rounded),
                )
              : null,
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(classByIdProvider(classId));
              ref.invalidate(classroomSetsProvider(classId));
              ref.invalidate(classAssignmentsProvider(classId));
              ref.invalidate(classMembersProvider(classId));
              ref.invalidate(myClassProgressProvider(classId));
              ref.invalidate(classProgressRowsProvider(classId));
              ref.invalidate(classAssignmentReportsProvider(classId));
              ref.invalidate(classStudentReportsProvider(classId));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Card(
                  child: ListTile(
                    title: Text(classroom.name),
                    subtitle: Text(
                      'Invite: ${classroom.inviteCode}\n${classroom.subject} ${classroom.grade}',
                    ),
                    isThreeLine: true,
                  ),
                ),
                const SizedBox(height: 12),
                if (isTeacher)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: () async => _showAssignDialog(
                          context: context,
                          ref: ref,
                          classId: classId,
                          classSets: setsAsync.valueOrNull ?? const [],
                        ),
                        icon: const Icon(Icons.assignment_add),
                        label: const Text('Assign Existing Class Set'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showImportFromMySetDialog(
                          context: context,
                          ref: ref,
                          classId: classId,
                          myStudySets: myStudySets,
                        ),
                        icon: const Icon(Icons.download_for_offline_outlined),
                        label: const Text('Import From My Study Sets'),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Text(
                  'Assignments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                assignmentsAsync.when(
                  data: (assignments) {
                    final progressByAssignment = <String, StudentAssignmentProgress>{
                      for (final p in (progressAsync.valueOrNull ?? const []))
                        p.assignmentId: p,
                    };
                    if (assignments.isEmpty) {
                      return const Card(
                        child: ListTile(title: Text('No assignments yet')),
                      );
                    }
                    return Column(
                      children: assignments.map((assignment) {
                        final progress = progressByAssignment[assignment.id];
                        return Card(
                          child: ListTile(
                            title: Text(assignment.setTitle),
                            subtitle: Text(
                              'Cards: ${assignment.setCardCount} | Due: ${assignment.dueAt?.toLocal().toString().split(' ').first ?? 'No due date'}'
                              '\nStatus: ${progress?.status ?? 'not_started'}',
                            ),
                            isThreeLine: true,
                            trailing: isTeacher
                                ? IconButton(
                                    tooltip: 'Preview set',
                                    onPressed: () async {
                                      await _startAssignmentStudy(
                                        context: context,
                                        ref: ref,
                                        classId: classId,
                                        assignment: assignment,
                                        classSets: setsAsync.valueOrNull ?? const [],
                                        markInProgress: false,
                                      );
                                    },
                                    icon: const Icon(Icons.play_arrow_rounded),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Start',
                                        onPressed: () async {
                                          await _startAssignmentStudy(
                                            context: context,
                                            ref: ref,
                                            classId: classId,
                                            assignment: assignment,
                                            classSets:
                                                setsAsync.valueOrNull ?? const [],
                                            markInProgress: true,
                                          );
                                        },
                                        icon: const Icon(Icons.play_arrow_rounded),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          await ref
                                              .read(classroomServiceProvider)
                                              .upsertMyProgress(
                                                assignmentId: assignment.id,
                                                status: value,
                                              );
                                          ref.invalidate(
                                            myClassProgressProvider(classId),
                                          );
                                          ref.invalidate(
                                            classProgressRowsProvider(classId),
                                          );
                                          ref.invalidate(
                                            classAssignmentReportsProvider(classId),
                                          );
                                          ref.invalidate(
                                            classStudentReportsProvider(classId),
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  value == 'completed'
                                                      ? 'Marked completed'
                                                      : 'Marked in progress',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'in_progress',
                                            child: Text('Mark In Progress'),
                                          ),
                                          PopupMenuItem(
                                            value: 'completed',
                                            child: Text('Mark Completed'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  error: (e, _) => Text('Failed to load assignments: $e'),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                if (isTeacher) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Progress Overview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  classProgressAsync.when(
                    data: (rows) {
                      if (rows.isEmpty) {
                        return const Card(
                          child: ListTile(
                            title: Text('No student progress submitted yet'),
                          ),
                        );
                      }
                      return Column(
                        children: rows
                            .map(
                              (row) => Card(
                                child: ListTile(
                                  leading: const Icon(Icons.insights_rounded),
                                  title: Text(
                                    '${row.studentDisplayName} - ${row.assignmentTitle}',
                                  ),
                                  subtitle: Text(
                                    'Status: ${row.status} | Score: ${row.score?.toStringAsFixed(1) ?? '-'}',
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                    error: (e, _) => Text('Failed to load progress: $e'),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  reportAsync.when(
                    data: (reports) {
                      if (reports.isEmpty) return const SizedBox.shrink();
                      return Column(
                        children: reports
                            .map(
                              (report) => Card(
                                child: ListTile(
                                  leading: const Icon(Icons.analytics_rounded),
                                  title: Text(report.assignmentTitle),
                                  subtitle: Text(
                                    'Completion: ${(report.completionRate * 100).round()}% | Avg score: ${report.averageScore.toStringAsFixed(1)}'
                                    '\nCompleted: ${report.completedCount} | In progress: ${report.inProgressCount} | Not started: ${report.notStartedCount}',
                                  ),
                                  isThreeLine: true,
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                    error: (e, _) => Text('Failed to load report: $e'),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Student Overview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  studentReportAsync.when(
                    data: (reports) {
                      if (reports.isEmpty) {
                        return const Card(
                          child: ListTile(title: Text('No students to report')),
                        );
                      }
                      return Column(
                        children: reports
                            .map(
                              (report) => Card(
                                child: ListTile(
                                  leading: const Icon(Icons.person_pin_rounded),
                                  title: Text(report.studentDisplayName),
                                  subtitle: Text(
                                    'Completion: ${(report.completionRate * 100).round()}% | Avg score: ${report.averageScore.toStringAsFixed(1)}'
                                    '\nCompleted: ${report.completedCount} | In progress: ${report.inProgressCount} | Not started: ${report.notStartedCount}',
                                  ),
                                  isThreeLine: true,
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                  onTap: () => context.push(
                                    '/classes/$classId/student/${report.studentId}',
                                    extra: <String, dynamic>{
                                      'studentName': report.studentDisplayName,
                                    },
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                    error: (e, _) => Text('Failed to load student overview: $e'),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Class Sets',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                setsAsync.when(
                  data: (sets) {
                    if (sets.isEmpty) {
                      return const Card(
                        child: ListTile(title: Text('No class sets yet')),
                      );
                    }
                    return Column(
                      children: sets
                          .map(
                            (set) => Card(
                              child: ListTile(
                                title: Text(set.title),
                                subtitle: Text('Cards: ${set.cards.length}'),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                  error: (e, _) => Text('Failed to load sets: $e'),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Students',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                membersAsync.when(
                  data: (members) {
                    if (members.isEmpty) {
                      return const Card(
                        child: ListTile(title: Text('No students yet')),
                      );
                    }
                    return Column(
                      children: members
                          .where((item) => item.status == 'active')
                          .map(
                            (member) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text(member.displayName),
                                subtitle: Text(member.studentId),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                  error: (e, _) => Text('Failed to load members: $e'),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Failed to load class: $error')),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _startAssignmentStudy({
    required BuildContext context,
    required WidgetRef ref,
    required String classId,
    required ClassroomAssignment assignment,
    required List<ClassroomSet> classSets,
    required bool markInProgress,
  }) async {
    final linkedSet = classSets.where((set) => set.id == assignment.setId).firstOrNull;
    if (linkedSet == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Linked class set not found')),
        );
      }
      return;
    }

    final localSetId = 'class_${classId}_${linkedSet.id}';
    final cards = linkedSet.cards.map((row) {
      final id = row['id']?.toString().trim();
      return Flashcard(
        id: (id != null && id.isNotEmpty)
            ? id
            : '${localSetId}_${row['term'] ?? ''}_${DateTime.now().microsecondsSinceEpoch}',
        term: row['term']?.toString() ?? '',
        definition: row['definition']?.toString() ?? '',
        exampleSentence: row['exampleSentence']?.toString() ?? '',
      );
    }).toList();

    final notifier = ref.read(studySetsProvider.notifier);
    final existing = notifier.getById(localSetId);
    final payload = StudySet(
      id: localSetId,
      title: linkedSet.title,
      description: linkedSet.description,
      createdAt: existing?.createdAt ?? linkedSet.createdAt,
      updatedAt: DateTime.now().toUtc(),
      cards: cards,
      isSynced: false,
      folderId: existing?.folderId,
      isPinned: existing?.isPinned ?? false,
      lastStudiedAt: existing?.lastStudiedAt,
    );
    if (existing == null) {
      await notifier.add(payload);
    } else {
      await notifier.update(payload);
    }

    if (markInProgress) {
      await ref.read(classroomServiceProvider).upsertMyProgress(
            assignmentId: assignment.id,
            status: 'in_progress',
          );
      ref.invalidate(myClassProgressProvider(classId));
      ref.invalidate(classProgressRowsProvider(classId));
      ref.invalidate(classAssignmentReportsProvider(classId));
      ref.invalidate(classStudentReportsProvider(classId));
    }

    if (context.mounted) {
      context.push('/study/$localSetId');
    }
  }

  Future<void> _showCreateSetDialog(
    BuildContext context,
    WidgetRef ref,
    String classId,
  ) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final cardsController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Class Set'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cardsController,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Cards (term|definition, one per line)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              final cards = _parseCards(cardsController.text);
              if (cards.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Please add at least 1 card.')),
                );
                return;
              }
              await ref.read(classroomServiceProvider).createClassSet(
                classId: classId,
                title: title,
                description: descriptionController.text,
                cards: cards,
              );
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    titleController.dispose();
    descriptionController.dispose();
    cardsController.dispose();
    if (created == true) {
      ref.invalidate(classroomSetsProvider(classId));
    }
  }

  Future<void> _showAssignDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String classId,
    required List<ClassroomSet> classSets,
  }) async {
    if (classSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create class sets first.')),
      );
      return;
    }

    String selectedSetId = classSets.first.id;
    DateTime? dueAt;
    final assigned = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign Set'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedSetId,
                isExpanded: true,
                items: classSets
                    .map(
                      (set) => DropdownMenuItem(
                        value: set.id,
                        child: Text(set.title),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedSetId = value);
                },
                decoration: const InputDecoration(labelText: 'Class set'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (selected != null) {
                    setState(() => dueAt = selected);
                  }
                },
                icon: const Icon(Icons.event_rounded),
                label: Text(
                  dueAt == null
                      ? 'Set due date (optional)'
                      : 'Due: ${dueAt!.toLocal().toString().split(' ').first}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(classroomServiceProvider).createAssignment(
                  classId: classId,
                  setId: selectedSetId,
                  dueAt: dueAt,
                );
                if (context.mounted) Navigator.of(context).pop(true);
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (assigned == true) {
      ref.invalidate(classAssignmentsProvider(classId));
    }
  }

  Future<void> _showImportFromMySetDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String classId,
    required List<StudySet> myStudySets,
  }) async {
    if (myStudySets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No local study sets to import.')),
      );
      return;
    }

    final sets = myStudySets;
    String selectedId = sets.first.id;
    final imported = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Import My Study Set'),
          content: DropdownButtonFormField<String>(
            value: selectedId,
            isExpanded: true,
            items: sets
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(item.title),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedId = value);
            },
            decoration: const InputDecoration(labelText: 'Study set'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final selected = sets.where((item) => item.id == selectedId);
                if (selected.isEmpty) return;
                final set = selected.first;
                final cards = set.cards
                    .map((card) => {
                          'id': card.id,
                          'term': card.term,
                          'definition': card.definition,
                          'exampleSentence': card.exampleSentence,
                        })
                    .toList();
                await ref.read(classroomServiceProvider).createClassSet(
                      classId: classId,
                      title: set.title,
                      description: set.description,
                      cards: cards,
                    );
                if (context.mounted) Navigator.of(context).pop(true);
              },
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );

    if (imported == true) {
      ref.invalidate(classroomSetsProvider(classId));
    }
  }

  List<Map<String, dynamic>> _parseCards(String raw) {
    final lines = raw.split('\n');
    final cards = <Map<String, dynamic>>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final split = trimmed.split('|');
      final term = split.first.trim();
      final definition = split.length > 1
          ? split.sublist(1).join('|').trim()
          : '';
      if (term.isEmpty || definition.isEmpty) continue;
      cards.add({
        'id': DateTime.now().microsecondsSinceEpoch.toString() + term,
        'term': term,
        'definition': definition,
      });
    }
    return cards;
  }
}
