import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_project/model/course.dart';
import 'package:mobile_project/model/assignment.dart';
import 'package:mobile_project/model/work_step.dart';
import 'package:mobile_project/service/study_service.dart';

void main() {
  late StudyService service;
  late Course testCourse;

  setUp(() {
    service = StudyService();
    testCourse = Course(id: 'c1', name: 'Mobile Development');
    service.addCourse(testCourse);
  });

  group('Domain Lifecycle and Cascade', () {
    test('creates hierarchy and cascades deletion without affecting history', () {
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

      service.recordFocusSession(
        id: 'sess_1',
        courseId: 'c1',
        assignmentId: 'a1',
        stepId: 's1',
        minutesSpent: 30,
      );
      expect(service.sessions.length, equals(1));

      final removed = service.removeCourse('c1');
      expect(removed, isTrue);
      expect(service.courses, isEmpty);
      expect(service.findAssignmentById('a1'), isNull);

      expect(service.sessions.length, equals(1));
      expect(service.getTotalStudyMinutesForCourse('c1'), equals(30));
    });

    test('coordinates multi-entity step completion and reopening', () {
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
  });

  group('Validation Rules and Boundaries', () {
    test('enforces preconditions on dates and completed tasks', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final futureDate = DateTime.now().add(const Duration(days: 2));

      expect(
        () => service.createAssignmentForCourse(
          courseId: 'c1',
          assignmentId: 'a_bad',
          title: 'Past Task',
          dueDate: pastDate,
        ),
        throwsA(isA<ArgumentError>()),
      );

      service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_valid',
        title: 'Valid Task',
        dueDate: futureDate,
      );
      expect(
        () => service.updateAssignment(assignmentId: 'a_valid', dueDate: pastDate),
        throwsA(isA<ArgumentError>()),
      );

      final assignment = service.findAssignmentById('a_valid')!;
      assignment.completeAll();
      expect(
        () => service.addStepToAssignment(
          assignmentId: 'a_valid',
          stepId: 's_late',
          title: 'Late Step',
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        () => service.recordFocusSession(
          id: 'sess_bad',
          courseId: 'c1',
          assignmentId: 'a_valid',
          stepId: 'missing_step',
          minutesSpent: 25,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('enforces boundary rules on work step duration', () {
      final step = WorkStep(id: 's_v', title: 'Normal Step', estimatedMinutes: 25);
      expect(step.estimatedMinutes, equals(25));

      expect(
        () => WorkStep(id: 's_zero', title: 'Zero Step', estimatedMinutes: 0),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => WorkStep(id: 's_big', title: 'Huge Step', estimatedMinutes: 500),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Recommendation Engine and Priority Scoring', () {
    test('ranks tasks using urgency, progress momentum, recent activity, and type', () {
      final now = DateTime.now();

      service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_dist',
        title: 'Distant Homework',
        dueDate: now.add(const Duration(days: 7)),
        type: AssignmentType.homework,
      );
      service.addStepToAssignment(
        assignmentId: 'a_dist',
        stepId: 's_dist',
        title: 'Low Urgency Step',
      );

      service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_exam',
        title: 'Midterm Exam',
        dueDate: now.add(const Duration(hours: 12)),
        type: AssignmentType.exam,
      );
      final examStep = service.addStepToAssignment(
        assignmentId: 'a_exam',
        stepId: 's_exam',
        title: 'Study Chapter 3',
      );

      service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_proj',
        title: 'Group Project',
        dueDate: now.add(const Duration(hours: 12)),
        type: AssignmentType.project,
      );
      final projStep = service.addStepToAssignment(
        assignmentId: 'a_proj',
        stepId: 's_proj',
        title: 'Write Auth Module',
      );

      service.recordFocusSession(
        id: 'sess_recent',
        courseId: 'c1',
        assignmentId: 'a_proj',
        stepId: 's_proj',
        minutesSpent: 25,
      );

      final topStep = service.getTopRecommendedStep();
      expect(topStep, equals(projStep));

      final top3 = service.getTopRecommendedSteps(limit: 3);
      expect(top3.length, equals(3));
      expect(top3[0], equals(projStep));
      expect(top3[1], equals(examStep));
    });

    test('boosts heavy assignment due soon over light assignment with same deadline', () {
      final sameDue = DateTime.now().add(const Duration(hours: 30));

      service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_light',
        title: 'Light Task',
        dueDate: sameDue,
      );
      service.addStepToAssignment(
        assignmentId: 'a_light',
        stepId: 's_light',
        title: 'Light Step',
        estimatedMinutes: 25,
      );

      service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_heavy',
        title: 'Heavy Project',
        dueDate: sameDue,
      );
      for (var i = 1; i <= 4; i++) {
        service.addStepToAssignment(
          assignmentId: 'a_heavy',
          stepId: 's_h_$i',
          title: 'Heavy Step $i',
          estimatedMinutes: 40,
        );
      }

      final topStep = service.getTopRecommendedStep();
      expect(topStep!.title, equals('Heavy Step 1'));
    });
  });

  group('Study Streaks and Workload Analysis', () {
    test('calculates forgiving study streak with 1-day grace window and all-time record', () {
      final now = DateTime.now();
      final dayMinus3 = DateTime(now.year, now.month, now.day - 3, 10, 0);
      final dayMinus2 = DateTime(now.year, now.month, now.day - 2, 10, 0);
      final dayToday = DateTime(now.year, now.month, now.day, 10, 0);

      service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_strk',
        title: 'Streak Assignment',
        dueDate: now.add(const Duration(days: 5)),
      );
      service.addStepToAssignment(
        assignmentId: 'a_strk',
        stepId: 's_strk',
        title: 'Streak Step',
      );

      service.recordFocusSession(
        id: 'sess_s1',
        courseId: 'c1',
        assignmentId: 'a_strk',
        stepId: 's_strk',
        minutesSpent: 25,
        completedAt: dayMinus3,
      );

      service.recordFocusSession(
        id: 'sess_s2',
        courseId: 'c1',
        assignmentId: 'a_strk',
        stepId: 's_strk',
        minutesSpent: 25,
        completedAt: dayMinus2,
      );

      service.recordFocusSession(
        id: 'sess_s3',
        courseId: 'c1',
        assignmentId: 'a_strk',
        stepId: 's_strk',
        minutesSpent: 25,
        completedAt: dayToday,
      );

      expect(service.getCurrentStudyStreakDays(allowedMissedDays: 0), equals(1));
      expect(service.getCurrentStudyStreakDays(allowedMissedDays: 1), equals(3));
      expect(service.getLongestStudyStreakDays(), equals(2));
    });

    test('calculates daily workload minutes and flags capacity overload', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_due_tomo',
        title: 'Tomorrow Task',
        dueDate: tomorrow,
      );
      service.addStepToAssignment(
        assignmentId: 'a_due_tomo',
        stepId: 's_t1',
        title: 'Step 1',
        estimatedMinutes: 60,
      );
      service.addStepToAssignment(
        assignmentId: 'a_due_tomo',
        stepId: 's_t2',
        title: 'Step 2',
        estimatedMinutes: 90,
      );

      expect(service.calculateDailyWorkloadMinutes(tomorrow), equals(150));
      expect(service.isWorkloadOverloaded(tomorrow), isFalse);
      expect(service.isWorkloadOverloaded(tomorrow, dailyLimitMinutes: 120), isTrue);
    });

    test('tracks daily study goals and completion progress', () {
      final today = DateTime.now();
      final studyTime = DateTime(today.year, today.month, today.day, 14, 0);

      service.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_goal',
        title: 'Goal Work',
        dueDate: today.add(const Duration(days: 2)),
      );
      service.addStepToAssignment(
        assignmentId: 'a_goal',
        stepId: 's_g1',
        title: 'Goal Step',
      );

      service.updateProfile(dailyGoalMinutes: 60, maxDailyWorkloadMinutes: 120);
      expect(service.profile.dailyGoalMinutes, equals(60));

      expect(service.getDailyGoalProgress(today), equals(0.0));
      expect(service.isDailyGoalMet(today), isFalse);

      service.recordFocusSession(
        id: 'sess_g1',
        courseId: 'c1',
        assignmentId: 'a_goal',
        stepId: 's_g1',
        minutesSpent: 30,
        completedAt: studyTime,
      );
      expect(service.getDailyStudyMinutes(today), equals(30));
      expect(service.getDailyGoalProgress(today), equals(0.5));
      expect(service.isDailyGoalMet(today), isFalse);

      service.recordFocusSession(
        id: 'sess_g2',
        courseId: 'c1',
        assignmentId: 'a_goal',
        stepId: 's_g1',
        minutesSpent: 30,
        completedAt: studyTime.add(const Duration(hours: 1)),
      );
      expect(service.getDailyStudyMinutes(today), equals(60));
      expect(service.getDailyGoalProgress(today), equals(1.0));
      expect(service.isDailyGoalMet(today), isTrue);

      service.recordFocusSession(
        id: 'sess_g3',
        courseId: 'c1',
        assignmentId: 'a_goal',
        stepId: 's_g1',
        minutesSpent: 15,
        completedAt: studyTime.add(const Duration(hours: 2)),
      );
      expect(service.getDailyGoalProgress(today), equals(1.25));
    });
  });
}
