import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio.dart';
import 'coach.dart';
import 'models.dart';
import 'panels.dart';
import 'store.dart';
import 'widgets.dart';

/// One quiz question. kind: mc | rev | listen | drill (multiple choice) | speak | write
class Q {
  final String kind, prompt, sub;
  final String? say, explain;
  final List<String> options;
  final int answer;
  final Item? item;
  const Q({required this.kind, this.prompt = '', this.sub = '', this.say, this.explain, this.options = const [], this.answer = 0, this.item});
}

final _rnd = Random();

({List<String> opts, int ans}) _shuffled(String right, List<String> wrong) {
  final o = [right, ...wrong]..shuffle(_rnd);
  return (opts: o, ans: o.indexOf(right));
}

List<String> _distractors(Item it, List<Item> pool, String Function(Item) f) {
  final c = pool.where((x) => x.id != it.id && f(x) != f(it)).map(f).toSet().toList()..shuffle(_rnd);
  return c.take(3).toList();
}

Q drillQ(Drill d) {
  final s = _shuffled(d.o[d.a], [...d.o]..removeAt(d.a));
  return Q(kind: 'drill', prompt: d.q, options: s.opts, answer: s.ans, explain: d.e);
}

/// Mixed quiz from [src] items (+ grammar drills). quick = tap-answers only (memory checks).
List<Q> buildQuiz(Lang l, List<Item> src, int n, {List<Drill> drills = const [], bool quick = false}) {
  final pool = [...src, ...l.allItems];
  final picks = [...src]..shuffle(_rnd);
  final out = <Q>[];
  for (final it in picks.take(n)) {
    final kinds = ['mc', 'rev', 'listen'];
    if (!quick && it.speak && it.tone == null) kinds.add('speak');
    if (!quick && it.w != null) kinds.add('write');
    switch (kinds[_rnd.nextInt(kinds.length)]) {
      case 'rev':
        final s = _shuffled(it.t, _distractors(it, pool, (x) => x.t));
        out.add(Q(kind: 'rev', prompt: it.m, options: s.opts, answer: s.ans, item: it, say: it.t));
        break;
      case 'listen':
        final s = _shuffled(it.t, _distractors(it, pool, (x) => x.t));
        out.add(Q(kind: 'listen', prompt: 'Sikiliza, kisha chagua ulichosikia', options: s.opts, answer: s.ans, item: it, say: it.t));
        break;
      case 'speak':
        out.add(Q(kind: 'speak', item: it));
        break;
      case 'write':
        out.add(Q(kind: 'write', item: it));
        break;
      default:
        final s = _shuffled(it.m, _distractors(it, pool, (x) => x.m));
        out.add(Q(kind: 'mc', prompt: it.t, sub: it.r, options: s.opts, answer: s.ans, item: it, say: it.t));
    }
  }
  final d = [...drills]..shuffle(_rnd);
  for (final x in d.take(quick ? 0 : 3)) { out.add(drillQ(x)); }
  out.shuffle(_rnd);
  return out;
}

class QuizScreen extends StatefulWidget {
  final Lang lang;
  final String title;
  final List<Q> qs;
  const QuizScreen({super.key, required this.lang, required this.title, required this.qs});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int i = 0, correct = 0;
  int? picked;
  Mood mood = Mood.think;
  String line = 'Chukua muda wako... lakini si mwingi sana!';
  final missed = <Item>[];
  Q get q => widget.qs[i];

  @override
  void initState() {
    super.initState();
    _enter();
  }

  void _enter() {
    if (q.kind == 'listen') WidgetsBinding.instance.addPostFrameCallback((_) => _say());
  }

  Future<void> _say() => context.read<Voice>().say(q.say!, widget.lang.tts, rate: 0.45);

  Future<void> _pick(int k) async {
    if (picked != null) return;
    final ok = k == q.answer;
    final st = context.read<AppState>();
    if (ok) { correct++; } else if (q.item != null) { missed.add(q.item!); }
    if (q.item != null) st.rate(q.item!, ok);
    final r = ok ? Coach.right() : Coach.wrong(q.explain);
    setState(() { picked = k; mood = r.mood; line = r.line; });
    if (st.coachVoice) await context.read<Voice>().coach(r);
  }

  void _panelDone(bool ok) {
    if (ok) { correct++; } else { missed.add(q.item!); }
    context.read<AppState>().rate(q.item!, ok);
    _next();
  }

  void _next() {
    if (i + 1 >= widget.qs.length) {
      Navigator.pop(context, QuizResult(correct, widget.qs.length, missed));
      return;
    }
    setState(() { i++; picked = null; mood = Mood.think; line = 'Inayofuata!'; });
    _enter();
  }

  @override
  Widget build(BuildContext context) {
    final isPanel = q.kind == 'speak' || q.kind == 'write';
    return Scaffold(
      appBar: AppBar(title: Text('${widget.title}  ${i + 1}/${widget.qs.length}')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          LinearProgressIndicator(value: i / widget.qs.length, minHeight: 8),
          const SizedBox(height: 16),
          if (isPanel)
            (q.kind == 'speak'
                ? SpeakPanel(key: ValueKey('s$i'), lang: widget.lang, item: q.item!, onDone: _panelDone)
                : WritePad(key: ValueKey('w$i'), lang: widget.lang, item: q.item!, traceStart: false, onDone: _panelDone))
          else ...[
            Mascot(mood: mood, line: line),
            const SizedBox(height: 20),
            if (q.kind == 'listen')
              Center(child: IconButton.filled(iconSize: 56, onPressed: _say, icon: const Icon(Icons.volume_up)))
            else
              Text(q.prompt, textAlign: TextAlign.center, style: TextStyle(fontSize: q.kind == 'mc' ? 42 : 24, fontWeight: FontWeight.bold)),
            if (q.sub.isNotEmpty) Text(q.sub, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
            if (q.kind == 'listen') Padding(padding: const EdgeInsets.only(top: 8), child: Text(q.prompt, textAlign: TextAlign.center)),
            if (q.kind == 'mc' || q.kind == 'rev')
              Center(child: TextButton.icon(onPressed: _say, icon: const Icon(Icons.volume_up), label: const Text('Sikiliza'))),
            const SizedBox(height: 12),
            for (var k = 0; k < q.options.length; k++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: picked == null ? null : (k == q.answer ? Colors.green.shade200 : (k == picked ? Colors.red.shade200 : null)),
                  ),
                  onPressed: picked == null ? () => _pick(k) : null,
                  child: Text(q.options[k], style: const TextStyle(fontSize: 20), textAlign: TextAlign.center),
                ),
              ),
            if (picked != null)
              Padding(padding: const EdgeInsets.only(top: 12), child: FilledButton.icon(onPressed: _next, icon: const Icon(Icons.arrow_forward), label: Text(i + 1 >= widget.qs.length ? 'Maliza' : 'Endelea'))),
          ],
        ]),
      ),
    );
  }
}
