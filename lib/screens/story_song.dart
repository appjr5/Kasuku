import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio.dart';
import '../models.dart';
import '../panels.dart';
import '../quiz.dart';
import '../widgets.dart';

Future<void> _practiseLine(BuildContext context, Lang lang, String id, Line l) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(child: SpeakPanel(lang: lang, item: Item.line(id, l), onDone: (_) => Navigator.pop(context))),
      ),
    );

/// Shared reader for stories and songs: tap a line to hear it, 🎤 to say it, ▶ to hear the whole thing.
class _LinesView extends StatefulWidget {
  final Lang lang;
  final String id, title;
  final List<Line> lines;
  final bool song;
  final VoidCallback? onQuiz;
  const _LinesView({required this.lang, required this.id, required this.title, required this.lines, required this.song, this.onQuiz});
  @override
  State<_LinesView> createState() => _LinesViewState();
}

class _LinesViewState extends State<_LinesView> {
  late final Voice voice;
  bool showTr = true, playing = false;
  int now = -1;

  @override
  void initState() {
    super.initState();
    voice = context.read<Voice>();
  }

  Future<void> _playAll() async {
    if (playing) { setState(() => playing = false); await voice.stop(); return; }
    setState(() => playing = true);
    for (var i = 0; i < widget.lines.length && playing; i++) {
      setState(() => now = i);
      await voice.say(widget.lines[i].t, widget.lang.tts, rate: widget.song ? 0.36 : 0.42, pitch: widget.song ? 1.12 : 1.0);
      await Future<void>.delayed(Duration(milliseconds: widget.song ? 350 : 200));
    }
    if (mounted) setState(() { playing = false; now = -1; });
  }

  @override
  void dispose() {
    voice.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          FilledButton.icon(onPressed: _playAll, icon: Icon(playing ? Icons.stop : Icons.play_arrow), label: Text(playing ? 'Simamisha' : (widget.song ? 'Imba pamoja' : 'Sikiliza hadithi'))),
          const Spacer(),
          const Text('Tafsiri'),
          Switch(value: showTr, onChanged: (v) => setState(() => showTr = v)),
        ]),
        for (var i = 0; i < widget.lines.length; i++)
          Card(
            color: i == now ? Colors.amber.shade100 : null,
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              title: Text(widget.lines[i].t, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (widget.lines[i].r.isNotEmpty) Text(widget.lines[i].r, style: const TextStyle(fontStyle: FontStyle.italic)),
                if (showTr) Text(widget.lines[i].m, style: TextStyle(color: Colors.grey.shade800)),
              ]),
              onTap: () => voice.say(widget.lines[i].t, widget.lang.tts, rate: 0.4),
              trailing: IconButton.filledTonal(icon: const Icon(Icons.mic), onPressed: () => _practiseLine(context, widget.lang, '${widget.id}_$i', widget.lines[i])),
            ),
          ),
        if (widget.onQuiz != null) Padding(padding: const EdgeInsets.only(top: 12), child: FilledButton.icon(onPressed: widget.onQuiz, icon: const Icon(Icons.quiz), label: const Text('Maswali ya hadithi'))),
      ]),
    );
  }
}

class StoryListScreen extends StatelessWidget {
  final Lang lang;
  const StoryListScreen({super.key, required this.lang});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('📖 Hadithi')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final s in lang.stories)
            bigTile(
              emoji: s.emoji, title: s.title, sub: 'Mistari ${s.lines.length}',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _LinesView(
                    lang: lang, id: s.id, title: s.title, lines: s.lines, song: false,
                    onQuiz: () async {
                      final res = await Navigator.push<QuizResult>(context, MaterialPageRoute(builder: (_) => QuizScreen(lang: lang, title: s.title, qs: s.quiz.map(drillQ).toList())));
                      if (res != null && context.mounted) await showResult(context, 'Maswali ya hadithi', res.ratio);
                    },
                  ))),
            ),
        ]),
      );
}

class SongListScreen extends StatelessWidget {
  final Lang lang;
  const SongListScreen({super.key, required this.lang});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('🎵 Nyimbo')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final s in lang.songs)
            bigTile(
              emoji: s.emoji, title: s.title, sub: 'Mistari ${s.lines.length}',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _LinesView(lang: lang, id: s.id, title: s.title, lines: s.lines, song: true))),
            ),
          const Padding(padding: EdgeInsets.all(12), child: Text('Kumbuka: sauti ya simu husoma kwa mdundo, si kuimba kikamilifu. Imba pamoja nayo!', style: TextStyle(color: Colors.grey))),
        ]),
      );
}
