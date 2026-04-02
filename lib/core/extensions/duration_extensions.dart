extension DurationExtensions on Duration {
  /// Delays the execution for the given duration.
  /// Example: await const Duration(seconds: 2).delay();
  Future<void> delay() => Future.delayed(this);

  /// Formats the duration to mm:ss format.
  /// Example: const Duration(minutes: 2, seconds: 30).format() // 02:30
  String format() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(inMinutes.remainder(60));
    final seconds = twoDigits(inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
