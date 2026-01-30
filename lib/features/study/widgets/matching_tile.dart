import 'package:flutter/material.dart';

enum MatchingTileState { normal, selected, matched, incorrect }

class MatchingTile extends StatelessWidget {
  final String text;
  final MatchingTileState state;
  final VoidCallback? onTap;

  const MatchingTile({
    super.key,
    required this.text,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    double opacity;

    switch (state) {
      case MatchingTileState.selected:
        bgColor = Theme.of(context).colorScheme.primaryContainer;
        borderColor = Theme.of(context).colorScheme.primary;
        opacity = 1.0;
      case MatchingTileState.matched:
        bgColor = Colors.green.shade100;
        borderColor = Colors.green;
        opacity = 0.6;
      case MatchingTileState.incorrect:
        bgColor = Colors.red.shade100;
        borderColor = Colors.red;
        opacity = 1.0;
      case MatchingTileState.normal:
        bgColor = Theme.of(context).colorScheme.surface;
        borderColor = Theme.of(context).colorScheme.outlineVariant;
        opacity = 1.0;
    }

    return Opacity(
      opacity: opacity,
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: 2),
        ),
        child: InkWell(
          onTap: state == MatchingTileState.matched ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
