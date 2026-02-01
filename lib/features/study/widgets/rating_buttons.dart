import 'package:flutter/material.dart';

/// Four rating buttons: Again / Hard / Good / Easy with predicted intervals.
class RatingButtons extends StatelessWidget {
  final Map<int, String> intervals; // rating (1-4) → interval string
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
          color: Colors.red,
          onTap: () => onRating(1),
        ),
        const SizedBox(width: 8),
        _RatingButton(
          label: 'Hard',
          interval: intervals[2] ?? '',
          color: Colors.orange,
          onTap: () => onRating(2),
        ),
        const SizedBox(width: 8),
        _RatingButton(
          label: 'Good',
          interval: intervals[3] ?? '',
          color: Colors.green,
          onTap: () => onRating(3),
        ),
        const SizedBox(width: 8),
        _RatingButton(
          label: 'Easy',
          interval: intervals[4] ?? '',
          color: Colors.blue,
          onTap: () => onRating(4),
        ),
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  interval,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
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
