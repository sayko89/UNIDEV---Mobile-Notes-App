import 'dart:math';

final _random = Random();

/// A short, unique id such as `m2x9k1q-1h3j9z`: time-based so ids sort roughly by creation,
/// plus a random part so two notes created in the same instant don't collide.
String generateId() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  // 0x7fffffff keeps this safe on the web, where ints are JavaScript numbers.
  final random = _random.nextInt(0x7fffffff).toRadixString(36);
  return '$time-$random';
}
