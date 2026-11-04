import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio.dart';
import '../coach.dart';
import '../store.dart';
import '../widgets.dart';
import 'lang_screen.dart';
import 'settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<String> missing = [];
  bool swMissing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from Android's voice installer: look again automatically.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _check(recheck: true);
  }

  Future<void> _check({bool recheck = false}) async {
    final voice = context.read<Voice>();
    final st = context.read<AppState>();
    if (recheck) await voice.recheckCoach();
    final miss = <String>[];
    for (final c in AppState.order) {
      final l = st.langs[c];
      if (l != null && !await voice.available(l.tts)) miss.add(l.swName);
    }
    if (mounted) setState(() { missing = miss; swMissing = voice.coachLocale == null; });
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final g = Coach.greeting(st.streak);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasuku', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())))],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Chip(label: Text('🔥 siku ${st.streak} mfululizo')),
          const SizedBox(width: 12),
          Chip(label: Text('⭐ ${st.xp} XP')),
        ]),
        const SizedBox(height: 12),
        Mascot(mood: g.mood, line: g.line),
        if (swMissing || missing.isNotEmpty)
          Card(
            color: Colors.amber.shade100,
            margin: const EdgeInsets.only(top: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(swMissing ? 'Simu yako haina sauti ya Kiswahili, kwa hiyo mwalimu atakuwa kimya.' : 'Simu yako haina sauti za: ${missing.join(', ')}. Bila hizo siwezi kuongea lugha hizo.', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                FilledButton.icon(onPressed: context.read<Voice>().openVoiceInstaller, icon: const Icon(Icons.download), label: const Text('Pakua sauti')),
              ]),
            ),
          ),
        const SizedBox(height: 8),
        for (final c in AppState.order)
          if (st.langs[c] != null) _LangCard(code: c),
        if (st.langs.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Masomo hayajapatikana. (assets/content/*.json)')),
      ]),
    );
  }
}

class _LangCard extends StatelessWidget {
  final String code;
  const _LangCard({required this.code});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final l = st.langs[code]!;
    final due = st.dueCount(l);
    return Card(
      color: Color(l.color).withOpacity(0.14),
      margin: const EdgeInsets.symmetric(vertical: 7),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LangScreen(lang: l))),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Text(l.flag, style: const TextStyle(fontSize: 44)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${l.swName}  ·  ${l.native}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: st.progress(l), minHeight: 10, color: Color(l.color))),
                if (due > 0) Padding(padding: const EdgeInsets.only(top: 6), child: Text('🔁 maneno $due ya kurudia', style: const TextStyle(fontWeight: FontWeight.w600))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
