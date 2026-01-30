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
  String _currentUrl = '';
  bool _isLoading = true;

  bool get _isOnQuizletSet =>
      _currentUrl.contains('quizlet.com/') &&
      !_currentUrl.endsWith('quizlet.com/') &&
      !_currentUrl.endsWith('quizlet.com');

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              setState(() {
                _currentUrl = url;
                _isLoading = true;
              });
            },
            onPageFinished: (url) {
              setState(() {
                _currentUrl = url;
                _isLoading = false;
              });
            },
          ),
        )
        ..loadRequest(Uri.parse('https://quizlet.com'));
    } else {
      _controller = null;
    }
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
        context.go('/import/review', extra: studySet);
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
      body: Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_isLoading) const LinearProgressIndicator(),
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
