import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/features/study/models/conversation_transcript.dart';
import 'package:share_plus/share_plus.dart';

class TranscriptExportService {
  TranscriptExportService._();

  static String format(ConversationTranscript transcript, AppLocalizations l10n) {
    final buf = StringBuffer();
    final date = transcript.completedAt.toLocal();
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    buf.writeln('=== ${l10n.conversationReport} ===');
    buf.writeln('${l10n.exportScenarioLabel}: ${transcript.scenarioTitle}');
    buf.writeln('${l10n.exportDifficultyLabel}: ${transcript.difficulty}');
    buf.writeln('${l10n.exportDateLabel}: $dateStr');
    buf.writeln('${l10n.exportScoreLabel}: ${transcript.overallScore.toStringAsFixed(1)} / 5.0');
    buf.writeln('${l10n.exportTurnsLabel}: ${transcript.totalTurns}');
    buf.writeln('');

    for (var i = 0; i < transcript.turns.length; i++) {
      final turn = transcript.turns[i];
      buf.writeln('--- ${l10n.exportTurnPrefix.replaceFirst('{n}', '${i + 1}')} ---');
      buf.writeln('AI: ${turn.aiQuestion}');
      buf.writeln('${l10n.you}: ${turn.userResponse}');
      if (turn.grammarScore > 0 || turn.vocabScore > 0 || turn.relevanceScore > 0) {
        buf.writeln(
            '${l10n.exportScoreLabel}: G=${turn.grammarScore} V=${turn.vocabScore} R=${turn.relevanceScore}');
      }
      if (turn.correction.isNotEmpty) {
        buf.writeln('${l10n.exportCorrectionPrefix}: ${turn.correction}');
      }
      buf.writeln('');
    }

    buf.writeln(l10n.exportGeneratedBy);
    return buf.toString();
  }

  static Future<void> share(ConversationTranscript transcript, AppLocalizations l10n) async {
    final text = format(transcript, l10n);
    await Share.share(text);
  }
}
