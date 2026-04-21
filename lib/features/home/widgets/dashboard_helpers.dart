import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';
import 'package:recall_app/core/widgets/glass_press_effect.dart';
import 'package:recall_app/models/sync_conflict.dart';
import 'package:recall_app/providers/tts_engine_provider.dart';

class HomeSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const HomeSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.indigo.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class HomeQuickActionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;

  const HomeQuickActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });

  @override
  State<HomeQuickActionTile> createState() => _HomeQuickActionTileState();
}

class _HomeQuickActionTileState extends State<HomeQuickActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _pressed = true);
      },
      onTap: () {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: AppTheme.softCardDecoration(
            fillColor: Colors.white,
            borderRadius: 14,
            borderColor: widget.tint.withValues(alpha: 0.22),
            elevation: _pressed ? 0.8 : 1.1,
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.tint, size: 22),
              ),
              const Spacer(),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color tint;

  const TaskMetric({
    super.key,
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tint,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

Widget serifSettingTitle(BuildContext context, String text) {
  return Text(
    text,
    style: GoogleFonts.notoSerifTc(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

class HomeAmbientGlow extends StatelessWidget {
  const HomeAmbientGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 24,
            child: GlowOrb(
              size: 160,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            top: 28,
            right: -18,
            child: GlowOrb(
              size: 220,
              color: AppTheme.cyan.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 148,
            left: -44,
            child: GlowOrb(
              size: 180,
              color: AppTheme.indigo.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class BackdropAccents extends StatelessWidget {
  const BackdropAccents({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          const Positioned.fill(child: DiagonalLightVeil()),
          Positioned(
            top: -68,
            right: -56,
            child: GlowOrb(
              size: 280,
              color: Colors.white.withValues(alpha: 0.24),
            ),
          ),
          Positioned(
            top: 120,
            left: -72,
            child: GlowOrb(
              size: 240,
              color: AppTheme.cyan.withValues(alpha: 0.13),
            ),
          ),
          Positioned(
            bottom: -80,
            right: 10,
            child: GlowOrb(
              size: 220,
              color: AppTheme.indigo.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class DiagonalLightVeil extends StatelessWidget {
  const DiagonalLightVeil({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -60,
          child: Transform.rotate(
            angle: -0.32,
            child: Container(
              width: 360,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          right: -80,
          child: Transform.rotate(
            angle: -0.28,
            child: Container(
              width: 340,
              height: 170,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.cyan.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const GlowOrb({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.02),
            Colors.transparent,
          ],
          stops: const [0.0, 0.62, 1.0],
        ),
      ),
    );
  }
}

class SheetItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const SheetItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPressEffect(
      borderRadius: 12,
      pressedOpacity: 0.13,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: Icon(
          CupertinoIcons.chevron_right,
          color: Colors.grey.shade400,
          size: 18,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}

class ConflictRow extends StatelessWidget {
  final SyncConflict conflict;
  final Future<void> Function() onKeepLocal;
  final Future<void> Function() onKeepRemote;
  final Future<void> Function() onMerge;

  const ConflictRow({
    super.key,
    required this.conflict,
    required this.onKeepLocal,
    required this.onKeepRemote,
    required this.onMerge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          conflict.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Local: ${conflict.localUpdatedAt.toLocal()}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          'Remote: ${conflict.remoteUpdatedAt.toLocal()}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => onKeepLocal(),
              child: const Text('Keep Local'),
            ),
            OutlinedButton(
              onPressed: () => onKeepRemote(),
              child: const Text('Keep Remote'),
            ),
            ElevatedButton(
              onPressed: () => onMerge(),
              child: const Text('Merge'),
            ),
          ],
        ),
      ],
    );
  }
}

class AdaptiveSettingsCard extends StatelessWidget {
  final Widget child;

  const AdaptiveSettingsCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AdaptiveGlassCard(
      borderRadius: 22,
      fillColor: Colors.white.withValues(alpha: 0.82),
      borderColor: Colors.white.withValues(alpha: 0.38),
      elevation: 2.0,
      child: child,
    );
  }
}

class SettingsGroupTitle extends StatelessWidget {
  final String title;

  const SettingsGroupTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}

class StaggeredFadeItem extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggeredFadeItem({super.key, required this.index, required this.child});

  @override
  State<StaggeredFadeItem> createState() => _StaggeredFadeItemState();
}

class _StaggeredFadeItemState extends State<StaggeredFadeItem> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 60 * (widget.index.clamp(0, 6)));
    Future.delayed(delay, () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutQuart,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutQuart,
        offset: _visible ? Offset.zero : const Offset(0, 0.04),
        child: widget.child,
      ),
    );
  }
}

class TtsEnginePicker extends ConsumerWidget {
  const TtsEnginePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(ttsEngineProvider);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ttsEngine,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        _ttsOption(context, ref, TtsEngine.cloudTts, engine, l10n.ttsCloudTts, l10n.ttsCloudTtsDesc),
        _ttsOption(context, ref, TtsEngine.geminiTts, engine, l10n.ttsGeminiTts, l10n.ttsGeminiTtsDesc),
        _ttsOption(context, ref, TtsEngine.deviceTts, engine, l10n.ttsDeviceTts, l10n.ttsDeviceTtsDesc),
      ],
    );
  }

  Widget _ttsOption(
    BuildContext context,
    WidgetRef ref,
    TtsEngine value,
    TtsEngine current,
    String title,
    String subtitle,
  ) {
    return RadioListTile<TtsEngine>(
      value: value,
      groupValue: current,
      onChanged: (v) {
        if (v != null) ref.read(ttsEngineProvider.notifier).setEngine(v);
      },
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      dense: true,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

