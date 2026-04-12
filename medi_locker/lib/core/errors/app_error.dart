/// Typed application error — wraps all caught exceptions into
/// a single class so the UI always gets a clean human-readable message.
class AppError implements Exception {
  final String message;
  final String? code;
  final Object? original;

  const AppError({
    required this.message,
    this.code,
    this.original,
  });

  factory AppError.fromException(Object e) {
    // Firebase Auth errors
    final str = e.toString();
    if (str.contains('firebase_auth')) {
      if (str.contains('user-not-found')) {
        return const AppError(
            message: 'No account found with this email.', code: 'user-not-found');
      }
      if (str.contains('wrong-password') || str.contains('invalid-credential')) {
        return const AppError(
            message: 'Incorrect email or password.', code: 'wrong-password');
      }
      if (str.contains('email-already-in-use')) {
        return const AppError(
            message: 'An account with this email already exists.',
            code: 'email-already-in-use');
      }
      if (str.contains('weak-password')) {
        return const AppError(
            message: 'Password is too weak. Use at least 6 characters.',
            code: 'weak-password');
      }
      if (str.contains('network-request-failed')) {
        return const AppError(
            message: 'No internet connection. Please check your network.',
            code: 'network-error');
      }
      if (str.contains('too-many-requests')) {
        return const AppError(
            message: 'Too many attempts. Please wait and try again.',
            code: 'too-many-requests');
      }
    }
    // Firestore / Storage errors
    if (str.contains('permission-denied')) {
      return const AppError(
          message: 'Access denied. Please sign in again.', code: 'permission-denied');
    }
    if (str.contains('not-found')) {
      return const AppError(message: 'Data not found.', code: 'not-found');
    }
    if (str.contains('unavailable') || str.contains('SocketException')) {
      return const AppError(
          message: 'No internet connection. Please try again.',
          code: 'network-error');
    }
    if (str.contains('storage')) {
      return const AppError(
          message: 'File upload failed. Please try again.', code: 'storage-error');
    }
    return AppError(message: 'Something went wrong. Please try again.', original: e);
  }

  @override
  String toString() => 'AppError($code): $message';
}
