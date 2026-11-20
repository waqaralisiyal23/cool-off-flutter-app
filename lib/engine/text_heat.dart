/// On-device heuristics for how heated a message *reads*
/// (docs/03-heat-engine.md). No network, no AI, and nothing here is ever
/// logged: the matches stay in this function.
library;

/// One thing in the text that added heat.
enum TextHeatSignal {
  /// Much of it is in CAPITALS.
  caps,

  /// Runs of "!!!" or "?!?!".
  punctuation,

  /// Insults or swearing.
  harshWords,

  /// Absolute words: "always", "never", "you people".
  absolutes,
}

/// The text's heat: [points] 0 (none), 1 (some) or 2 (a lot), and the
/// [signals] that added it.
class TextHeatResult {
  const TextHeatResult({required this.points, required this.signals});

  static const TextHeatResult none = TextHeatResult(points: 0, signals: {});

  final int points;
  final Set<TextHeatSignal> signals;
}

class TextHeat {
  TextHeat._();

  /// Messages with fewer letters than this ignore the CAPS rule ("OK", "NO").
  static const int minLettersForCaps = 12;

  /// Share of capital letters (among letters) that reads as shouting.
  static const double strongCapsRatio = 0.6;
  static const double someCapsRatio = 0.3;

  /// Upper-case words this short or listed in [_acronyms] are not shouting.
  static const int minShoutWordLength = 3;

  static final RegExp _letter = RegExp('[A-Za-z]');
  static final RegExp _upper = RegExp('[A-Z]');
  static final RegExp _word = RegExp(r"[A-Za-z][A-Za-z']*");
  static final RegExp _punctuationRun = RegExp(r'[!?]{2,}');

  static const Set<String> _acronyms = {
    'ASAP',
    'FYI',
    'CEO',
    'CTO',
    'HR',
    'PDF',
    'ETA',
    'USA',
    'UK',
    'OK',
    'LOL',
    'BTW',
    'IMO',
    'TBH',
    'AM',
    'PM',
    'API',
    'URL',
    'ID',
    'QA',
    'PR',
    'EOD',
    'OOO',
    'NYC',
    'TV',
    'DM',
    'IT',
    'UI',
    'UX',
    'KPI',
  };

  /// Insults and swearing, lower case. Small and English-first by design.
  static const Set<String> _harshWords = {
    'idiot',
    'idiots',
    'idiotic',
    'stupid',
    'moron',
    'morons',
    'dumb',
    'pathetic',
    'useless',
    'incompetent',
    'ridiculous',
    'liar',
    'liars',
    'loser',
    'losers',
    'clown',
    'clowns',
    'disgusting',
    'garbage',
    'trash',
    'worthless',
    'lazy',
    'selfish',
    'hate',
    'hated',
    'shameful',
    'joke',
    'nonsense',
    'crap',
    'damn',
    'dammit',
    'wtf',
    'stfu',
    'fuck',
    'fucking',
    'fucked',
    'fck',
    'shit',
    'bullshit',
    'ass',
    'asshole',
    'bitch',
    'bastard',
    'dick',
    'jerk',
    'piss',
    'pissed',
    'screw',
    'sucks',
    'unbelievable',
    'unacceptable',
    'clueless',
    'fool',
    'fools',
  };

  /// Harsh phrases, matched on the lower-cased text.
  static final List<RegExp> _harshPhrases = [
    RegExp(r'\bshut up\b'),
    RegExp(r'\bhow dare you\b'),
    RegExp(r'\bsick of\b'),
    RegExp(r'\bfed up\b'),
    RegExp(r'\bscrew you\b'),
    RegExp(r'\bgo to hell\b'),
    RegExp(r'\bf[*#@]+k'),
    // Dismissing someone.
    RegExp(r'\bget out of (?:here|my)\b'),
    RegExp(r'\bget lost\b'),
    RegExp(r'\bleave me alone\b'),
    RegExp(r'\bmind your own business\b'),
    RegExp(r'\bdon.?t (?:ever )?(?:talk|speak|text|call) (?:to )?me\b'),
    RegExp(r'\bnever (?:come back|talk to me|contact me)\b'),
    // Questioning someone's sense.
    RegExp(r'\bin your (?:right )?senses\b'),
    RegExp(r'\bout of your mind\b'),
    RegExp(r'\blost your mind\b'),
    RegExp(r'\bare you (?:crazy|mad|insane|blind|deaf)\b'),
    RegExp(r'\bwhat.?s wrong with you\b'),
    RegExp(r'\bwhat is wrong with you\b'),
    RegExp(r'\bwho do you think you are\b'),
    // "You are messy", "you're such a mess": a word that is only an insult
    // when it describes the person.
    RegExp(
      r"\byou(?:'re| are| r)\s+(?:(?:so|such|really|being|always|just|a|an"
      r'|totally|completely)\s+)*(?:messy|a mess|rude|crazy|mad|insane'
      r'|annoying|careless|hopeless|irresponsible|terrible|awful|horrible'
      r'|mean|toxic|impossible|unprofessional|childish|immature|fake|ugly'
      r'|arrogant|shameless|nuts|psycho|disrespectful|unbearable|evil'
      r'|ignorant|senseless|brainless|spineless|heartless|cheap|a disgrace'
      r'|a failure|a waste)\b',
    ),
  ];

  static final List<RegExp> _absolutes = [
    RegExp(r'\balways\b'),
    RegExp(r'\bnever\b'),
    RegExp(r'\byou people\b'),
    RegExp(r'\bevery single time\b'),
    RegExp(r'\bevery time\b'),
    RegExp(r'\bnobody\b'),
    RegExp(r'\bno one ever\b'),
  ];

  static TextHeatResult analyze(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return TextHeatResult.none;
    }
    final lower = trimmed.toLowerCase();
    final signals = <TextHeatSignal>{};
    var raw = 0;

    final caps = _capsLevel(trimmed);
    if (caps > 0) {
      signals.add(TextHeatSignal.caps);
      raw += caps;
    }

    final runs = _punctuationRun.allMatches(trimmed).toList();
    if (runs.isNotEmpty) {
      signals.add(TextHeatSignal.punctuation);
      final longest = runs
          .map((m) => m.end - m.start)
          .reduce((a, b) => a > b ? a : b);
      raw += runs.length >= 2 || longest >= 3 ? 2 : 1;
    }

    final harsh = _harshCount(lower);
    if (harsh > 0) {
      signals.add(TextHeatSignal.harshWords);
      raw += harsh >= 2 ? 3 : 2;
    }

    if (_absolutes.any((pattern) => pattern.hasMatch(lower))) {
      signals.add(TextHeatSignal.absolutes);
      raw += 1;
    }

    final points = raw == 0
        ? 0
        : raw <= 2
        ? 1
        : 2;
    return TextHeatResult(points: points, signals: signals);
  }

  /// 0, 1 (some shouting) or 2 (mostly capitals).
  static int _capsLevel(String text) {
    final letters = _letter.allMatches(text).length;
    if (letters < minLettersForCaps) {
      return 0;
    }
    var upper = 0;
    var shoutWords = 0;
    for (final match in _word.allMatches(text)) {
      final word = match.group(0)!;
      final letterOnly = word.replaceAll("'", '');
      if (letterOnly.length < minShoutWordLength ||
          _acronyms.contains(letterOnly)) {
        continue;
      }
      final wordUpper = _upper.allMatches(letterOnly).length;
      upper += wordUpper;
      if (wordUpper == letterOnly.length) {
        shoutWords++;
      }
    }
    final ratio = upper / letters;
    if (ratio >= strongCapsRatio) {
      return 2;
    }
    if (ratio >= someCapsRatio || shoutWords >= 2) {
      return 1;
    }
    return 0;
  }

  static int _harshCount(String lower) {
    var count = 0;
    for (final match in _word.allMatches(lower)) {
      if (_harshWords.contains(match.group(0))) {
        count++;
      }
    }
    for (final phrase in _harshPhrases) {
      count += phrase.allMatches(lower).length;
    }
    return count;
  }
}
