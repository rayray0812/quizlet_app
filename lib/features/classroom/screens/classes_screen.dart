import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';
import 'package:recall_app/models/classroom.dart';
import 'package:recall_app/providers/classroom_provider.dart';

enum _ClassListFilter { all, active, archived }

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});

  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _ClassListFilter _listFilter = _ClassListFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim().toLowerCase();
      if (next != _query) {
        setState(() => _query = next);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(myRoleProvider);
    final classesAsync = ref.watch(myClassesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('教室')),
      body: classesAsync.when(
        data: (items) {
          final role = roleAsync.valueOrNull ?? 'student';
          final visible = _filterClasses(items);
          final archivedCount = items.where((item) => item.isArchived).length;
          final activeCount = items.length - archivedCount;
          final activeVisible = visible.where((item) => !item.isArchived).toList();
          final archivedVisible = visible.where((item) => item.isArchived).toList();

          return RefreshIndicator(
            onRefresh: _refreshAll,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _HeroPanel(
                  role: role,
                  totalCount: items.length,
                  activeCount: activeCount,
                  archivedCount: archivedCount,
                  onRoleChanged: (value) async {
                    await ref.read(classroomServiceProvider).updateMyRole(value);
                    ref.invalidate(myRoleProvider);
                    ref.invalidate(myClassesProvider);
                  },
                  onPrimaryAction: () {
                    if (role == 'teacher') {
                      _showCreateClassDialog(context, ref);
                    } else {
                      _showJoinClassDialog(context, ref);
                    }
                  },
                  onSecondaryAction: () {
                    if (role == 'teacher') {
                      _showJoinClassDialog(context, ref);
                    } else {
                      _searchController.clear();
                    }
                  },
                ),
                const SizedBox(height: 16),
                AdaptiveGlassCard(
                  borderRadius: 24,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role == 'teacher' ? '你的教學空間' : '你的學習教室',
                        style: GoogleFonts.notoSerifTc(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        role == 'teacher'
                            ? '建立班級、整理教材、追蹤學生進度。'
                            : '加入班級、查看作業、快速回到你的學習入口。',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded),
                          hintText: role == 'teacher'
                              ? '搜尋班級名稱、科目或年級'
                              : '搜尋已加入的班級',
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: _searchController.clear,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _QuickStatsRow(
                  role: role,
                  totalCount: items.length,
                  activeCount: activeCount,
                  filteredCount: visible.length,
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ListFilterChip(
                        label: '全部',
                        selected: _listFilter == _ClassListFilter.all,
                        onTap: () => setState(() => _listFilter = _ClassListFilter.all),
                      ),
                      _ListFilterChip(
                        label: '啟用中',
                        selected: _listFilter == _ClassListFilter.active,
                        onTap: () => setState(() => _listFilter = _ClassListFilter.active),
                      ),
                      _ListFilterChip(
                        label: '已封存',
                        selected: _listFilter == _ClassListFilter.archived,
                        onTap: () => setState(() => _listFilter = _ClassListFilter.archived),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      role == 'teacher' ? '班級列表' : '已加入的班級',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (_query.isNotEmpty)
                      Text(
                        '${visible.length} 筆結果',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  _EmptyClassesState(
                    role: role,
                    onPrimaryAction: () {
                      if (role == 'teacher') {
                        _showCreateClassDialog(context, ref);
                      } else {
                        _showJoinClassDialog(context, ref);
                      }
                    },
                  )
                else if (visible.isEmpty)
                  _SearchEmptyState(
                    query: _searchController.text.trim(),
                    onClear: _searchController.clear,
                  )
                else ...[
                  if (_listFilter != _ClassListFilter.archived && activeVisible.isNotEmpty) ...[
                    _ListSectionHeader(
                      title: '啟用中的班級',
                      subtitle: role == 'teacher' ? '目前持續使用的教學班級。' : '你現在正在參與的學習空間。',
                    ),
                    const SizedBox(height: 10),
                    ...activeVisible.map(
                      (classroom) => _ClassCard(item: classroom, role: role),
                    ),
                  ],
                  if (_listFilter == _ClassListFilter.all &&
                      activeVisible.isNotEmpty &&
                      archivedVisible.isNotEmpty)
                    const SizedBox(height: 8),
                  if (_listFilter != _ClassListFilter.active && archivedVisible.isNotEmpty) ...[
                    _ListSectionHeader(
                      title: '已封存的班級',
                      subtitle: role == 'teacher' ? '保留紀錄但暫停使用的班級。' : '這些班級目前不再開放新的學習活動。',
                    ),
                    const SizedBox(height: 10),
                    ...archivedVisible.map(
                      (classroom) => _ClassCard(item: classroom, role: role),
                    ),
                  ],
                  if (_listFilter == _ClassListFilter.active && activeVisible.isEmpty)
                    const _SimpleListEmpty(
                      title: '沒有啟用中的班級',
                      message: '目前沒有符合條件的班級。',
                    ),
                  if (_listFilter == _ClassListFilter.archived && archivedVisible.isEmpty)
                    const _SimpleListEmpty(
                      title: '沒有已封存的班級',
                      message: '目前沒有符合條件的班級。',
                    ),
                ],
              ],
            ),
          );
        },
        error: (err, _) => Center(child: Text('載入教室失敗：$err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  List<Classroom> _filterClasses(List<Classroom> items) {
    final queryFiltered = _query.isEmpty
        ? items
        : items.where((item) {
      final haystack = [item.name, item.subject, item.grade, item.inviteCode]
          .join(' ')
          .toLowerCase();
      return haystack.contains(_query);
    }).toList();
    switch (_listFilter) {
      case _ClassListFilter.active:
        return queryFiltered.where((item) => !item.isArchived).toList();
      case _ClassListFilter.archived:
        return queryFiltered.where((item) => item.isArchived).toList();
      case _ClassListFilter.all:
        return queryFiltered;
    }
  }

  Future<void> _refreshAll() async {
    ref.invalidate(myRoleProvider);
    ref.invalidate(myClassesProvider);
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  Future<void> _showCreateClassDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final subjectController = TextEditingController();
    final gradeController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('建立班級'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '班級名稱'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: '科目'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: gradeController,
                decoration: const InputDecoration(labelText: '年級'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                await ref.read(classroomServiceProvider).createClass(
                      name: nameController.text,
                      subject: subjectController.text,
                      grade: gradeController.text,
                    );
                if (context.mounted) Navigator.of(context).pop(true);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('建立班級失敗：$e')),
                );
              }
            },
            child: const Text('建立'),
          ),
        ],
      ),
    );

    nameController.dispose();
    subjectController.dispose();
    gradeController.dispose();
    if (created == true) {
      ref.invalidate(myClassesProvider);
    }
  }

  Future<void> _showJoinClassDialog(BuildContext context, WidgetRef ref) async {
    final codeController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final joined = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加入班級'),
        content: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: '邀請碼',
            hintText: '例如：A1B2C3D4',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref
                    .read(classroomServiceProvider)
                    .joinClassByInviteCode(codeController.text);
                if (context.mounted) Navigator.of(context).pop(true);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('加入班級失敗：$e')),
                );
              }
            },
            child: const Text('加入'),
          ),
        ],
      ),
    );
    codeController.dispose();
    if (joined == true) {
      ref.invalidate(myClassesProvider);
    }
  }
}

class _HeroPanel extends StatelessWidget {
  final String role;
  final int totalCount;
  final int activeCount;
  final int archivedCount;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;

  const _HeroPanel({
    required this.role,
    required this.totalCount,
    required this.activeCount,
    required this.archivedCount,
    required this.onRoleChanged,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.indigo.withValues(alpha: 0.18),
            AppTheme.cyan.withValues(alpha: 0.18),
            AppTheme.gold.withValues(alpha: 0.24),
          ],
        ),
      ),
      child: AdaptiveGlassCard(
        borderRadius: 28,
        fillColor: Colors.white.withValues(alpha: 0.44),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    role == 'teacher'
                        ? Icons.co_present_rounded
                        : Icons.auto_stories_rounded,
                    color: AppTheme.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role == 'teacher' ? '老師控制台' : '學生教室',
                        style: GoogleFonts.notoSerifTc(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role == 'teacher'
                            ? '集中管理班級、教材與學生進度'
                            : '快速掌握你加入的班級與學習入口',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'teacher',
                  icon: Icon(Icons.school_rounded, size: 16),
                  label: Text('老師'),
                ),
                ButtonSegment<String>(
                  value: 'student',
                  icon: Icon(Icons.person_rounded, size: 16),
                  label: Text('學生'),
                ),
              ],
              selected: {role},
              onSelectionChanged: (value) => onRoleChanged(value.first),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TinyMetric(label: '總數', value: '$totalCount'),
                _TinyMetric(label: '啟用', value: '$activeCount'),
                _TinyMetric(label: '封存', value: '$archivedCount'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onPrimaryAction,
                    icon: Icon(
                      role == 'teacher'
                          ? Icons.add_circle_outline_rounded
                          : Icons.input_rounded,
                    ),
                    label: Text(role == 'teacher' ? '建立班級' : '加入班級'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSecondaryAction,
                    icon: Icon(
                      role == 'teacher'
                          ? Icons.group_add_rounded
                          : Icons.cleaning_services_outlined,
                    ),
                    label: Text(role == 'teacher' ? '測試加入流程' : '清除搜尋'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TinyMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final String role;
  final int totalCount;
  final int activeCount;
  final int filteredCount;

  const _QuickStatsRow({
    required this.role,
    required this.totalCount,
    required this.activeCount,
    required this.filteredCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoPill(
            icon: role == 'teacher'
                ? Icons.space_dashboard_rounded
                : Icons.menu_book_rounded,
            label: role == 'teacher' ? '教學中' : '已加入',
            value: '$totalCount',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoPill(
            icon: Icons.bolt_rounded,
            label: '啟用中',
            value: '$activeCount',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoPill(
            icon: Icons.filter_alt_rounded,
            label: '目前顯示',
            value: '$filteredCount',
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveGlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final Classroom item;
  final String role;

  const _ClassCard({required this.item, required this.role});

  @override
  Widget build(BuildContext context) {
    final subtitle = [item.subject, item.grade]
        .where((s) => s.trim().isNotEmpty)
        .join(' · ');
    return AdaptiveGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: InkWell(
        onTap: () => context.push('/classes/${item.id}'),
        borderRadius: BorderRadius.circular(22),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.orange.withValues(alpha: 0.26),
                    AppTheme.indigo.withValues(alpha: 0.20),
                  ],
                ),
              ),
              child: Icon(
                role == 'teacher'
                    ? Icons.cast_for_education_rounded
                    : Icons.collections_bookmark_rounded,
                color: AppTheme.green,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (item.isArchived)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '已封存',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.red),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle.isEmpty ? '尚未設定科目或年級' : subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CardTag(icon: Icons.key_rounded, label: item.inviteCode),
                      _CardTag(
                        icon: Icons.schedule_rounded,
                        label: '更新於 ${item.updatedAt.toLocal().toString().split(' ').first}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _CardTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CardTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.green),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ListFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ListFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ListSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ListSectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SimpleListEmpty extends StatelessWidget {
  final String title;
  final String message;

  const _SimpleListEmpty({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveGlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(message),
        ],
      ),
    );
  }
}

class _EmptyClassesState extends StatelessWidget {
  final String role;
  final VoidCallback onPrimaryAction;

  const _EmptyClassesState({required this.role, required this.onPrimaryAction});

  @override
  Widget build(BuildContext context) {
    return AdaptiveGlassCard(
      borderRadius: 28,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.gold.withValues(alpha: 0.46),
            ),
            child: Icon(
              role == 'teacher' ? Icons.school_rounded : Icons.meeting_room_rounded,
              size: 36,
              color: AppTheme.green,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            role == 'teacher' ? '還沒有建立任何班級' : '你還沒有加入任何班級',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            role == 'teacher'
                ? '先開一個教室，之後就能匯入教材、派發作業、追蹤學生進度。'
                : '輸入老師提供的邀請碼，就能看到教材與作業安排。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onPrimaryAction,
            icon: Icon(
              role == 'teacher'
                  ? Icons.add_circle_outline_rounded
                  : Icons.group_add_rounded,
            ),
            label: Text(role == 'teacher' ? '建立第一個班級' : '加入班級'),
          ),
        ],
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _SearchEmptyState({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return AdaptiveGlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 34),
          const SizedBox(height: 10),
          Text(
            '找不到和 "$query" 有關的班級',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '試試看班級名稱、科目、年級或邀請碼。',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('清除搜尋'),
          ),
        ],
      ),
    );
  }
}
