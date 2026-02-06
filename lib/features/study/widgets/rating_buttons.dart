import 'package:flutter/material.dart';
import 'package:quizlet_app/core/theme/app_theme.dart';

/// Four rating buttons: Again / Hard / Good / Easy with predicted intervals.
class RatingButtons extends StatelessWidget {
  final Map<int, String> intervals; // rating (1-4) -> interval string
  final void Function(int rating) onRating;

  const RatingButtons({
    super.key,
    required this.intervals,
    required this.onRating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RatingButton(
          label: 'Again',
          interval: intervals[1] ?? '',
          color: AppTheme.red,
          onTap: () => onRating(1),
        ),
        const SizedBox(width: 8),
        _RatingButton(
          label: 'Hard',
          interval: intervals[2] ?? '',
          color: AppTheme.orange,
          onTap: () => onRating(2),
        ),
        const SizedBox(width: 8),
        _RatingButton(
          label: 'Good',
          interval: intervals[3] ?? '',
          color: AppTheme.green,
          onTap: () => onRating(3),
        ),
        const SizedBox(width: 8),
        _RatingButton(
          label: 'Easy',
          interval: intervals[4] ?? '',
          color: AppTheme.indigo,
          onTap: () => onRating(4),
        ),
      ],
    );
  }
}

class _RatingButton extends StatefulWidget {
  final String label;
  final String interval;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.interval,
    required this.color,
    required this.onTap,
  });

  @override
  State<_RatingButton> createState() => _RatingButtonState();
}

class _RatingButtonState extends State<_RatingButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.color.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.interval,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
