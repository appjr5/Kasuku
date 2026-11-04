import 'dart:math';

enum Mood { happy, proud, meh, sad, strict, think }

class Reaction {
  final Mood mood;
  final String line;
  const Reaction(this.mood, this.line);
}

/// Mwalimu Neema, the teacher: kind to kids, but she never pretends a wrong answer was right.
/// All lines are Swahili. These are the instant, always-available reactions; the on-device
/// Swahili Gemma brain (brain.dart) adds a personalised tip on top when it is installed.
class Coach {
  static final _r = Random();
  static String _p(List<String> l) => l[_r.nextInt(l.length)];

  static const name = 'Mwalimu Neema'; // placeholder name: change it here and everywhere updates

  static Reaction greeting(int streak) => Reaction(Mood.happy, streak > 0
      ? 'Karibu tena! Mimi ni $name. Sema kwa sauti na wazi... mimi ni mkali!'
      : 'Habari! Mimi ni $name. Nitakufundisha kuzungumza lugha mpya. Chagua lugha!');

  /// Speaking verdict. [s] = similarity 0..1, [th] = pass mark, [tries] = attempts on this word.
  static Reaction forScore(double s, double th, int tries) {
    if (s >= 0.97) return Reaction(Mood.proud, _p(['Safi kabisa! Nimefurahi sana!', 'Hongera! Umeitamka vizuri mno!', 'Kamili! Hakuna kosa hata moja!']));
    if (s >= th) return Reaction(Mood.happy, _p(['Vizuri! Umeitamka wazi.', 'Sawa kabisa! Endelea hivyo!', 'Nzuri! Hongera.']));
    if (s >= th - 0.2) {
      return Reaction(Mood.meh, _p([
        'Hmm. Karibu, lakini bado haitoshi. Sikiliza tena, kisha jaribu tena.',
        'Karibu sana, lakini karibu haitoshi. Tena!',
        'Si sawasawa. Matamshi yako yamelegea kidogo. Jaribu tena.',
      ]));
    }
    if (tries >= 3) {
      return Reaction(Mood.strict, _p([
        'Hapana, hapana, hapana! Bado ni makosa. Sikiliza kwa makini. Polepole safari hii.',
        'Mara tatu na bado si sawa. Sikiliza sauti yangu vizuri.',
      ]));
    }
    return Reaction(Mood.sad, _p([
      'Hmmmm. Lo! Hiyo si sahihi. Nimekata tamaa kidogo. Jaribu tena.',
      'Oh jamani. Nimesikitika. Unaweza kufanya vizuri kuliko hivyo.',
      'Hapana, siyo hivyo. Nisikilize, kisha jaribu tena.',
    ]));
  }

  static Reaction noSound() => const Reaction(Mood.meh, 'Sikusikia chochote. Shika simu karibu na kinywa na useme kwa sauti!');
  static Reaction right() => Reaction(Mood.happy, _p(['Sahihi! Umefanya vizuri!', 'Ndiyo! Umekumbuka!', 'Jibu sahihi! Hongera!']));
  static Reaction wrong(String? why) =>
      Reaction(Mood.sad, 'Hmmm. Hapana. Hilo si jibu sahihi.${why != null && why.isNotEmpty ? ' $why' : ''} Kumbuka hili!');
  static Reaction memoryFail() => const Reaction(Mood.strict, 'Hmmmm. Umesahau mengi kutoka masomo yaliyopita. Lazima tupitie upya kabla ya kuendelea.');
  static Reaction memoryPass() => const Reaction(Mood.happy, 'Vizuri. Kumbukumbu yako ni imara. Sasa, mambo mapya!');
  static Reaction quizPass(bool perfect) => perfect
      ? const Reaction(Mood.proud, 'Alama kamili! Nimejivunia sana!')
      : const Reaction(Mood.happy, 'Kazi nzuri! Umefaulu.');
  static Reaction quizFail() => const Reaction(Mood.sad, 'Hmmmm. Haitoshi. Unahitaji kufanya mazoezi zaidi, kisha ujaribu tena.');

  static Reaction writeOk() => Reaction(Mood.proud, _p(['Maandishi mazuri! Naweza kuyasoma vizuri kabisa.', 'Safi na sahihi. Hongera!']));
  static Reaction writeBad(int tries) => tries >= 3
      ? const Reaction(Mood.strict, 'Siwezi kusoma hayo. Nakili umbo la kijivu polepole, mstari kwa mstari.')
      : const Reaction(Mood.sad, 'Hmmm. Siwezi kusoma hayo. Je, hiyo ni herufi sahihi kweli? Jaribu tena.');
  static Reaction strokes(int got, int need) =>
      Reaction(Mood.meh, 'Umbo ni sahihi, lakini umetumia mistari $got na inahitaji $need. Mpangilio wa mistari ni muhimu! Tena.');

  static const _toneNames = {1: 'ya juu na tambarare', 2: 'inayopanda', 3: 'inayoshuka kisha kupanda', 4: 'inayoshuka kwa kasi'};
  static String toneName(int t) => _toneNames[t] ?? '';
  static Reaction tone(int want, int got) => want == got
      ? const Reaction(Mood.proud, 'Toni kamilifu! Sauti yako ilifanya umbo sahihi kabisa!')
      : Reaction(Mood.sad, 'Hmmmm. Hiyo ilikuwa toni ${toneName(got)}. Nilitaka toni ${toneName(want)}. Tena!');
  static Reaction noVoice() => const Reaction(Mood.meh, 'Sikusikia sauti wazi. Sema silabi moja tu, kwa sauti zaidi kidogo.');

  /// Prompt for the Swahili Gemma brain: asks for a short, in-character coaching tip (2 sentences, Swahili).
  static String tipPrompt({required String langSw, required String target, required String reading, required String heard, required int pct, required int tries}) =>
      'Wewe ni $name, mwalimu mkali lakini mwenye upendo, unafundisha watoto $langSw. '
      'Mwanafunzi alitakiwa kusema: "$target"${reading.isEmpty ? '' : ' ($reading)'}. '
      'Alisema: "${heard.isEmpty ? 'hakuna' : heard}". Alama: $pct%. Jaribio la $tries. '
      'Andika sentensi MBILI tu fupi kwa Kiswahili: (1) onyesha kukata tamaa kidogo kama mwalimu mkali, '
      '(2) mpe ushauri mmoja wa wazi wa kurekebisha matamshi. Usitumie emoji wala nyota.';

  /// Cleans LLM output: strips markdown/emoji, keeps at most 2 sentences and ~220 characters.
  static String cleanTip(String raw) {
    var t = raw.replaceAll(RegExp(r'[*_#`>]+'), ' ').replaceAll(RegExp(r'[\u{1F000}-\u{1FFFF}\u{2600}-\u{27BF}]', unicode: true), '');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    final parts = RegExp(r'[^.!?]+[.!?]+').allMatches(t).map((m) => m.group(0)!.trim()).toList();
    if (parts.isNotEmpty) t = parts.take(2).join(' ');
    return t.length > 220 ? '${t.substring(0, 217)}...' : t;
  }
}
