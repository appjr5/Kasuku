import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// App-wide state: content, XP/streak, spaced repetition (Leitner boxes + per-item stats), unit stars, settings.
class AppState extends ChangeNotifier {
  SharedPreferences? _p; // null in unit tests
  final Map<String, Lang> langs = {};
  final Map<String, List<int>> srs = {}; // itemId -> [box 0..5, dueEpochMs]
  final Map<String, List<int>> stats = {}; // itemId -> [timesRight, timesWrong]
  final Map<String, int> stars = {}; // unitId -> 0..3
  int xp = 0, streak = 0, strict = 1;
  String lastDay = '', model = 'tiny';
  bool coachVoice = true, uiSw = true;

  static const order = ['es', 'ja', 'zh', 'ru'];
  static const gapMin = [10, 1440, 4320, 10080, 20160, 43200]; // minutes until next review, per box

  /// Pass mark for speaking: Gentle 60%, Strict 80%, Sensei 90%.
  double get threshold => const [0.6, 0.8, 0.9][strict];

  Future<void> load() async {
    final p = _p = await SharedPreferences.getInstance();
    xp = p.getInt('xp') ?? 0;
    streak = p.getInt('streak') ?? 0;
    strict = p.getInt('strict') ?? 1;
    lastDay = p.getString('lastDay') ?? '';
    model = p.getString('model') ?? 'tiny';
    coachVoice = p.getBool('coachVoice') ?? true;
    uiSw = p.getBool('uiSw') ?? true;
    _readMap(p.getString('srs'), (k, v) => srs[k] = List<int>.from(v as List));
    _readMap(p.getString('stats'), (k, v) => stats[k] = List<int>.from(v as List));
    _readMap(p.getString('stars'), (k, v) => stars[k] = v as int);
    await loadContent();
  }

  Future<void> loadContent() async {
    for (final c in order) {
      try {
        final j = jsonDecode(await rootBundle.loadString('assets/content/$c.json')) as Map<String, dynamic>;
        langs[c] = Lang.fromJson(j, sw: uiSw);
      } catch (_) {
        // curriculum file missing/invalid: skip (the Core Lab works without content)
      }
    }
    notifyListeners();
  }

  void _readMap(String? s, void Function(String, dynamic) put) {
    if (s == null) return;
    (jsonDecode(s) as Map<String, dynamic>).forEach(put);
  }

  void _save() {
    final p = _p;
    if (p != null) {
      p.setInt('xp', xp);
      p.setInt('streak', streak);
      p.setInt('strict', strict);
      p.setString('lastDay', lastDay);
      p.setString('model', model);
      p.setBool('coachVoice', coachVoice);
      p.setBool('uiSw', uiSw);
      p.setString('srs', jsonEncode(srs));
      p.setString('stats', jsonEncode(stats));
      p.setString('stars', jsonEncode(stars));
    }
    notifyListeners();
  }

  String _day(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _touch([DateTime? now]) {
    now ??= DateTime.now();
    final today = _day(now);
    if (lastDay == today) return;
    streak = lastDay == _day(now.subtract(const Duration(days: 1))) ? streak + 1 : 1;
    lastDay = today;
  }

  // ---- progress -------------------------------------------------------------
  bool unitUnlocked(Lang l, int i) => i == 0 || (stars[l.units[i - 1].id] ?? 0) >= 1;
  double progress(Lang l) => l.units.where((u) => (stars[u.id] ?? 0) >= 1).length / l.units.length;

  void setStars(String unitId, int s) {
    stars[unitId] = max(stars[unitId] ?? 0, s);
    xp += 25 * s;
    _touch();
    _save();
  }

  void addXp(int n) {
    xp += n;
    _touch();
    _save();
  }

  // ---- spaced repetition ----------------------------------------------------
  /// First time a card is shown it enters box 0 and is due for a first check in 10 minutes.
  void seen(Item it, {DateTime? now}) {
    if (!srs.containsKey(it.id)) {
      srs[it.id] = [0, (now ?? DateTime.now()).add(const Duration(minutes: 10)).millisecondsSinceEpoch];
      _save();
    }
  }

  /// Right: up one box, next review after that box's gap. Wrong (a lapse): down two boxes, back in 10 minutes.
  void rate(Item it, bool ok, {DateTime? now}) {
    now ??= DateTime.now();
    var box = (srs[it.id] ?? [0, 0])[0];
    box = ok ? min(box + 1, 5) : max(box - 2, 0);
    srs[it.id] = [box, now.add(Duration(minutes: ok ? gapMin[box] : gapMin[0])).millisecondsSinceEpoch];
    final s = stats[it.id] ?? [0, 0];
    s[ok ? 0 : 1]++;
    stats[it.id] = s;
    xp += ok ? 10 : 1;
    _touch(now);
    _save();
  }

  /// Items the learner has met in units before [beforeUnit].
  List<Item> learned(Lang l, int beforeUnit) =>
      l.units.take(beforeUnit).expand((u) => u.items).where((i) => srs.containsKey(i.id)).toList();

  List<Item> dueItems(Lang l, {int max = 10, DateTime? now}) {
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final d = l.allItems.where((i) => srs.containsKey(i.id) && srs[i.id]![1] <= t).toList()
      ..sort((a, b) => srs[a.id]![1].compareTo(srs[b.id]![1]));
    return d.take(max).toList();
  }

  int dueCount(Lang l) => dueItems(l, max: 9999).length;

  double _priority(Item i, int nowMs) {
    final s = stats[i.id] ?? [0, 0];
    final overdueDays = ((nowMs - srs[i.id]![1]) / 86400000.0).clamp(-2.0, 10.0).toDouble();
    return s[1] * 2.0 + overdueDays;
  }

  /// [n] items from earlier units for the "memory check" before a new unit: weak and overdue ones first.
  List<Item> memoryPool(Lang l, int beforeUnit, int n, {DateTime? now}) {
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final c = learned(l, beforeUnit)..sort((a, b) => _priority(b, t).compareTo(_priority(a, t)));
    return c.take(n).toList()..shuffle();
  }

  /// The items you fail most (targeted review).
  List<Item> weakItems(Lang l, {int n = 8}) {
    final c = l.allItems.where((i) => (stats[i.id]?[1] ?? 0) > 0).toList()
      ..sort((a, b) => _wrongRatio(b).compareTo(_wrongRatio(a)));
    return c.take(n).toList();
  }

  double _wrongRatio(Item i) {
    final s = stats[i.id] ?? [0, 0];
    return s[1] / max(1, s[0] + s[1]);
  }

  // ---- settings -------------------------------------------------------------
  void setStrict(int v) { strict = v; _save(); }
  void setModel(String v) { model = v; _save(); }
  void setCoachVoice(bool v) { coachVoice = v; _save(); }
  Future<void> setUiSw(bool v) async { uiSw = v; _save(); await loadContent(); }
  Future<void> reset() async {
    srs.clear(); stats.clear(); stars.clear(); xp = 0; streak = 0; lastDay = '';
    _save();
  }
}
