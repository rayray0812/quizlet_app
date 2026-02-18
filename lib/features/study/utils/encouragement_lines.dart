import 'dart:math';

class EncouragementLines {
  static String? _lastPickedLine;

  static const List<String> high = <String>[
    '唉呦不錯喔，這局很穩。',
    '太強了吧，節奏抓得超好。',
    '今天狀態滿分，繼續連勝。',
    '漂亮，這個表現可以炫耀一下。',
    '這分數，我給滿分。',
    '沒想到你是高手',
    '太扯，你是天才吧？',
    '哎呦，很秋喔！',
    '太神啦，請收下我的膝蓋。',
    '有料。',
    '強到沒朋友欸。',
    '穩到不行，這局你扛。',
    '你真的很努力，連我也被激勵到了。',
    '狀態滿分！請保持這股氣勢。',
    '辛苦了，這分數是實至名歸。',
    '看得出來你花了很多心力，超棒。',
  ];

  static const List<String> mid = <String>[
    '這分數很尷尬，不上不下的。',
    '鄰居小孩柏辰都可以考',
    '不錯喔，有在進步（敷衍）。',
    '還可以啦，再一場？',
    '不錯喔，有在進步。',
    '還行，但離大神還有距離。',
    '熱身結束，下一場認真點。',
    '不錯，節奏有抓到。',
    '不錯喔，再一輪會更順。',
    '有在進步，節奏越來越穩。',
    '這局打得很可以，繼續。',
    '今天手感不錯，維持下去。',
    '差一點就更高分了，再來一把。',
    '普普通通，再拚一下？',
    '穩穩地前進也是一種進步。',
    '很不錯，感覺你越來越順手了。',
    '今天的狀態很穩，繼續保持下去。',
    '累了就稍息一下，這分數已經及格了。',
    '每一輪的練習都在累積，你做得很好。',
  ];

  static const List<String> low = <String>[
    '沒事，背單字本來就是一場馬拉松。',
    '累了吧？休息一下，腦袋也需要緩衝。',
    '分數不代表全部，至少你今天開始做了。',
    '這一局比較難，下一局我們一起找回手感。',
    '別灰心，最難的單字往往都是這時候記住的。',
    '今天的狀態不好也沒關係，明天我們再試一次。',
    '有開始就很棒，下一輪會更好。',
    '別急，慢慢來你會越來越快。',
    '今天先穩住，下一局超回來。',
    '每一輪都在累積，繼續就對了。',
    '你已經在變強了，真的。',
    '欸，你剛才有開機嗎？',
    '這分數...我看還是算了。',
    '沒事，人生總有低潮。',
    '連我阿嬤都比你強。',
    '加油好嗎？這分數會被笑。',
    '安捏母湯，你要確欸？',
    '這分數...洗洗睡吧。',
    '哩係勒哈囉？',
  ];

  static String pick(int score, {Random? random}) {
    final r = random ?? Random();
    final pool = score >= 88
        ? high
        : score >= 70
            ? mid
            : low;
    if (pool.length <= 1) return pool.first;

    String picked = pool[r.nextInt(pool.length)];
    if (_lastPickedLine != null && picked == _lastPickedLine) {
      final candidates = pool.where((line) => line != _lastPickedLine).toList();
      picked = candidates[r.nextInt(candidates.length)];
    }

    _lastPickedLine = picked;
    return picked;
  }
}
