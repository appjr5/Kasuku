import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Mono PCM audio. Pure Dart (no plugins) so it can be unit-tested.
class Wav {
  final List<double> s;
  final int rate;
  Wav(this.s, this.rate);

  double get rms {
    if (s.isEmpty) return 0;
    var a = 0.0;
    for (final v in s) { a += v * v; }
    return sqrt(a / s.length);
  }

  static Future<Wav> read(String path) async {
    final b = await File(path).readAsBytes();
    final bd = ByteData.sublistView(b);
    var p = 12, start = 44, len = max(0, b.length - 44), rate = 16000;
    while (p + 8 <= b.length) {
      final id = String.fromCharCodes(b.sublist(p, p + 4));
      final sz = bd.getUint32(p + 4, Endian.little);
      if (id == 'fmt ' && p + 16 <= b.length) rate = bd.getUint32(p + 12, Endian.little);
      if (id == 'data') {
        start = p + 8;
        len = (sz == 0 || sz > b.length - start) ? b.length - start : sz;
        break;
      }
      p += 8 + sz + (sz & 1);
    }
    final n = len ~/ 2;
    final out = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) { out[i] = bd.getInt16(start + 2 * i, Endian.little) / 32768.0; }
    return Wav(out, rate);
  }
}

class ToneResult {
  final int? tone; // 1..4, null = could not tell
  final List<double> curve; // 20 points, semitones relative to the speaker's median pitch
  const ToneResult(this.tone, this.curve);
}

/// Lightweight pitch (F0) tracker + tone classifier for ONE Mandarin syllable.
/// Speech recognisers "auto-correct" tones, so tones are judged from the pitch contour instead.
class Pitch {
  static ToneResult analyse(Wav w) {
    final s = w.s, sr = w.rate;
    final fr = (sr * 0.04).round(), hop = (sr * 0.01).round();
    final minLag = (sr / 400).round(), maxLag = (sr / 75).round();
    var peak = 0.0;
    for (final v in s) { if (v.abs() > peak) peak = v.abs(); }
    if (peak < 0.02) return const ToneResult(null, []);

    final cs = List<double>.filled(s.length + 1, 0); // prefix sums of energy
    for (var i = 0; i < s.length; i++) { cs[i + 1] = cs[i] + s[i] * s[i]; }

    final f0 = <double>[];
    for (var st = 0; st + fr + maxLag < s.length; st += hop) {
      var r0 = 0.0;
      for (var i = 0; i < fr; i++) { r0 += s[st + i] * s[st + i]; }
      if (r0 / fr < pow(peak * 0.1, 2)) { f0.add(0); continue; }
      final r = List<double>.filled(maxLag + 1, 0);
      var best = minLag;
      for (var lag = minLag; lag <= maxLag; lag++) {
        var a = 0.0;
        for (var i = 0; i < fr; i++) { a += s[st + i] * s[st + i + lag]; }
        r[lag] = a / sqrt(r0 * (cs[st + lag + fr] - cs[st + lag]) + 1e-12); // normalised autocorrelation
        if (r[lag] > r[best]) best = lag;
      }
      if (r[best] < 0.5) { f0.add(0); continue; }
      for (final d in [2, 3]) { // octave-error guard
        final l = (best / d).round();
        if (l >= minLag && r[l] > 0.85 * r[best]) { best = l; break; }
      }
      f0.add(sr / best);
    }

    // longest voiced run (gaps up to 2 frames tolerated)
    var bs = 0, bl = 0, rs = -1, re = -1, gap = 0;
    for (var i = 0; i < f0.length; i++) {
      if (f0[i] > 0) {
        if (rs < 0) rs = i;
        re = i;
        gap = 0;
      } else if (rs >= 0 && ++gap > 2) {
        if (re - rs + 1 > bl) { bs = rs; bl = re - rs + 1; }
        rs = -1;
        gap = 0;
      }
    }
    if (rs >= 0 && re - rs + 1 > bl) { bs = rs; bl = re - rs + 1; }
    if (bl < 8) return const ToneResult(null, []);

    final seg = f0.sublist(bs, bs + bl);
    for (var i = 0; i < seg.length; i++) { if (seg[i] == 0) seg[i] = i > 0 ? seg[i - 1] : seg.firstWhere((x) => x > 0); }
    final sm = List<double>.generate(seg.length, (i) {
      final win = seg.sublist(max(0, i - 2), min(seg.length, i + 3))..sort();
      return win[win.length ~/ 2];
    });
    final sorted = [...sm]..sort();
    final med = sorted[sorted.length ~/ 2];
    final semi = sm.map((f) => 12 * log(f / med) / ln2).toList();
    final cur = List<double>.generate(20, (k) {
      final p = k * (semi.length - 1) / 19;
      final i = p.floor(), f = p - i, j = min(i + 1, semi.length - 1);
      return semi[i] * (1 - f) + semi[j] * f;
    });

    double avg(int a, int b) => cur.sublist(a, b).reduce((x, y) => x + y) / (b - a);
    final first = avg(0, 4), mid = avg(8, 12), last = avg(16, 20);
    final range = cur.reduce(max) - cur.reduce(min);
    int tone;
    if (range < 3.0) {
      tone = 1;
    } else if (mid < first - 1.5 && mid < last - 1.5) {
      tone = 3;
    } else if (last - first > 2.5) {
      tone = 2;
    } else if (first - last > 2.5) {
      tone = 4;
    } else {
      tone = 1;
    }
    return ToneResult(tone, cur);
  }
}
