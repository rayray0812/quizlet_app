import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizlet_app/models/flashcard.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/features/study/widgets/matching_tile.dart';

class MatchingGameScreen extends ConsumerStatefulWidget {
  final String setId;

  const MatchingGameScreen({super.key, required this.setId});

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

  void _initGame() {
    final studySet =
        ref.read(studySetsProvider.notifier).getById(widget.setId);
    if (studySet == null) return;

    // Take up to 6 cards for a manageable grid
    final cards = List.of(studySet.cards)..shuffle(Random());
    _gameCards = cards.take(min(6, cards.length)).toList();

    // Create tiles: one for each term and one for each definition
    _tiles = [];
    for (final card in _gameCards) {
      _tiles.add(_TileItem(cardId: card.id, text: card.term, isTerm: true));
      _tiles
          .add(_TileItem(cardId: card.id, text: card.definition, isTerm: false));
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
      // Match!
      setState(() {
        _matchedCardIds.add(first.cardId);
        _selectedIndex = null;
      });

      if (_matchedCardIds.length == _gameCards.length) {
        _stopwatch.stop();
        _showResults();
      }
    } else {
      // No match - show red briefly
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
    final seconds = _stopwatch.elapsed.inSeconds;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${seconds}s',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text('$_attempts attempts for ${_gameCards.length} pairs'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _initGame());
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studySet =
        ref.watch(studySetsProvider.notifier).getById(widget.setId);

    if (studySet == null || studySet.cards.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('Matching Game')),
        body: const Center(child: Text('Need at least 2 cards')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Matched: ${_matchedCardIds.length} / ${_gameCards.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _initGame()),
            tooltip: 'Restart',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gameCards.length <= 3 ? 2 : 3,
            childAspectRatio: 1.3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _tiles.length,
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
        ),
      ),
    );
  }
}

class _TileItem {
  final String cardId;
  final String text;
  final bool isTerm;

  _TileItem({
    required this.cardId,
    required this.text,
    required this.isTerm,
  });
}
