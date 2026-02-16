import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';

/// Four rating buttons: Again / Hard / Good / Easy with predicted intervals.
class RatingButtons extends StatelessWidget {
  final Map<int, String> intervals; // rating (1-4) -> interval string
  final void Function(int rating) onRating;
  final bool enabled;

  const RatingButtons({
    super.key,
    required this.intervals,
    required this.onRating,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _RatingButton(
          icon: Icons.replay_rounded,
          label: l10n.ratingAgain,
          interval: intervals[1] ?? '',
          color: AppTheme.red,
          enabled: enabled,
          onTap: () => onRating(1),
        ),
        const SizedBox(width: 8),
        _RatingButton(
          icon: Icons.sentiment_dissatisfied_rounded,
          label: l10n.ratingHard,
          interval: intervals[2] ?? '',
          color: AppTheme.orange,
          enabled: enabled,
          onTap: () => onRating(2),
        ),
        const SizedBox(width: 8),
        _RatingButton(
          icon: Icons.sentiment_satisfied_rounded,
          label: l10n.ratingGood,
          interval: intervals[3] ?? '',
          color: AppTheme.green,
          enabled: enabled,
          onTap: () => onRating(3),
        ),
        const SizedBox(width: 8),
        _RatingButton(
          icon: Icons.sentiment_very_satisfied_rounded,
          label: l10n.ratingEasy,
          interval: intervals[4] ?? '',
          color: AppTheme.indigo,
          enabled: enabled,
          onTap: () => onRating(4),
        ),
      ],
    );
  }
}

class _RatingButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String interval;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _RatingButton({
    required this.icon,
    required this.label,
    required this.interval,
    required this.color,
    required this.onTap,
    required this.enabled,
  });

  @override
  State<_RatingButton> createState() => _RatingButtonState();
}

class _RatingButtonState extends State<_RatingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _springController;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController.unbounded(
      vsync: this,
      value: 1,
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _runSpringDown() {
    _springController.value = 1;
    _springController.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 180, damping: 12),
        1,
        0.93,
        0,
      ),
    );
  }

  void _runSpringUp() {
    _springController.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 180, damping: 12),
        _springController.value,
        1,
        0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) {
                HapticFeedback.selectionClick();
                _runSpringDown();
              }
            : null,
        onTap: widget.enabled
            ? () {
                HapticFeedback.lightImpact();
                _runSpringUp();
                widget.onTap();
              }
            : null,
        onTapCancel: widget.enabled
            ? _runSpringUp
            : null,
        child: ScaleTransition(
          scale: _springController,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: widget.enabled ? 1 : 0.45,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.color.withValues(alpha: 0.34),
                        ),
                      ),
                      child: Center(
                        child: Icon(widget.icon, color: widget.color, size: 27),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: widget.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.interval,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.color.withValues(alpha: 0.84),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
