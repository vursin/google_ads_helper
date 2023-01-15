/// Control when to excute the function
class CallCountOption {
  /// Call this function after [firstCount] times
  /// => show the ads in the first time
  final int firstCount;

  /// Call this function after [repeatCount] times, disable repeat if this value is 0
  /// => show the ads from the second time
  final int repeatCount;

  const CallCountOption({
    required this.firstCount,
    required this.repeatCount,
  });

  @override
  String toString() {
    return 'CallCountOption(firstCount: $firstCount, repeatCount: $repeatCount)';
  }
}
