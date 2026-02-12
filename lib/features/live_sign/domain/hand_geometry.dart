import 'dart:math';

/// Extracts geometric features from normalized landmarks.
class HandGeometry {
  final List<List<double>> landmarks;

  HandGeometry(this.landmarks);

  /// Computes curl ratio for a finger (0.0 = Extended, 1.0 = Fully Curled).
  /// Uses angle at the middle joint (PIP) for 4 fingers, IP for thumb.
  /// [baseIndex]: MCP joint index
  /// [midIndex]: PIP joint index
  /// [tipIndex]: Tip index
  double computeCurl(int baseIndex, int midIndex, int tipIndex) {
    final base = landmarks[baseIndex];
    final mid = landmarks[midIndex];
    final tip = landmarks[tipIndex];

    // Vectors: Mid->Base and Mid->Tip
    final v1 = [base[0] - mid[0], base[1] - mid[1], base[2] - mid[2]];
    final v2 = [tip[0] - mid[0], tip[1] - mid[1], tip[2] - mid[2]];

    final angle = _angleBetween(v1, v2);

    // Map Angle (degrees) to Curl Ratio
    // 180 degrees (straight) -> 0.0
    // 50 degrees (fully bent) -> 1.0
    return _mapRange(angle, 170, 60);
  }

  /// Special logic for Thumb (uses CMC, MCP, IP)
  double computeThumbCurl() {
    // 1=CMC, 2=MCP, 4=Tip. Angle at 2.
    // Thumb is weird; geometric curl often needs checking tip distance to pinky base.
    final angleScore = computeCurl(1, 2, 4);

    // Distance heuristic: Thumb Tip (4) to Pinky MCP (17)
    final dist = _distance(landmarks[4], landmarks[17]);
    // If closer than 0.15 (normalized), it's curled.
    final distScore = (dist < 0.2) ? 1.0 : 0.0;

    return (angleScore * 0.7) + (distScore * 0.3);
  }

  /// Computes normalized Euclidean distance between two landmark indices.
  double computeDistance(int idx1, int idx2) {
    return _distance(landmarks[idx1], landmarks[idx2]);
  }

  /// 0.0 = fingers touching, 1.0 = wide spread
  double computeSpread(int idx1, int idx2) {
    final dist = _distance(landmarks[idx1], landmarks[idx2]);
    return _mapRange(dist, 0.05, 0.25, reverse: true); // 0.05=close, 0.25=far
  }

  // --- Helpers ---

  double _distance(List<double> p1, List<double> p2) {
    return sqrt(pow(p1[0] - p2[0], 2) + pow(p1[1] - p2[1], 2) + pow(p1[2] - p2[2], 2));
  }

  double _angleBetween(List<double> v1, List<double> v2) {
    final dot = v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2];
    final mag1 = sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2]);
    final mag2 = sqrt(v2[0] * v2[0] + v2[1] * v2[1] + v2[2] * v2[2]);
    if (mag1 * mag2 == 0) return 0.0;
    final cosine = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return acos(cosine) * 180 / pi;
  }

  /// Maps value from [min, max] to [0.0, 1.0].
  /// If [reverse], maps [min, max] to [0.0, 1.0] (where min is score 0)
  /// Actually, let's keep simple: Input degrees.
  /// Straight (180) should be score 0 (not curled).
  /// Bent (60) should be score 1 (curled).
  double _mapRange(double value, double straightVal, double curledVal, {bool reverse = false}) {
    // Linear interpolation
    double t = (value - straightVal) / (curledVal - straightVal);
    return t.clamp(0.0, 1.0);
  }
}