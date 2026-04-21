import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';

enum LegalDocType { privacy, terms, youth }

class LegalDocumentScreen extends StatelessWidget {
  final LegalDocType type;

  const LegalDocumentScreen({super.key, required this.type});

  String _assetPath(Locale locale) {
    final lang = locale.languageCode.toLowerCase() == 'en' ? 'en' : 'zh';
    switch (type) {
      case LegalDocType.privacy:
        return 'assets/legal/privacy-policy-$lang.md';
      case LegalDocType.terms:
        return 'assets/legal/terms-of-service-$lang.md';
      case LegalDocType.youth:
        return 'assets/legal/youth-protection-$lang.md';
    }
  }

  String _title(AppLocalizations l10n) {
    switch (type) {
      case LegalDocType.privacy:
        return l10n.privacyPolicy;
      case LegalDocType.terms:
        return l10n.termsOfService;
      case LegalDocType.youth:
        return l10n.youthProtectionNotice;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(_title(l10n)),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(_assetPath(locale)),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error?.toString() ?? 'Failed to load document',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            );
          }
          return Markdown(
            data: snapshot.data!,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            selectable: true,
          );
        },
      ),
    );
  }
}
