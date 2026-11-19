import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_project/model/course.dart';
import 'package:mobile_project/model/assignment.dart';
import 'package:mobile_project/service/study_service.dart';

void main() {
  late StudyService service;
  late Course testCourse;

  setUp(() {
    service = StudyService();
    testCourse = Course(id: 'c1', name: 'Mobile Development');
    service.addCourse(testCourse);
  });

  group('StudyService - Courses and Assignments', () {
    test('deleting a course also deletes its assignments and steps', () {
      final dueDate = DateTime.now().add(const Duration(days: 3));
      final assignment = service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a1',
        title: 'Milestone 2',
        dueDate: dueDate,
        type: AssignmentType.project,
      );

      final step1 = service.addStepToAssignment(
        assignmentId: 'a1',
        stepId: 's1',
        title: 'Draft diagrams',
        estimatedMinutes: 30,
      );

      expect(assignment.steps.length, equals(1));
      expect(assignment.steps.first, equals(step1));
      expect(assignment.remainingMinutes, equals(30));

      final removed = service.removeCourse('c1');
      expect(removed, isTrue);
      expect(service.courses, isEmpty);
      expect(service.findAssignmentById('a1'), isNull);
    });

    test('allows creating tasks with no due date or past due dates', () {
      // Optional undated assignment
      final undated = service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_undated',
        title: 'Backlog Reading',
        dueDate: null,
      );
      expect(undated.dueDate, isNull);
      expect(undated.isOverdue, isFalse);

      // Backlog overdue assignment
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final overdue = service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_past',
        title: 'Catch-up Lab',
        dueDate: pastDate,
      );
      expect(overdue.isOverdue, isTrue);
    });

    test('completing all steps marks assignment done and reopening uncompletes it', () {
      final dueDate = DateTime.now().add(const Duration(days: 2));
      service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a1',
        title: 'Lab 1',
        dueDate: dueDate,
      );
      service.addStepToAssignment(
        assignmentId: 'a1',
        stepId: 's1',
        title: 'Only Step',
      );

      service.completeStep(assignmentId: 'a1', stepId: 's1');
      final assignment = service.findAssignmentById('a1')!;
      expect(assignment.isCompleted, isTrue);
      expect(assignment.progress, equals(1.0));

      service.uncompleteStep(assignmentId: 'a1', stepId: 's1');
      expect(assignment.isCompleted, isFalse);
      expect(assignment.progress, equals(0.0));
      expect(assignment.pendingSteps.length, equals(1));
    });

    test('cannot add steps to a completed assignment', () {
      final assignment = service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_done',
        title: 'Done Task',
        dueDate: null,
      );
      assignment.completeAll();

      expect(
        () => service.addStepToAssignment(
          assignmentId: 'a_done',
          stepId: 's_fail',
          title: 'Extra step',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('StudyService - Workload and Profile', () {
    test('calculates daily study minutes and warns when overloaded', () {
      final targetDate = DateTime(2026, 11, 20);

      service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a1',
        title: 'Assignment 1',
        dueDate: DateTime(2026, 11, 20, 14, 0),
      );
      service.addStepToAssignment(
        assignmentId: 'a1',
        stepId: 's1',
        title: 'Step 1',
        estimatedMinutes: 150,
      );

      service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a2',
        title: 'Assignment 2',
        dueDate: DateTime(2026, 11, 20, 18, 0),
      );
      service.addStepToAssignment(
        assignmentId: 'a2',
        stepId: 's2',
        title: 'Step 2',
        estimatedMinutes: 120,
      );

      // Total = 270 minutes, which exceeds default workload limit of 240
      expect(service.calculateDailyWorkloadMinutes(targetDate), equals(270));
      expect(service.isWorkloadOverloaded(targetDate), isTrue);

      // But does not exceed a 300-minute custom limit
      expect(
        service.isWorkloadOverloaded(targetDate, dailyLimitMinutes: 300),
        isFalse,
      );
    });

    test('updates study profile settings', () {
      service.updateProfile(
        dailyStudyGoalMinutes: 150,
        dailyWorkloadLimitMinutes: 300,
        stepDurationMinutes: 30,
        breakDurationMinutes: 10,
      );

      expect(service.profile.dailyStudyGoalMinutes, equals(150));
      expect(service.profile.dailyWorkloadLimitMinutes, equals(300));
      expect(service.profile.stepDurationMinutes, equals(30));
      expect(service.profile.breakDurationMinutes, equals(10));
    });
  });
}
