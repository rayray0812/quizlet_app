import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizlet_app/models/flashcard.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/features/study/widgets/matching_tile.dart';
import 'package:quizlet_app/features/study/widgets/rounded_progress_bar.dart';
import 'package:quizlet_app/features/study/widgets/study_result_widgets.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';
import 'package:quizlet_app/core/theme/app_theme.dart';

class MatchingGameScreen extends ConsumerStatefulWidget {
  final String setId;
  final int? pairCount;

  const MatchingGameScreen({super.key, required this.setId, this.pairCount});

  @override
  ConsumerState<MatchingGameScreen> createState() => _MatchingGameScreenState();
}

class _MatchingGameScreenState extends ConsumerState<MatchingGameScreen> {
  late List<Flashcard> _gameCards;
  late List<_TileItem> _tiles;
  int? _selectedIndex;
  final Set<String> _matchedCardIds = {};
  final Set<int> _incorrectIndices = {};
  final Stopwatch _stopwatch = Stopwatch();
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  void _initGame() {
    final studySet = ref.read(studySetsProvider.notifier).getById(widget.setId);
    if (studySet == null) return;

    final maxPairs = widget.pairCount ?? 6;
    final cards = List.of(studySet.cards)..shuffle(Random());
    _gameCards = cards.take(min(maxPairs, cards.length)).toList();

    _tiles = [];
    for (final card in _gameCards) {
      _tiles.add(_TileItem(cardId: card.id, text: card.term, isTerm: true));
      _tiles.add(
        _TileItem(cardId: card.id, text: card.definition, isTerm: false),
      );
    }
    _tiles.shuffle(Random());

    _selectedIndex = null;
    _matchedCardIds.clear();
    _incorrectIndices.clear();
    _attempts = 0;
    _stopwatch
      ..reset()
      ..start();
  }

  void _onTileTap(int index) {
    if (_matchedCardIds.contains(_tiles[index].cardId)) return;
    if (_incorrectIndices.isNotEmpty) return;

    if (_selectedIndex == null) {
      setState(() => _selectedIndex = index);
      return;
    }

    if (_selectedIndex == index) {
      setState(() => _selectedIndex = null);
      return;
    }

    final first = _tiles[_selectedIndex!];
    final second = _tiles[index];
    _attempts++;

    if (first.cardId == second.cardId && first.isTerm != second.isTerm) {
      setState(() {
        _matchedCardIds.add(first.cardId);
        _selectedIndex = null;
      });

      if (_matchedCardIds.length == _gameCards.length) {
        _stopwatch.stop();
        _showResults();
      }
    } else {
      setState(() {
        _incorrectIndices.addAll([_selectedIndex!, index]);
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _incorrectIndices.clear();
          _selectedIndex = null;
        });
      });
    }
  }

  void _showResults() {
    final l10n = AppLocalizations.of(context);
    final seconds = _stopwatch.elapsed.inSeconds;
    final efficiency = _gameCards.isEmpty
        ? 0
        : (_gameCards.length * 2 / _attempts);
    final accent = efficiency >= 0.75 ? AppTheme.green : AppTheme.gold;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StudyResultHeader(
              accentColor: accent,
              icon: Icons.extension_rounded,
              title: l10n.gameComplete,
              primaryText: l10n.timeSeconds(seconds),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StudyResultChip(
                  label: 'Pairs',
                  value: '${_gameCards.length}',
                  color: AppTheme.indigo,
                  icon: Icons.grid_view_rounded,
                ),
                StudyResultChip(
                  label: 'Attempts',
                  value: '$_attempts',
                  color: AppTheme.orange,
                  icon: Icons.touch_app_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            StudyResultDialogActions(
              leftLabel: l10n.playAgain,
              rightLabel: l10n.done,
              onLeft: () {
                Navigator.pop(context);
                setState(() => _initGame());
              },
              onRight: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _goHomeSmooth() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final studySet = ref
        .watch(studySetsProvider)
        .where((s) => s.id == widget.setId)
        .firstOrNull;
    final l10n = AppLocalizations.of(context);

    if (studySet == null || studySet.cards.length < 2) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.matchingGame)),
        body: Center(child: Text(l10n.needAtLeast2Cards)),
      );
    }

    final progress = _gameCards.isEmpty
        ? 0.0
        : _matchedCardIds.length / _gameCards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.matched(_matchedCardIds.length, _gameCards.length)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() => _initGame()),
            tooltip: l10n.restart,
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: _goHomeSmooth,
            tooltip: l10n.home,
          ),
        ],
      ),
      body: Column(
        children: [
          RoundedProgressBar(value: progress),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossCount = _gameCards.length <= 3 ? 2 : 3;
                  final tileCount = _tiles.length;
                  final rowCount = (tileCount / crossCount).ceil();
                  final spacing = 8.0;
                  final availH =
                      constraints.maxHeight - (rowCount - 1) * spacing;
                  final availW =
                      constraints.maxWidth - (crossCount - 1) * spacing;
                  final tileH = availH / rowCount;
                  final tileW = availW / crossCount;
                  final aspect = tileW / tileH;

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      childAspectRatio: aspect.clamp(0.5, 3.0),
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                    ),
                    itemCount: tileCount,
                    itemBuilder: (context, index) {
                      final tile = _tiles[index];
                      MatchingTileState state;

                      if (_matchedCardIds.contains(tile.cardId)) {
                        state = MatchingTileState.matched;
                      } else if (_incorrectIndices.contains(index)) {
                        state = MatchingTileState.incorrect;
                      } else if (_selectedIndex == index) {
                        state = MatchingTileState.selected;
                      } else {
                        state = MatchingTileState.normal;
                      }

                      return MatchingTile(
                        text: tile.text,
                        state: state,
                        onTap: () => _onTileTap(index),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TileItem {
  final String cardId;
  final String text;
  final bool isTerm;

  _TileItem({required this.cardId, required this.text, required this.isTerm});
}
