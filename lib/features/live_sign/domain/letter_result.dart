class LetterResult {
  final String letter;
  final double score;
  final double confidence; // Gap between best and second best

  LetterResult(this.letter, this.score, this.confidence);

  @override
  String toString() => "$letter (${(score * 100).toInt()}%)";
}