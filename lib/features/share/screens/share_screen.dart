import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/services/import_export_service.dart';
import 'package:recall_app/features/share/utils/share_codec.dart';

class ShareScreen extends ConsumerWidget {
  final String setId;

  const ShareScreen({super.key, required this.setId});

  bool _canGenerateQr(String data) {
    try {
      final qr = QrCode.fromData(
        data: data,
        errorCorrectLevel: QrErrorCorrectLevel.L,
      );
      qr.moduleCount;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studySet = ref.watch(studySetByIdProvider(setId));
    final l10n = AppLocalizations.of(context);

    if (studySet == null) {
      return Scaffold(
        appBar: AppBar(leading: const AppBackButton()),
        body: Center(child: Text(l10n.studySetNotFound)),
      );
    }

    final deepLink = ShareCodec.toDeepLink(studySet);
    final encoded = ShareCodec.encode(studySet);
    final qrCandidate = deepLink.length <= 2000 ? deepLink : encoded;
    final qrOk = qrCandidate.length <= 2000 && _canGenerateQr(qrCandidate);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.shareSet),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.indigo.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.indigo.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.indigo.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: AppTheme.indigo,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    studySet.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.nCards(studySet.cards.length),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Primary: Share as file
            _ShareOption(
              icon: Icons.send_rounded,
              color: AppTheme.indigo,
              title: l10n.shareToFriend,
              subtitle: l10n.shareToFriendDesc,
              onTap: () async {
                try {
                  await ImportExportService().exportAsJson(studySet);
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.shareError)),
                  );
                }
              },
            ),
            const SizedBox(height: 10),

            // Copy link
            _ShareOption(
              icon: Icons.copy_rounded,
              color: AppTheme.purple,
              title: l10n.copyLink,
              subtitle: l10n.copyLinkDesc,
              onTap: () {
                Clipboard.setData(ClipboardData(text: deepLink));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.linkCopied)),
                );
              },
            ),
            const SizedBox(height: 10),

            // QR Code (expandable)
            if (qrOk) ...[
              _QrSection(qrData: qrCandidate, l10n: l10n),
            ] else
              _ShareOption(
                icon: Icons.qr_code_rounded,
                color: Colors.grey,
                title: 'QR Code',
                subtitle: l10n.qrTooLarge,
                onTap: null,
              ),
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ShareOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: enabled
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.grey.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (enabled ? color : Colors.grey).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: enabled ? color : Colors.grey, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: enabled ? Colors.grey[900] : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled ? Colors.grey[600] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrSection extends StatefulWidget {
  final String qrData;
  final AppLocalizations l10n;

  const _QrSection({required this.qrData, required this.l10n});

  @override
  State<_QrSection> createState() => _QrSectionState();
}

class _QrSectionState extends State<_QrSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.cyan.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.qr_code_rounded,
                        color: AppTheme.cyan, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR Code',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.l10n.scanToImport,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right_rounded,
                        color: Colors.grey[400], size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
              ),
              child: QrImageView(
                data: widget.qrData,
                version: QrVersions.auto,
                errorCorrectionLevel: QrErrorCorrectLevel.L,
                size: 220,
                backgroundColor: Colors.white,
                errorStateBuilder: (_, __) => SizedBox(
                  width: 220,
                  height: 220,
                  child: Center(
                    child: Text(
                      widget.l10n.qrTooLarge,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}
