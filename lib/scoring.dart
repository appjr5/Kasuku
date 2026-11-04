import 'dart:math';
import 'models.dart';

/// Normalises text so punctuation / accents / script variants don't count as pronunciation mistakes.
String norm(String s, String lang) {
  var t = s.toLowerCase().replaceAll(RegExp(r'\[[^\]]*\]|\([^)]*\)'), '');
  t = t.replaceAll('\u0301', ''); // Russian stress marks
  if (lang == 'ru') t = t.replaceAll('ё', 'е');
  if (lang == 'es') {
    const m = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};
    m.forEach((k, v) => t = t.replaceAll(k, v));
  }
  if (lang == 'ja') {
    // fold katakana into hiragana so コーヒー == こーひー
    t = String.fromCharCodes(t.runes.map((c) => (c >= 0x30A1 && c <= 0x30F6) ? c - 0x60 : c));
  }
  return t.replaceAll(RegExp(r'[\s\p{P}\p{S}]', unicode: true), '');
}

int _lev(List<int> a, List<int> b) {
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0);
    cur[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final c = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = min(min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + c);
    }
    prev = cur;
  }
  return prev[b.length];
}

/// 1.0 = identical, 0.0 = nothing in common (character-level edit distance).
double similarity(String a, String b) {
  final x = a.runes.toList(), y = b.runes.toList();
  if (x.isEmpty && y.isEmpty) return 1;
  if (x.isEmpty || y.isEmpty) return 0;
  return 1 - _lev(x, y) / max(x.length, y.length);
}

/// 0..1 score of what the speech engine heard vs. everything we accept for this item.
double bestScore(Item it, String heard, String lang) {
  final h = norm(heard, lang);
  if (h.isEmpty) return 0;
  return it.targets.map((t) => similarity(norm(t, lang), h)).reduce(max);
}

/// How a spoken attempt went wrong; used to choose the coaching tip.
enum ErrKind { empty, short, long, wrong, close }

ErrKind diagnose(Item it, String heard, String lang) {
  final h = norm(heard, lang);
  if (h.isEmpty) return ErrKind.empty;
  // compare against the closest accepted spelling
  final ts = it.targets.map((t) => norm(t, lang)).toList()..sort((a, b) => similarity(b, h).compareTo(similarity(a, h)));
  final t = ts.first;
  final s = similarity(t, h);
  if (s >= 0.65) return ErrKind.close;
  if (h.runes.length <= t.runes.length * 0.6) return ErrKind.short;
  if (h.runes.length >= t.runes.length * 1.5) return ErrKind.long;
  return ErrKind.wrong;
}
