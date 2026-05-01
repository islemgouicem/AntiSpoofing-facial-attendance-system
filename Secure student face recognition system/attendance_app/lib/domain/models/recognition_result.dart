/// Result returned by the AI recognition endpoint.
class RecognitionResult {
  final bool recognized;
  final String? name;
  final double? confidence;
  final String? reason; // no_face_found | unknown_person | spoof_detected

  const RecognitionResult({
    required this.recognized,
    this.name,
    this.confidence,
    this.reason,
  });

  factory RecognitionResult.fromJson(Map<String, dynamic> json) =>
      RecognitionResult(
        recognized: json['recognized'] as bool? ?? false,
        name: json['name'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble(),
        reason: json['reason'] as String?,
      );
}
