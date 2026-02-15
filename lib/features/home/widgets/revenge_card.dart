import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/providers/revenge_provider.dart';

class RevengeCard extends ConsumerStatefulWidget {
  const RevengeCard({super.key});

  @override
  ConsumerState<RevengeCard> createState() => _RevengeCardState();
}

class _RevengeCardState extends ConsumerState<RevengeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cardIds = ref.watch(revengeCardIdsProvider);
    final count = cardIds.length;
    final l10n = AppLocalizations.of(context);

    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          context.push(
            '/review',
            extra: {'revengeCardIds': cardIds},
          );
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.withValues(alpha: 0.88),
                  Colors.indigo.withValues(alpha: 0.82),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withValues(alpha: _pressed ? 0.09 : 0.18),
                  blurRadius: _pressed ? 6 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.replay_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.revengeMode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.revengeCount(count),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      context.push(
                        '/review',
                        extra: {'revengeCardIds': cardIds},
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(l10n.play),
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
