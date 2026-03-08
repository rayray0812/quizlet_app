import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';
import 'package:recall_app/models/classroom.dart';
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
      appBar: AppBar(title: Text(studentName)),
      body: detailsAsync.when(
        data: (items) {
          final assignmentCount = items.length;
          final completedCount = items.where((e) => e.status == 'completed').length;
          final inProgressCount = items.where((e) => e.status == 'in_progress').length;
          final notStartedCount = items.where((e) => e.status == 'not_started').length;
          final scored = items.where((e) => e.score != null).toList();
          final averageScore = scored.isEmpty
              ? 0.0
              : scored.map((e) => e.score!).reduce((a, b) => a + b) / scored.length;

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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                AdaptiveGlassCard(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.48),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            studentName.isEmpty ? '?' : studentName.characters.first,
                            style: GoogleFonts.notoSerifTc(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.green,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(studentName, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text('共 $assignmentCount 份作業 · 平均分數 ${averageScore.toStringAsFixed(1)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _Metric(label: '已完成', value: '$completedCount', icon: Icons.check_circle_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _Metric(label: '進行中', value: '$inProgressCount', icon: Icons.timelapse_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _Metric(label: '未開始', value: '$notStartedCount', icon: Icons.hourglass_empty_rounded)),
                  ],
                ),
                const SizedBox(height: 18),
                Text('作業紀錄', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  const _EmptyState()
                else
                  ...items.map((item) {
                    final statusLabel = item.status == 'completed'
                        ? '已完成'
                        : item.status == 'in_progress'
                            ? '進行中'
                            : '未開始';
                    return AdaptiveGlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      borderRadius: 22,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.assignmentTitle, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text('狀態：$statusLabel'),
                          const SizedBox(height: 4),
                          Text('截止：${item.dueAt?.toLocal().toString().split(' ').first ?? '未設定'}'),
                          const SizedBox(height: 4),
                          Text('分數：${item.score?.toStringAsFixed(1) ?? '尚無'}'),
                          const SizedBox(height: 4),
                          Text('發布狀態：${item.isPublished ? '已發布' : '草稿'}'),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
        error: (e, _) => Center(child: Text('載入學生資料失敗：$e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Metric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return AdaptiveGlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.green),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return AdaptiveGlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.assignment_late_outlined, size: 34),
          const SizedBox(height: 10),
          Text('沒有可顯示的作業紀錄', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('這位學生目前還沒有任何可顯示的學習資料。', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
