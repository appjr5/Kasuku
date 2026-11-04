import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'brain.dart';
import 'coach.dart';
import 'models.dart';
import 'scoring.dart';

/// Authored Swahili coaching tips (assets/content/tips_sw.json), chosen by WHAT went wrong
/// (nothing heard / too short / too long / wrong sound / nearly right) and by language.
/// Instant, offline, can't crash. Generated and extended offline with swahili-gemma-1b (tool/gen_tips.py).
class TipBank {
  final Map<String, dynamic> d;
  TipBank(this.d);
  static final _r = Random();

  static Future<TipBank> load() async {
    try {
      return TipBank(jsonDecode(await rootBundle.loadString('assets/content/tips_sw.json')) as Map<String, dynamic>);
    } catch (_) {
      return TipBank({});
    }
  }

  List<String> _list(dynamic x) => x is List ? x.map((e) => e.toString()).toList() : <String>[];

  String pick(ErrKind k, String lang, String target, String heard, {String note = ''}) {
    final key = k.name;
    final generic = _list(d[key]);
    final specific = _list(((d['lang'] as Map?)?[lang] as Map?)?[key]);
    final pool = [...generic, ...specific, ...specific]; // language-specific advice is twice as likely
    var t = pool.isEmpty ? 'Jaribu tena.' : pool[_r.nextInt(pool.length)];
    t = t.replaceAll('{target}', target).replaceAll('{heard}', heard.isEmpty ? '...' : heard);
    if (note.isNotEmpty) t += ' Kumbuka: $note';
    return t;
  }
}

/// Fluid by design: the bank answers instantly; the optional brain only prefetches a fresh tip in the
/// background, which replaces the bank tip on the NEXT failed attempt of that word. No awaiting, no retries.
class TipService {
  final TipBank bank;
  final BrainClient brain;
  final Map<String, String> _fresh = {};
  TipService(this.bank, this.brain);

  Reaction tipFor(Lang lang, Item it, String heard, double score, int tries, Mood mood) {
    final text = _fresh.remove(it.id) ?? bank.pick(diagnose(it, heard, lang.whisper), lang.code, it.t, heard, note: it.n);
    if (brain.ready) {
      brain
          .tip(lang: lang, target: it.t, reading: it.r, heard: heard, score: score, tries: tries)
          .then((t) { if (t != null) _fresh[it.id] = t; })
          .catchError((_) {});
    }
    return Reaction(mood, text);
  }
}
