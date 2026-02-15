import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/features/study/widgets/rating_buttons.dart';
import 'package:recall_app/features/study/widgets/rounded_progress_bar.dart';
import 'package:recall_app/models/card_progress.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/providers/fsrs_provider.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/providers/widget_provider.dart';

/// SRS review screen: show card front -> tap to flip -> rate Again/Hard/Good/Easy.
class SrsReviewScreen extends ConsumerStatefulWidget {
  final String? setId;
  final List<String>? filterTags;
  final int? maxCards;
  final bool challengeMode;
  final int? challengeTarget;
  final List<String>? revengeCardIds;

  const SrsReviewScreen({
    super.key,
    this.setId,
    this.filterTags,
    this.maxCards,
    this.challengeMode = false,
    this.challengeTarget,
    this.revengeCardIds,
  });

  @override
  ConsumerState<SrsReviewScreen> createState() => _SrsReviewScreenState();
}

class _SrsReviewScreenState extends ConsumerState<SrsReviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showFront = true;
  bool _isFlipped = false;
  bool _isSubmittingRating = false;
  int? _lastRating;

  List<_ReviewItem> _queue = [];
  int _currentIndex = 0;
  int _againCount = 0;
  int _hardCount = 0;
  int _goodCount = 0;
  int _easyCount = 0;
  late final FlutterTts _tts;
  bool _isTtsReady = false;
  String _lastSpokenCardId = '';
  bool _suppressFlipOnce = false;
  Set<String>? _supportedLanguages;
  List<Map<String, String>>? _availableVoices;
  String? _activeLanguage;
  String? _activeVoiceKey;
  bool _isSpeaking = false;
  DateTime? _lastSpeakRequestedAt;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _flipAnimation.addListener(() {
      if (_flipAnimation.value >= 0.5 && _showFront) {
        setState(() => _showFront = false);
      } else if (_flipAnimation.value < 0.5 && !_showFront) {
        setState(() => _showFront = true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _buildQueue());
    _initTts();
  }

  void _buildQueue() {
    final localStorage = ref.read(localStorageServiceProvider);
    final studySets = ref.read(studySetsProvider);
    final now = DateTime.now().toUtc();

    final List<_ReviewItem> items = [];

    if (widget.revengeCardIds != null && widget.revengeCardIds!.isNotEmpty) {
      // Revenge mode: load specific cards by ID regardless of due status
      final cardsById = <String, Flashcard>{};
      for (final set in studySets) {
        for (final card in set.cards) {
          cardsById[card.id] = card;
        }
      }
      for (final cardId in widget.revengeCardIds!) {
        final card = cardsById[cardId];
        if (card == null) continue;
        final progress = localStorage.getCardProgress(cardId);
        if (progress == null) continue;
        items.add(_ReviewItem(card: card, progress: progress));
      }
    } else if (widget.setId != null) {
      final studySet = localStorage.getStudySet(widget.setId!);
      if (studySet == null) return;
      for (final card in studySet.cards) {
        final progress = localStorage.getCardProgress(card.id);
        if (progress != null) {
          final isDue = progress.due == null || !progress.due!.isAfter(now);
          if (isDue) {
            items.add(_ReviewItem(card: card, progress: progress));
          }
        }
      }
    } else {
      final dueProgress = localStorage.getDueCardProgress();
      final cardsById = <String, Flashcard>{};
      for (final set in studySets) {
        for (final card in set.cards) {
          cardsById[card.id] = card;
        }
      }

      final tags = widget.filterTags;

      for (final progress in dueProgress) {
        final card = cardsById[progress.cardId];
        if (card == null) continue;

        // If tags are specified (custom study), only include matching cards
        if (tags != null && tags.isNotEmpty) {
          if (!card.tags.any((t) => tags.contains(t))) continue;
        }

        items.add(_ReviewItem(card: card, progress: progress));
      }
    }

    items.shuffle();
    if (widget.maxCards != null && widget.maxCards! > 0 && items.length > widget.maxCards!) {
      items.removeRange(widget.maxCards!, items.length);
    }
    setState(() => _queue = items);
    if (items.isNotEmpty) {
      _speakCardTerm(items.first.card);
    }
  }

  @override
  void dispose() {
    if (_isTtsReady) {
      _isSpeaking = false;
      _tts.stop();
    }
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _isTtsReady = true;
    } catch (_) {
      _isTtsReady = false;
    }
  }

  String _pickLanguage(String text) {
    final hasJapaneseKana = RegExp(r'[\u3040-\u30FF]').hasMatch(text);
    if (hasJapaneseKana) return 'ja-JP';
    final hasChinese = RegExp(r'[\u3400-\u9FFF]').hasMatch(text);
    return hasChinese ? 'zh-TW' : 'en-US';
  }

  String _normalizeLocaleCode(String code) {
    return code.replaceAll('_', '-').toLowerCase();
  }

  Future<Set<String>> _loadSupportedLanguages() async {
    if (_supportedLanguages != null) return _supportedLanguages!;
    try {
      final langs = await _tts.getLanguages;
      final normalized = langs
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      _supportedLanguages = normalized;
      return normalized;
    } catch (_) {
      _supportedLanguages = <String>{};
      return _supportedLanguages!;
    }
  }

  Future<List<Map<String, String>>> _loadAvailableVoices() async {
    if (_availableVoices != null) return _availableVoices!;
    try {
      final voices = await _tts.getVoices;
      final normalized = <Map<String, String>>[];
      for (final voice in voices) {
        if (voice is Map) {
          final name = voice['name']?.toString().trim() ?? '';
          final locale = voice['locale']?.toString().trim() ?? '';
          if (name.isNotEmpty && locale.isNotEmpty) {
            normalized.add({
              'name': name,
              'locale': locale,
              'quality': voice['quality']?.toString().trim().toLowerCase() ?? '',
              'identifier':
                  voice['identifier']?.toString().trim().toLowerCase() ?? '',
            });
          }
        }
      }
      _availableVoices = normalized;
      return normalized;
    } catch (_) {
      _availableVoices = const <Map<String, String>>[];
      return _availableVoices!;
    }
  }

  int _voiceNaturalnessScore(Map<String, String> voice, String preferred) {
    final name = (voice['name'] ?? '').toLowerCase();
    final quality = (voice['quality'] ?? '').toLowerCase();
    final identifier = (voice['identifier'] ?? '').toLowerCase();
    var score = 0;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      if (quality.contains('premium') || quality.contains('enhanced')) score += 40;
      if (quality == '2' || quality == '300') score += 24;
      if (name.contains('compact') || identifier.contains('compact')) score -= 24;
    }

    if (name.contains('novelty') ||
        name.contains('zarvox') ||
        name.contains('boing') ||
        name.contains('bubbles') ||
        name.contains('bad news')) {
      score -= 20;
    }

    if (preferred.startsWith('en')) {
      if (name.contains('samantha') || name.contains('alex')) score += 8;
    }

    return score;
  }

  Map<String, String>? _pickBestVoiceForLocale(
    List<Map<String, String>> voices,
    String preferred,
    String localePrefix,
  ) {
    final matches = voices.where((voice) {
      final locale = _normalizeLocaleCode(voice['locale'] ?? '');
      return locale == localePrefix || locale.startsWith('$localePrefix-');
    }).toList();
    if (matches.isEmpty) return null;
    matches.sort(
      (a, b) => _voiceNaturalnessScore(
        b,
        preferred,
      ).compareTo(_voiceNaturalnessScore(a, preferred)),
    );
    return matches.first;
  }

  Future<String?> _resolveLanguage(String preferred) async {
    final available = await _loadSupportedLanguages();
    if (available.isEmpty) return null;
    final lowerMap = <String, String>{
      for (final lang in available) _normalizeLocaleCode(lang): lang,
    };
    final normalizedPreferred = _normalizeLocaleCode(preferred);
    final candidates = preferred.startsWith('zh')
        ? <String>[preferred, 'zh-TW', 'zh-CN', 'zh']
        : preferred.startsWith('ja')
        ? <String>[preferred, 'ja-JP', 'ja']
        : <String>[preferred, 'en-US', 'en-GB', 'en'];
    for (final candidate in candidates) {
      final normalizedCandidate = _normalizeLocaleCode(candidate);
      final exact = lowerMap[normalizedCandidate];
      if (exact != null) return exact;
      final prefix = '$normalizedCandidate-';
      for (final entry in lowerMap.entries) {
        if (entry.key == normalizedCandidate || entry.key.startsWith(prefix)) {
          return entry.value;
        }
      }
    }
    if (normalizedPreferred.startsWith('en')) {
      for (final entry in lowerMap.entries) {
        if (entry.key.startsWith('en')) return entry.value;
      }
    }
    if (normalizedPreferred.startsWith('ja')) {
      for (final entry in lowerMap.entries) {
        if (entry.key.startsWith('ja')) return entry.value;
      }
    }
    return null;
  }

  Future<Map<String, String>?> _resolveVoice(String preferred) async {
    final voices = await _loadAvailableVoices();
    if (voices.isEmpty) return null;
    final localeCandidates = preferred.startsWith('zh')
        ? <String>['zh-tw', 'zh-cn', 'zh']
        : preferred.startsWith('ja')
        ? <String>['ja-jp', 'ja']
        : <String>['en-us', 'en-gb', 'en-au', 'en'];
    for (final candidate in localeCandidates) {
      final best = _pickBestVoiceForLocale(voices, preferred, candidate);
      if (best != null) return best;
    }
    return null;
  }

  Future<void> _speakText(String text, {bool userInitiated = false}) async {
    if (!_isTtsReady) {
      await _initTts();
      if (!_isTtsReady) return;
    }
    final value = text.trim();
    if (value.isEmpty) return;
    final now = DateTime.now();
    final lastAt = _lastSpeakRequestedAt;
    if (!userInitiated &&
        lastAt != null &&
        now.difference(lastAt).inMilliseconds < 120) {
      return;
    }
    _lastSpeakRequestedAt = now;
    try {
      if (_isSpeaking) {
        await _tts.stop();
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      final resolved = await _resolveLanguage(_pickLanguage(value));
      if (resolved != null && resolved != _activeLanguage) {
        try {
          await _tts.setLanguage(resolved);
          _activeLanguage = resolved;
        } catch (_) {}
      }
      if (defaultTargetPlatform != TargetPlatform.iOS) {
        final voice = await _resolveVoice(_pickLanguage(value));
        if (voice != null) {
          final voiceKey = '${voice['name']}|${voice['locale']}';
          if (voiceKey != _activeVoiceKey) {
            try {
              await _tts.setVoice({
                'name': voice['name'] ?? '',
                'locale': voice['locale'] ?? '',
              });
              _activeVoiceKey = voiceKey;
            } catch (_) {}
          }
        }
      }
      _isSpeaking = true;
      await _tts.speak(value);
    } catch (_) {
    } finally {
      _isSpeaking = false;
    }
  }

  Future<void> _speakCardTerm(Flashcard card) async {
    _lastSpokenCardId = card.id;
    await _speakText(card.term);
  }

  void _flip() {
    if (_suppressFlipOnce) {
      _suppressFlipOnce = false;
      return;
    }
    if (_flipController.isAnimating || _isSubmittingRating) return;
    HapticFeedback.selectionClick();
    setState(() => _isFlipped = true);
    _flipController.forward();
  }

  Future<void> _onRate(int rating) async {
    if (_isSubmittingRating) return;
    setState(() {
      _isSubmittingRating = true;
      _lastRating = rating;
    });

    final item = _queue[_currentIndex];
    final fsrsService = ref.read(fsrsServiceProvider);
    final localStorage = ref.read(localStorageServiceProvider);

    final result = fsrsService.reviewCard(item.progress, rating);
    await localStorage.saveCardProgress(result.progress);
    await localStorage.saveReviewLog(result.log);
    ref.invalidate(allCardProgressProvider);
    ref.read(widgetRefreshProvider)();
    if (!mounted) return;

    switch (rating) {
      case 1:
        _againCount++;
      case 2:
        _hardCount++;
      case 3:
        _goodCount++;
      case 4:
        _easyCount++;
    }

    if (_currentIndex + 1 >= _queue.length) {
      final total = _againCount + _hardCount + _goodCount + _easyCount;
      final challengeTarget = widget.challengeTarget ?? widget.maxCards;
      final challengeCompleted =
          widget.challengeMode &&
          challengeTarget != null &&
          challengeTarget > 0 &&
          total >= challengeTarget;
      HapticFeedback.mediumImpact();
      context.go(
        '/review/summary',
        extra: {
          'totalReviewed': total,
          'againCount': _againCount,
          'hardCount': _hardCount,
          'goodCount': _goodCount,
          'easyCount': _easyCount,
          'challengeMode': widget.challengeMode,
          'challengeTarget': challengeTarget,
          'challengeCompleted': challengeCompleted,
        },
      );
    } else {
      HapticFeedback.lightImpact();
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (!mounted) return;
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _showFront = true;
        _isSubmittingRating = false;
        _lastRating = null;
      });
      _flipController.reset();
      _speakCardTerm(_queue[_currentIndex].card);
    }
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
    final l10n = AppLocalizations.of(context);

    if (_queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.srsReview)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: AppTheme.green,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.noDueCards,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: Text(l10n.done),
              ),
            ],
          ),
        ),
      );
    }

    final item = _queue[_currentIndex];
    if (_lastSpokenCardId != item.card.id && !_isSubmittingRating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lastSpokenCardId != item.card.id) {
          _speakCardTerm(item.card);
        }
      });
    }
    final fsrsService = ref.read(fsrsServiceProvider);
    final intervals = fsrsService.getSchedulingPreview(item.progress);
    final progress = _queue.isEmpty ? 0.0 : _currentIndex / _queue.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${_queue.length}'),
        actions: [
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: _isFlipped ? null : _flip,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: AnimatedScale(
                      scale: _isSubmittingRating ? 0.98 : 1,
                      duration: const Duration(milliseconds: 140),
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final angle = _flipAnimation.value * pi;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            child: _showFront
                                ? _buildCardSide(
                                    text: item.card.term,
                                    label: l10n.tapToFlip,
                                    onSpeak: () {
                                      _suppressFlipOnce = true;
                                      _speakText(
                                        item.card.term,
                                        userInitiated: true,
                                      );
                                    },
                                    bgColor: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    textColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                    imageUrl: item.card.imageUrl,
                                  )
                                : Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()..rotateY(pi),
                                    child: _buildCardSide(
                                      text: item.card.definition,
                                      label: l10n.definitionLabel,
                                      onSpeak: () {
                                        _suppressFlipOnce = true;
                                        _speakText(
                                          item.card.definition,
                                          userInitiated: true,
                                        );
                                      },
                                      bgColor: Theme.of(
                                        context,
                                      ).colorScheme.secondaryContainer,
                                      textColor: Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _isSubmittingRating ? 1 : 0,
                    duration: const Duration(milliseconds: 100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _ratingLabel(_lastRating),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isFlipped)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              child: RatingButtons(
                intervals: intervals,
                onRating: _onRate,
                enabled: !_isSubmittingRating,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Text(
                l10n.tapToFlip,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _ratingLabel(int? rating) {
    final l10n = AppLocalizations.of(context);
    switch (rating) {
      case 1:
        return l10n.ratingAgain;
      case 2:
        return l10n.ratingHard;
      case 3:
        return l10n.ratingGood;
      case 4:
        return l10n.ratingEasy;
      default:
        return '';
    }
  }

  Widget _buildCardSide({
    required String text,
    required String label,
    required Color bgColor,
    required Color textColor,
    VoidCallback? onSpeak,
    String imageUrl = '',
  }) {
    final hasImage = imageUrl.isNotEmpty;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.5;

    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: screenHeight * 0.18,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.45),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    onPressed: onSpeak,
                    tooltip: AppLocalizations.of(context).listen,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.volume_up_rounded,
                      color: textColor.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem {
  final Flashcard card;
  final CardProgress progress;

  _ReviewItem({required this.card, required this.progress});
}
