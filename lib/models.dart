/// Content models. Every text field is resolved at load time: the Swahili field ('ms', 'ns', 'ts', 'is', 'qs',
/// 'os', 'es') is used when present, otherwise the English one. Screens just read .m / .n / .title / .q, and the
/// whole app switches to Swahili as the Swahili fields get filled in the JSON.
String _pick(Map<String, dynamic> j, String swKey, String enKey, bool sw, [String def = '']) =>
    ((sw ? j[swKey] : null) ?? j[enKey] ?? def) as String;

class Line {
  final String t, r, m;
  final List<String> alt;
  const Line(this.t, this.r, this.m, this.alt);
  factory Line.fromJson(Map<String, dynamic> j, bool sw) =>
      Line(j['t'] as String, (j['r'] ?? '') as String, _pick(j, 'ms', 'm', sw), List<String>.from(j['alt'] ?? const []));
}

class Item {
  final String id, t, r, m, n, en; // m = meaning shown (Swahili), en = English meaning, n = note
  final List<String> alt; // other accepted spellings (traditional hanzi, kana reading...)
  final bool speak; // can the speech engine judge it?
  final String? w; // what to write (null = not a writing item)
  final int strokes; // expected stroke count (0 = unknown)
  final String? tone; // '1'..'4' for Tone Gym items
  const Item({required this.id, required this.t, required this.m, this.en = '', this.r = '', this.n = '', this.alt = const [], this.speak = true, this.w, this.strokes = 0, this.tone});

  factory Item.fromJson(String uid, int i, Map<String, dynamic> j, bool sw) => Item(
        id: '${uid}_$i',
        t: j['t'] as String,
        r: (j['r'] ?? '') as String,
        m: _pick(j, 'ms', 'm', sw),
        en: (j['m'] ?? '') as String,
        n: _pick(j, 'ns', 'n', sw),
        alt: List<String>.from(j['alt'] ?? const []),
        speak: (j['s'] ?? 1) == 1,
        w: j['w'] as String?,
        strokes: (j['k'] ?? 0) as int,
        tone: j['tone'] as String?,
      );

  factory Item.line(String id, Line l) => Item(id: id, t: l.t, r: l.r, m: l.m, alt: l.alt);
  List<String> get targets => [t, ...alt];
}

class Drill {
  final String q, e;
  final List<String> o;
  final int a;
  const Drill(this.q, this.o, this.a, this.e);
  factory Drill.fromJson(Map<String, dynamic> j, bool sw) {
    final os = sw ? j['os'] : null;
    return Drill(_pick(j, 'qs', 'q', sw), List<String>.from((os ?? j['o']) as List), j['a'] as int, _pick(j, 'es', 'e', sw));
  }
}

class Unit {
  final String id, title, emoji, intro;
  final List<Item> items;
  final List<Drill> drills;
  const Unit(this.id, this.title, this.emoji, this.intro, this.items, this.drills);
  factory Unit.fromJson(Map<String, dynamic> j, bool sw) {
    final id = j['id'] as String;
    final raw = j['items'] as List;
    return Unit(id, _pick(j, 'ts', 'title', sw), j['emoji'] as String, _pick(j, 'is', 'intro', sw),
        List.generate(raw.length, (i) => Item.fromJson(id, i, raw[i] as Map<String, dynamic>, sw)),
        (j['drills'] as List).map((d) => Drill.fromJson(d as Map<String, dynamic>, sw)).toList());
  }
}

class Story {
  final String id, title, emoji;
  final List<Line> lines;
  final List<Drill> quiz;
  const Story(this.id, this.title, this.emoji, this.lines, this.quiz);
  factory Story.fromJson(Map<String, dynamic> j, bool sw) => Story(j['id'] as String, _pick(j, 'ts', 'title', sw), j['emoji'] as String,
      (j['lines'] as List).map((l) => Line.fromJson(l as Map<String, dynamic>, sw)).toList(),
      (j['quiz'] as List).map((d) => Drill.fromJson(d as Map<String, dynamic>, sw)).toList());
}

class Song {
  final String id, title, emoji;
  final List<Line> lines;
  const Song(this.id, this.title, this.emoji, this.lines);
  factory Song.fromJson(Map<String, dynamic> j, bool sw) => Song(j['id'] as String, _pick(j, 'ts', 'title', sw), j['emoji'] as String,
      (j['lines'] as List).map((l) => Line.fromJson(l as Map<String, dynamic>, sw)).toList());
}

class Lang {
  final String code, name, native, flag, tts, whisper, ink;
  final int color;
  final List<Unit> units;
  final List<Story> stories;
  final List<Song> songs;
  const Lang(this.code, this.name, this.native, this.flag, this.tts, this.whisper, this.ink, this.color, this.units, this.stories, this.songs);

  /// Name of the language in Swahili (UI + the instructor's prompts).
  static const swNames = {'es': 'Kihispania', 'ja': 'Kijapani', 'zh': 'Kichina', 'ru': 'Kirusi'};
  String get swName => swNames[code] ?? name;

  factory Lang.fromJson(Map<String, dynamic> j, {bool sw = true}) => Lang(
        j['code'] as String, j['name'] as String, j['native'] as String, j['flag'] as String, j['tts'] as String,
        j['whisper'] as String, j['ink'] as String, j['color'] as int,
        (j['units'] as List).map((u) => Unit.fromJson(u as Map<String, dynamic>, sw)).toList(),
        (j['stories'] as List).map((s) => Story.fromJson(s as Map<String, dynamic>, sw)).toList(),
        (j['songs'] as List).map((s) => Song.fromJson(s as Map<String, dynamic>, sw)).toList(),
      );
  List<Item> get allItems => units.expand((u) => u.items).toList();
  List<Item> get toneItems => allItems.where((i) => i.tone != null).toList();
}
