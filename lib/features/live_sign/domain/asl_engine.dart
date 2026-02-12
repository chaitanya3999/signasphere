import 'package:signasphere/features/live_sign/domain/hand_coordinate_transform.dart';
import 'package:signasphere/features/live_sign/domain/hand_geometry.dart';
import 'package:signasphere/features/live_sign/domain/letter_result.dart';

class ASLEngine {
  static const double _matchThreshold = 0.78; // Minimum score to accept a letter

  /// Returns the best matching letter and its confidence score.
  static LetterResult? detectLetter(List<List<double>> rawLandmarks) {
    if (rawLandmarks.length < 21) return null;

    // 1. Normalize
    final normalized = HandCoordinateTransform.normalize(rawLandmarks);
    final geo = HandGeometry(normalized);

    // 2. Extract Features
    // Curls: 0.0 (Straight) -> 1.0 (Curled)
    final thumbCurl = geo.computeThumbCurl();
    final indexCurl = geo.computeCurl(5, 6, 8);
    final midCurl = geo.computeCurl(9, 10, 12);
    final ringCurl = geo.computeCurl(13, 14, 16);
    final pinkyCurl = geo.computeCurl(17, 18, 20);

    // Distances & Relationships
    final tiDist = geo.computeDistance(4, 8); // Thumb-Index Tip
    final tmDist = geo.computeDistance(4, 12); // Thumb-Mid Tip
    final imSpread = geo.computeDistance(8, 12); // Index-Mid Spread (Crossing check)

    // Z-Axis checks (Palm facing)
    // Thumb Tip Z relative to Index MCP Z
    final thumbZ = normalized[4][2];

    // 3. Scoring Definitions (The Dictionary)
    final scores = <String, double>{};

    // --- A: Fist, Thumb along side of index ---
    // All fingers curled (1.0), Thumb straightish (0.2) but tucked against palm
    scores['A'] = _score([
      _match(indexCurl, 1.0),
      _match(midCurl, 1.0),
      _match(ringCurl, 1.0),
      _match(pinkyCurl, 1.0),
      _match(thumbCurl, 0.0, weight: 0.5), // Thumb is straight up against hand
      // Thumb tip should be close to Index MCP (5)
      _match(geo.computeDistance(4, 5), 0.05, weight: 0.8),
    ]);

    // --- B: Open Palm, Thumb tucked ---
    scores['B'] = _score([
      _match(indexCurl, 0.0),
      _match(midCurl, 0.0),
      _match(ringCurl, 0.0),
      _match(pinkyCurl, 0.0),
      _match(thumbCurl, 1.0), // Thumb tucked across palm
    ]);

    // --- C: Curved Hand ---
    scores['C'] = _score([
      // Fingers partially curled (~0.4 - 0.6)
      _range(indexCurl, 0.3, 0.7),
      _range(midCurl, 0.3, 0.7),
      _range(ringCurl, 0.3, 0.7),
      // Thumb also curved
      _range(thumbCurl, 0.2, 0.6),
      // Wide gap between thumb and index
      _match(tiDist, 0.25, weight: 1.5),
    ]);

    // --- D: Index Up, others curled loop ---
    scores['D'] = _score([
      _match(indexCurl, 0.0),
      _match(midCurl, 1.0),
      _match(ringCurl, 1.0),
      _match(pinkyCurl, 1.0),
      // Thumb touching Middle Tip
      _match(tmDist, 0.05, weight: 1.5),
    ]);

    // --- E: Clenched Fist, Thumb tucked under ---
    scores['E'] = _score([
      _range(indexCurl, 0.85, 1.0),
      _range(midCurl, 0.85, 1.0),
      _range(ringCurl, 0.85, 1.0),
      _range(pinkyCurl, 0.85, 1.0),

      // Thumb tucked strongly
      _range(thumbCurl, 0.7, 1.0),

      // Fingertips near palm center (tight fist)
      _match(geo.computeDistance(8, 0), 0.1, weight: 1.5),
    ]);

    // --- F: OK Sign (Index+Thumb touch, others open) ---
    scores['F'] = _score([
      _match(midCurl, 0.0),
      _match(ringCurl, 0.0),
      _match(pinkyCurl, 0.0),
      _match(tiDist, 0.0, weight: 2.0), // Touching
      _range(indexCurl, 0.4, 1.0), // Index forms circle
    ]);

    // --- G: Pointing Horizontal ---
    // Hard to distinguish from D without Orientation.
    // Normalized frame aligns Y with fingers. G points Index sideways relative to Wrist-Middle?
    // In local frame: Index is pointing X-ish (sideways) instead of Y-ish?
    // For MVP, we treat G as Index extended, thumb parallel, others curled.
    scores['G'] = _score([
      _match(indexCurl, 0.0),
      _match(midCurl, 1.0),
      _match(ringCurl, 1.0),
      _match(pinkyCurl, 1.0),
      // Thumb and Index parallel and close-ish but not touching
      _match(thumbCurl, 0.0),
      // Index points sideways (check X coord of tip vs base)
      // normalized[8].x > normalized[5].x significantly?
    ]);

    // --- H: Index+Middle horizontal ---
    scores['H'] = _score([
      _range(indexCurl, 0.0, 0.25),
      _range(midCurl, 0.0, 0.25),

      _match(ringCurl, 1.0, weight: 1.0),
      _match(pinkyCurl, 1.0, weight: 1.0),

      // Fingers must be close together (touching)
      _match(imSpread, 0.0, weight: 2.0),

      // Thumb MUST be tucked
      _range(thumbCurl, 0.6, 1.0),

      // Thumb NOT touching middle pip (prevents K confusion)
      _match(geo.computeDistance(4, 10), 0.15, weight: 1.5),
    ]);


    // --- I: Pinky Up ---
    scores['I'] = _score([
      _match(indexCurl, 1.0),
      _match(midCurl, 1.0),
      _match(ringCurl, 1.0),
      _match(pinkyCurl, 0.0),
      _match(thumbCurl, 1.0), // Thumb tucked on index
    ]);

    // --- K: Victory sign but Thumb on Middle PIP ---
    scores['K'] = _score([
      _match(indexCurl, 0.0, weight: 1.5),
      _match(midCurl, 0.0, weight: 1.5),
      _match(ringCurl, 1.0),
      _match(pinkyCurl, 1.0),

      // Thumb MUST be very close to middle PIP
      _range(geo.computeDistance(4, 10), 0.0, 0.04),

      // Thumb NOT tucked (must be visible)
      _range(thumbCurl, 0.0, 0.4),
    ]);



    // --- L: L Shape ---
    scores['L'] = _score([
      _match(indexCurl, 0.0),
      _match(midCurl, 1.0),
      _match(ringCurl, 1.0),
      _match(pinkyCurl, 1.0),
      _match(thumbCurl, 0.0), // Thumb extended
      // Wide spread
      _match(tiDist, 0.3, weight: 1.5), // Expecting large distance
    ]);

    // --- M: 3 fingers over thumb ---
    // Thumb tip is hidden (high depth?) or under Ring.
    // Hard to distinguish M/N/T purely on landmarks without depth occlusion.
    // Heuristic: Thumb is "inside" the hand.
    scores['M'] = _score([
      _range(indexCurl, 0.8, 1.0),
      _range(midCurl, 0.8, 1.0),
      _range(ringCurl, 0.8, 1.0),
      _range(pinkyCurl, 0.8, 1.0),
    ]) * 0.7; // reduce weight


    // --- O: All tips touching thumb ---
    scores['O'] = _score([
      _range(indexCurl, 0.4, 0.8),
      _range(midCurl, 0.4, 0.8),
      _range(ringCurl, 0.4, 0.8),
      _range(pinkyCurl, 0.4, 0.8),
      _match(tiDist, 0.05, weight: 1.0),
      _match(tmDist, 0.05, weight: 1.0),
    ]);

    // --- R: Crossed Fingers ---
    // Index and Middle extended but CROSSING.
    // X-coord of Middle Tip < X-coord of Index Tip (swapped order)
    final double crossDistance =
    (normalized[12][0] - normalized[8][0]).abs();

    bool isCrossed =
        crossDistance < 0.03 && // very close horizontally
            normalized[12][1] < normalized[8][1]; // middle slightly in front

    scores['R'] = _score([
      _match(indexCurl, 0.0),
      _match(midCurl, 0.0),
      _match(ringCurl, 1.0),
      _match(pinkyCurl, 1.0),
      (isCrossed ? 1.0 : 0.0) * 0.8, // Reduced weight
    ]);

    // --- S: Fist, Thumb OVER fingers ---
    scores['S'] = _score([
      _match(indexCurl, 1.0),
      _match(midCurl, 1.0),
      _match(ringCurl, 1.0),
      _match(pinkyCurl, 1.0),
      // Thumb across Index/Middle (0.8 curl)
      _range(thumbCurl, 0.5, 0.9),
      // Thumb tip z > Index Z (on top)
    ]);

    // --- T: Thumb between Index/Middle ---
    scores['T'] = _score([
      _match(indexCurl, 0.8), // Index loosely curled
      _match(midCurl, 1.0),
      _match(ringCurl, 1.0),
      _match(pinkyCurl, 1.0),
      // Thumb tip close to Index PIP
    ]);

    // --- U: Index+Middle up, touching ---
    scores['U'] = _score([
      _match(indexCurl, 0.0),
      _match(midCurl, 0.0),
      _match(ringCurl, 1.0),
      _match(pinkyCurl, 1.0),
      _match(imSpread, 0.0, weight: 2.0), // Touching
    ]);

    // --- V: Index+Middle up, spread ---
    scores['V'] = _score([
      _match(indexCurl, 0.0),
      _match(midCurl, 0.0),
      _match(ringCurl, 1.0),
      _match(pinkyCurl, 1.0),
      _match(imSpread, 0.2, weight: 2.0), // stronger spread requirement
    ]);

    // --- W: 3 fingers up ---
    scores['W'] = _score([
      _match(indexCurl, 0.0),
      _match(midCurl, 0.0),
      _match(ringCurl, 0.0),
      _match(pinkyCurl, 1.0),
      _range(thumbCurl, 0.5, 1.0), // thumb tucked
    ]);


    // --- X: Index hooked ---
    scores['X'] = _score([
      _range(indexCurl, 0.4, 0.7), // Hooked
      _match(midCurl, 1.0),
      _match(ringCurl, 1.0),
      _match(pinkyCurl, 1.0),
      _match(thumbCurl, 1.0),
    ]);

    // --- Y: Thumb + Pinky ---
    scores['Y'] = _score([
      _match(indexCurl, 1.0),
      _match(midCurl, 1.0),
      _match(ringCurl, 1.0),
      _match(pinkyCurl, 0.0),
      _match(thumbCurl, 0.0),
    ]);

    if (scores['K'] != null) {
      scores['K'] = scores['K']! * 0.75;
    }


    // 4. Find Best Match
    String? bestLetter;
    double bestScore = 0.0;
    double secondBest = 0.0;

    scores.forEach((letter, score) {
      if (score > bestScore) {
        secondBest = bestScore;
        bestScore = score;
        bestLetter = letter;
      } else if (score > secondBest) {
        secondBest = score;
      }
    });

    if (bestLetter != null && bestScore > _matchThreshold) {
      // Calculate confidence spread
      final confidence = (bestScore - secondBest) / bestScore;
      return LetterResult(bestLetter!, bestScore, confidence);
    }

    return null;
  }

  // --- Scoring Helpers ---

  /// Weighted Average
  static double _score(List<double> features) {
    if (features.isEmpty) return 0.0;
    // Simple average for now, but features can be pre-weighted
    return features.reduce((a, b) => a + b) / features.length;
  }

  /// Score how close [actual] is to [target]. 1.0 = perfect, 0.0 = bad.
  static double _match(double actual, double target, {double weight = 1.0}) {
    final error = (actual - target).abs();
    // Tolerance curve: 0 error -> 1.0, 0.3 error -> 0.0
    final score = (1.0 - (error / 0.4)).clamp(0.0, 1.0);
    return score * weight; // Note: weight scales the result, requires normalization in sum if used heavily
  }

  /// Score if [actual] is within [min, max]
  static double _range(double actual, double min, double max) {
    if (actual >= min && actual <= max) return 1.0;
    final dist = (actual < min) ? (min - actual) : (actual - max);
    return (1.0 - (dist / 0.2)).clamp(0.0, 1.0);
  }
}