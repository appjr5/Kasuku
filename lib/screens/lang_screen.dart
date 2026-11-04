import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio.dart';
import '../coach.dart';
import '../models.dart';
import '../quiz.dart';
import '../store.dart';
import '../widgets.dart';
import 'cards.dart';
import 'drills.dart';
import 'story_song.dart';
import 'tone_gym.dart';

class LangScreen extends StatelessWidget {
  final Lang lang;
  const LangScreen({super.key, required this.lang});

  /// Memory gate: before a new unit the teacher quizzes you on OLD material. Forget too much -> review first.
  Future<void> _open(BuildContext context, int ui) async {
    final st = context.read<AppState>();
    if (!st.unitUnlocked(lang, ui)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔒 Fanya mtihani wa somo lililopita kwanza. Hakuna njia za mkato!')));
      return;
    }
    final prior = st.learned(lang, ui);
    if (prior.length >= 3) {
      final qs = buildQuiz(lang, st.memoryPool(lang, ui, 8), 4, quick: true);
      final res = await Navigator.push<QuizResult>(context, MaterialPageRoute(builder: (_) => QuizScreen(lang: lang, title: 'Kumbukumbu', qs: qs)));
      if (res == null || !context.mounted) return;
      if (res.ratio < 0.5) {
        final r = Coach.memoryFail();
        if (st.coachVoice) context.read<Voice>().coach(r);
        await showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Wakati wa kurudia 📚'), content: Mascot(mood: r.mood, line: r.line), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Sawa'))]));
        if (!context.mounted) return;
        final review = res.missed.isNotEmpty ? res.missed : prior.take(6).toList();
        await Navigator.push(context, MaterialPageRoute(builder: (_) => CardsScreen(lang: lang, items: review, title: 'Kurudia')));
        if (!context.mounted) return;
      } else if (st.coachVoice) {
        context.read<Voice>().coach(Coach.memoryPass());
      }
    }
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => UnitScreen(lang: lang, unit: lang.units[ui])));
  }

  Future<void> _review(BuildContext context) async {
    final st = context.read<AppState>();
    final due = st.dueItems(lang, max: 10);
    if (due.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hakuna cha kurudia bado. Maliza kadi kwanza! 🃏')));
      return;
    }
    final res = await Navigator.push<QuizResult>(context, MaterialPageRoute(builder: (_) => QuizScreen(lang: lang, title: 'Kurudia kila siku', qs: buildQuiz(lang, due, due.length))));
    if (res != null && context.mounted) await showResult(context, 'Umemaliza kurudia', res.ratio);
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final due = st.dueCount(lang);
    return Scaffold(
      appBar: AppBar(title: Text('${lang.flag} ${lang.swName}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        bigTile(emoji: '🔁', title: 'Kurudia kila siku', sub: due > 0 ? 'Maneno $due yanakusubiri' : 'Hakuna cha kurudia sasa hivi', color: Colors.amber.shade50, onTap: () => _review(context)),
        if (lang.toneItems.isNotEmpty)
          bigTile(emoji: '🎚️', title: 'Mazoezi ya Toni', sub: 'Fundisha toni 4. Ninakagua sauti yako!', color: Colors.orange.shade50, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ToneGymScreen(lang: lang)))),
        const Padding(padding: EdgeInsets.fromLTRB(4, 12, 4, 4), child: Text('Masomo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        for (var i = 0; i < lang.units.length; i++)
          bigTile(
            emoji: st.unitUnlocked(lang, i) ? lang.units[i].emoji : '🔒',
            title: '${i + 1}. ${lang.units[i].title}',
            sub: 'Maneno ${lang.units[i].items.length}',
            trailing: Text(starText(st.stars[lang.units[i].id] ?? 0)),
            onTap: () => _open(context, i),
          ),
        const Padding(padding: EdgeInsets.fromLTRB(4, 12, 4, 4), child: Text('Burudani', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        bigTile(emoji: '📖', title: 'Hadithi', sub: 'Soma, sikiliza, sema, kisha jibu maswali', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryListScreen(lang: lang)))),
        bigTile(emoji: '🎵', title: 'Nyimbo', sub: 'Imba pamoja na mwalimu', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SongListScreen(lang: lang)))),
      ]),
    );
  }
}

class UnitScreen extends StatelessWidget {
  final Lang lang;
  final Unit unit;
  const UnitScreen({super.key, required this.lang, required this.unit});

  @override
  Widget build(BuildContext context) {
    final st = context.read<AppState>();
    final speakable = unit.items.where((i) => i.speak && i.tone == null).toList();
    final writable = unit.items.where((i) => i.w != null).toList();
    return Scaffold(
      appBar: AppBar(title: Text('${unit.emoji} ${unit.title}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: Color(lang.color).withOpacity(0.12), child: Padding(padding: const EdgeInsets.all(16), child: Text(unit.intro, style: const TextStyle(fontSize: 16, height: 1.4)))),
        const SizedBox(height: 8),
        bigTile(emoji: '🃏', title: 'Kadi', sub: 'Jifunze kadi ${unit.items.length}', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CardsScreen(lang: lang, items: unit.items, title: unit.title)))),
        if (speakable.isNotEmpty) bigTile(emoji: '🎤', title: 'Mazoezi ya kuongea', sub: 'Sema. Mwalimu anahukumu matamshi yako.', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SpeakScreen(lang: lang, items: speakable)))),
        if (writable.isNotEmpty) bigTile(emoji: '✍️', title: 'Mazoezi ya kuandika', sub: 'Chora kwa kidole chako', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WriteScreen(lang: lang, items: writable)))),
        if (unit.items.any((i) => i.tone != null)) bigTile(emoji: '🎚️', title: 'Mazoezi ya Toni', sub: 'Sema kila toni, ninakagua sauti yako', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ToneGymScreen(lang: lang)))),
        bigTile(
          emoji: '📝', title: 'Mtihani wa somo', sub: 'Pata 70% kufungua somo lijalo', color: Colors.green.shade50,
          trailing: Text(starText(st.stars[unit.id] ?? 0)),
          onTap: () async {
            final qs = buildQuiz(lang, unit.items, 6, drills: unit.drills);
            final res = await Navigator.push<QuizResult>(context, MaterialPageRoute(builder: (_) => QuizScreen(lang: lang, title: unit.title, qs: qs)));
            if (res == null || !context.mounted) return;
            final s = starsFor(res.ratio);
            if (s > 0) st.setStars(unit.id, s);
            await showResult(context, 'Mtihani wa somo', res.ratio, extra: s > 0 ? null : 'Fanya mazoezi kwa kadi na kuongea, kisha ujaribu tena.');
          },
        ),
      ]),
    );
  }
}
