import 'package:flutter/material.dart';
import '../audio.dart';
import '../coach.dart';
import '../models.dart';
import '../scoring.dart';
import '../store.dart';
import '../tips.dart';

/// Developer test bench for the core layer (voice stack, scoring, personality, tips). Opened from Settings.
class CoreLab extends StatefulWidget {
  final AppState st;
  final Voice voice;
  final TipService tips;
  const CoreLab({super.key, required this.st, required this.voice, required this.tips});
  @override
  State<CoreLab> createState() => _CoreLabState();
}

class _CoreLabState extends State<CoreLab> with WidgetsBindingObserver {
  static const langs = {'es': ('es-ES', 'es', 'Kihispania'), 'ja': ('ja-JP', 'ja', 'Kijapani'), 'zh': ('zh-CN', 'zh', 'Kichina'), 'ru': ('ru-RU', 'ru', 'Kirusi')};
  final ear = Ear();
  final target = TextEditingController(text: 'hola');
  String lang = 'es', log = '', ttsReport = 'inakagua...';
  bool rec = false, busy = false;
  int tries = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkVoices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from Android's voice installer: look again, no button press needed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _checkVoices(recheck: true);
  }

  Future<void> _checkVoices({bool recheck = false}) async {
    if (recheck) await widget.voice.recheckCoach();
    final b = StringBuffer('Sauti ya mwalimu (Kiswahili): ${widget.voice.coachLocale ?? 'HAIPO'}\n');
    for (final e in langs.entries) {
      b.writeln('${e.value.$3}: ${await widget.voice.available(e.value.$1) ? 'sawa' : 'HAIPO'}');
    }
    if (mounted) setState(() => ttsReport = b.toString());
  }

  void _say(String s) => setState(() => log = '$s\n\n$log');

  Future<void> _react(Reaction r) async {
    _say('[${r.mood.name}] ${r.line}');
    await widget.voice.coach(r);
  }

  Future<void> _toggle() async {
    if (busy) return;
    final (_, wh, _) = langs[lang]!;
    if (!rec) {
      if (!await ear.hasPermission()) { _say('Ruhusu kipaza sauti (allow microphone).'); return; }
      await widget.voice.stop();
      await ear.start();
      setState(() => rec = true);
      return;
    }
    setState(() { rec = false; busy = true; });
    try {
      final path = await ear.stop();
      if (path == null || !await ear.hasSignal(path)) { await _react(Coach.noSound()); return; }
      final heard = await ear.transcribe(path, wh, widget.st.model);
      final item = Item(id: 'lab', t: target.text.trim(), m: '');
      final s = bestScore(item, heard, wh);
      tries++;
      _say('Nimesikia: "$heard"  ->  ${(s * 100).round()}% (pass ${(widget.st.threshold * 100).round()}%)');
      final r = Coach.forScore(s, widget.st.threshold, tries);
      await _react(r);
      if (s < widget.st.threshold) {
        final l = Lang.fromJson({'code': lang, 'name': lang, 'native': '', 'flag': '', 'tts': '', 'whisper': wh, 'ink': '', 'color': 0, 'units': [], 'stories': [], 'songs': []});
        await _react(widget.tips.tipFor(l, item, heard, s, tries, r.mood)); // instant, from the tip bank
      } else {
        tries = 0;
      }
    } catch (e) {
      _say('Hitilafu: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.st;
    return Scaffold(
      appBar: AppBar(title: const Text('Core Lab · Mwalimu Neema')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(ttsReport),
        if (widget.voice.coachLocale == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FilledButton.icon(onPressed: widget.voice.openVoiceInstaller, icon: const Icon(Icons.download), label: const Text('Pakua sauti ya Kiswahili')),
          ),
        const Divider(height: 28),
        const Text('1. Personality (tap to hear him)', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(spacing: 8, children: [
          ActionChip(label: const Text('proud'), onPressed: () => _react(Coach.forScore(1.0, 0.8, 1))),
          ActionChip(label: const Text('happy'), onPressed: () => _react(Coach.forScore(0.85, 0.8, 1))),
          ActionChip(label: const Text('meh'), onPressed: () => _react(Coach.forScore(0.7, 0.8, 1))),
          ActionChip(label: const Text('disappointed'), onPressed: () => _react(Coach.forScore(0.3, 0.8, 1))),
          ActionChip(label: const Text('strict'), onPressed: () => _react(Coach.forScore(0.3, 0.8, 3))),
          ActionChip(label: const Text('memory fail'), onPressed: () => _react(Coach.memoryFail())),
        ]),
        const Divider(height: 28),
        const Text('2. Speaking test (ears + scoring + teacher + tip bank)', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(children: [
          DropdownButton<String>(value: lang, items: [for (final e in langs.entries) DropdownMenuItem(value: e.key, child: Text(e.value.$3))], onChanged: (v) => setState(() => lang = v!)),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: target, decoration: const InputDecoration(labelText: 'Word/phrase (hola, 你好, こんにちは, привет)'))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          IconButton.filledTonal(onPressed: () => widget.voice.say(target.text, langs[lang]!.$1), icon: const Icon(Icons.volume_up)),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: rec ? Colors.red : null),
            onPressed: _toggle,
            icon: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(rec ? Icons.stop : Icons.mic),
            label: Text(busy ? 'Ninafikiri... (first run downloads ~75 MB)' : (rec ? 'Simamisha' : 'Sema')),
          ),
        ]),
        SegmentedButton<int>(
          segments: const [ButtonSegment(value: 0, label: Text('Gentle 60')), ButtonSegment(value: 1, label: Text('Strict 80')), ButtonSegment(value: 2, label: Text('Sensei 90'))],
          selected: {st.strict},
          onSelectionChanged: (v) => setState(() => st.setStrict(v.first)),
        ),
        const Divider(height: 28),
        Text(log.isEmpty ? 'Log...' : log),
      ]),
    );
  }
}
