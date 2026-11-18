import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_project/model/assignment.dart';
import 'package:mobile_project/model/work_step.dart';

void main() {
  group('Assignment Model', () {
    test('instantiates with optional null dueDate', () {
      final assignment = Assignment(
        id: 'a1',
        courseId: 'c1',
        title: 'Undated Homework',
        dueDate: null,
      );

      expect(assignment.dueDate, isNull);
      expect(assignment.isOverdue, isFalse);
    });

    test('correctly computes isOverdue when dueDate is provided', () {
      final pastDate = DateTime.now().subtract(const Duration(hours: 1));
      final futureDate = DateTime.now().add(const Duration(days: 2));

      final overdueAssignment = Assignment(
        id: 'a_overdue',
        courseId: 'c1',
        title: 'Overdue Task',
        dueDate: pastDate,
      );
      expect(overdueAssignment.isOverdue, isTrue);

      final upcomingAssignment = Assignment(
        id: 'a_upcoming',
        courseId: 'c1',
        title: 'Upcoming Task',
        dueDate: futureDate,
      );
      expect(upcomingAssignment.isOverdue, isFalse);

      overdueAssignment.completeAll();
      expect(overdueAssignment.isOverdue, isFalse);
    });

    test('supports updating dueDate to null or future date', () {
      final assignment = Assignment(
        id: 'a1',
        courseId: 'c1',
        title: 'Task',
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );

      assignment.dueDate = null;
      expect(assignment.dueDate, isNull);
      expect(assignment.isOverdue, isFalse);
    });

    test('manages steps and progress calculations accurately', () {
      final assignment = Assignment(
        id: 'a1',
        courseId: 'c1',
        title: 'Task with Steps',
        dueDate: null,
      );

      final step1 = WorkStep(id: 's1', title: 'Step 1', estimatedMinutes: 20);
      final step2 = WorkStep(id: 's2', title: 'Step 2', estimatedMinutes: 30);
      assignment.addStep(step1);
      assignment.addStep(step2);

      expect(assignment.steps.length, equals(2));
      expect(assignment.remainingMinutes, equals(50));
      expect(assignment.progress, equals(0.0));

      step1.complete();
      expect(assignment.progress, equals(0.5));
      expect(assignment.remainingMinutes, equals(30));

      assignment.completeAll();
      expect(assignment.isCompleted, isTrue);
      expect(assignment.progress, equals(1.0));
      expect(assignment.remainingMinutes, equals(0));
    });
  });
}
