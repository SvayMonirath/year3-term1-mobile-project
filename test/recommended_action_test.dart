import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_project/model/course.dart';
import 'package:mobile_project/model/work_step.dart';
import 'package:mobile_project/model/recommended_action.dart';

void main() {
  group('RecommendedAction', () {
    test('holds task details, course info, and priority score', () {
      final step = WorkStep(id: 's1', title: 'Write Intro', estimatedMinutes: 25);
      final dueDate = DateTime.now().add(const Duration(days: 2));

      final action = RecommendedAction(
        step: step,
        assignmentId: 'a1',
        assignmentTitle: 'Project Report',
        dueDate: dueDate,
        courseId: 'c1',
        courseName: 'Mobile Development',
        courseColor: CourseColor.purple,
        priorityScore: 85.5,
      );

      expect(action.step.id, equals('s1'));
      expect(action.assignmentId, equals('a1'));
      expect(action.assignmentTitle, equals('Project Report'));
      expect(action.dueDate, equals(dueDate));
      expect(action.courseId, equals('c1'));
      expect(action.courseName, equals('Mobile Development'));
      expect(action.courseColor, equals(CourseColor.purple));
      expect(action.priorityScore, equals(85.5));
    });

    test('is equal when task and course match', () {
      final step = WorkStep(id: 's1', title: 'Step 1');
      final a1 = RecommendedAction(
        step: step,
        assignmentId: 'a1',
        assignmentTitle: 'Title',
        courseId: 'c1',
        courseName: 'Course',
        courseColor: CourseColor.blue,
        priorityScore: 70.0,
      );
      final a2 = RecommendedAction(
        step: step,
        assignmentId: 'a1',
        assignmentTitle: 'Title',
        courseId: 'c1',
        courseName: 'Course',
        courseColor: CourseColor.blue,
        priorityScore: 70.0,
      );

      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
      expect(a1.toString(), contains('RecommendedAction'));
    });
  });
}
