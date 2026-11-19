class StudyProfile {
  int dailyStudyGoalMinutes;
  int dailyWorkloadLimitMinutes;
  int stepDurationMinutes;
  int breakDurationMinutes;

  StudyProfile({
    this.dailyStudyGoalMinutes = 120,
    int? dailyWorkloadLimitMinutes,
    this.stepDurationMinutes = 25,
    this.breakDurationMinutes = 5,
  }) : dailyWorkloadLimitMinutes = dailyWorkloadLimitMinutes ?? 240 {
    // raise limit if goal is bigger than limit
    if (dailyStudyGoalMinutes > this.dailyWorkloadLimitMinutes) {
      this.dailyWorkloadLimitMinutes = dailyStudyGoalMinutes;
    }
    _checkBounds();
  }

  void _checkBounds() {
    if (dailyStudyGoalMinutes < 15 || dailyStudyGoalMinutes > 720) {
      throw ArgumentError('daily study goal must be between 15 and 720 minutes');
    }
    if (dailyWorkloadLimitMinutes < dailyStudyGoalMinutes ||
        dailyWorkloadLimitMinutes > 720) {
      throw ArgumentError('workload limit cannot be less than daily goal');
    }
    if (stepDurationMinutes < 5 || stepDurationMinutes > 120) {
      throw ArgumentError('step duration must be between 5 and 120 minutes');
    }
    if (breakDurationMinutes < 1 || breakDurationMinutes > 60) {
      throw ArgumentError('break duration must be between 1 and 60 minutes');
    }
  }

  void update({
    int? dailyStudyGoalMinutes,
    int? dailyWorkloadLimitMinutes,
    int? stepDurationMinutes,
    int? breakDurationMinutes,
  }) {
    if (dailyStudyGoalMinutes != null) {
      this.dailyStudyGoalMinutes = dailyStudyGoalMinutes;
    }
    if (dailyWorkloadLimitMinutes != null) {
      this.dailyWorkloadLimitMinutes = dailyWorkloadLimitMinutes;
    }
    if (stepDurationMinutes != null) {
      this.stepDurationMinutes = stepDurationMinutes;
    }
    if (breakDurationMinutes != null) {
      this.breakDurationMinutes = breakDurationMinutes;
    }

    // raise limit if goal is bigger than limit
    if (this.dailyStudyGoalMinutes > this.dailyWorkloadLimitMinutes) {
      this.dailyWorkloadLimitMinutes = this.dailyStudyGoalMinutes;
    }

    _checkBounds();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudyProfile &&
        other.dailyStudyGoalMinutes == dailyStudyGoalMinutes &&
        other.dailyWorkloadLimitMinutes == dailyWorkloadLimitMinutes &&
        other.stepDurationMinutes == stepDurationMinutes &&
        other.breakDurationMinutes == breakDurationMinutes;
  }

  @override
  int get hashCode => Object.hash(
    dailyStudyGoalMinutes,
    dailyWorkloadLimitMinutes,
    stepDurationMinutes,
    breakDurationMinutes,
  );

  @override
  String toString() {
    return 'StudyProfile(goal: ${dailyStudyGoalMinutes}m, limit: ${dailyWorkloadLimitMinutes}m, step: ${stepDurationMinutes}m, break: ${breakDurationMinutes}m)';
  }
}
