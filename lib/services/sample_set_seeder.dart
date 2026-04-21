import 'package:uuid/uuid.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/providers/study_set_provider.dart';

class SampleSetSeeder {
  static const _uuid = Uuid();

  static Future<void> seed(
    StudySetsNotifier notifier, {
    required String title,
    required String description,
  }) async {
    final now = DateTime.now().toUtc();
    final cards = _sampleCards.map((entry) {
      return Flashcard(
        id: _uuid.v4(),
        term: entry.term,
        definition: entry.definition,
        exampleSentence: entry.example,
        tags: [entry.pos],
      );
    }).toList();

    final set = StudySet(
      id: _uuid.v4(),
      title: title,
      description: description,
      createdAt: now,
      updatedAt: now,
      cards: cards,
    );

    await notifier.add(set);
  }

  static const List<_SampleEntry> _sampleCards = [
    _SampleEntry('abandon', '放棄；遺棄', 'v.',
        'She refused to abandon her dream of becoming a writer.'),
    _SampleEntry('accomplish', '完成；達成', 'v.',
        'He accomplished the task ahead of schedule.'),
    _SampleEntry('benefit', '利益；好處', 'n.',
        'Regular exercise offers many health benefits.'),
    _SampleEntry('challenge', '挑戰', 'n.',
        'Learning a new language is always a challenge.'),
    _SampleEntry('consequence', '後果；結果', 'n.',
        'Every decision has its consequences.'),
    _SampleEntry('demonstrate', '展示；證明', 'v.',
        'The teacher demonstrated how to solve the equation.'),
    _SampleEntry('efficient', '有效率的', 'adj.',
        'Email is a more efficient way to communicate.'),
    _SampleEntry('emphasize', '強調', 'v.',
        'The coach emphasized the importance of teamwork.'),
    _SampleEntry('essential', '必要的；基本的', 'adj.',
        'Water is essential for life.'),
    _SampleEntry('fundamental', '根本的；基礎的', 'adj.',
        'Reading is a fundamental skill.'),
    _SampleEntry('generate', '產生；引起', 'v.',
        'Solar panels generate clean energy.'),
    _SampleEntry('gradually', '逐漸地', 'adv.',
        'Her confidence grew gradually over time.'),
    _SampleEntry('inevitable', '不可避免的', 'adj.',
        'Change is inevitable in life.'),
    _SampleEntry('investigate', '調查', 'v.',
        'Police are investigating the cause of the accident.'),
    _SampleEntry('remarkable', '非凡的；值得注意的', 'adj.',
        'She has made remarkable progress this year.'),
  ];
}

class _SampleEntry {
  final String term;
  final String definition;
  final String pos;
  final String example;

  const _SampleEntry(this.term, this.definition, this.pos, this.example);
}
