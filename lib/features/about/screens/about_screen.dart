import 'package:flutter/material.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.aboutApp),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
        children: [
          // -- Hero --
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 40,
                color: AppTheme.indigo,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              AppConstants.appName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'v${AppConstants.appVersion}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.aboutTagline,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ),
          ),

          const SizedBox(height: 36),

          // -- SRS Section --
          _FeatureSection(
            icon: Icons.psychology_rounded,
            iconColor: AppTheme.purple,
            title: l10n.aboutSrsTitle,
            paragraphs: [
              l10n.aboutSrsP1,
              l10n.aboutSrsP2,
            ],
            highlight: l10n.aboutSrsHighlight,
          ),

          const SizedBox(height: 28),

          // -- Quiz Section --
          _FeatureSection(
            icon: Icons.quiz_rounded,
            iconColor: AppTheme.orange,
            title: l10n.aboutQuizTitle,
            paragraphs: [
              l10n.aboutQuizP1,
              l10n.aboutQuizP2,
            ],
            highlight: l10n.aboutQuizHighlight,
          ),

          const SizedBox(height: 28),

          // -- More Features --
          _FeatureSection(
            icon: Icons.star_rounded,
            iconColor: AppTheme.cyan,
            title: l10n.aboutMoreTitle,
            paragraphs: [
              l10n.aboutMoreP1,
            ],
          ),

          const SizedBox(height: 28),

          // -- Feature chips grid --
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _MiniFeatureChip(
                icon: Icons.repeat_rounded,
                label: l10n.aboutChipSrs,
                color: AppTheme.purple,
              ),
              _MiniFeatureChip(
                icon: Icons.edit_rounded,
                label: l10n.aboutChipQuiz,
                color: AppTheme.orange,
              ),
              _MiniFeatureChip(
                icon: Icons.grid_view_rounded,
                label: l10n.aboutChipMatch,
                color: AppTheme.indigo,
              ),
              _MiniFeatureChip(
                icon: Icons.camera_alt_rounded,
                label: l10n.aboutChipPhoto,
                color: AppTheme.cyan,
              ),
              _MiniFeatureChip(
                icon: Icons.local_fire_department_rounded,
                label: l10n.aboutChipDaily,
                color: AppTheme.red,
              ),
              _MiniFeatureChip(
                icon: Icons.record_voice_over_rounded,
                label: l10n.aboutChipSpeak,
                color: AppTheme.green,
              ),
            ],
          ),

          const SizedBox(height: 36),

          // -- References --
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.softCardDecoration(
              fillColor: Colors.white,
              borderRadius: 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.aboutReferences,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _RefItem(text: l10n.aboutRef1),
                const SizedBox(height: 6),
                _RefItem(text: l10n.aboutRef2),
                const SizedBox(height: 6),
                _RefItem(text: l10n.aboutRef3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> paragraphs;
  final String? highlight;

  const _FeatureSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.paragraphs,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.softCardDecoration(
        fillColor: Colors.white,
        borderRadius: 16,
        borderColor: iconColor.withValues(alpha: 0.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final p in paragraphs) ...[
            Text(
              p,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.7,
                fontSize: 14,
              ),
            ),
            if (p != paragraphs.last) const SizedBox(height: 12),
          ],
          if (highlight != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                highlight!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniFeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniFeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefItem extends StatelessWidget {
  final String text;
  const _RefItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.circle,
            size: 5,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
