import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio.dart';
import '../store.dart';
import '../tips.dart';
import 'core_lab.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mipangilio')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Ukali wa mwalimu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [ButtonSegment(value: 0, label: Text('Mpole 60%')), ButtonSegment(value: 1, label: Text('Mkali 80%')), ButtonSegment(value: 2, label: Text('Sensei 90%'))],
          selected: {st.strict},
          onSelectionChanged: (v) => st.setStrict(v.first),
        ),
        const Padding(padding: EdgeInsets.only(top: 6), child: Text('Asilimia ya chini ya kufaulu matamshi.', style: TextStyle(color: Colors.grey))),
        const Divider(height: 32),
        const Text('Masikio ya mwalimu (kutambua sauti)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        RadioListTile<String>(value: 'tiny', groupValue: st.model, onChanged: (v) => st.setModel(v!), title: const Text('Ndogo (haraka, MB 75)')),
        RadioListTile<String>(value: 'base', groupValue: st.model, onChanged: (v) => st.setModel(v!), title: const Text('Wastani (sahihi zaidi kwa Kichina na Kirusi, MB 140)')),
        const Divider(height: 32),
        SwitchListTile(value: st.coachVoice, onChanged: st.setCoachVoice, title: const Text('Mwalimu aongee kwa sauti')),
        ListTile(
          leading: const Icon(Icons.record_voice_over),
          title: const Text('Pakua sauti za simu'),
          subtitle: const Text('Kiswahili, Kihispania, Kijapani, Kichina, Kirusi'),
          onTap: context.read<Voice>().openVoiceInstaller,
        ),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Futa maendeleo yote'),
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Una uhakika?'),
                content: const Text('Nyota, XP na kumbukumbu zote zitafutwa.'),
                actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hapana')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Futa'))],
              ),
            );
            if (ok == true) await st.reset();
          },
        ),
        ListTile(
          leading: const Icon(Icons.science),
          title: const Text('Maabara ya majaribio (msanidi)'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CoreLab(st: st, voice: context.read<Voice>(), tips: context.read<TipService>()))),
        ),
      ]),
    );
  }
}
