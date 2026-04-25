class OnboardingRequest {
  final String mukzziName;
  final double height;
  final double weight;
  final String activityLevel;
  final String goal;
  final int bodyType;
  final int muscle;
  final int skinTone;
  final int expression;

  OnboardingRequest({
    required this.mukzziName,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.goal,
    required this.bodyType,
    required this.muscle,
    required this.skinTone,
    required this.expression,
  });

  Map<String, dynamic> toJson() {
    return {
      'mukzzi_name': mukzziName,
      'height': height,
      'weight': weight,
      'activity_level': activityLevel,
      'goal': goal,
      'body_type': bodyType,
      'muscle': muscle,
      'skin_tone': skinTone,
      'expression': expression,
    };
  }
}
