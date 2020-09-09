import 'dart:math';
import 'dart:ui';

class MonotoneX {
  static num _sign(num x) {
    return x < 0 ? -1 : 1;
  }

  // Calculate a one-sided slope.
  static double _slope2(double x0, double y0, double x1, double y1, double t) {
    var h = x1 - x0;
    return h != 0 ? (3 * (y1 - y0) / h - t) / 2 : t;
  }

  static double _slope3(double x0, double y0, double x1, double y1, double x2, double y2) {
    double h0 = x1 - x0;
    double h1 = x2 - x1;
    double s0 = (y1 - y0) / (h0 != 0 ? h0 : (h1 < 0 ? -double.infinity : double.infinity));
    double s1 = (y2 - y1) / (h1 != 0 ? h1 : (h0 < 0 ? -double.infinity : double.infinity));
    double p = (s0 * h1 + s1 * h0) / (h0 + h1);
    var source = [s0.abs(), s1.abs(), 0.5 * p.abs()];
    source.sort();
    return (_sign(s0) + _sign(s1)) * source.first ?? 0;
  }

  // According to https://en.wikipedia.org/wiki/Cubic_Hermite_spline#Representations
  // "you can express cubic Hermite interpolation in terms of cubic Bézier curves
  // with respect to the four values p0, p0 + m0 / 3, p1 - m1 / 3, p1".
  static Path _point(Path path, double x0, double y0, double x1, double y1, double t0, double t1) {
    var dx = (x1 - x0) / 3;
    path.cubicTo(x0 + dx, y0 + dx * t0, x1 - dx, y1 - dx * t1, x1, y1);
    return path;
  }

  static Path initPath(List<Point> points) {
    var targetPoints = List<Point>();
    targetPoints.addAll(points);
    targetPoints.add(Point(points[points.length - 1].x * 2, points[points.length - 1].y * 2));
    double x0, y0, x1, y1, t0;
    var path = Path();
    for (int i = 0; i < targetPoints.length; i++) {
      double t1;
      double x = targetPoints[i].x;
      double y = targetPoints[i].y;
      if (x == x1 && y == y1) continue;
      switch (i) {
        case 0:
          path.moveTo(x, y);
          break;
        case 1:
          break;
        case 2:
          t1 = _slope3(x0, y0, x1, y1, x, y);
          _point(path, x0, y0, x1, y1, _slope2(x0, y0, x1, y1, t1), t1);
          break;
        default:
          t1 = _slope3(x0, y0, x1, y1, x, y);
          _point(path, x0, y0, x1, y1, t0, t1);
      }
      x0 = x1;
      y0 = y1;
      x1 = x;
      y1 = y;
      t0 = t1;
    }
    return path;
  }
}
