import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_project/model/study_profile.dart';

void main() {
  group('StudyProfile', () {
    test('has default study and break settings', () {
      final profile = StudyProfile();

      expect(profile.dailyStudyGoalMinutes, equals(120));
      expect(profile.dailyWorkloadLimitMinutes, equals(240));
      expect(profile.stepDurationMinutes, equals(25));
      expect(profile.breakDurationMinutes, equals(5));
    });

    test('raises workload limit when study goal is higher', () {
      final profile = StudyProfile();
      profile.update(dailyStudyGoalMinutes: 300);

      expect(profile.dailyStudyGoalMinutes, equals(300));
      expect(profile.dailyWorkloadLimitMinutes, equals(300));
    });

    test('updates all settings with valid numbers', () {
      final profile = StudyProfile();
      profile.update(
        dailyStudyGoalMinutes: 180,
        dailyWorkloadLimitMinutes: 360,
        stepDurationMinutes: 45,
        breakDurationMinutes: 10,
      );

      expect(profile.dailyStudyGoalMinutes, equals(180));
      expect(profile.dailyWorkloadLimitMinutes, equals(360));
      expect(profile.stepDurationMinutes, equals(45));
      expect(profile.breakDurationMinutes, equals(10));
    });

    test('rejects numbers that are too small or too big', () {
      expect(
        () => StudyProfile(dailyStudyGoalMinutes: 10),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => StudyProfile(stepDurationMinutes: 2),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => StudyProfile(breakDurationMinutes: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('is equal when all settings match', () {
      final p1 = StudyProfile(
        dailyStudyGoalMinutes: 100,
        dailyWorkloadLimitMinutes: 200,
        stepDurationMinutes: 30,
        breakDurationMinutes: 5,
      );
      final p2 = StudyProfile(
        dailyStudyGoalMinutes: 100,
        dailyWorkloadLimitMinutes: 200,
        stepDurationMinutes: 30,
        breakDurationMinutes: 5,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });
  });
}
