import 'dart:math';

/// Transforms raw 3D landmarks into a local coordinate system invariant to rotation.
class HandCoordinateTransform {
  /// Transforms raw landmarks to a normalized local frame.
  /// Origin: Wrist (0)
  /// Y-Axis: Direction from Wrist to Middle Finger MCP (normalized)
  /// X-Axis: Approximate Palm Plane (Index MCP to Pinky MCP)
  /// Z-Axis: Palm Normal (Cross Product of X and Y)
  static List<List<double>> normalize(List<List<double>> rawLandmarks) {
    if (rawLandmarks.length < 21) return [];

    // 1. Translation: Move Wrist (0) to Origin (0,0,0)
    final wrist = rawLandmarks[0];
    final centered = rawLandmarks.map((p) => [
      p[0] - wrist[0],
      p[1] - wrist[1],
      p[2] - wrist[2]
    ]).toList();

    // 2. Compute Basis Vectors
    // Y-Axis: Wrist -> Middle MCP (12 is tip, 9 is MCP)
    // Actually typically 0->9 or 0->MiddleMCP is the main hand axis.
    // MediaPipe Hand: 0=Wrist, 9=Middle MCP.
    final middleMcp = centered[9];
    final yAxis = _normalize(middleMcp);

    // Temp Vector: Wrist -> Index MCP (5)
    final indexMcp = centered[5];
    final pinkyMcp = centered[17];

    // X-Axis Candidate: Index MCP - Pinky MCP (approx width of palm)
    // We want X to point roughly from Pinky to Index or vice versa.
    // Let's define X as IndexMCP - PinkyMCP.
    final xTemp = [
      indexMcp[0] - pinkyMcp[0],
      indexMcp[1] - pinkyMcp[1],
      indexMcp[2] - pinkyMcp[2]
    ];

    // Z-Axis: Cross Product (X cross Y) -> Normal to Palm
    final zAxis = _normalize(_crossProduct(xTemp, yAxis));

    // Re-orthogonalize X-Axis: Y cross Z
    final xAxis = _normalize(_crossProduct(yAxis, zAxis));

    // 3. Construct Rotation Matrix & Transform
    // Matrix rows are X, Y, Z axes
    return centered.map((p) {
      return [
        p[0] * xAxis[0] + p[1] * xAxis[1] + p[2] * xAxis[2],
        p[0] * yAxis[0] + p[1] * yAxis[1] + p[2] * yAxis[2],
        p[0] * zAxis[0] + p[1] * zAxis[1] + p[2] * zAxis[2],
      ];
    }).toList();
  }

  // --- Vector Math Utilities (Inline for Performance) ---

  static List<double> _normalize(List<double> v) {
    final length = sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    if (length == 0) return [0.0, 0.0, 0.0];
    return [v[0] / length, v[1] / length, v[2] / length];
  }

  static List<double> _crossProduct(List<double> a, List<double> b) {
    return [
      a[1] * b[2] - a[2] * b[1],
      a[2] * b[0] - a[0] * b[2],
      a[0] * b[1] - a[1] * b[0]
    ];
  }
}