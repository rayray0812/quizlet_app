import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
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
        onTap: () {
          setState(() => _pressed = false);
          context.push('/revenge');
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            decoration: AppTheme.softCardDecoration(
              fillColor: Colors.white,
              borderRadius: 14,
              borderColor: AppTheme.purple.withValues(alpha: 0.25),
              elevation: _pressed ? 0.8 : 1.1,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.purple.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.replay_rounded,
                      color: AppTheme.purple,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.revengeMode,
                          style: GoogleFonts.notoSerifTc(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.revengeCount(count),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      context.push('/review', extra: {'revengeCardIds': cardIds});
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    child: Text(l10n.play),
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
