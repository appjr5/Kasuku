import 'dart:math';
import 'package:flutter/material.dart';
import 'coach.dart';

/// The teacher's portrait: an original flat illustration (a Black African woman teacher: patterned headwrap,
/// teacher's glasses, gold earrings) drawn in code, six moods. No external art, so no third-party licence.
/// Coordinates are fractions of the canvas; tweak the colours below to change her look.
class TeacherPainter extends CustomPainter {
  final Mood mood;
  const TeacherPainter(this.mood);

  static const skin = Color(0xFF6A4330), skinD = Color(0xFF3F2518), wrap = Color(0xFFE59A1A), wrapD = Color(0xFF8A1F11);
  static const dress = Color(0xFF1F7A6D), gold = Color(0xFFF2C14E), ink = Color(0xFF1B1B1B);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    Offset p(double x, double y) => Offset(x * w, y * h);
    Paint fill(Color col) => Paint()..color = col;
    Paint stroke(Color col, double wd) => Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = wd * w..strokeCap = StrokeCap.round;
    void ell(double cx, double cy, double ew, double eh, Paint pt) => c.drawOval(Rect.fromCenter(center: p(cx, cy), width: ew * w, height: eh * h), pt);
    void line(List<List<double>> pts, Color col, double wd) {
      final path = Path()..moveTo(pts.first[0] * w, pts.first[1] * h);
      for (final q in pts.skip(1)) { path.lineTo(q[0] * w, q[1] * h); }
      c.drawPath(path, stroke(col, wd));
    }
    void arc(double cx, double cy, double aw, double ah, double a0, double a1, Color col, double wd) =>
        c.drawArc(Rect.fromCenter(center: p(cx, cy), width: aw * w, height: ah * h), a0 * pi / 180, (a1 - a0) * pi / 180, false, stroke(col, wd));

    ell(.5, 1.02, .95, .5, fill(dress)); // shoulders / dress
    for (final x in [.22, .34, .66, .78]) { ell(x, .93, .035, .035, fill(gold)); } // kitenge dots
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromPoints(p(.425, .72), p(.575, .88)), Radius.circular(.03 * w)), fill(skinD)); // neck
    ell(.5, .30, .66, .40, fill(wrap)); // headwrap
    ell(.71, .16, .15, .12, fill(wrap));
    ell(.80, .21, .11, .10, fill(wrap)); // knot
    for (final q in [[.33, .22], [.44, .14], [.56, .13], [.37, .30], [.5, .23], [.66, .25], [.74, .15]]) { ell(q[0], q[1], .035, .035, fill(wrapD)); }
    ell(.5, .53, .50, .60, fill(skin)); // face
    arc(.5, .53, .52, .62, 200, 340, wrap, .065); // wrap band over the forehead
    arc(.5, .53, .52, .62, 204, 336, wrapD, .012);
    ell(.245, .60, .035, .06, fill(gold));
    ell(.755, .60, .035, .06, fill(gold)); // earrings

    const ex = [.40, .60];
    const ey = .50;
    void eyes(String kind, [double lx = 0, double ly = 0]) {
      for (final x in ex) {
        switch (kind) {
          case 'happy':
            arc(x, ey + .012, .09, .07, 200, 340, ink, .014);
          case 'narrow':
            ell(x, ey, .095, .038, fill(Colors.white));
            ell(x + lx, ey + ly, .032, .03, fill(ink));
            line([[x - .05, ey - .016], [x + .05, ey - .016]], skinD, .012);
          case 'down':
            ell(x, ey, .095, .058, fill(Colors.white));
            ell(x, ey + .016, .04, .036, fill(ink));
          default:
            ell(x, ey, .095, .062, fill(Colors.white));
            ell(x + lx, ey + ly, .04, .04, fill(ink));
        }
      }
    }
    void brow(double x0, double y0, double x1, double y1) => line([[x0, y0], [x1, y1]], ink, .016);

    switch (mood) {
      case Mood.happy:
        eyes('happy'); brow(.34, .405, .46, .395); brow(.54, .395, .66, .405);
        arc(.5, .64, .24, .17, 20, 160, ink, .016);
      case Mood.proud:
        eyes('happy'); brow(.34, .40, .46, .385); brow(.54, .385, .66, .40);
        c.drawArc(Rect.fromPoints(p(.38, .58), p(.62, .76)), 0, pi, true, fill(const Color(0xFF7A1F1F)));
        c.drawArc(Rect.fromPoints(p(.40, .605), p(.60, .655)), 0, pi, false, fill(Colors.white));
        for (final q in [[.17, .30], [.86, .35], [.12, .55]]) {
          line([[q[0] - .03, q[1]], [q[0] + .03, q[1]]], gold, .012);
          line([[q[0], q[1] - .03], [q[0], q[1] + .03]], gold, .012);
        }
      case Mood.meh:
        eyes('narrow', .008); brow(.34, .415, .46, .41); brow(.54, .39, .66, .375);
        line([[.43, .675], [.57, .655]], ink, .015);
      case Mood.sad:
        eyes('down'); brow(.33, .43, .46, .385); brow(.54, .385, .67, .43);
        arc(.5, .715, .2, .12, 205, 335, ink, .016);
      case Mood.strict:
        eyes('narrow'); brow(.33, .385, .46, .425); brow(.54, .425, .67, .385);
        line([[.44, .675], [.56, .675]], ink, .017);
      case Mood.think:
        eyes('open', .012, -.012); brow(.34, .41, .46, .40); brow(.54, .375, .66, .36);
        ell(.54, .675, .05, .05, stroke(ink, .013));
    }
    for (final x in ex) { ell(x, ey, .17, .17, stroke(gold, .008)); } // teacher's glasses
    line([[.485, ey], [.515, ey]], gold, .008);
    arc(.5, .585, .07, .05, 20, 160, skinD, .011); // nose
  }

  @override
  bool shouldRepaint(covariant TeacherPainter old) => old.mood != mood;
}
