class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  bool get isNetworkFailure => statusCode == null;

  bool get isUnauthorized => statusCode == 401;

  bool get isValidationFailure => statusCode == 422;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message, '
      'fieldErrors: $fieldErrors)';
}
