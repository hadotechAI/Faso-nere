import 'dart:math';

class OtpService {
  static String? _currentOtp;
  static DateTime? _expiresAt;

  static String generate() {
    final rng = Random.secure();
    _currentOtp = List.generate(6, (_) => rng.nextInt(10)).join();
    _expiresAt = DateTime.now().add(const Duration(minutes: 1));
    return _currentOtp!;
  }

  static bool validate(String input) {
    if (_currentOtp == null || _expiresAt == null) return false;
    if (DateTime.now().isAfter(_expiresAt!)) return false;
    return input.trim() == _currentOtp;
  }

  static int get secondsLeft =>
      _expiresAt == null ? 0 : _expiresAt!.difference(DateTime.now()).inSeconds.clamp(0, 60);

  static bool get isExpired =>
      _expiresAt == null || DateTime.now().isAfter(_expiresAt!);
}
