import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:recall_app/core/design_system.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/providers/gemini_key_provider.dart';
import 'package:recall_app/services/gemini_service.dart';

class PhotoImportScreen extends ConsumerStatefulWidget {
  const PhotoImportScreen({super.key});

  @override
  ConsumerState<PhotoImportScreen> createState() => _PhotoImportScreenState();
}

enum _Stage { pickImage, pickMode, analyzing }

class _PhotoImportScreenState extends ConsumerState<PhotoImportScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  String _mimeType = 'image/jpeg';
  _Stage _stage = _Stage.pickImage;
  bool _cancelled = false;

  final List<Flashcard> _accumulatedCards = [];
  int _photoCount = 0;
  late final AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 75,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final mime = picked.mimeType ?? 'image/jpeg';

    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _mimeType = mime;
      _stage = _Stage.pickMode;
    });
  }

  Future<void> _analyze(PhotoScanMode mode) async {
    final l10n = AppLocalizations.of(context);
    final apiKey = ref.read(geminiKeyProvider);

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.geminiApiKeyNotSet)),
      );
      return;
    }

    if (_imageBytes == null) return;

    _cancelled = false;
    setState(() => _stage = _Stage.analyzing);

    try {
      final results = await GeminiService.extractFlashcards(
        apiKey: apiKey,
        imageBytes: _imageBytes!,
        mimeType: _mimeType,
        mode: mode,
      );

      if (!mounted || _cancelled) return;

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noCardsExtracted)),
        );
        setState(() => _stage = _Stage.pickMode);
        return;
      }

      final cards = results
          .map((r) => Flashcard(
                id: const Uuid().v4(),
                term: r['term']!,
                definition: r['definition']!,
                exampleSentence: (r['exampleSentence'] ?? '').trim(),
              ))
          .toList();

      setState(() {
        _accumulatedCards.addAll(cards);
        _photoCount++;
        _imageBytes = null;
        _stage = _Stage.pickImage;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.photoAdded(cards.length)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on ScanException catch (e) {
      if (!mounted || _cancelled) return;
      debugPrint('ScanException [${e.reason}]: ${e.message}');
      final errorMsg = _errorMessage(AppLocalizations.of(context), e.reason);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorMsg\n${e.message}'),
          duration: const Duration(seconds: 8),
        ),
      );
      setState(() => _stage = _Stage.pickMode);
    } catch (e) {
      if (!mounted || _cancelled) return;
      debugPrint('Photo scan error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.photoScanFailed}\n$e'),
          duration: const Duration(seconds: 6),
        ),
      );
      setState(() => _stage = _Stage.pickMode);
    }
  }

  String _errorMessage(AppLocalizations l10n, ScanFailureReason reason) {
    return switch (reason) {
      ScanFailureReason.timeout => l10n.scanTimeout,
      ScanFailureReason.quotaExceeded => l10n.scanQuotaExceeded,
      ScanFailureReason.authError => 'API authentication failed. Please check your Gemini API key.',
      ScanFailureReason.invalidRequest => 'Image request was invalid. Try another image or mode.',
      ScanFailureReason.serverError => 'AI service is temporarily unavailable. Please retry shortly.',
      ScanFailureReason.parseError => l10n.scanParseError,
      ScanFailureReason.networkError => l10n.scanNetworkError,
      ScanFailureReason.unknown => l10n.photoScanFailed,
    };
  }

  void _cancelAnalysis() {
    _cancelled = true;
    setState(() => _stage = _Stage.pickMode);
  }

  void _reset() {
    setState(() {
      _imageBytes = null;
      _stage = _Stage.pickImage;
    });
  }

  void _goBack() {
    if (_stage == _Stage.analyzing) {
      _cancelAnalysis();
      return;
    }
    if (_stage == _Stage.pickMode) {
      _reset();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _reviewAndSave() {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final studySet = StudySet(
      id: const Uuid().v4(),
      title: '${l10n.photoToFlashcard} $timestamp',
      createdAt: now.toUtc(),
      cards: List.of(_accumulatedCards),
    );

    context.push('/import/review', extra: studySet);
  }

  Future<void> _showScanModeBottomSheet(AppLocalizations l10n) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (sheetContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(DS.r24),
                  boxShadow: DS.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: DS.text2.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: _ModeCard(
                        icon: Icons.list_alt_rounded,
                        iconColor: DS.primary,
                        title: l10n.vocabularyList,
                        description: l10n.vocabularyListDesc,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _analyze(PhotoScanMode.vocabularyList);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: _ModeCard(
                        icon: Icons.menu_book_rounded,
                        iconColor: AppTheme.purple,
                        title: l10n.textbookPage,
                        description: l10n.textbookPageDesc,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _analyze(PhotoScanMode.textbookPage);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _goBack,
        ),
        title: Text(
          l10n.photoToFlashcard,
          style: TextStyle(
            color: AppTheme.indigo,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          if (_accumulatedCards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: Icon(Icons.photo_library_rounded, size: 16, color: AppTheme.orange),
                label: Text(
                  l10n.cardsFromPhotos(_accumulatedCards.length, _photoCount),
                  style: const TextStyle(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: switch (_stage) {
                _Stage.pickImage => _buildPickImage(l10n),
                _Stage.pickMode => _buildPickMode(l10n),
                _Stage.analyzing => _buildAnalyzing(l10n),
              },
            ),
          ),
          if (_accumulatedCards.isNotEmpty) _buildBottomBar(l10n),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(Icons.layers_rounded, size: 20, color: AppTheme.indigo),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.cardsFromPhotos(_accumulatedCards.length, _photoCount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _reviewAndSave,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(l10n.reviewAndSave),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickImage(AppLocalizations l10n) {
    return Center(
      key: const ValueKey('pick-image'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.orange.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 48,
                color: AppTheme.orange.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _accumulatedCards.isEmpty
                  ? l10n.chooseImageSource
                  : l10n.addMorePhotos,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            if (!kIsWeb) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                  label: Text(l10n.takePhoto),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, size: 20),
                label: Text(l10n.chooseFromGallery),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickMode(AppLocalizations l10n) {
    return SingleChildScrollView(
      key: const ValueKey('pick-mode'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Image preview
          if (_imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.retryOrChooseAnother),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showScanModeBottomSheet(l10n),
              icon: const Icon(Icons.tune_rounded),
              label: Text(l10n.chooseMode),
              style: FilledButton.styleFrom(
                backgroundColor: DS.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DS.r16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzing(AppLocalizations l10n) {
    return Center(
      key: const ValueKey('analyzing'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 220,
                height: 140,
                decoration: BoxDecoration(
                  color: DS.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(DS.r16),
                  border: Border.all(color: DS.primary.withValues(alpha: 0.24)),
                ),
              ),
              AnimatedBuilder(
                animation: _scanLineController,
                builder: (context, child) {
                  return Positioned(
                    top: 20 + (_scanLineController.value * 92),
                    child: Container(
                      width: 200,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            DS.primary.withValues(alpha: 0.16),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.analyzing,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _cancelAnalysis,
            child: Text(l10n.cancelAnalysis),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AdaptiveGlassCard(
        borderRadius: 16,
        fillColor: Theme.of(context).cardColor,
        elevation: 1.2,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
