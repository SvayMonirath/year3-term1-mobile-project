import 'course.dart';
import 'work_step.dart';

class RecommendedAction {
  final WorkStep step;
  final String assignmentId;
  final String assignmentTitle;
  final DateTime? dueDate;
  final String courseId;
  final String courseName;
  final CourseColor courseColor;
  final double priorityScore;

  const RecommendedAction({
    required this.step,
    required this.assignmentId,
    required this.assignmentTitle,
    this.dueDate,
    required this.courseId,
    required this.courseName,
    required this.courseColor,
    required this.priorityScore,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecommendedAction &&
        other.step == step &&
        other.assignmentId == assignmentId &&
        other.courseId == courseId;
  }

  @override
  int get hashCode => Object.hash(step, assignmentId, courseId);

  @override
  String toString() {
    return 'RecommendedAction(step: ${step.title}, assignment: $assignmentTitle, course: $courseName, score: $priorityScore)';
  }
}
