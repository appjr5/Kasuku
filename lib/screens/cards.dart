import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio.dart';
import '../models.dart';
import '../store.dart';

/// Flashcards. "Bado" (not yet) puts the card back at the end of the pile: no skipping what you don't know.
class CardsScreen extends StatefulWidget {
  final Lang lang;
  final List<Item> items;
  final String title;
  const CardsScreen({super.key, required this.lang, required this.items, required this.title});
  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  late final List<Item> queue = [...widget.items];
  int i = 0, got = 0;
  bool flipped = false;

  Item get it => queue[i];

  @override
  void initState() {
    super.initState();
    _show();
  }

  void _show() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || i >= queue.length) return;
      context.read<AppState>().seen(it);
      context.read<Voice>().say(it.t, widget.lang.tts, rate: 0.45);
    });
  }

  void _rate(bool ok) {
    final st = context.read<AppState>();
    st.rate(it, ok);
    if (ok) { got++; } else { queue.add(it); }
    setState(() { i++; flipped = false; });
    _show();
  }

  @override
  Widget build(BuildContext context) {
    final voice = context.read<Voice>();
    if (i >= queue.length) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              Text('Umemaliza kadi ${widget.items.length}!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Rudi')),
            ]),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('${widget.title}  ${i + 1}/${queue.length}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            LinearProgressIndicator(value: i / queue.length, minHeight: 8),
            const SizedBox(height: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => flipped = !flipped),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Card(
                    key: ValueKey(flipped),
                    color: flipped ? Color(widget.lang.color).withOpacity(0.15) : Colors.white,
                    child: SizedBox.expand(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          if (!flipped) ...[
                            Text(it.t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold)),
                            if (it.r.isNotEmpty) Text(it.r, style: TextStyle(fontSize: 20, color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
                            const SizedBox(height: 24),
                            const Text('Gusa kugeuza', style: TextStyle(color: Colors.grey)),
                          ] else ...[
                            Text(it.m, textAlign: TextAlign.center, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                            if (it.en.isNotEmpty && it.en != it.m) Padding(padding: const EdgeInsets.only(top: 6), child: Text(it.en, style: TextStyle(fontSize: 16, color: Colors.grey.shade700))),
                            if (it.n.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 16), child: Text('💡 ${it.n}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17))),
                            const SizedBox(height: 16),
                            Text(it.t, style: const TextStyle(fontSize: 26)),
                          ],
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton.filledTonal(onPressed: () => voice.say(it.t, widget.lang.tts, rate: 0.45), icon: const Icon(Icons.volume_up)),
              const SizedBox(width: 8),
              IconButton.filledTonal(onPressed: () => voice.say(it.t, widget.lang.tts, rate: 0.28), icon: const Icon(Icons.hearing)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: flipped ? () => _rate(false) : null, icon: const Icon(Icons.replay), label: const Text('Bado'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton.icon(onPressed: flipped ? () => _rate(true) : null, icon: const Icon(Icons.check), label: const Text('Nimeelewa'))),
            ]),
            if (!flipped) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Geuza kadi kwanza: hakuna kuruka!', style: TextStyle(color: Colors.grey))),
          ]),
        ),
      ),
    );
  }
}
