import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall_app/core/design_system.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';

class FlipCardWidget extends StatefulWidget {
  final String frontText;
  final String backText;
  final String imageUrl;
  final VoidCallback? onAdvance;
  final ValueChanged<bool>? onFlipStateChanged;

  const FlipCardWidget({
    super.key,
    required this.frontText,
    required this.backText,
    this.imageUrl = '',
    this.onAdvance,
    this.onFlipStateChanged,
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late final FlutterTts _tts;
  bool _isFlipAnimating = false;
  bool _isTtsReady = false;
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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 520),
      reverseDuration: const Duration(milliseconds: 520),
      vsync: this,
    )..addStatusListener((status) {
      final animating =
          status == AnimationStatus.forward ||
          status == AnimationStatus.reverse;
      if (animating != _isFlipAnimating) {
        _isFlipAnimating = animating;
        widget.onFlipStateChanged?.call(animating);
      }
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        widget.onFlipStateChanged?.call(false);
      }
    });
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(FlipCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frontText != widget.frontText) {
      _controller.reset();
      _stopSpeaking();
    }
  }

  @override
  void dispose() {
    widget.onFlipStateChanged?.call(false);
    _stopSpeaking();
    _controller.dispose();
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

  Future<void> _stopSpeaking() async {
    if (!_isTtsReady) return;
    _isSpeaking = false;
    await _tts.stop();
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

  Future<void> _speakTerm({bool userInitiated = false}) async {
    if (!_isTtsReady) {
      await _initTts();
      if (!_isTtsReady) return;
    }
    final text = widget.frontText.trim();
    if (text.isEmpty) return;
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
      final resolved = await _resolveLanguage(_pickLanguage(text));
      if (resolved != null && resolved != _activeLanguage) {
        try {
          await _tts.setLanguage(resolved);
          _activeLanguage = resolved;
        } catch (_) {}
      }
      final voice = await _resolveVoice(_pickLanguage(text));
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
      await _tts.speak(text);
    } catch (_) {
    } finally {
      _isSpeaking = false;
    }
  }

  void _flip() {
    if (_suppressFlipOnce) {
      _suppressFlipOnce = false;
      return;
    }
    if (_controller.isAnimating) return;
    if (_controller.isCompleted) {
      if (widget.onAdvance != null) {
        widget.onAdvance!.call();
      } else {
        _controller.reverse();
      }
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final frontVisible = cos(angle) > 0;
          final perspective = Matrix4.identity()..setEntry(3, 2, 0.0008);

          final front = Transform(
            alignment: Alignment.center,
            transform: perspective.clone()..rotateY(angle),
            child: _buildSide(
              widget.frontText,
              const Color(0xFFF9F3E6),
              const Color(0xFF1A221A),
              AppLocalizations.of(context).tapToFlip,
              showImage: true,
              bgColorEnd: const Color(0xFFB9CCB2),
            ),
          );

          final back = Transform(
            alignment: Alignment.center,
            transform: perspective.clone()..rotateY(angle + pi),
            child: _buildSide(
              widget.backText,
              const Color(0xFFF6ECD9),
              const Color(0xFF1A221A),
              AppLocalizations.of(context).definitionLabel,
              bgColorEnd: const Color(0xFFB3C8AD),
            ),
          );

          return RepaintBoundary(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (frontVisible) front,
                if (!frontVisible) back,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSide(
    String text,
    Color bgColor,
    Color textColor,
    String label, {
    bool showImage = false,
    Color? bgColorEnd,
  }) {
    final hasImage = showImage && widget.imageUrl.isNotEmpty;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.55;
    final imageHeight = (screenHeight * 0.16).clamp(92.0, 138.0);

    return Container(
      width: double.infinity,
      height: cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            Color.lerp(bgColor, bgColorEnd ?? bgColor, 0.18) ?? bgColor,
            bgColorEnd ?? bgColor,
          ],
          stops: const [0.0, 0.74, 1.0],
        ),
        borderRadius: BorderRadius.circular(DS.r24),
        border: Border.all(
          color: const Color(0xFFFEFAF0).withValues(alpha: 0.55),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C4235).withValues(alpha: 0.09),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.38),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _PaperTexturePainter(
                  tone: const Color(0xFFFFF8EC),
                  shadowTone: const Color(0xFF496454),
                ),
              ),
            ),
          ),
          Column(
            children: [
              if (hasImage)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.34),
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        height: imageHeight,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        fadeInDuration: const Duration(milliseconds: 120),
                        fadeOutDuration: Duration.zero,
                        memCacheHeight: 420,
                        memCacheWidth: 620,
                        placeholder: (_, __) => Container(
                          height: imageHeight,
                          color: textColor.withValues(alpha: 0.05),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
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
                        style: GoogleFonts.notoSerifTc(
                          textStyle: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: textColor.withValues(alpha: 0.58),
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        onPressed: () {
                          _suppressFlipOnce = true;
                          _speakTerm(userInitiated: true);
                        },
                        tooltip: AppLocalizations.of(context).listen,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          CupertinoIcons.speaker_2,
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
                      style: GoogleFonts.notoSerifTc(
                        textStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          height: 1.45,
                          letterSpacing: 0.3,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  final Color tone;
  final Color shadowTone;

  const _PaperTexturePainter({
    required this.tone,
    required this.shadowTone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = tone.withValues(alpha: 0.12)
      ..strokeWidth = 0.9;
    final fiberPaint = Paint()
      ..color = shadowTone.withValues(alpha: 0.065)
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = tone.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    final diagonalPaint = Paint()
      ..color = shadowTone.withValues(alpha: 0.03)
      ..strokeWidth = 0.55;

    for (var i = 0; i < 34; i++) {
      final y = (size.height / 34) * i + ((i % 2) * 1.2);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 1.4),
        linePaint,
      );
    }

    for (var i = 0; i < 210; i++) {
      final x = (i * 31 % 100) / 100 * size.width;
      final y = (i * 17 % 100) / 100 * size.height;
      final r = 0.45 + (i % 4) * 0.22;
      canvas.drawCircle(Offset(x, y), r, i % 5 == 0 ? glowPaint : fiberPaint);
    }

    for (var i = 0; i < 18; i++) {
      final startX = (i * 23 % 100) / 100 * size.width;
      final startY = (i * 41 % 100) / 100 * size.height;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX + 24, startY + 8),
        diagonalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter oldDelegate) {
    return oldDelegate.tone != tone || oldDelegate.shadowTone != shadowTone;
  }
}
