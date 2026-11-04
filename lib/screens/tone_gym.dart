import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio.dart';
import '../coach.dart';
import '../models.dart';
import '../pitch.dart';
import '../store.dart';
import '../widgets.dart';

ToneResult _analyse(Wav w) => Pitch.analyse(w);

/// Say one Mandarin syllable; the teacher draws your pitch curve over the target and judges the tone.
class ToneGymScreen extends StatefulWidget {
  final Lang lang;
  const ToneGymScreen({super.key, required this.lang});
  @override
  State<ToneGymScreen> createState() => _ToneGymScreenState();
}

class _ToneGymScreenState extends State<ToneGymScreen> {
  late final List<Item> items = widget.lang.toneItems;
  int idx = 0;
  Mood mood = Mood.think;
  String line = 'Sikiliza toni, kisha useme silabi hiyo!';
  bool rec = false, busy = false;
  ToneResult? res;

  Item get it => items[idx];
  int get want => int.parse(it.tone!);

  Future<void> _react(Reaction r) async {
    if (!mounted) return;
    setState(() { mood = r.mood; line = r.line; });
    if (context.read<AppState>().coachVoice) await context.read<Voice>().coach(r);
  }

  Future<void> _record() async {
    if (rec || busy) return;
    final ear = context.read<Ear>();
    if (!await ear.hasPermission()) { setState(() => line = 'Ninahitaji kipaza sauti. Kiruhusu kwenye mipangilio.'); return; }
    await context.read<Voice>().stop();
    await ear.start();
    setState(() { rec = true; res = null; mood = Mood.think; line = 'Sema sasa! Silabi moja tu...'; });
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    setState(() { rec = false; busy = true; });
    try {
      final path = await ear.stop();
      if (path == null) return;
      final wav = await Wav.read(path);
      final r = await compute(_analyse, wav);
      if (!mounted) return;
      setState(() => res = r);
      if (r.tone == null) {
        await _react(Coach.noVoice());
      } else {
        final ok = r.tone == want;
        context.read<AppState>().rate(it, ok);
        await _react(Coach.tone(want, r.tone!));
      }
    } catch (e) {
      if (mounted) setState(() => line = 'Hitilafu: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎚️ Mazoezi ya Toni')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Mascot(mood: mood, line: line),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (var i = 0; i < items.length; i++)
              Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text('${items[i].t} ${items[i].r}'), selected: i == idx, onSelected: (_) => setState(() { idx = i; res = null; }))),
          ]),
        ),
        const SizedBox(height: 12),
        Center(child: Text(it.t, style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold))),
        Center(child: Text(it.r, style: const TextStyle(fontSize: 28, fontStyle: FontStyle.italic))),
        Center(child: Text(it.m)),
        const SizedBox(height: 8),
        SizedBox(height: 180, child: CustomPaint(painter: _ContourPainter(want, res?.curve), child: const SizedBox.expand())),
        const Text('Kijivu = toni inayotakiwa · Zambarau = sauti yako', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton.filledTonal(onPressed: () => context.read<Voice>().say(it.t, widget.lang.tts, rate: 0.4), icon: const Icon(Icons.volume_up)),
          const SizedBox(width: 18),
          FloatingActionButton.large(heroTag: null, onPressed: _record, backgroundColor: rec ? Colors.red : null, child: busy ? const CircularProgressIndicator() : Icon(rec ? Icons.graphic_eq : Icons.mic, size: 44)),
          const SizedBox(width: 18),
          IconButton.filledTonal(onPressed: () => setState(() { idx = (idx + 1) % items.length; res = null; }), icon: const Icon(Icons.skip_next)),
        ]),
      ]),
    );
  }
}

class _ContourPainter extends CustomPainter {
  final int tone;
  final List<double>? user;
  _ContourPainter(this.tone, this.user);

  static List<double> ideal(int t) => List.generate(20, (k) {
        final x = k / 19.0;
        switch (t) {
          case 1: return 2.0;
          case 2: return -3 + 6 * x;
          case 3: return -4 + 5 * pow((x - 0.5) / 0.5, 2).toDouble();
          default: return 4 - 8 * x;
        }
      });

  void _line(Canvas c, Size s, List<double> v, Paint p) {
    final path = Path();
    for (var k = 0; k < v.length; k++) {
      final x = s.width * k / (v.length - 1);
      final y = s.height / 2 - (v[k].clamp(-8.0, 8.0) / 8.0) * (s.height / 2 - 8);
      if (k == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    c.drawPath(path, p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)), Paint()..color = Colors.white);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), Paint()..color = Colors.grey.shade300);
    _line(canvas, size, ideal(tone), Paint()..color = Colors.grey..strokeWidth = 12..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    if (user != null && user!.isNotEmpty) _line(canvas, size, user!, Paint()..color = Colors.deepPurple..strokeWidth = 5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _ContourPainter old) => true;
}
