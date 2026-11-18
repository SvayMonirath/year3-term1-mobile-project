import '../model/course.dart';
import '../model/assignment.dart';
import '../model/work_step.dart';
import '../model/study_profile.dart';

class StudyService {
  final List<Course> _courses = [];
  final StudyProfile _profile = StudyProfile();

  List<Course> get courses => List.unmodifiable(_courses);
  StudyProfile get profile => _profile;

  void updateProfile({
    int? dailyStudyGoalMinutes,
    int? dailyWorkloadLimitMinutes,
    int? stepDurationMinutes,
    int? breakDurationMinutes,
  }) {
    _profile.update(
      dailyStudyGoalMinutes: dailyStudyGoalMinutes,
      dailyWorkloadLimitMinutes: dailyWorkloadLimitMinutes,
      stepDurationMinutes: stepDurationMinutes,
      breakDurationMinutes: breakDurationMinutes,
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

  // Create an assignment with an optional due date (future or past backlog dates supported)
  Assignment createAssignmentForCourse({
    required String courseId,
    required String assignmentId,
    required String title,
    DateTime? dueDate,
    AssignmentType type = AssignmentType.homework,
    List<WorkStep>? steps,
  }) {
    final course = findCourseById(courseId);
    if (course == null) {
      throw ArgumentError('course not found');
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
      assignment.dueDate = dueDate;
    }
    if (type != null) {
      assignment.type = type;
    }
  }

  // Add step to an active assignment; defaults to user's configured step duration
  WorkStep addStepToAssignment({
    required String assignmentId,
    required String stepId,
    required String title,
    int? estimatedMinutes,
  }) {
    final assignment = findAssignmentById(assignmentId);
    if (assignment == null) {
      throw ArgumentError('assignment not found');
    }

    if (assignment.isCompleted) {
      throw StateError('cannot add step to completed assignment');
    }

    final step = WorkStep(
      id: stepId,
      title: title,
      estimatedMinutes: estimatedMinutes ?? _profile.stepDurationMinutes,
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

    // auto finish assignment if all steps are completed
    if (assignment.pendingSteps.isEmpty && assignment.steps.isNotEmpty) {
      assignment.completeAll();
    }
  }

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

    if (assignment.isCompleted) {
      assignment.uncomplete();
    }
  }

  // Retrieve active assignments due on a specific calendar day
  List<Assignment> getAssignmentsDueOn(
    DateTime date, {
    bool includeOverdue = false,
  }) {
    final target = DateTime(date.year, date.month, date.day);
    final List<Assignment> result = [];
    for (final course in _courses) {
      for (final assignment in course.activeAssignments) {
        if (assignment.dueDate == null) continue;

        final due = DateTime(
          assignment.dueDate!.year,
          assignment.dueDate!.month,
          assignment.dueDate!.day,
        );
        if (due == target || (includeOverdue && due.isBefore(target))) {
          result.add(assignment);
        }
      }
    }
    return result;
  }

  // Calculate remaining workload minutes for tasks due on a given day
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

  // Check if homework due on a given day exceeds user capacity
  bool isWorkloadOverloaded(
    DateTime date, {
    int? dailyLimitMinutes,
    bool includeOverdue = false,
  }) {
    final limit = dailyLimitMinutes ?? _profile.dailyWorkloadLimitMinutes;
    return calculateDailyWorkloadMinutes(date, includeOverdue: includeOverdue) >
        limit;
  }
}
