import 'dart:math';

class UserService {
  static String? _currentUserId;

  static String _generateUserId() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        16,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  static String getCurrentUserId() {
    _currentUserId ??= _generateUserId();
    return _currentUserId!;
  }

  static void resetUserId() {
    _currentUserId = null;
  }
}
