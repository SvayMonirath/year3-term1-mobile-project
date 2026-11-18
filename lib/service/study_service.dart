import '../model/course.dart';
import '../model/assignment.dart';
import '../model/work_step.dart';
import '../model/focus_session.dart';
import '../model/study_profile.dart';

class StudyService {
  final List<Course> _courses = [];
  final List<FocusSession> _sessions = [];
  final StudyProfile _profile = StudyProfile();

  List<Course> get courses => List.unmodifiable(_courses);
  List<FocusSession> get sessions => List.unmodifiable(_sessions);
  StudyProfile get profile => _profile;

  void updateProfile({
    int? dailyGoalMinutes,
    int? maxDailyWorkloadMinutes,
    int? defaultStepMinutes,
  }) {
    _profile.update(
      dailyGoalMinutes: dailyGoalMinutes,
      maxDailyWorkloadMinutes: maxDailyWorkloadMinutes,
      defaultStepMinutes: defaultStepMinutes,
    );
  }

  void addCourse(Course course) {
    final exists = _courses.any((c) => c.id == course.id);
    if (exists) {
      throw ArgumentError('course already exists');
    }
    _courses.add(course);
  }

  bool removeCourse(String courseId) {
    final index = _courses.indexWhere((c) => c.id == courseId);
    if (index != -1) {
      _courses.removeAt(index);
      return true;
    }
    return false;
  }

  Course? findCourseById(String courseId) {
    try {
      return _courses.firstWhere((c) => c.id == courseId);
    } catch (_) {
      return null;
    }
  }

  void updateCourse({
    required String courseId,
    String? name,
    CourseColor? color,
  }) {
    final course = findCourseById(courseId);
    if (course == null) {
      throw ArgumentError('course not found');
    }
    if (name != null) {
      course.name = name;
    }
    if (color != null) {
      course.color = color;
    }
  }

  // create new homework under a course with a future date
  Assignment createAssignmentForCourse({
    required String courseId,
    required String assignmentId,
    required String title,
    required DateTime dueDate,
    AssignmentType type = AssignmentType.homework,
    List<WorkStep>? steps,
  }) {
    final course = findCourseById(courseId);
    if (course == null) {
      throw ArgumentError('course not found');
    }

    // cant set deadline in the past
    if (dueDate.isBefore(DateTime.now())) {
      throw ArgumentError('due date cannot be in the past');
    }

    final assignment = Assignment(
      id: assignmentId,
      courseId: courseId,
      title: title,
      dueDate: dueDate,
      type: type,
      steps: steps,
    );

    course.addAssignment(assignment);
    return assignment;
  }

  bool removeAssignmentFromCourse({
    required String courseId,
    required String assignmentId,
  }) {
    final course = findCourseById(courseId);
    if (course == null) {
      throw ArgumentError('course not found');
    }
    return course.removeAssignment(assignmentId);
  }

  Assignment? findAssignmentById(String assignmentId) {
    for (final course in _courses) {
      final assignment = course.findAssignmentById(assignmentId);
      if (assignment != null) {
        return assignment;
      }
    }
    return null;
  }

  void updateAssignment({
    required String assignmentId,
    String? title,
    DateTime? dueDate,
    AssignmentType? type,
  }) {
    final assignment = findAssignmentById(assignmentId);
    if (assignment == null) {
      throw ArgumentError('assignment not found');
    }
    if (title != null) {
      assignment.title = title;
    }
    if (dueDate != null) {
      if (dueDate.isBefore(DateTime.now())) {
        throw ArgumentError('due date cannot be in the past');
      }
      assignment.dueDate = dueDate;
    }
    if (type != null) {
      assignment.type = type;
    }
  }

  // add step to an assignment that is still open
  WorkStep addStepToAssignment({
    required String assignmentId,
    required String stepId,
    required String title,
    int estimatedMinutes = WorkStep.defaultMinutes,
  }) {
    final assignment = findAssignmentById(assignmentId);
    if (assignment == null) {
      throw ArgumentError('assignment not found');
    }

    // cant add work to an assignment already done
    if (assignment.isCompleted) {
      throw StateError('cannot add step to completed assignment');
    }

    final step = WorkStep(
      id: stepId,
      title: title,
      estimatedMinutes: estimatedMinutes,
    );

    assignment.addStep(step);
    return step;
  }

  bool removeStepFromAssignment({
    required String assignmentId,
    required String stepId,
  }) {
    final assignment = findAssignmentById(assignmentId);
    if (assignment == null) {
      throw ArgumentError('assignment not found');
    }
    return assignment.removeStep(stepId);
  }

  // mark step finished, and auto finish assignment if it was the last step
  void completeStep({required String assignmentId, required String stepId}) {
    final assignment = findAssignmentById(assignmentId);
    if (assignment == null) {
      throw ArgumentError('assignment not found');
    }

    final step = assignment.steps.firstWhere(
      (s) => s.id == stepId,
      orElse: () => throw ArgumentError('step not found'),
    );

    step.complete();

    // if all steps are done mark assignment done
    if (assignment.pendingSteps.isEmpty && assignment.steps.isNotEmpty) {
      assignment.completeAll();
    }
  }

  // reopen step and reopen parent assignment
  void uncompleteStep({required String assignmentId, required String stepId}) {
    final assignment = findAssignmentById(assignmentId);
    if (assignment == null) {
      throw ArgumentError('assignment not found');
    }

    final step = assignment.steps.firstWhere(
      (s) => s.id == stepId,
      orElse: () => throw ArgumentError('step not found'),
    );

    step.uncomplete();

    // reopen assignment if it was marked done
    if (assignment.isCompleted) {
      assignment.uncomplete();
    }
  }

  // log a completed focus timer session
  FocusSession recordFocusSession({
    required String id,
    required String courseId,
    required String assignmentId,
    required String stepId,
    required int minutesSpent,
    DateTime? completedAt,
  }) {
    final course = findCourseById(courseId);
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

  // total study minutes logged for this course
  int getTotalStudyMinutesForCourse(String courseId) {
    var total = 0;
    for (final session in _sessions) {
      if (session.courseId == courseId) {
        total += session.minutesSpent;
      }
    }
    return total;
  }

  // calculate study streak in days
  int getCurrentStudyStreakDays({int allowedMissedDays = 1}) {
    if (_sessions.isEmpty) return 0;

    final uniqueDays = _sessions.map((s) {
      return DateTime(
        s.completedAt.year,
        s.completedAt.month,
        s.completedAt.day,
      );
    }).toSet();

    var streak = 0;
    final now = DateTime.now();
    var checkDate = DateTime(now.year, now.month, now.day);
    var missed = 0;

    if (!uniqueDays.contains(checkDate)) {
      checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
      if (!uniqueDays.contains(checkDate)) {
        return 0;
      }
    }

    while (true) {
      if (uniqueDays.contains(checkDate)) {
        streak++;
        missed = 0;
      } else {
        missed++;
        if (missed > allowedMissedDays) {
          break;
        }
      }
      checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
    }

    return streak;
  }

  // calculate longest streak in dyas
  int getLongestStudyStreakDays() {
    if (_sessions.isEmpty) return 0;

    final sortedDays =
        _sessions
            .map(
              (s) => DateTime(
                s.completedAt.year,
                s.completedAt.month,
                s.completedAt.day,
              ),
            )
            .toSet()
            .toList()
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

  // get all homework due on this specific day
  List<Assignment> getAssignmentsDueOn(
    DateTime date, {
    bool includeOverdue = false,
  }) {
    final target = DateTime(date.year, date.month, date.day);
    final List<Assignment> result = [];
    for (final course in _courses) {
      for (final assignment in course.activeAssignments) {
        final due = DateTime(
          assignment.dueDate.year,
          assignment.dueDate.month,
          assignment.dueDate.day,
        );
        if (due == target || (includeOverdue && due.isBefore(target))) {
          result.add(assignment);
        }
      }
    }
    return result;
  }

  // calculate total study minutes due on this day
  int calculateDailyWorkloadMinutes(
    DateTime date, {
    bool includeOverdue = false,
  }) {
    final assignments = getAssignmentsDueOn(
      date,
      includeOverdue: includeOverdue,
    );
    var total = 0;
    for (final a in assignments) {
      total += a.remainingMinutes;
    }
    return total;
  }

  // check if the daily homework workload exceeds the student's capacity which is 4hours max
  bool isWorkloadOverloaded(
    DateTime date, {
    int? dailyLimitMinutes,
    bool includeOverdue = false,
  }) {
    final limit = dailyLimitMinutes ?? _profile.maxDailyWorkloadMinutes;
    return calculateDailyWorkloadMinutes(date, includeOverdue: includeOverdue) >
        limit;
  }

  // check if an assignment was started today and is currently paused
  bool isTaskInProgress(String assignmentId) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return _sessions.any(
      (s) => s.assignmentId == assignmentId && s.completedAt.isAfter(cutoff),
    );
  }

  // get the single best step to do right now
  WorkStep? getTopRecommendedStep() {
    final steps = getTopRecommendedSteps(limit: 1);
    return steps.isNotEmpty ? steps.first : null;
  }

  // get top 3 steps
  List<WorkStep> getTopRecommendedSteps({int limit = 3}) {
    if (limit <= 0) return [];

    final List<MapEntry<Assignment, double>> scoredAssignments = [];

    // score every active assignment
    for (final course in _courses) {
      for (final assignment in course.activeAssignments) {
        if (assignment.pendingSteps.isEmpty) continue;

        final score = calculatePriorityScore(assignment);
        scoredAssignments.add(MapEntry(assignment, score));
      }
    }

    // sort highest score first
    scoredAssignments.sort((a, b) => b.value.compareTo(a.value));

    // grab unfinished steps up to the limit
    final List<WorkStep> recommendations = [];
    for (final entry in scoredAssignments) {
      final assignment = entry.key;
      for (final step in assignment.pendingSteps) {
        recommendations.add(step);
        if (recommendations.length >= limit) {
          return recommendations;
        }
      }
    }

    return recommendations;
  }

  // recomendation base on how soon the assignment is due, how much progress has been made, and if it was recently started and paused
  double calculatePriorityScore(Assignment assignment) {
    final now = DateTime.now();
    final difference = assignment.dueDate.difference(now);
    final hoursRemaining = difference.inHours;

    double urgencyScore;
    if (hoursRemaining <= 0) {
      urgencyScore = 100.0;
    } else if (hoursRemaining <= 24) {
      urgencyScore = 80.0;
    } else if (hoursRemaining <= 72) {
      urgencyScore = 50.0;
    } else {
      urgencyScore = 20.0;
    }

    final momentumScore = assignment.progress * 30.0;

    final resumeBonus = isTaskInProgress(assignment.id) ? 15.0 : 0.0;

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

    final burdenBonus =
        (assignment.remainingMinutes > 120 && hoursRemaining <= 48)
            ? 10.0
            : 0.0;

    return urgencyScore + momentumScore + resumeBonus + typeBonus + burdenBonus;
  }

  // total study minutes logged on a specific calendar day
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

  // progress towards daily study goal (can exceed 1.0)
  double getDailyGoalProgress(DateTime date) {
    return getDailyStudyMinutes(date) / _profile.dailyGoalMinutes;
  }

  // check if daily study goal has been reached
  bool isDailyGoalMet(DateTime date) {
    return getDailyStudyMinutes(date) >= _profile.dailyGoalMinutes;
  }
}
