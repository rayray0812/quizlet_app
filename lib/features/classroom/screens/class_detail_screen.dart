import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:recall_app/models/classroom.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/providers/classroom_provider.dart';
import 'package:recall_app/providers/study_set_provider.dart';

enum _AssignmentFilter { all, pending, completed, overdue }

String _formatClassDate(DateTime? date) {
  if (date == null) return 'Not set';
  return DateFormat('yyyy/MM/dd').format(date.toLocal());
}

class ClassDetailScreen extends ConsumerStatefulWidget {
  final String classId;

  const ClassDetailScreen({super.key, required this.classId});

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen> {
  _AssignmentFilter _assignmentFilter = _AssignmentFilter.all;

  @override
  Widget build(BuildContext context) {
    final classId = widget.classId;
    final classroomAsync = ref.watch(classByIdProvider(classId));
    final setsAsync = ref.watch(classroomSetsProvider(classId));
    final assignmentsAsync = ref.watch(classAssignmentsProvider(classId));
    final membersAsync = ref.watch(classMembersProvider(classId));
    final progressAsync = ref.watch(myClassProgressProvider(classId));
    final reportAsync = ref.watch(classAssignmentReportsProvider(classId));
    final studentReportAsync = ref.watch(classStudentReportsProvider(classId));
    final myStudySets = ref.watch(studySetsProvider);
    final userId = ref.watch(currentUserProvider)?.id ?? '';

    return classroomAsync.when(
      data: (classroom) {
        if (classroom == null) {
          return const Scaffold(body: Center(child: Text('Class not found')));
        }

        final isTeacher = classroom.teacherId == userId;
        final sets = setsAsync.valueOrNull ?? const <ClassroomSet>[];
        final assignments = assignmentsAsync.valueOrNull ?? const <ClassroomAssignment>[];
        final members = membersAsync.valueOrNull ?? const <ClassroomMember>[];
        final progresses = progressAsync.valueOrNull ?? const <StudentAssignmentProgress>[];
        final reports = reportAsync.valueOrNull ?? const <ClassroomAssignmentReport>[];
        final studentReports = studentReportAsync.valueOrNull ?? const <ClassroomStudentReport>[];

        final filteredAssignments = assignments.where((assignment) {
          final progress = _findProgress(progresses, assignment.id);
          final isCompleted = progress?.status == 'completed';
          final isOverdue = assignment.dueAt != null && assignment.dueAt!.isBefore(DateTime.now()) && !isCompleted;
          switch (_assignmentFilter) {
            case _AssignmentFilter.pending:
              return !isCompleted;
            case _AssignmentFilter.completed:
              return isCompleted;
            case _AssignmentFilter.overdue:
              return isOverdue;
            case _AssignmentFilter.all:
              return true;
          }
        }).toList();

        final completedCount = progresses.where((item) => item.status == 'completed').length;
        final inProgressCount = progresses.where((item) => item.status == 'in_progress').length;
        final pendingCount = assignments.where((assignment) => _findProgress(progresses, assignment.id)?.status != 'completed').length;
        DateTime? nearestDue;
        for (final assignment in assignments) {
          if (assignment.dueAt == null) continue;
          if (_findProgress(progresses, assignment.id)?.status == 'completed') continue;
          if (nearestDue == null || assignment.dueAt!.isBefore(nearestDue)) {
            nearestDue = assignment.dueAt;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(classroom.name),
            actions: [
              IconButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: classroom.inviteCode));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code copied')));
                },
                icon: const Icon(Icons.key_rounded),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'archive') {
                    await ref.read(classroomServiceProvider).updateClassArchiveStatus(classId: classId, isArchived: !classroom.isArchived);
                    ref.invalidate(classByIdProvider(classId));
                    ref.invalidate(myClassesProvider);
                  }
                  if (value == 'leave') {
                    await ref.read(classroomServiceProvider).leaveClass(classId);
                    ref.invalidate(myClassesProvider);
                    if (context.mounted) context.pop();
                  }
                },
                itemBuilder: (context) => [
                  if (isTeacher)
                    PopupMenuItem(value: 'archive', child: Text(classroom.isArchived ? 'Restore class' : 'Archive class')),
                  if (!isTeacher)
                    const PopupMenuItem(value: 'leave', child: Text('Leave class')),
                ],
              ),
            ],
          ),
          floatingActionButton: isTeacher
              ? FloatingActionButton.extended(
                  onPressed: () => _showCreateSetDialog(context, classId),
                  icon: const Icon(Icons.library_add_rounded),
                  label: const Text('New set'),
                )
              : null,
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(classByIdProvider(classId));
              ref.invalidate(classroomSetsProvider(classId));
              ref.invalidate(classAssignmentsProvider(classId));
              ref.invalidate(classMembersProvider(classId));
              ref.invalidate(myClassProgressProvider(classId));
              ref.invalidate(classAssignmentReportsProvider(classId));
              ref.invalidate(classStudentReportsProvider(classId));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Card(
                  child: ListTile(
                    title: Text(classroom.name),
                    subtitle: Text(isTeacher
                        ? 'Invite: ${classroom.inviteCode} | Sets: ${sets.length} | Assignments: ${assignments.length}'
                        : 'Completed: $completedCount | In progress: $inProgressCount | Pending: $pendingCount${nearestDue == null ? '' : ' | Next due: ${_formatClassDate(nearestDue)}'}'),
                  ),
                ),
                if (isTeacher) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _showAssignDialog(context, classId, sets),
                          icon: const Icon(Icons.post_add_rounded),
                          label: const Text('Assign set'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showImportDialog(context, classId, myStudySets),
                          icon: const Icon(Icons.download_for_offline_outlined),
                          label: const Text('Import set'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(label: const Text('All'), selected: _assignmentFilter == _AssignmentFilter.all, onSelected: (_) => setState(() => _assignmentFilter = _AssignmentFilter.all)),
                    ChoiceChip(label: const Text('Pending'), selected: _assignmentFilter == _AssignmentFilter.pending, onSelected: (_) => setState(() => _assignmentFilter = _AssignmentFilter.pending)),
                    ChoiceChip(label: const Text('Completed'), selected: _assignmentFilter == _AssignmentFilter.completed, onSelected: (_) => setState(() => _assignmentFilter = _AssignmentFilter.completed)),
                    ChoiceChip(label: const Text('Overdue'), selected: _assignmentFilter == _AssignmentFilter.overdue, onSelected: (_) => setState(() => _assignmentFilter = _AssignmentFilter.overdue)),
                  ],
                ),
                const SizedBox(height: 8),
                ...filteredAssignments.map((assignment) {
                  final progress = _findProgress(progresses, assignment.id);
                  final report = _findAssignmentReport(reports, assignment.id);
                  final status = progress?.status ?? 'not_started';
                  return Card(
                    child: ListTile(
                      title: Text(assignment.setTitle),
                      subtitle: Text('Due: ${_formatClassDate(assignment.dueAt)} | Cards: ${assignment.setCardCount} | Status: $status${report == null ? '' : ' | Done: ${report.completedCount}/${report.studentCount}'}'),
                      trailing: TextButton(
                        onPressed: () => _startAssignmentStudy(context, classId, assignment, sets, !isTeacher),
                        child: Text(isTeacher ? 'Preview' : 'Start'),
                      ),
                    ),
                  );
                }),
                if (filteredAssignments.isEmpty)
                  const Card(child: ListTile(title: Text('No assignments found'))),
                const SizedBox(height: 16),
                const Text('Class sets'),
                const SizedBox(height: 8),
                ...sets.map((set) => Card(child: ListTile(title: Text(set.title), subtitle: Text('${set.cards.length} cards | Updated ${_formatClassDate(set.updatedAt)}')))),
                if (sets.isEmpty)
                  const Card(child: ListTile(title: Text('No class sets yet'))),
                const SizedBox(height: 16),
                Text(isTeacher ? 'Members' : 'Classmates'),
                const SizedBox(height: 8),
                ...members.where((member) => member.status == 'active').map((member) {
                  final report = _findStudentReport(studentReports, member.studentId);
                  return Card(
                    child: ListTile(
                      title: Text(member.displayName),
                      subtitle: Text(report == null ? member.studentId : 'Completed ${report.completedCount}/${report.assignmentCount} | Avg ${report.averageScore.toStringAsFixed(1)}'),
                      trailing: isTeacher ? const Icon(Icons.chevron_right_rounded) : null,
                      onTap: isTeacher
                          ? () => context.push('/classes/$classId/student/${member.studentId}', extra: <String, dynamic>{'studentName': member.displayName})
                          : null,
                    ),
                  );
                }),
                if (members.where((member) => member.status == 'active').isEmpty)
                  const Card(child: ListTile(title: Text('No active members'))),
              ],
            ),
          ),
        );
      },
      error: (error, _) => Scaffold(body: Center(child: Text('Failed to load class: $error'))),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  Future<void> _startAssignmentStudy(BuildContext context, String classId, ClassroomAssignment assignment, List<ClassroomSet> classSets, bool markInProgress) async {
    ClassroomSet? linkedSet;
    for (final item in classSets) {
      if (item.id == assignment.setId) linkedSet = item;
    }
    if (linkedSet == null) return;
    final localSetId = 'class_${classId}_${linkedSet.id}';
    final cards = linkedSet.cards.map((row) => Flashcard(
      id: row['id']?.toString() ?? '${DateTime.now().microsecondsSinceEpoch}',
      term: row['term']?.toString() ?? '',
      definition: row['definition']?.toString() ?? '',
      exampleSentence: row['exampleSentence']?.toString() ?? '',
    )).toList();
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
      await ref.read(classroomServiceProvider).upsertMyProgress(assignmentId: assignment.id, status: 'in_progress');
      ref.invalidate(myClassProgressProvider(classId));
      ref.invalidate(classAssignmentReportsProvider(classId));
      ref.invalidate(classStudentReportsProvider(classId));
    }
    if (context.mounted) context.push('/study/$localSetId');
  }

  Future<void> _showCreateSetDialog(BuildContext context, String classId) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final cardsController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create class set'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 8),
              TextField(controller: cardsController, minLines: 6, maxLines: 10, decoration: const InputDecoration(labelText: 'Cards', hintText: 'term|definition')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final cards = _parseCards(cardsController.text);
              if (titleController.text.trim().isEmpty || cards.isEmpty) return;
              await ref.read(classroomServiceProvider).createClassSet(classId: classId, title: titleController.text, description: descriptionController.text, cards: cards);
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
    if (created == true) ref.invalidate(classroomSetsProvider(classId));
  }

  Future<void> _showAssignDialog(BuildContext context, String classId, List<ClassroomSet> classSets) async {
    if (classSets.isEmpty) return;
    String selectedSetId = classSets.first.id;
    DateTime? dueAt;
    final assigned = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign class set'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedSetId,
                items: classSets.map((set) => DropdownMenuItem(value: set.id, child: Text(set.title))).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => selectedSetId = value);
                },
                decoration: const InputDecoration(labelText: 'Set'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due date'),
                subtitle: Text(dueAt == null ? 'No due date' : _formatClassDate(dueAt)),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final picked = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: dueAt ?? DateTime.now().add(const Duration(days: 7)));
                  if (picked != null) {
                    setState(() => dueAt = DateTime(picked.year, picked.month, picked.day, 23, 59));
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                await ref.read(classroomServiceProvider).createAssignment(classId: classId, setId: selectedSetId, dueAt: dueAt);
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
      ref.invalidate(classAssignmentReportsProvider(classId));
      ref.invalidate(classStudentReportsProvider(classId));
    }
  }

  Future<void> _showImportDialog(BuildContext context, String classId, List<StudySet> myStudySets) async {
    if (myStudySets.isEmpty) return;
    String selectedId = myStudySets.first.id;
    final imported = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Import from my study sets'),
          content: DropdownButtonFormField<String>(
            value: selectedId,
            items: myStudySets.map((item) => DropdownMenuItem(value: item.id, child: Text(item.title))).toList(),
            onChanged: (value) {
              if (value != null) setState(() => selectedId = value);
            },
            decoration: const InputDecoration(labelText: 'Study set'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final set = myStudySets.firstWhere((item) => item.id == selectedId);
                await ref.read(classroomServiceProvider).createClassSet(
                  classId: classId,
                  title: set.title,
                  description: set.description,
                  cards: set.cards.map((card) => <String, dynamic>{
                    'id': card.id,
                    'term': card.term,
                    'definition': card.definition,
                    'exampleSentence': card.exampleSentence,
                  }).toList(),
                );
                if (context.mounted) Navigator.of(context).pop(true);
              },
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
    if (imported == true) ref.invalidate(classroomSetsProvider(classId));
  }

  List<Map<String, dynamic>> _parseCards(String raw) {
    final cards = <Map<String, dynamic>>[];
    var index = 0;
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split('|');
      if (parts.length < 2) continue;
      cards.add(<String, dynamic>{
        'id': 'card_${DateTime.now().microsecondsSinceEpoch}_$index',
        'term': parts[0].trim(),
        'definition': parts.sublist(1).join('|').trim(),
      });
      index++;
    }
    return cards;
  }

  StudentAssignmentProgress? _findProgress(List<StudentAssignmentProgress> items, String assignmentId) {
    for (final item in items) {
      if (item.assignmentId == assignmentId) return item;
    }
    return null;
  }

  ClassroomAssignmentReport? _findAssignmentReport(List<ClassroomAssignmentReport> items, String assignmentId) {
    for (final item in items) {
      if (item.assignmentId == assignmentId) return item;
    }
    return null;
  }

  ClassroomStudentReport? _findStudentReport(List<ClassroomStudentReport> items, String studentId) {
    for (final item in items) {
      if (item.studentId == studentId) return item;
    }
    return null;
  }
}
