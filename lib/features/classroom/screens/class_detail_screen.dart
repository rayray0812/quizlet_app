import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';
import 'package:recall_app/features/classroom/utils/class_detail_metrics.dart';
import 'package:recall_app/models/classroom.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/providers/classroom_provider.dart';
import 'package:recall_app/providers/study_set_provider.dart';

String _formatClassDate(DateTime? date) {
  if (date == null) return 'Not set';
  return DateFormat('yyyy/MM/dd').format(date.toLocal());
}

String _statusLabel(String status) {
  return switch (status) {
    'completed' => 'Completed',
    'in_progress' => 'In progress',
    _ => 'Not started',
  };
}

class ClassDetailScreen extends ConsumerStatefulWidget {
  final String classId;

  const ClassDetailScreen({super.key, required this.classId});

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen> {
  ClassAssignmentFilter _assignmentFilter = ClassAssignmentFilter.all;

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
        final assignments =
            assignmentsAsync.valueOrNull ?? const <ClassroomAssignment>[];
        final members = membersAsync.valueOrNull ?? const <ClassroomMember>[];
        final progresses =
            progressAsync.valueOrNull ?? const <StudentAssignmentProgress>[];
        final reports =
            reportAsync.valueOrNull ?? const <ClassroomAssignmentReport>[];
        final studentReports =
            studentReportAsync.valueOrNull ?? const <ClassroomStudentReport>[];

        final summary = buildClassDetailSummary(
          assignments: assignments,
          sets: sets,
          members: members,
          progresses: progresses,
          assignmentReports: reports,
          studentReports: studentReports,
        );
        final filteredAssignments = filterAssignments(
          assignments: assignments,
          progresses: progresses,
          filter: _assignmentFilter,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(classroom.name),
            actions: [
              IconButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: classroom.inviteCode),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite code copied')),
                  );
                },
                icon: const Icon(Icons.key_rounded),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'archive') {
                    await ref
                        .read(classroomServiceProvider)
                        .updateClassArchiveStatus(
                          classId: classId,
                          isArchived: !classroom.isArchived,
                        );
                    await _refreshClassData(classId);
                    ref.invalidate(myClassesProvider);
                  }
                  if (value == 'leave') {
                    await ref
                        .read(classroomServiceProvider)
                        .leaveClass(classId);
                    ref.invalidate(myClassesProvider);
                    if (context.mounted) context.pop();
                  }
                },
                itemBuilder: (context) => [
                  if (isTeacher)
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(
                        classroom.isArchived
                            ? 'Restore class'
                            : 'Archive class',
                      ),
                    ),
                  if (!isTeacher)
                    const PopupMenuItem(
                      value: 'leave',
                      child: Text('Leave class'),
                    ),
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
            onRefresh: () => _refreshClassData(classId),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _buildHeroCard(
                  context: context,
                  classroom: classroom,
                  isTeacher: isTeacher,
                  summary: summary,
                ),
                if (isTeacher) ...[
                  const SizedBox(height: 14),
                  _buildTeacherActionRow(context, classId, sets, myStudySets),
                  const SizedBox(height: 14),
                  _buildTeacherInsights(context, summary),
                ] else ...[
                  const SizedBox(height: 14),
                  _buildStudentInsights(context, summary),
                ],
                const SizedBox(height: 18),
                _buildSectionHeader(
                  context,
                  'Assignments',
                  '${filteredAssignments.length} visible',
                ),
                const SizedBox(height: 10),
                _buildAssignmentFilters(),
                const SizedBox(height: 10),
                if (filteredAssignments.isEmpty)
                  _buildEmptyCard(
                    context,
                    'No assignments in this filter right now.',
                  )
                else
                  ...filteredAssignments.map(
                    (assignment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildAssignmentCard(
                        context: context,
                        classId: classId,
                        assignment: assignment,
                        sets: sets,
                        progress: findAssignmentProgress(
                          progresses,
                          assignment.id,
                        ),
                        report: findAssignmentReport(reports, assignment.id),
                        isTeacher: isTeacher,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                _buildSectionHeader(
                  context,
                  'Class sets',
                  '${sets.length} sets',
                ),
                const SizedBox(height: 10),
                if (sets.isEmpty)
                  _buildEmptyCard(context, 'No class sets yet.')
                else
                  ...sets.map(
                    (set) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AdaptiveGlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              set.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (set.description.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(set.description),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildStatPill(
                                  context,
                                  '${set.cards.length} cards',
                                  Icons.style_rounded,
                                ),
                                _buildStatPill(
                                  context,
                                  'Updated ${_formatClassDate(set.updatedAt)}',
                                  Icons.schedule_rounded,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                _buildSectionHeader(
                  context,
                  isTeacher ? 'Members' : 'Classmates',
                  '${summary.activeMemberCount} active',
                ),
                const SizedBox(height: 10),
                if (members
                    .where((member) => member.status == 'active')
                    .isEmpty)
                  _buildEmptyCard(context, 'No active members.')
                else
                  ...members
                      .where((member) => member.status == 'active')
                      .map(
                        (member) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildMemberCard(
                            context: context,
                            classId: classId,
                            member: member,
                            report: findStudentReport(
                              studentReports,
                              member.studentId,
                            ),
                            isTeacher: isTeacher,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Failed to load class: $error'))),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  Widget _buildHeroCard({
    required BuildContext context,
    required Classroom classroom,
    required bool isTeacher,
    required ClassDetailSummary summary,
  }) {
    final theme = Theme.of(context);
    final subtitle = isTeacher
        ? 'Invite ${classroom.inviteCode} • ${summary.activeMemberCount} active students'
        : 'Stay on top of deadlines and update your progress in one place.';

    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(18),
      fillColor: Colors.white.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            classroom.subject.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTheme.indigo,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(classroom.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMetricTile(
                context,
                isTeacher ? 'Assignments' : 'Completed',
                isTeacher
                    ? '${summary.assignmentCount}'
                    : '${summary.completedCount}/${summary.assignmentCount}',
                isTeacher ? Icons.assignment_rounded : Icons.task_alt_rounded,
              ),
              _buildMetricTile(
                context,
                isTeacher ? 'Class score' : 'In progress',
                isTeacher
                    ? '${summary.averageScore.toStringAsFixed(0)}%'
                    : '${summary.inProgressCount}',
                isTeacher ? Icons.insights_rounded : Icons.timelapse_rounded,
              ),
              _buildMetricTile(
                context,
                isTeacher ? 'Completion' : 'Next due',
                isTeacher
                    ? '${(summary.averageAssignmentCompletionRate * 100).toStringAsFixed(0)}%'
                    : _formatClassDate(summary.nearestDue),
                isTeacher ? Icons.show_chart_rounded : Icons.event_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherActionRow(
    BuildContext context,
    String classId,
    List<ClassroomSet> sets,
    List<StudySet> myStudySets,
  ) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _showAssignDialog(context, classId, sets),
            icon: const Icon(Icons.post_add_rounded),
            label: const Text('Assign set'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showImportDialog(context, classId, myStudySets),
            icon: const Icon(Icons.download_for_offline_outlined),
            label: const Text('Import set'),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherInsights(
    BuildContext context,
    ClassDetailSummary summary,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildStudentRankingCard(
            context: context,
            title: 'Top students',
            icon: Icons.emoji_events_rounded,
            reports: summary.topStudents,
            emptyText: 'No student activity yet.',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStudentRankingCard(
            context: context,
            title: 'Needs attention',
            icon: Icons.flag_rounded,
            reports: summary.riskStudents,
            emptyText: 'Everyone is on track.',
            emphasizeRisk: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentInsights(
    BuildContext context,
    ClassDetailSummary summary,
  ) {
    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildInsightColumn(
              context,
              'Pending',
              '${summary.pendingCount}',
              Icons.pending_actions_rounded,
            ),
          ),
          Expanded(
            child: _buildInsightColumn(
              context,
              'Overdue',
              '${summary.overdueCount}',
              Icons.warning_amber_rounded,
              color: AppTheme.red,
            ),
          ),
          Expanded(
            child: _buildInsightColumn(
              context,
              'Completion',
              '${(summary.studentCompletionRate * 100).toStringAsFixed(0)}%',
              Icons.trending_up_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip('All', ClassAssignmentFilter.all),
        _buildFilterChip('Pending', ClassAssignmentFilter.pending),
        _buildFilterChip('Completed', ClassAssignmentFilter.completed),
        _buildFilterChip('Overdue', ClassAssignmentFilter.overdue),
      ],
    );
  }

  Widget _buildAssignmentCard({
    required BuildContext context,
    required String classId,
    required ClassroomAssignment assignment,
    required List<ClassroomSet> sets,
    required StudentAssignmentProgress? progress,
    required ClassroomAssignmentReport? report,
    required bool isTeacher,
  }) {
    final theme = Theme.of(context);
    final status = progress?.status ?? 'not_started';
    final isOverdue =
        assignment.dueAt != null &&
        assignment.dueAt!.isBefore(DateTime.now()) &&
        status != 'completed';

    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.setTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Due ${_formatClassDate(assignment.dueAt)} • ${assignment.setCardCount} cards',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              _buildStatusChip(context, status, isOverdue: isOverdue),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (report != null) ...[
                _buildStatPill(
                  context,
                  '${report.completedCount}/${report.studentCount} done',
                  Icons.group_rounded,
                ),
                _buildStatPill(
                  context,
                  '${(report.completionRate * 100).toStringAsFixed(0)}% completion',
                  Icons.bar_chart_rounded,
                ),
              ] else ...[
                _buildStatPill(
                  context,
                  _statusLabel(status),
                  Icons.person_rounded,
                ),
                if (progress?.score != null)
                  _buildStatPill(
                    context,
                    'Score ${progress!.score!.toStringAsFixed(0)}%',
                    Icons.workspace_premium_rounded,
                  ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _startAssignmentStudy(
                    context,
                    classId,
                    assignment,
                    sets,
                    !isTeacher && status == 'not_started',
                  ),
                  icon: Icon(
                    isTeacher
                        ? Icons.visibility_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(isTeacher ? 'Preview' : 'Study now'),
                ),
              ),
              if (!isTeacher) ...[
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _updateMyProgressStatus(classId, assignment.id, value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'not_started',
                      child: Text('Mark not started'),
                    ),
                    PopupMenuItem(
                      value: 'in_progress',
                      child: Text('Mark in progress'),
                    ),
                    PopupMenuItem(
                      value: 'completed',
                      child: Text('Mark completed'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.more_horiz_rounded),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard({
    required BuildContext context,
    required String classId,
    required ClassroomMember member,
    required ClassroomStudentReport? report,
    required bool isTeacher,
  }) {
    final theme = Theme.of(context);
    final subtitle = report == null
        ? member.studentId
        : 'Completed ${report.completedCount}/${report.assignmentCount} • Avg ${report.averageScore.toStringAsFixed(0)}%';

    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(16),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(member.displayName, style: theme.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: isTeacher ? const Icon(Icons.chevron_right_rounded) : null,
        onTap: isTeacher
            ? () => context.push(
                '/classes/$classId/student/${member.studentId}',
                extra: <String, dynamic>{'studentName': member.displayName},
              )
            : null,
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String trailing,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
        Text(trailing, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.softCardDecoration(
        fillColor: Colors.white.withValues(alpha: 0.82),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.indigo),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildStudentRankingCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<ClassroomStudentReport> reports,
    required String emptyText,
    bool emphasizeRisk = false,
  }) {
    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: emphasizeRisk ? AppTheme.red : AppTheme.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (reports.isEmpty)
            Text(emptyText, style: Theme.of(context).textTheme.bodyMedium)
          else
            ...reports.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(report.studentDisplayName),
                          Text(
                            '${(report.completionRate * 100).toStringAsFixed(0)}% completion',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${report.averageScore.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightColumn(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final displayColor = color ?? AppTheme.indigo;
    return Column(
      children: [
        Icon(icon, color: displayColor),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildStatPill(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.indigo),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    String status, {
    required bool isOverdue,
  }) {
    final color = isOverdue
        ? AppTheme.red
        : switch (status) {
            'completed' => AppTheme.green,
            'in_progress' => AppTheme.orange,
            _ => AppTheme.indigo,
          };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOverdue ? 'Overdue' : _statusLabel(status),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context, String message) {
    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(18),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildFilterChip(String label, ClassAssignmentFilter value) {
    return ChoiceChip(
      label: Text(label),
      selected: _assignmentFilter == value,
      onSelected: (_) => setState(() => _assignmentFilter = value),
    );
  }

  Future<void> _refreshClassData(String classId) async {
    ref.invalidate(classByIdProvider(classId));
    ref.invalidate(classroomSetsProvider(classId));
    ref.invalidate(classAssignmentsProvider(classId));
    ref.invalidate(classMembersProvider(classId));
    ref.invalidate(myClassProgressProvider(classId));
    ref.invalidate(classAssignmentReportsProvider(classId));
    ref.invalidate(classStudentReportsProvider(classId));
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  Future<void> _updateMyProgressStatus(
    String classId,
    String assignmentId,
    String status,
  ) async {
    await ref
        .read(classroomServiceProvider)
        .upsertMyProgress(assignmentId: assignmentId, status: status);
    await _refreshClassData(classId);
  }

  Future<void> _startAssignmentStudy(
    BuildContext context,
    String classId,
    ClassroomAssignment assignment,
    List<ClassroomSet> classSets,
    bool markInProgress,
  ) async {
    ClassroomSet? linkedSet;
    for (final item in classSets) {
      if (item.id == assignment.setId) linkedSet = item;
    }
    if (linkedSet == null) return;
    final localSetId = 'class_${classId}_${linkedSet.id}';
    final cards = linkedSet.cards
        .map(
          (row) => Flashcard(
            id:
                row['id']?.toString() ??
                '${DateTime.now().microsecondsSinceEpoch}',
            term: row['term']?.toString() ?? '',
            definition: row['definition']?.toString() ?? '',
            exampleSentence: row['exampleSentence']?.toString() ?? '',
          ),
        )
        .toList();
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
      await ref
          .read(classroomServiceProvider)
          .upsertMyProgress(assignmentId: assignment.id, status: 'in_progress');
      await _refreshClassData(classId);
    }
    if (context.mounted) context.push('/study/$localSetId');
  }

  Future<void> _showCreateSetDialog(
    BuildContext context,
    String classId,
  ) async {
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
                  labelText: 'Cards',
                  hintText: 'term|definition',
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
              final cards = _parseCards(cardsController.text);
              if (titleController.text.trim().isEmpty || cards.isEmpty) return;
              await ref
                  .read(classroomServiceProvider)
                  .createClassSet(
                    classId: classId,
                    title: titleController.text,
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

  Future<void> _showAssignDialog(
    BuildContext context,
    String classId,
    List<ClassroomSet> classSets,
  ) async {
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
                items: classSets
                    .map(
                      (set) => DropdownMenuItem(
                        value: set.id,
                        child: Text(set.title),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => selectedSetId = value);
                },
                decoration: const InputDecoration(labelText: 'Set'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due date'),
                subtitle: Text(
                  dueAt == null ? 'No due date' : _formatClassDate(dueAt),
                ),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDate:
                        dueAt ?? DateTime.now().add(const Duration(days: 7)),
                  );
                  if (picked != null) {
                    setState(
                      () => dueAt = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        23,
                        59,
                      ),
                    );
                  }
                },
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
                await ref
                    .read(classroomServiceProvider)
                    .createAssignment(
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
      await _refreshClassData(classId);
    }
  }

  Future<void> _showImportDialog(
    BuildContext context,
    String classId,
    List<StudySet> myStudySets,
  ) async {
    if (myStudySets.isEmpty) return;
    String selectedId = myStudySets.first.id;
    final imported = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Import from my study sets'),
          content: DropdownButtonFormField<String>(
            value: selectedId,
            items: myStudySets
                .map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.title)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => selectedId = value);
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
                final set = myStudySets.firstWhere(
                  (item) => item.id == selectedId,
                );
                await ref
                    .read(classroomServiceProvider)
                    .createClassSet(
                      classId: classId,
                      title: set.title,
                      description: set.description,
                      cards: set.cards
                          .map(
                            (card) => <String, dynamic>{
                              'id': card.id,
                              'term': card.term,
                              'definition': card.definition,
                              'exampleSentence': card.exampleSentence,
                            },
                          )
                          .toList(),
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
}
