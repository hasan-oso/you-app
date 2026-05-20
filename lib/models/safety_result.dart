class SafetyResult {
  final bool isSafe;
  final List<String> conflictingIngredients;
  final String warningMessage;

  SafetyResult({
    required this.isSafe,
    required this.conflictingIngredients,
    required this.warningMessage,
  });
}
