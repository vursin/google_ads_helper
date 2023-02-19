/// Control when to excute the function
class CallCountOption {
  /// Call this function after [firstCount] times
  /// => show the ads in the first time
  final int firstCount;

  /// Call this function after [repeatCount] times, disable repeat if this value is 0
  /// => show the ads from the second time
  final int repeatCount;

  /// Max number of times to reload the ads if failed
  final int maxFailedLoadAttempts;

  /// Delay in milliseconds berween 2 reload attempts
  final int delayBetweenFailedLoadMilisecconds;

  const CallCountOption({
    required this.firstCount,
    required this.repeatCount,
    required this.maxFailedLoadAttempts,
    required this.delayBetweenFailedLoadMilisecconds,
  });

  @override
  String toString() {
    return 'CallCountOption(firstCount: $firstCount, repeatCount: $repeatCount, maxFailedLoadAttempts: $maxFailedLoadAttempts)';
  }
}
