import '../model/course.dart';
import '../model/assignment.dart';
import '../model/focus_session.dart';
import '../model/recommended_action.dart';
import 'study_service.dart';

class FocusService {
  final StudyService studyService;
  final List<FocusSession> _sessions = [];

  FocusService({required this.studyService});

  List<FocusSession> get sessions => List.unmodifiable(_sessions);

  // Log a completed focus timer session
  FocusSession recordFocusSession({
    required String id,
    required String courseId,
    required String assignmentId,
    required String stepId,
    required int minutesSpent,
    DateTime? completedAt,
  }) {
    final course = studyService.findCourseById(courseId);
    if (course == null) {
      throw ArgumentError('course not found');
    }

    final assignment = course.findAssignmentById(assignmentId);
    if (assignment == null) {
      throw ArgumentError('assignment not found');
    }

    final stepExists = assignment.steps.any((s) => s.id == stepId);
    if (!stepExists) {
      throw ArgumentError('step not found');
    }

    final session = FocusSession(
      id: id,
      courseId: courseId,
      assignmentId: assignmentId,
      stepId: stepId,
      minutesSpent: minutesSpent,
      completedAt: completedAt,
    );

    _sessions.add(session);
    return session;
  }

  // Atomically record timer session and mark step finished
  FocusSession recordSessionAndCompleteStep({
    required String id,
    required String courseId,
    required String assignmentId,
    required String stepId,
    required int minutesSpent,
    DateTime? completedAt,
  }) {
    final session = recordFocusSession(
      id: id,
      courseId: courseId,
      assignmentId: assignmentId,
      stepId: stepId,
      minutesSpent: minutesSpent,
      completedAt: completedAt,
    );

    studyService.completeStep(
      assignmentId: assignmentId,
      stepId: stepId,
    );

    return session;
  }

  // Total study minutes logged for a specific course
  int getTotalStudyMinutesForCourse(String courseId) {
    var total = 0;
    for (final session in _sessions) {
      if (session.courseId == courseId) {
        total += session.minutesSpent;
      }
    }
    return total;
  }

  // Total study minutes logged on a specific calendar day
  int getDailyStudyMinutes(DateTime date, {String? courseId}) {
    final target = DateTime(date.year, date.month, date.day);
    var total = 0;
    for (final session in _sessions) {
      final sessionDay = DateTime(
        session.completedAt.year,
        session.completedAt.month,
        session.completedAt.day,
      );
      if (sessionDay == target) {
        if (courseId == null || session.courseId == courseId) {
          total += session.minutesSpent;
        }
      }
    }
    return total;
  }

  // Progress towards daily study goal
  double getDailyGoalProgress(DateTime date) {
    final goal = studyService.profile.dailyStudyGoalMinutes;
    if (goal == 0) return 1.0;
    return getDailyStudyMinutes(date) / goal;
  }

  // Check if daily study goal has been reached
  bool isDailyGoalMet(DateTime date) {
    return getDailyStudyMinutes(date) >=
        studyService.profile.dailyStudyGoalMinutes;
  }

  // Calculate consecutive study streak (today is pending until midnight)
  int getCurrentStudyStreakDays({DateTime? relativeNow}) {
    if (_sessions.isEmpty) return 0;

    final uniqueDays = _sessions.map((s) {
      return DateTime(
        s.completedAt.year,
        s.completedAt.month,
        s.completedAt.day,
      );
    }).toSet();

    final now = relativeNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var streak = 0;
    DateTime checkDate;

    if (uniqueDays.contains(today)) {
      streak = 1;
      checkDate = DateTime(today.year, today.month, today.day - 1);
    } else {
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      if (!uniqueDays.contains(yesterday)) {
        return 0;
      }
      streak = 1;
      checkDate = DateTime(yesterday.year, yesterday.month, yesterday.day - 1);
    }

    while (uniqueDays.contains(checkDate)) {
      streak++;
      checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
    }

    return streak;
  }

  // Calculate all-time longest streak in days
  int getLongestStudyStreakDays() {
    if (_sessions.isEmpty) return 0;

    final sortedDays = _sessions.map((s) {
      return DateTime(
        s.completedAt.year,
        s.completedAt.month,
        s.completedAt.day,
      );
    }).toSet().toList()
      ..sort();

    var longest = 1;
    var current = 1;

    for (var i = 0; i < sortedDays.length - 1; i++) {
      final nextDay = DateTime(
        sortedDays[i].year,
        sortedDays[i].month,
        sortedDays[i].day + 1,
      );
      if (sortedDays[i + 1] == nextDay) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }

    return longest;
  }

  // Check if task was worked on within the last 24 hours
  bool isTaskInProgress(String assignmentId, {DateTime? relativeNow}) {
    final now = relativeNow ?? DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));
    return _sessions.any(
      (s) => s.assignmentId == assignmentId && s.completedAt.isAfter(cutoff),
    );
  }

  // Priority scoring with overdue deprioritization and calm baseline for undated work
  double calculatePriorityScore(
    Assignment assignment, {
    DateTime? relativeNow,
  }) {
    final now = relativeNow ?? DateTime.now();

    double urgencyScore;
    int? hoursRemaining;

    if (assignment.dueDate == null) {
      urgencyScore = 20.0;
    } else {
      final diff = assignment.dueDate!.difference(now);
      hoursRemaining = diff.inHours;

      if (hoursRemaining < -168) {
        // Overdue by more than 7 days: deprioritize so upcoming deadlines aren't blocked
        urgencyScore = 40.0;
      } else if (hoursRemaining <= 0) {
        urgencyScore = 100.0;
      } else if (hoursRemaining <= 24) {
        urgencyScore = 80.0;
      } else if (hoursRemaining <= 72) {
        urgencyScore = 50.0;
      } else {
        urgencyScore = 20.0;
      }
    }

    final momentumScore = assignment.progress * 30.0;
    final resumeBonus =
        isTaskInProgress(assignment.id, relativeNow: now) ? 15.0 : 0.0;

    double typeBonus;
    switch (assignment.type) {
      case AssignmentType.exam:
        typeBonus = 15.0;
        break;
      case AssignmentType.project:
        typeBonus = 10.0;
        break;
      case AssignmentType.homework:
        typeBonus = 0.0;
        break;
    }

    final burdenBonus = (assignment.remainingMinutes > 120 &&
            hoursRemaining != null &&
            hoursRemaining <= 48 &&
            hoursRemaining > 0)
        ? 10.0
        : 0.0;

    return urgencyScore + momentumScore + resumeBonus + typeBonus + burdenBonus;
  }

  // Diverse recommendations selecting the top pending step from distinct assignments
  List<RecommendedAction> getTopRecommendedSteps({
    int limit = 3,
    DateTime? relativeNow,
  }) {
    if (limit <= 0) return [];

    final List<_AssignmentCandidate> candidates = [];

    for (final course in studyService.courses) {
      for (final assignment in course.activeAssignments) {
        if (assignment.pendingSteps.isEmpty) continue;

        final score = calculatePriorityScore(
          assignment,
          relativeNow: relativeNow,
        );
        candidates.add(_AssignmentCandidate(
          course: course,
          assignment: assignment,
          score: score,
        ));
      }
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));

    final List<RecommendedAction> results = [];
    for (final candidate in candidates) {
      final step = candidate.assignment.pendingSteps.first;
      results.add(RecommendedAction(
        step: step,
        assignmentId: candidate.assignment.id,
        assignmentTitle: candidate.assignment.title,
        dueDate: candidate.assignment.dueDate,
        courseId: candidate.course.id,
        courseName: candidate.course.name,
        courseColor: candidate.course.color,
        priorityScore: candidate.score,
      ));

      if (results.length >= limit) {
        break;
      }
    }

    return results;
  }

  // Get the single top recommended step
  RecommendedAction? getTopRecommendedStep({DateTime? relativeNow}) {
    final steps = getTopRecommendedSteps(limit: 1, relativeNow: relativeNow);
    return steps.isNotEmpty ? steps.first : null;
  }
}

class _AssignmentCandidate {
  final Course course;
  final Assignment assignment;
  final double score;

  _AssignmentCandidate({
    required this.course,
    required this.assignment,
    required this.score,
  });
}
