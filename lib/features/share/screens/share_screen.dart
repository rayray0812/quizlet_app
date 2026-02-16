import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/features/share/utils/share_codec.dart';

class ShareScreen extends ConsumerWidget {
  final String setId;

  const ShareScreen({super.key, required this.setId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studySet = ref.watch(studySetsProvider)
        .where((s) => s.id == setId)
        .firstOrNull;
    final l10n = AppLocalizations.of(context);

    if (studySet == null) {
      return Scaffold(
        appBar: AppBar(leading: const AppBackButton()),
        body: Center(child: Text(l10n.studySetNotFound)),
      );
    }

    final deepLink = ShareCodec.toDeepLink(studySet);
    final encoded = ShareCodec.encode(studySet);
    final qrData = deepLink.length <= 2953 ? deepLink : encoded;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.shareSet),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                studySet.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.nCards(studySet.cards.length),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.scanToImport,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: deepLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.linkCopied)),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(l10n.copyLink),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Share.share(deepLink);
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(l10n.share),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
