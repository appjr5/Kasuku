import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../panels.dart';
import '../store.dart';
import '../widgets.dart';

/// Runs a list of items through a panel one by one (speaking or writing), rates each, shows a summary.
class _DrillScreen extends StatefulWidget {
  final Lang lang;
  final List<Item> items;
  final String title;
  final Widget Function(Item, ValueChanged<bool>) panel;
  const _DrillScreen({required this.lang, required this.items, required this.title, required this.panel});
  @override
  State<_DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends State<_DrillScreen> {
  int i = 0, passed = 0;

  void _done(bool ok) {
    final st = context.read<AppState>();
    st.rate(widget.items[i], ok);
    if (ok) passed++;
    if (i + 1 >= widget.items.length) {
      final nav = Navigator.of(context);
      nav.pop();
      showResult(nav.context, widget.title, passed / widget.items.length);
      return;
    }
    setState(() => i++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.title}  ${i + 1}/${widget.items.length}')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          LinearProgressIndicator(value: i / widget.items.length, minHeight: 8),
          const SizedBox(height: 16),
          widget.panel(widget.items[i], _done),
        ]),
      ),
    );
  }
}

class SpeakScreen extends StatelessWidget {
  final Lang lang;
  final List<Item> items;
  const SpeakScreen({super.key, required this.lang, required this.items});
  @override
  Widget build(BuildContext context) => _DrillScreen(
        lang: lang, items: items, title: 'Mazoezi ya Kuongea',
        panel: (it, done) => SpeakPanel(key: ValueKey(it.id), lang: lang, item: it, onDone: done),
      );
}

class WriteScreen extends StatelessWidget {
  final Lang lang;
  final List<Item> items;
  const WriteScreen({super.key, required this.lang, required this.items});
  @override
  Widget build(BuildContext context) => _DrillScreen(
        lang: lang, items: items, title: 'Mazoezi ya Kuandika',
        panel: (it, done) => WritePad(key: ValueKey(it.id), lang: lang, item: it, onDone: done),
      );
}
