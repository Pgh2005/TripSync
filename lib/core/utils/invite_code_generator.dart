import 'dart:math';

class InviteCodeGenerator {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static final Random _random = Random();

  /// مثال:
  /// TRP-X8K4MZ
  static String generate() {
    final buffer = StringBuffer('TRP-');

    for (int i = 0; i < 6; i++) {
      buffer.write(_chars[_random.nextInt(_chars.length)]);
    }

    return buffer.toString();
  }
}
