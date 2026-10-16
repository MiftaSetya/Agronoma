/// Kesalahan dari backend, sudah diterjemahkan ke bentuk yang siap dipakai UI.
///
/// Backend membalas JSON dengan bentuk konsisten:
/// - `{message, errors}` untuk 422 (validasi / kredensial salah)
/// - `{message}` untuk 401/403/404/500
///
/// [fieldErrors] memetakan nama field backend ke pesan pertamanya, sehingga
/// layar bisa menempelkan pesan ke kolom yang tepat.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  /// Backend tidak terhubung (server mati, alamat salah, atau tanpa jaringan).
  bool get isNetworkFailure => statusCode == null;

  /// Token hilang/kedaluwarsa; pemanggil bisa mengarahkan ulang ke login.
  bool get isUnauthorized => statusCode == 401;

  /// Validasi gagal — pesan per field tersedia di [fieldErrors].
  bool get isValidationFailure => statusCode == 422;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message, '
      'fieldErrors: $fieldErrors)';
}
