import 'dart:math';
import 'dart:ui' show PointMode;
import 'package:flutter/material.dart' hide Ink;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:provider/provider.dart';
import 'audio.dart';
import 'coach.dart';
import 'models.dart';
import 'scoring.dart';
import 'store.dart';
import 'tips.dart';
import 'widgets.dart';

/// Speaking trainer for one item: the teacher says it, you say it back, Whisper listens, the teacher judges and coaches.
class SpeakPanel extends StatefulWidget {
  final Lang lang;
  final Item item;
  final ValueChanged<bool> onDone; // true = passed, false = skipped after failing
  const SpeakPanel({super.key, required this.lang, required this.item, required this.onDone});
  @override
  State<SpeakPanel> createState() => _SpeakPanelState();
}

class _SpeakPanelState extends State<SpeakPanel> {
  Mood mood = Mood.think;
  String line = 'Sikiliza kwanza. Kisha rudia baada yangu!';
  bool rec = false, busy = false, passed = false;
  int tries = 0;
  double? score;
  String heard = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _demo());
  }

  Future<void> _demo({double rate = 0.45}) => context.read<Voice>().say(widget.item.t, widget.lang.tts, rate: rate);

  Future<void> _react(Reaction r) async {
    if (!mounted) return;
    setState(() { mood = r.mood; line = r.line; });
    if (context.read<AppState>().coachVoice) await context.read<Voice>().coach(r);
  }

  Future<void> _toggle() async {
    if (busy) return;
    final ear = context.read<Ear>();
    final st = context.read<AppState>();
    if (!rec) {
      if (!await ear.hasPermission()) {
        setState(() => line = 'Ninahitaji kipaza sauti ili nikusikie. Kiruhusu kwenye mipangilio ya simu.');
        return;
      }
      await context.read<Voice>().stop();
      await ear.start();
      if (!mounted) return;
      setState(() { rec = true; mood = Mood.think; line = 'Nakusikiliza... bonyeza mraba ukimaliza.'; });
      return;
    }
    setState(() { rec = false; busy = true; mood = Mood.think; line = 'Hmm, ngoja nifikiri... (mara ya kwanza napakua ubongo wangu wa sauti, MB 75 hivi)'; });
    try {
      final path = await ear.stop();
      if (path == null || !await ear.hasSignal(path)) {
        await _react(Coach.noSound());
        return;
      }
      final text = await ear.transcribe(path, widget.lang.whisper, st.model);
      final s = bestScore(widget.item, text, widget.lang.whisper);
      tries++;
      if (!mounted) return;
      setState(() { heard = text.isEmpty ? '...' : text; score = s; passed = s >= st.threshold; });
      final r = Coach.forScore(s, st.threshold, tries);
      await _react(r);
      if (!passed && mounted) {
        // instant, personalised tip from the Swahili tip bank (a fresh Gemma tip replaces it on later tries)
        await _react(context.read<TipService>().tipFor(widget.lang, widget.item, text, s, tries, r.mood));
        if (tries >= 2 && mounted) await _demo(rate: 0.3); // the teacher shows you again, slowly
      }
    } catch (e) {
      if (mounted) setState(() { mood = Mood.meh; line = 'Lo, masikio yangu yana tatizo: $e'; });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final th = context.read<AppState>().threshold;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Mascot(mood: mood, line: line),
      const SizedBox(height: 16),
      Text(it.t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold)),
      if (it.r.isNotEmpty) Text(it.r, style: TextStyle(fontSize: 18, color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
      Text(it.m, style: const TextStyle(fontSize: 16)),
      if (score != null) ScoreBar(score: score!, threshold: th, heard: heard),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton.filledTonal(onPressed: () => _demo(), icon: const Icon(Icons.volume_up), tooltip: 'Sikiliza'),
        const SizedBox(width: 18),
        FloatingActionButton.large(
          heroTag: null,
          onPressed: _toggle,
          backgroundColor: rec ? Colors.red : null,
          child: busy ? const CircularProgressIndicator() : Icon(rec ? Icons.stop : Icons.mic, size: 44),
        ),
        const SizedBox(width: 18),
        IconButton.filledTonal(onPressed: () => _demo(rate: 0.28), icon: const Icon(Icons.hearing), tooltip: 'Polepole'),
      ]),
      const SizedBox(height: 12),
      if (passed)
        FilledButton.icon(onPressed: () => widget.onDone(true), icon: const Icon(Icons.arrow_forward), label: const Text('Endelea'))
      else if (tries >= 3)
        TextButton(onPressed: () => widget.onDone(false), child: const Text('Nitalifanyia mazoezi baadaye')),
    ]);
  }
}

/// Handwriting trainer: draw the character, ML Kit Digital Ink recognises it, the teacher judges (and counts strokes).
class WritePad extends StatefulWidget {
  final Lang lang;
  final Item item;
  final bool traceStart;
  final ValueChanged<bool> onDone;
  const WritePad({super.key, required this.lang, required this.item, required this.onDone, this.traceStart = true});
  @override
  State<WritePad> createState() => _WritePadState();
}

class _WritePadState extends State<WritePad> {
  final List<List<Offset>> strokes = [];
  final List<List<int>> times = [];
  final sw = Stopwatch()..start();
  late bool trace = widget.traceStart;
  Mood mood = Mood.think;
  String line = 'Angalia umbo. Kisha liandike!';
  bool busy = false, passed = false, fallback = false;
  int tries = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<Voice>().say(widget.item.t, widget.lang.tts, rate: 0.4));
  }

  Future<void> _react(Reaction r) async {
    if (!mounted) return;
    setState(() { mood = r.mood; line = r.line; });
    if (context.read<AppState>().coachVoice) await context.read<Voice>().coach(r);
  }

  Future<void> _check() async {
    if (strokes.isEmpty || busy) return;
    setState(() { busy = true; line = 'Ngoja niangalie mwandiko wako...'; });
    final target = widget.item.w!.toLowerCase();
    try {
      final tag = widget.lang.ink;
      final mm = DigitalInkRecognizerModelManager();
      if (!await mm.isModelDownloaded(tag)) {
        setState(() => line = 'Napakua macho yangu ya mwandiko (mara moja tu, dogo)...');
        await mm.downloadModel(tag, isWifiRequired: false);
      }
      final recognizer = DigitalInkRecognizer(languageCode: tag);
      final ink = Ink();
      for (var i = 0; i < strokes.length; i++) {
        final s = Stroke();
        for (var j = 0; j < strokes[i].length; j++) {
          s.points.add(StrokePoint(x: strokes[i][j].dx, y: strokes[i][j].dy, t: times[i][j]));
        }
        ink.strokes.add(s);
      }
      final cands = await recognizer.recognize(ink);
      await recognizer.close();
      final texts = cands.map((c) => c.text.toLowerCase().replaceAll(' ', '')).take(3).toList();
      tries++;
      final shapeOk = texts.contains(target);
      final need = widget.item.strokes;
      if (shapeOk && need > 0 && strokes.length != need) {
        await _react(Coach.strokes(strokes.length, need));
      } else if (shapeOk) {
        passed = true;
        await _react(Coach.writeOk());
      } else {
        if (tries >= 3) trace = true;
        await _react(Coach.writeBad(tries));
      }
    } catch (e) {
      fallback = true; // no Google Play services / model unavailable -> honest self-check
      if (mounted) setState(() { mood = Mood.think; line = 'Macho yangu ya mwandiko hayafanyi kazi hapa. Linganisha na umbo mwenyewe, kwa uaminifu!'; trace = true; });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _clear() => setState(() { strokes.clear(); times.clear(); });

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final len = it.w!.runes.length;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Mascot(mood: mood, line: line),
      const SizedBox(height: 8),
      Text('${it.t}   ${it.r}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      Text(it.m + (it.strokes > 0 ? '  ·  mistari ${it.strokes}' : '')),
      const SizedBox(height: 8),
      AspectRatio(
        aspectRatio: len.clamp(1, 3).toDouble(),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.deepPurple, width: 2), borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GestureDetector(
              onPanStart: (d) => setState(() { strokes.add([d.localPosition]); times.add([sw.elapsedMilliseconds]); }),
              onPanUpdate: (d) => setState(() { strokes.last.add(d.localPosition); times.last.add(sw.elapsedMilliseconds); }),
              child: CustomPaint(painter: _PadPainter(strokes, trace ? it.w! : null), child: const SizedBox.expand()),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
        IconButton.filledTonal(onPressed: () => context.read<Voice>().say(it.t, widget.lang.tts, rate: 0.4), icon: const Icon(Icons.volume_up)),
        OutlinedButton.icon(onPressed: _clear, icon: const Icon(Icons.delete_outline), label: const Text('Futa')),
        OutlinedButton.icon(onPressed: () => setState(() { if (strokes.isNotEmpty) { strokes.removeLast(); times.removeLast(); } }), icon: const Icon(Icons.undo), label: const Text('Rudisha')),
        FilterChip(label: const Text('Fuatilia'), selected: trace, onSelected: (v) => setState(() => trace = v)),
      ]),
      const SizedBox(height: 8),
      if (passed)
        FilledButton.icon(onPressed: () => widget.onDone(true), icon: const Icon(Icons.arrow_forward), label: const Text('Endelea'))
      else if (fallback)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FilledButton(onPressed: () => widget.onDone(true), child: const Text('Nimeandika sawa')),
          const SizedBox(width: 12),
          OutlinedButton(onPressed: _clear, child: const Text('Bado')),
        ])
      else
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FilledButton.icon(onPressed: busy ? null : _check, icon: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check), label: const Text('Kagua')),
          if (tries >= 3) TextButton(onPressed: () => widget.onDone(false), child: const Text('Baadaye')),
        ]),
    ]);
  }
}

class _PadPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final String? guide;
  _PadPainter(this.strokes, this.guide);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = Colors.grey.shade300..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), grid);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), grid);
    if (guide != null) {
      final n = guide!.runes.length;
      final tp = TextPainter(
        text: TextSpan(text: guide, style: TextStyle(fontSize: min(size.height * 0.78, size.width * 0.85 / n), color: Colors.grey.withOpacity(0.28))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
    }
    final ink = Paint()..color = Colors.deepPurple..strokeWidth = 8..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length == 1) { canvas.drawPoints(PointMode.points, s, ink); continue; }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final p in s.skip(1)) { path.lineTo(p.dx, p.dy); }
      canvas.drawPath(path, ink);
    }
  }

  @override
  bool shouldRepaint(covariant _PadPainter old) => true;
}
