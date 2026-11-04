import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio.dart';
import 'coach.dart';
import 'models.dart';
import 'store.dart';
import 'teacher.dart';

/// The teacher: her face changes with her mood, and she talks in a speech bubble.
class Mascot extends StatelessWidget {
  final Mood mood;
  final String line;
  const Mascot({super.key, required this.mood, required this.line});

  static const faces = {Mood.happy: '😄', Mood.proud: '🤩', Mood.meh: '🤨', Mood.sad: '😞', Mood.strict: '😠', Mood.think: '🤔'};
  static const tints = {
    Mood.happy: Color(0xFFD7F5DD), Mood.proud: Color(0xFFFFF1B8), Mood.meh: Color(0xFFFFE3C2),
    Mood.sad: Color(0xFFD9DEE8), Mood.strict: Color(0xFFFFCFCF), Mood.think: Color(0xFFE6E0FF),
  };

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      TweenAnimationBuilder<double>(
        key: ValueKey(mood),
        tween: Tween(begin: 0.6, end: 1.0),
        duration: const Duration(milliseconds: 450),
        curve: Curves.elasticOut,
        builder: (c, v, _) => Transform.scale(
          scale: v,
          child: Transform.rotate(
            angle: mood == Mood.sad ? -0.18 : (mood == Mood.strict ? 0.06 : 0),
            child: Container(
              width: 84, height: 84,
              decoration: BoxDecoration(color: tints[mood], shape: BoxShape.circle),
              child: ClipOval(child: CustomPaint(painter: TeacherPainter(mood))),
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Container(
            key: ValueKey(line),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: tints[mood], borderRadius: BorderRadius.circular(16)),
            child: Text(line, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    ]);
  }
}

class ScoreBar extends StatelessWidget {
  final double score, threshold;
  final String heard;
  const ScoreBar({super.key, required this.score, required this.threshold, required this.heard});
  @override
  Widget build(BuildContext context) {
    final ok = score >= threshold;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: score.clamp(0.0, 1.0), minHeight: 14, color: ok ? Colors.green : (score >= threshold - 0.2 ? Colors.orange : Colors.red)),
        ),
        const SizedBox(height: 4),
        Text('Nimesikia: "$heard"  ·  ${(score * 100).round()}%  (inahitajika ${(threshold * 100).round()}%)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
      ]),
    );
  }
}

class QuizResult {
  final int correct, total;
  final List<Item> missed;
  const QuizResult(this.correct, this.total, this.missed);
  double get ratio => total == 0 ? 0 : correct / total;
}

int starsFor(double ratio) => ratio >= 1 ? 3 : (ratio >= 0.85 ? 2 : (ratio >= 0.7 ? 1 : 0));
String starText(int s) => '${'⭐' * s}${'☆' * (3 - s)}';

/// Result dialog: the teacher reacts and speaks.
Future<void> showResult(BuildContext context, String title, double ratio, {String? extra}) async {
  final st = context.read<AppState>();
  final stars = starsFor(ratio);
  final r = ratio >= 0.7 ? Coach.quizPass(ratio >= 1) : Coach.quizFail();
  if (st.coachVoice) context.read<Voice>().coach(r);
  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title, textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Mascot(mood: r.mood, line: r.line),
          const SizedBox(height: 12),
          Text(starText(stars), style: const TextStyle(fontSize: 34)),
          Text('${(ratio * 100).round()}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (extra != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(extra)),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Sawa'))],
    ),
  );
}

Widget bigTile({required String emoji, required String title, String? sub, required VoidCallback? onTap, Color? color, Widget? trailing}) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 6),
    color: color,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Text(emoji, style: const TextStyle(fontSize: 32)),
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      subtitle: sub == null ? null : Text(sub),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
