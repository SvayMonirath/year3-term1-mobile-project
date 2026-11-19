import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_project/model/course.dart';
import 'package:mobile_project/service/study_service.dart';
import 'package:mobile_project/service/focus_service.dart';

void main() {
  late StudyService studyService;
  late FocusService focusService;
  late Course course1;
  late Course course2;

  setUp(() {
    studyService = StudyService();
    focusService = FocusService(studyService: studyService);

    course1 = Course(id: 'c1', name: 'Mobile Dev', color: CourseColor.blue);
    course2 = Course(id: 'c2', name: 'Cloud Computing', color: CourseColor.orange);
    studyService.addCourse(course1);
    studyService.addCourse(course2);
  });

  group('FocusService - Session Recording & Daily Goals', () {
    test('records session and calculates daily & course totals', () {
      final now = DateTime(2026, 11, 19, 10, 0);
      studyService.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a1',
        title: 'Project 1',
      );
      studyService.addStepToAssignment(
        assignmentId: 'a1',
        stepId: 's1',
        title: 'Step 1',
      );

      final session = focusService.recordFocusSession(
        id: 'sess1',
        courseId: 'c1',
        assignmentId: 'a1',
        stepId: 's1',
        minutesSpent: 30,
        completedAt: now,
      );

      expect(session.minutesSpent, equals(30));
      expect(focusService.getTotalStudyMinutesForCourse('c1'), equals(30));
      expect(focusService.getDailyStudyMinutes(now), equals(30));
      expect(focusService.getDailyGoalProgress(now), closeTo(30 / 120, 0.01));
      expect(focusService.isDailyGoalMet(now), isFalse);
    });

    test('atomically records session and marks step complete', () {
      studyService.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a1',
        title: 'Project 1',
      );
      studyService.addStepToAssignment(
        assignmentId: 'a1',
        stepId: 's1',
        title: 'Step 1',
      );

      focusService.recordSessionAndCompleteStep(
        id: 'sess_atomic',
        courseId: 'c1',
        assignmentId: 'a1',
        stepId: 's1',
        minutesSpent: 25,
      );

      expect(focusService.sessions.length, equals(1));
      final assignment = studyService.findAssignmentById('a1')!;
      expect(assignment.steps.first.isCompleted, isTrue);
      expect(assignment.isCompleted, isTrue);
    });
  });

  group('FocusService - Consecutive Study Streaks', () {
    test('calculates consecutive streak and allows pending today', () {
      final today = DateTime(2026, 11, 19);
      final yesterday = DateTime(2026, 11, 18);
      final twoDaysAgo = DateTime(2026, 11, 17);

      studyService.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a1',
        title: 'Task',
      );
      studyService.addStepToAssignment(
        assignmentId: 'a1',
        stepId: 's1',
        title: 'Step',
      );

      // Student studied yesterday and two days ago, but has not studied today yet
      focusService.recordFocusSession(
        id: 's_yest',
        courseId: 'c1',
        assignmentId: 'a1',
        stepId: 's1',
        minutesSpent: 30,
        completedAt: yesterday,
      );
      focusService.recordFocusSession(
        id: 's_prev',
        courseId: 'c1',
        assignmentId: 'a1',
        stepId: 's1',
        minutesSpent: 25,
        completedAt: twoDaysAgo,
      );

      // Streak is preserved at 2 because today is still open
      expect(
        focusService.getCurrentStudyStreakDays(relativeNow: today),
        equals(2),
      );

      // After studying today, streak extends to 3
      focusService.recordFocusSession(
        id: 's_today',
        courseId: 'c1',
        assignmentId: 'a1',
        stepId: 's1',
        minutesSpent: 25,
        completedAt: today,
      );
      expect(
        focusService.getCurrentStudyStreakDays(relativeNow: today),
        equals(3),
      );
    });

    test('resets streak to 0 when consecutive day chain is broken', () {
      final today = DateTime(2026, 11, 19);
      final threeDaysAgo = DateTime(2026, 11, 16);

      studyService.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a1',
        title: 'Task',
      );
      studyService.addStepToAssignment(
        assignmentId: 'a1',
        stepId: 's1',
        title: 'Step',
      );

      focusService.recordFocusSession(
        id: 's_old',
        courseId: 'c1',
        assignmentId: 'a1',
        stepId: 's1',
        minutesSpent: 30,
        completedAt: threeDaysAgo,
      );

      // Yesterday and today were missed -> streak is 0
      expect(
        focusService.getCurrentStudyStreakDays(relativeNow: today),
        equals(0),
      );
    });
  });

  group('FocusService - Multi-Course Recommendations & Edge Cases', () {
    test('returns diverse recommendations across distinct assignments', () {
      final now = DateTime(2026, 11, 19, 12, 0);

      // Assignment 1 has 3 steps (Course 1)
      studyService.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a1',
        title: 'Mobile Milestone',
        dueDate: now.add(const Duration(hours: 10)),
      );
      studyService.addStepToAssignment(
        assignmentId: 'a1',
        stepId: 's1_1',
        title: 'Step 1 of A1',
      );
      studyService.addStepToAssignment(
        assignmentId: 'a1',
        stepId: 's1_2',
        title: 'Step 2 of A1',
      );

      // Assignment 2 has 2 steps (Course 2)
      studyService.createAssignmentForCourse(
        courseId: 'c2',
        assignmentId: 'a2',
        title: 'Cloud Lab',
        dueDate: now.add(const Duration(hours: 15)),
      );
      studyService.addStepToAssignment(
        assignmentId: 'a2',
        stepId: 's2_1',
        title: 'Step 1 of A2',
      );

      final recommendations = focusService.getTopRecommendedSteps(
        limit: 3,
        relativeNow: now,
      );

      // Must draw 1 step from A1 and 1 step from A2, NOT 2 steps from A1
      expect(recommendations.length, equals(2));
      expect(recommendations[0].assignmentId, equals('a1'));
      expect(recommendations[0].step.id, equals('s1_1'));
      expect(recommendations[0].courseName, equals('Mobile Dev'));
      expect(recommendations[0].courseColor, equals(CourseColor.blue));

      expect(recommendations[1].assignmentId, equals('a2'));
      expect(recommendations[1].step.id, equals('s2_1'));
      expect(recommendations[1].courseName, equals('Cloud Computing'));
    });

    test('scores undated assignments with calm baseline and deprioritizes stale overdue tasks', () {
      final now = DateTime(2026, 11, 19, 12, 0);

      // Stale overdue assignment (>7 days ago)
      final aStale = studyService.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_stale',
        title: 'Ancient Homework',
        dueDate: now.subtract(const Duration(days: 10)),
      );
      final scoreStale = focusService.calculatePriorityScore(aStale, relativeNow: now);

      // Active urgent assignment (due in 8 hours)
      final aUrgent = studyService.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_urgent',
        title: 'Today Homework',
        dueDate: now.add(const Duration(hours: 8)),
      );
      final scoreUrgent = focusService.calculatePriorityScore(aUrgent, relativeNow: now);

      // Urgent assignment must outrank stale overdue assignment!
      expect(scoreUrgent, greaterThan(scoreStale));

      // Undated assignment receives 20 pts baseline
      final aUndated = studyService.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_undated',
        title: 'Ongoing Reading',
        dueDate: null,
      );
      final scoreUndated = focusService.calculatePriorityScore(aUndated, relativeNow: now);
      expect(scoreUndated, equals(20.0));
    });

    test('awards tiered bonus points based on task size for work due soon', () {
      final now = DateTime(2026, 11, 19, 12, 0);
      final dueTomorrow = now.add(const Duration(hours: 24));

      // Small task: 30 minutes -> 0 bonus (80 pts total)
      final aSmall = studyService.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_small',
        title: 'Small Quiz',
        dueDate: dueTomorrow,
      );
      studyService.addStepToAssignment(
        assignmentId: 'a_small',
        stepId: 's_sm',
        title: 'Quiz Step',
        estimatedMinutes: 30,
      );

      // Medium task: 90 minutes -> +5 bonus (85 pts total)
      final aMed = studyService.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_med',
        title: 'Medium Worksheet',
        dueDate: dueTomorrow,
      );
      studyService.addStepToAssignment(
        assignmentId: 'a_med',
        stepId: 's_med',
        title: 'Worksheet Step',
        estimatedMinutes: 90,
      );

      // Heavy task: 150 minutes -> +10 bonus (90 pts total)
      final aHeavy = studyService.createAssignmentForCourse(
        courseId: 'c1',
        assignmentId: 'a_heavy',
        title: 'Heavy Project',
        dueDate: dueTomorrow,
      );
      studyService.addStepToAssignment(
        assignmentId: 'a_heavy',
        stepId: 's_heavy',
        title: 'Project Step',
        estimatedMinutes: 150,
      );

      final scoreSmall = focusService.calculatePriorityScore(aSmall, relativeNow: now);
      final scoreMed = focusService.calculatePriorityScore(aMed, relativeNow: now);
      final scoreHeavy = focusService.calculatePriorityScore(aHeavy, relativeNow: now);

      expect(scoreSmall, equals(80.0));
      expect(scoreMed, equals(85.0));
      expect(scoreHeavy, equals(90.0));
    });
  });
}
