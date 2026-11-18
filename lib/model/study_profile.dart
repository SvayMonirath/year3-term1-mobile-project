class StudyProfile {
  static const int minGoalMinutes = 15;
  static const int maxGoalMinutes = 720;
  static const int minStepMinutes = 5;
  static const int maxStepMinutes = 120;

  int _dailyGoalMinutes;
  int _maxDailyWorkloadMinutes;
  int _defaultStepMinutes;

  StudyProfile({
    this._dailyGoalMinutes = 120,
    this._maxDailyWorkloadMinutes = 240,
    this._defaultStepMinutes = 25,
  }) {
    _validate(
      dailyGoalMinutes: _dailyGoalMinutes,
      maxDailyWorkloadMinutes: _maxDailyWorkloadMinutes,
      defaultStepMinutes: _defaultStepMinutes,
    );
  }

  static void _validate({
    required int dailyGoalMinutes,
    required int maxDailyWorkloadMinutes,
    required int defaultStepMinutes,
  }) {
    if (dailyGoalMinutes < minGoalMinutes || dailyGoalMinutes > maxGoalMinutes) {
      throw ArgumentError(
        'daily goal minutes must be between $minGoalMinutes and $maxGoalMinutes',
      );
    }
    if (maxDailyWorkloadMinutes < dailyGoalMinutes ||
        maxDailyWorkloadMinutes > maxGoalMinutes) {
      throw ArgumentError(
        'max daily workload minutes must be between daily goal ($dailyGoalMinutes) and $maxGoalMinutes',
      );
    }
    if (defaultStepMinutes < minStepMinutes ||
        defaultStepMinutes > maxStepMinutes) {
      throw ArgumentError(
        'default step minutes must be between $minStepMinutes and $maxStepMinutes',
      );
    }
  }

  int get dailyGoalMinutes => _dailyGoalMinutes;
  int get maxDailyWorkloadMinutes => _maxDailyWorkloadMinutes;
  int get defaultStepMinutes => _defaultStepMinutes;

  void update({
    int? dailyGoalMinutes,
    int? maxDailyWorkloadMinutes,
    int? defaultStepMinutes,
  }) {
    final newGoal = dailyGoalMinutes ?? _dailyGoalMinutes;
    final newMax = maxDailyWorkloadMinutes ?? _maxDailyWorkloadMinutes;
    final newStep = defaultStepMinutes ?? _defaultStepMinutes;

    _validate(
      dailyGoalMinutes: newGoal,
      maxDailyWorkloadMinutes: newMax,
      defaultStepMinutes: newStep,
    );

    _dailyGoalMinutes = newGoal;
    _maxDailyWorkloadMinutes = newMax;
    _defaultStepMinutes = newStep;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudyProfile &&
        other._dailyGoalMinutes == _dailyGoalMinutes &&
        other._maxDailyWorkloadMinutes == _maxDailyWorkloadMinutes &&
        other._defaultStepMinutes == _defaultStepMinutes;
  }

  @override
  int get hashCode => Object.hash(
    _dailyGoalMinutes,
    _maxDailyWorkloadMinutes,
    _defaultStepMinutes,
  );

  @override
  String toString() {
    return 'StudyProfile(goal: ${_dailyGoalMinutes}m, maxWorkload: ${_maxDailyWorkloadMinutes}m, step: ${_defaultStepMinutes}m)';
  }
}
