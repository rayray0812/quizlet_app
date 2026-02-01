import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:quizlet_app/features/import/utils/js_scraper.dart';
import 'package:quizlet_app/models/flashcard.dart';
import 'package:quizlet_app/models/study_set.dart';

class WebImportScreen extends StatefulWidget {
  const WebImportScreen({super.key});

  @override
  State<WebImportScreen> createState() => _WebImportScreenState();
}

class _WebImportScreenState extends State<WebImportScreen> {
  late final WebViewController? _controller;
  late final TextEditingController _urlController;
  String _currentUrl = '';
  bool _isLoading = true;

  bool get _isOnQuizletSet =>
      _currentUrl.contains('quizlet.com/') &&
      !_currentUrl.endsWith('quizlet.com/') &&
      !_currentUrl.endsWith('quizlet.com');

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: 'https://quizlet.com');
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              setState(() {
                _currentUrl = url;
                _isLoading = true;
                _urlController.text = url;
              });
            },
            onPageFinished: (url) {
              setState(() {
                _currentUrl = url;
                _isLoading = false;
                _urlController.text = url;
              });
            },
          ),
        )
        ..loadRequest(Uri.parse('https://quizlet.com'));
    } else {
      _controller = null;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _navigateToUrl() {
    if (_controller == null) return;
    var url = _urlController.text.trim();
    if (url.isEmpty) return;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
      _urlController.text = url;
    }

    if (!url.contains('quizlet.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Quizlet URL')),
      );
      return;
    }

    _controller.loadRequest(Uri.parse(url));
  }

  Future<void> _scrapeAndImport() async {
    if (_controller == null) return;

    try {
      final result = await _controller.runJavaScriptReturningResult(
        JsScraper.scrapeScript,
      );

      String jsonStr = result.toString();
      // Remove surrounding quotes if present
      if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
        jsonStr = jsonStr.substring(1, jsonStr.length - 1);
        jsonStr = jsonStr.replaceAll(r'\"', '"');
        jsonStr = jsonStr.replaceAll(r'\\n', '\n');
      }

      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final title = data['title'] as String? ?? 'Imported Set';
      final cardsData = data['cards'] as List? ?? [];

      if (cardsData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No flashcards found. Try scrolling down to load all cards first.'),
            ),
          );
        }
        return;
      }

      final cards = cardsData.map((c) {
        return Flashcard(
          id: const Uuid().v4(),
          term: c['term'] as String? ?? '',
          definition: c['definition'] as String? ?? '',
        );
      }).toList();

      final studySet = StudySet(
        id: const Uuid().v4(),
        title: title,
        createdAt: DateTime.now(),
        cards: cards,
      );

      if (mounted) {
        context.push('/import/review', extra: studySet);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Import')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_android,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Use the mobile app to import',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'WebView import is only available on mobile devices.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from Quizlet'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'Enter Quizlet URL',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _navigateToUrl(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _navigateToUrl,
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Go',
                ),
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: WebViewWidget(controller: _controller!),
          ),
        ],
      ),
      floatingActionButton: _isOnQuizletSet
          ? FloatingActionButton.extended(
              onPressed: _scrapeAndImport,
              icon: const Icon(Icons.download),
              label: const Text('Import Set'),
            )
          : null,
    );
  }
}
