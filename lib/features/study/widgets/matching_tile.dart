import 'package:flutter/material.dart';
import 'package:recall_app/core/theme/app_theme.dart';

enum MatchingTileState { normal, selected, matched, incorrect }

class MatchingTile extends StatefulWidget {
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
  State<MatchingTile> createState() => _MatchingTileState();
}

class _MatchingTileState extends State<MatchingTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    double opacity;

    switch (widget.state) {
      case MatchingTileState.selected:
        bgColor = AppTheme.indigo.withValues(alpha: 0.08);
        borderColor = AppTheme.indigo;
        opacity = 1.0;
      case MatchingTileState.matched:
        bgColor = AppTheme.green.withValues(alpha: 0.1);
        borderColor = AppTheme.green;
        opacity = 0.5;
      case MatchingTileState.incorrect:
        bgColor = AppTheme.red.withValues(alpha: 0.08);
        borderColor = AppTheme.red;
        opacity = 1.0;
      case MatchingTileState.normal:
        bgColor = Theme.of(context).cardColor;
        borderColor = Colors.grey.shade200;
        opacity = 1.0;
    }

    final canTap = widget.state != MatchingTileState.matched && widget.onTap != null;

    return GestureDetector(
      onTapDown: canTap ? (_) => setState(() => _pressed = true) : null,
      onTapUp: canTap
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: canTap ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 300),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: widget.state == MatchingTileState.normal ? 1.5 : 2,
              ),
              boxShadow: widget.state == MatchingTileState.normal
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
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

