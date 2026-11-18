class StudyProfile {
  static const int minGoalMinutes = 15;
  static const int maxGoalMinutes = 720;
  static const int minStepMinutes = 5;
  static const int maxStepMinutes = 120;
  static const int minBreakMinutes = 1;
  static const int maxBreakMinutes = 60;

  int _dailyStudyGoalMinutes;
  int _dailyWorkloadLimitMinutes;
  int _stepDurationMinutes;
  int _breakDurationMinutes;

  StudyProfile({
    int dailyStudyGoalMinutes = 120,
    int? dailyWorkloadLimitMinutes,
    this._stepDurationMinutes = 25,
    this._breakDurationMinutes = 5,
  }) : _dailyStudyGoalMinutes = dailyStudyGoalMinutes,
       _dailyWorkloadLimitMinutes = dailyWorkloadLimitMinutes ??
           (dailyStudyGoalMinutes > 240 ? dailyStudyGoalMinutes : 240) {
    _validate(
      dailyStudyGoalMinutes: _dailyStudyGoalMinutes,
      dailyWorkloadLimitMinutes: _dailyWorkloadLimitMinutes,
      stepDurationMinutes: _stepDurationMinutes,
      breakDurationMinutes: _breakDurationMinutes,
    );
  }

  static void _validate({
    required int dailyStudyGoalMinutes,
    required int dailyWorkloadLimitMinutes,
    required int stepDurationMinutes,
    required int breakDurationMinutes,
  }) {
    if (dailyStudyGoalMinutes < minGoalMinutes ||
        dailyStudyGoalMinutes > maxGoalMinutes) {
      throw ArgumentError(
        'daily study goal minutes must be between $minGoalMinutes and $maxGoalMinutes',
      );
    }
    if (dailyWorkloadLimitMinutes < dailyStudyGoalMinutes ||
        dailyWorkloadLimitMinutes > maxGoalMinutes) {
      throw ArgumentError(
        'daily workload limit minutes must be between daily study goal ($dailyStudyGoalMinutes) and $maxGoalMinutes',
      );
    }
    if (stepDurationMinutes < minStepMinutes ||
        stepDurationMinutes > maxStepMinutes) {
      throw ArgumentError(
        'step duration minutes must be between $minStepMinutes and $maxStepMinutes',
      );
    }
    if (breakDurationMinutes < minBreakMinutes ||
        breakDurationMinutes > maxBreakMinutes) {
      throw ArgumentError(
        'break duration minutes must be between $minBreakMinutes and $maxBreakMinutes',
      );
    }
  }

  int get dailyStudyGoalMinutes => _dailyStudyGoalMinutes;
  int get dailyWorkloadLimitMinutes => _dailyWorkloadLimitMinutes;
  int get stepDurationMinutes => _stepDurationMinutes;
  int get breakDurationMinutes => _breakDurationMinutes;

  void update({
    int? dailyStudyGoalMinutes,
    int? dailyWorkloadLimitMinutes,
    int? stepDurationMinutes,
    int? breakDurationMinutes,
  }) {
    final newGoal = dailyStudyGoalMinutes ?? _dailyStudyGoalMinutes;
    var newLimit = dailyWorkloadLimitMinutes ?? _dailyWorkloadLimitMinutes;
    final newStep = stepDurationMinutes ?? _stepDurationMinutes;
    final newBreak = breakDurationMinutes ?? _breakDurationMinutes;

    // auto-adjust limit if goal exceeds current limit to prevent validation crashes
    if (newGoal > newLimit) {
      newLimit = newGoal;
    }

    _validate(
      dailyStudyGoalMinutes: newGoal,
      dailyWorkloadLimitMinutes: newLimit,
      stepDurationMinutes: newStep,
      breakDurationMinutes: newBreak,
    );

    _dailyStudyGoalMinutes = newGoal;
    _dailyWorkloadLimitMinutes = newLimit;
    _stepDurationMinutes = newStep;
    _breakDurationMinutes = newBreak;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudyProfile &&
        other._dailyStudyGoalMinutes == _dailyStudyGoalMinutes &&
        other._dailyWorkloadLimitMinutes == _dailyWorkloadLimitMinutes &&
        other._stepDurationMinutes == _stepDurationMinutes &&
        other._breakDurationMinutes == _breakDurationMinutes;
  }

  @override
  int get hashCode => Object.hash(
    _dailyStudyGoalMinutes,
    _dailyWorkloadLimitMinutes,
    _stepDurationMinutes,
    _breakDurationMinutes,
  );

  @override
  String toString() {
    return 'StudyProfile(goal: ${_dailyStudyGoalMinutes}m, workloadLimit: ${_dailyWorkloadLimitMinutes}m, step: ${_stepDurationMinutes}m, break: ${_breakDurationMinutes}m)';
  }
}
