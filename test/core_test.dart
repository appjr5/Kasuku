import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasuku/brain.dart';
import 'package:kasuku/coach.dart';
import 'package:kasuku/models.dart';
import 'package:kasuku/pitch.dart';
import 'package:kasuku/scoring.dart';
import 'package:kasuku/store.dart';
import 'package:kasuku/tips.dart';

Lang fixture() => Lang.fromJson({
      'code': 'es', 'name': 'Spanish', 'native': 'Español', 'flag': '🇪🇸', 'tts': 'es-ES', 'whisper': 'es', 'ink': 'es', 'color': 0xFFE5484D,
      'units': [
        {
          'id': 'u1', 'title': 'Sounds', 'ts': 'Sauti', 'emoji': '🔤', 'intro': 'Intro', 'is': 'Utangulizi',
          'items': [
            {'t': 'hola', 'r': 'OH-lah', 'm': 'hello', 'ms': 'habari'},
            {'t': 'perro', 'r': 'PEH-rro', 'm': 'dog'}, // no Swahili yet -> falls back to English
            {'t': 'casa', 'r': 'KAH-sa', 'm': 'house', 'ms': 'nyumba'},
          ],
          'drills': [{'q': 'Q?', 'qs': 'Swali?', 'o': ['a', 'b'], 'a': 0, 'e': ''}],
        },
        {'id': 'u2', 'title': 'Verbs', 'emoji': '⚙️', 'intro': 'x', 'items': [{'t': 'hablo', 'm': 'I speak', 'ms': 'ninaongea'}], 'drills': []},
      ],
      'stories': [], 'songs': [],
    });

Wav synth(double Function(double x) hz, {double dur = 0.6, int sr = 16000}) {
  final pad = (0.15 * sr).round(), n = (dur * sr).round();
  final out = List<double>.filled(n + 2 * pad, 0);
  var ph = 0.0;
  final rnd = Random(1);
  for (var i = 0; i < n; i++) {
    ph += 2 * pi * hz(i / n) / sr;
    final env = min(1.0, min(i / (0.03 * sr), (n - i) / (0.05 * sr)));
    out[pad + i] = 0.4 * env * (sin(ph) + 0.5 * sin(2 * ph) + 0.3 * sin(3 * ph)) / 1.6 + (rnd.nextDouble() - 0.5) * 0.02;
  }
  return Wav(out, sr);
}

void main() {
  group('shipped curriculum', () {
    for (final c in AppState.order) {
      test('$c.json parses, ids unique, drill answers valid, Swahili present', () {
        final l = Lang.fromJson(jsonDecode(File('assets/content/$c.json').readAsStringSync()) as Map<String, dynamic>);
        expect(l.units, isNotEmpty);
        final ids = l.allItems.map((i) => i.id).toList();
        expect(ids.toSet().length, ids.length);
        for (final u in l.units) {
          expect(u.items, isNotEmpty);
          for (final d in u.drills) { expect(d.a, inInclusiveRange(0, d.o.length - 1)); }
          for (final i in u.items) { expect(i.m, isNotEmpty); }
        }
        for (final s in l.stories) { for (final d in s.quiz) { expect(d.a, inInclusiveRange(0, d.o.length - 1)); } }
        expect(l.songs, isNotEmpty);
      });
    }
  });

  group('scoring', () {
    test('punctuation, case and Spanish accents are ignored', () {
      expect(norm('¡Hola!', 'es'), 'hola');
      expect(norm('Adiós.', 'es'), 'adios');
    });
    test('katakana folds to hiragana; Russian ё == е', () {
      expect(norm('コーヒー', 'ja'), norm('こーひー', 'ja'));
      expect(norm('ёлка', 'ru'), norm('елка', 'ru'));
    });
    test('Mandarin traditional alt is accepted', () {
      const it = Item(id: 'x', t: '谢谢', m: 'asante', alt: ['謝謝']);
      expect(bestScore(it, '謝謝', 'zh'), 1.0);
    });
    test('bad pronunciation scores low, near miss scores in between', () {
      const it = Item(id: 'x', t: 'perro', m: 'mbwa');
      expect(bestScore(it, 'perro', 'es'), 1.0);
      expect(bestScore(it, 'pero', 'es'), closeTo(0.8, 0.01));
      expect(bestScore(it, 'casa', 'es'), lessThan(0.4));
      expect(bestScore(it, '', 'es'), 0);
    });
  });

  group('models', () {
    test('Swahili preferred, English fallback', () {
      final l = fixture();
      expect(l.units[0].title, 'Sauti');
      expect(l.units[0].items[0].m, 'habari');
      expect(l.units[0].items[1].m, 'dog');
      expect(l.units[0].drills[0].q, 'Swali?');
      expect(l.swName, 'Kihispania');
      final en = Lang.fromJson({...{'code': 'es', 'name': 'S', 'native': 'S', 'flag': '', 'tts': '', 'whisper': '', 'ink': '', 'color': 1, 'units': [], 'stories': [], 'songs': []}}, sw: false);
      expect(en.units, isEmpty);
    });
  });

  group('spaced repetition', () {
    test('right answers climb boxes; a lapse drops two and returns in 10 min', () {
      final st = AppState();
      final it = fixture().units[0].items[0];
      final t0 = DateTime(2026, 10, 23, 8);
      st.seen(it, now: t0);
      expect(st.srs[it.id]![0], 0);
      for (var i = 0; i < 4; i++) { st.rate(it, true, now: t0); }
      expect(st.srs[it.id]![0], 4);
      expect(st.srs[it.id]![1], t0.add(const Duration(minutes: 20160)).millisecondsSinceEpoch);
      st.rate(it, false, now: t0);
      expect(st.srs[it.id]![0], 2);
      expect(st.srs[it.id]![1], t0.add(const Duration(minutes: 10)).millisecondsSinceEpoch);
      expect(st.stats[it.id], [4, 1]);
    });
    test('due list, memory pool and unit gating', () {
      final st = AppState();
      final l = fixture();
      st.langs['es'] = l;
      final t0 = DateTime(2026, 10, 23, 8);
      for (final i in l.units[0].items) { st.seen(i, now: t0); }
      expect(st.dueItems(l, now: t0), isEmpty);
      expect(st.dueItems(l, now: t0.add(const Duration(minutes: 11))).length, 3);
      st.rate(l.units[0].items[1], false, now: t0); // 'perro' is a weak item
      final pool = st.memoryPool(l, 1, 2, now: t0.add(const Duration(hours: 1)));
      expect(pool.map((i) => i.t), contains('perro'));
      expect(st.weakItems(l).first.t, 'perro');
      expect(st.unitUnlocked(l, 1), isFalse);
      st.setStars('u1', 1);
      expect(st.unitUnlocked(l, 1), isTrue);
    });
    test('streak counts consecutive days', () {
      final st = AppState();
      final it = fixture().units[0].items[0];
      st.rate(it, true, now: DateTime(2026, 10, 21, 9));
      st.rate(it, true, now: DateTime(2026, 10, 22, 9));
      expect(st.streak, 2);
      st.rate(it, true, now: DateTime(2026, 10, 25, 9));
      expect(st.streak, 1);
    });
  });


  group('diagnosis + tips', () {
    const it = Item(id: 'p', t: 'perro', m: 'mbwa', n: 'rr inavuma');
    test('error kinds', () {
      expect(diagnose(it, '', 'es'), ErrKind.empty);
      expect(diagnose(it, 'pero', 'es'), ErrKind.close);
      expect(diagnose(it, 'pe', 'es'), ErrKind.short);
      expect(diagnose(it, 'perro por favor gracias', 'es'), ErrKind.long);
      expect(diagnose(it, 'xyzq', 'es'), ErrKind.wrong);
    });
    final bank = TipBank({
      'wrong': ['Nilisikia "{heard}", nilitaka "{target}".'],
      'lang': {'zh': {'wrong': ['Toni!']}},
    });
    test('placeholders and item note are filled', () {
      final t = bank.pick(ErrKind.wrong, 'es', 'perro', 'casa', note: 'rr inavuma');
      expect(t, 'Nilisikia "casa", nilitaka "perro". Kumbuka: rr inavuma');
    });
    test('missing bank never throws', () {
      expect(TipBank({}).pick(ErrKind.close, 'es', 'a', 'b'), isNotEmpty);
    });
    test('fresh brain tip is used on the NEXT failure; slow/failed brain changes nothing', () async {
      final l = fixture();
      final fake = _FakeBrain();
      final svc = TipService(bank, fake);
      final first = svc.tipFor(l, it, 'casa', 0.2, 1, Mood.sad);
      expect(first.line, contains('Nilisikia')); // instant, from the bank
      await Future<void>.delayed(Duration.zero);
      final second = svc.tipFor(l, it, 'casa', 0.2, 2, Mood.sad);
      expect(second.line, 'TIP YA MODELI'); // fresh tip arrived in the background
      fake.fail = true; // from now on the brain "crashes" on every call
      await Future<void>.delayed(Duration.zero); // the prefetch started by the 2nd call lands
      expect(svc.tipFor(l, it, 'casa', 0.2, 3, Mood.sad).line, 'TIP YA MODELI');
      await Future<void>.delayed(Duration.zero); // 3rd call's prefetch threw: nothing stored, nothing shown
      expect(svc.tipFor(l, it, 'casa', 0.2, 4, Mood.sad).line, contains('Nilisikia')); // failure is invisible
    });
  });

  group('coach', () {
    test('strictness changes the verdict', () {
      expect(Coach.forScore(0.7, 0.6, 1).mood, Mood.happy);
      expect(Coach.forScore(0.7, 0.8, 1).mood, Mood.meh);
      expect(Coach.forScore(0.3, 0.8, 1).mood, Mood.sad);
      expect(Coach.forScore(0.3, 0.8, 3).mood, Mood.strict);
      expect(Coach.forScore(1.0, 0.8, 1).mood, Mood.proud);
    });
    test('LLM tip cleanup', () {
      final t = Coach.cleanTip('**Hmm!** Umekosea 😞 sana. Jaribu tena polepole. Sentensi ya tatu.');
      expect(t.contains('*'), isFalse);
      expect(t.contains('😞'), isFalse);
      expect(t.contains('Sentensi ya tatu'), isFalse);
    });
    test('prompt is Swahili and carries the facts', () {
      final p = Coach.tipPrompt(langSw: 'Kichina', target: '你好', reading: 'nǐ hǎo', heard: '你号', pct: 50, tries: 2);
      expect(p, contains('Kichina'));
      expect(p, contains('你号'));
      expect(p, contains('50%'));
    });
  });

  group('tone analyser (synthetic voices)', () {
    for (final base in [120.0, 180.0, 260.0]) {
      test('four tones at base ${base.round()} Hz', () {
        final c = <int, double Function(double)>{
          1: (x) => base * 1.15,
          2: (x) => base * (0.9 + 0.4 * x),
          3: (x) => base * (1.0 - 0.45 * sin(pi * min(x, 1.0) * 0.95) + 0.15 * x),
          4: (x) => base * (1.35 - 0.55 * x),
        };
        c.forEach((want, f) => expect(Pitch.analyse(synth(f)).tone, want, reason: 'tone $want'));
      });
    }
    test('silence is rejected', () {
      expect(Pitch.analyse(Wav(List<double>.filled(16000, 0), 16000)).tone, isNull);
    });
  });
}

class _FakeBrain implements BrainClient {
  bool fail = false;
  @override
  bool get ready => true;
  @override
  Future<String?> tip({required Lang lang, required String target, required String reading, required String heard, required double score, required int tries}) async {
    if (fail) throw StateError('native crash');
    return 'TIP YA MODELI';
  }
}
