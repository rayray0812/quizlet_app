import 'package:flutter/material.dart';

enum QuizOptionState { normal, correct, incorrect }

class QuizOptionTile extends StatelessWidget {
  final String text;
  final QuizOptionState state;
  final VoidCallback? onTap;

  const QuizOptionTile({
    super.key,
    required this.text,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (state) {
      case QuizOptionState.correct:
        bgColor = Colors.green.shade50;
        borderColor = Colors.green;
        textColor = Colors.green.shade800;
      case QuizOptionState.incorrect:
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
        textColor = Colors.red.shade800;
      case QuizOptionState.normal:
        bgColor = Theme.of(context).colorScheme.surface;
        borderColor = Theme.of(context).colorScheme.outline;
        textColor = Theme.of(context).colorScheme.onSurface;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (state == QuizOptionState.correct)
                  const Icon(Icons.check_circle, color: Colors.green),
                if (state == QuizOptionState.incorrect)
                  const Icon(Icons.cancel, color: Colors.red),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
