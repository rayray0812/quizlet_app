import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/providers/fsrs_provider.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/services/import_export_service.dart';
import 'package:recall_app/services/unsplash_service.dart';
import 'package:recall_app/features/study/widgets/count_picker_dialog.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';

class StudyModePickerScreen extends ConsumerStatefulWidget {
  final String setId;

  const StudyModePickerScreen({super.key, required this.setId});

  @override
  ConsumerState<StudyModePickerScreen> createState() =>
      _StudyModePickerScreenState();
}

class _StudyModePickerScreenState extends ConsumerState<StudyModePickerScreen> {
  bool _isAutoFetching = false;
  bool _cancelAutoFetch = false;
  int _autoFetchDone = 0;
  int _autoFetchTotal = 0;
  final Random _random = Random();
  late final FlutterTts _tts;
  bool _isTtsReady = false;
  Set<String>? _supportedLanguages;
  List<Map<String, String>>? _availableVoices;
  String? _activeLanguage;
  String? _activeVoiceKey;
  bool _isSpeaking = false;
  DateTime? _lastSpeakRequestedAt;
  List<Flashcard> _previewCards = <Flashcard>[];
  final Map<String, bool> _previewFlipped = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    if (_isTtsReady) {
      _isSpeaking = false;
      _tts.stop();
    }
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
            normalized.add({'name': name, 'locale': locale});
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
      for (final voice in voices) {
        final locale = _normalizeLocaleCode(voice['locale']!);
        if (locale == candidate || locale.startsWith('$candidate-')) {
          return voice;
        }
      }
    }
    if (preferred.startsWith('en')) {
      for (final voice in voices) {
        final locale = _normalizeLocaleCode(voice['locale']!);
        if (locale.startsWith('en')) return voice;
      }
    }
    if (preferred.startsWith('ja')) {
      for (final voice in voices) {
        final locale = _normalizeLocaleCode(voice['locale']!);
        if (locale.startsWith('ja')) return voice;
      }
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
      final voice = await _resolveVoice(_pickLanguage(value));
      if (voice != null) {
        final voiceKey = '${voice['name']}|${voice['locale']}';
        if (voiceKey != _activeVoiceKey) {
          try {
            await _tts.setVoice(voice);
            _activeVoiceKey = voiceKey;
          } catch (_) {}
        }
      }
      _isSpeaking = true;
      await _tts.speak(value);
    } catch (_) {
    } finally {
      _isSpeaking = false;
    }
  }

  Future<void> _autoFetchImages({
    required BuildContext context,
    required AppLocalizations l10n,
    required StudySet studySet,
  }) async {
    if (_isAutoFetching) return;

    final cardsToFetch = studySet.cards
        .where((c) => c.imageUrl.isEmpty && c.term.isNotEmpty)
        .length;
    if (cardsToFetch == 0) return;

    setState(() {
      _isAutoFetching = true;
      _cancelAutoFetch = false;
      _autoFetchDone = 0;
      _autoFetchTotal = cardsToFetch;
    });

    final unsplash = UnsplashService();
    final updatedCards = <Flashcard>[];
    Object? firstError;
    var updatedCount = 0;

    for (final card in studySet.cards) {
      if (_cancelAutoFetch) break;
      if (card.imageUrl.isEmpty && card.term.isNotEmpty) {
        try {
          final url = await unsplash.searchPhoto(card.term);
          if (url.isNotEmpty) {
            updatedCards.add(card.copyWith(imageUrl: url));
            updatedCount++;
          } else {
            updatedCards.add(card);
          }
        } catch (e) {
          firstError ??= e;
          updatedCards.add(card);
        }
        if (mounted) {
          setState(() => _autoFetchDone++);
        }
      } else {
        updatedCards.add(card);
      }
    }

    if (mounted && updatedCount > 0 && !_cancelAutoFetch) {
      await ref
          .read(studySetsProvider.notifier)
          .update(studySet.copyWith(cards: updatedCards));
    }

    if (mounted) {
      final wasCancelled = _cancelAutoFetch;
      setState(() {
        _isAutoFetching = false;
        _cancelAutoFetch = false;
      });
      if (context.mounted) {
        if (wasCancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.autoImageCancelled)),
          );
        } else if (firstError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.importFailed('$firstError'))),
          );
        } else if (updatedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.autoImageDone(updatedCount))),
          );
        }
      }
    }
  }

  void _syncPreviewCards(List<Flashcard> cards) {
    final oldIds = _previewCards.map((e) => e.id).toSet();
    final newIds = cards.map((e) => e.id).toSet();
    if (oldIds.length == newIds.length && oldIds.containsAll(newIds)) {
      if (_previewCards.length == cards.length) return;
    }
    _previewCards = List<Flashcard>.of(cards)..shuffle(_random);
    _previewFlipped
      ..clear()
      ..addEntries(_previewCards.map((c) => MapEntry(c.id, false)));
  }

  void _togglePreviewCard(String cardId) {
    setState(() {
      _previewFlipped[cardId] = !(_previewFlipped[cardId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final studySet = ref
        .watch(studySetsProvider)
        .where((s) => s.id == widget.setId)
        .firstOrNull;
    final l10n = AppLocalizations.of(context);

    if (studySet == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.studySetNotFound)),
      );
    }

    final hasEnoughCards = studySet.cards.length >= 4;
    _syncPreviewCards(studySet.cards);

    return Scaffold(
      appBar: AppBar(
        title: Text(studySet.title),
        actions: [
          if (_isAutoFetching)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_autoFetchDone/$_autoFetchTotal',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _cancelAutoFetch = true),
                      tooltip: l10n.cancel,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                    ),
                  ],
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              final service = ImportExportService();
              if (value == 'json') {
                await service.exportAsJson(studySet);
              } else if (value == 'csv') {
                await service.exportAsCsv(studySet);
              } else if (value == 'share') {
                context.push('/study/${widget.setId}/share');
              } else if (value == 'auto_image') {
                await _autoFetchImages(
                  context: context,
                  l10n: l10n,
                  studySet: studySet,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'json',
                child: ListTile(
                  leading: const Icon(Icons.code),
                  title: Text(l10n.exportAsJson),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: Text(l10n.exportAsCsv),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: const Icon(Icons.qr_code_rounded),
                  title: Text(l10n.shareSet),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'auto_image',
                enabled: !_isAutoFetching,
                child: ListTile(
                  leading: const Icon(Icons.image_search),
                  title: Text(l10n.autoFetchImage),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 48),
        children: [
          // Card count
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              l10n.nCards(studySet.cards.length),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Horizontal card preview
          if (studySet.cards.isNotEmpty)
            SizedBox(
              height: 144,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: _previewCards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final card = _previewCards[i];
                  final flipped = _previewFlipped[card.id] ?? false;
                  return SizedBox(
                    width: 150,
                    child: _PreviewFlipCard(
                      term: card.term,
                      definition: card.definition,
                      imageUrl: card.imageUrl,
                      flipped: flipped,
                      onTap: () => _togglePreviewCard(card.id),
                      onLongPress: () => _speakText(
                        flipped ? card.definition : card.term,
                        userInitiated: true,
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 28),

          // Study mode cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final dueCount = ref.watch(
                      dueCountForSetProvider(widget.setId),
                    );
                    return _StudyModeCard(
                      icon: Icons.psychology_rounded,
                      iconColor: AppTheme.purple,
                      title: l10n.srsReview,
                      description: dueCount > 0
                          ? '${l10n.srsReviewDesc} \u2014 ${l10n.nDueCards(dueCount)}'
                          : l10n.srsReviewDesc,
                      onTap: studySet.cards.isEmpty
                          ? null
                          : () => context.push('/study/${widget.setId}/srs'),
                      badge: dueCount > 0 ? '$dueCount' : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _StudyModeCard(
                  icon: Icons.flip_rounded,
                  iconColor: AppTheme.cyan,
                  title: l10n.quickBrowse,
                  description: l10n.quickBrowseDesc,
                  onTap: studySet.cards.isEmpty
                      ? null
                      : () => context.push('/study/${widget.setId}/flashcards'),
                ),
                const SizedBox(height: 12),
                _StudyModeCard(
                  icon: Icons.record_voice_over_rounded,
                  iconColor: AppTheme.green,
                  title: l10n.speakingPractice,
                  description: l10n.speakingPracticeDesc,
                  onTap: studySet.cards.isEmpty
                      ? null
                      : () => context.push('/study/${widget.setId}/speaking'),
                ),
                const SizedBox(height: 12),
                _StudyModeCard(
                  icon: Icons.quiz_rounded,
                  iconColor: AppTheme.orange,
                  title: l10n.quiz,
                  description: l10n.quizDesc,
                  onTap: hasEnoughCards
                      ? () async {
                          final count = await showCountPickerDialog(
                            context: context,
                            maxCount: studySet.cards.length,
                            minCount: 4,
                          );
                          if (count != null && context.mounted) {
                            context.push(
                              '/study/${widget.setId}/quiz',
                              extra: {'questionCount': count},
                            );
                          }
                        }
                      : null,
                  disabledReason: hasEnoughCards
                      ? null
                      : l10n.needAtLeast4Cards,
                ),
                const SizedBox(height: 12),
                _StudyModeCard(
                  icon: Icons.grid_view_rounded,
                  iconColor: AppTheme.indigo,
                  title: l10n.matchingGame,
                  description: l10n.matchingGameDesc,
                  onTap: studySet.cards.length >= 2
                      ? () => context.push('/study/${widget.setId}/match')
                      : null,
                  disabledReason: studySet.cards.length >= 2
                      ? null
                      : l10n.needAtLeast2Cards,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/edit/${widget.setId}'),
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: Text(
                  studySet.cards.isEmpty ? l10n.addCards : l10n.editCards,
                ),
              ),
            ),
          ),

          // All terms list
          if (studySet.cards.isNotEmpty) ...[
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.allTerms,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            ...studySet.cards.asMap().entries.map((entry) {
              final card = entry.value;
              return AdaptiveGlassCard(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                fillColor: Theme.of(context).cardColor,
                borderRadius: 12,
                elevation: 0.5,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        card.term,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: SizedBox(
                        height: 20,
                        child: VerticalDivider(
                          width: 1,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(
                        card.definition,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () =>
                          _speakText(card.term, userInitiated: true),
                      tooltip: l10n.listen,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.volume_up_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _PreviewFlipCard extends StatelessWidget {
  const _PreviewFlipCard({
    required this.term,
    required this.definition,
    required this.imageUrl,
    required this.flipped,
    required this.onTap,
    required this.onLongPress,
  });

  final String term;
  final String definition;
  final String imageUrl;
  final bool flipped;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onLongPress: onLongPress,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: flipped ? 1 : 0),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
        builder: (context, value, _) {
          final angle = value * pi;
          final isBack = value >= 0.5;
          final text = isBack ? definition : term;
          final showImage = imageUrl.isNotEmpty && !isBack;
          final surface = Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(isBack ? pi : 0),
            child: Container(
              decoration: AppTheme.softCardDecoration(
                fillColor: Theme.of(context).cardColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showImage)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        text,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: showImage ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: surface,
          );
        },
      ),
    );
  }
}

class _StudyModeCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final String? disabledReason;
  final String? badge;

  const _StudyModeCard({
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor = Colors.deepPurple,
    this.onTap,
    this.disabledReason,
    this.badge,
  });

  @override
  State<_StudyModeCard> createState() => _StudyModeCardState();
}

class _StudyModeCardState extends State<_StudyModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: isDisabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            },
      onTapCancel: isDisabled ? null : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: AdaptiveGlassCard(
              fillColor: Theme.of(context).cardColor,
              borderRadius: 16,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Badge(
                    isLabelVisible: widget.badge != null,
                    label: widget.badge != null ? Text(widget.badge!) : null,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: widget.iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 26,
                        color: isDisabled
                            ? Theme.of(context).colorScheme.outline
                            : widget.iconColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.disabledReason ?? widget.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDisabled
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (!isDisabled)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.outline,
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
