# Study & Focus System Refactoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the CourseCue study planner domain and service architecture to comply with the 2-service syllabus requirement, eliminate domain bloat, fix streak calculation bugs, support optional due dates, and provide diverse multi-course next-step recommendations.

**Architecture:** Split the monolithic `StudyService` into two focused services (`StudyService` for coursework/workload management and `FocusService` for timer sessions, streaks, and recommendations). Refactor `StudyProfile` with intuitive attribute names and focus break support. Introduce a rich `RecommendedAction` read model to deliver cross-course recommendations without context loss.

**Tech Stack:** Dart 3.13+, Flutter, `flutter_test`.

**Spec:** `../../docs/milestone-1-proposal.md` and `../../docs/project-description.md`.

## Global Constraints

- 100% offline pure Dart domain and service layer with zero UI or network dependencies.
- At least 2 distinct domain services with meaningful business rules and multi-entity coordination.
- Zero mock data in production routes and models; strict type safety and input validation.
- All unit tests must execute and pass via `flutter test` with clean `flutter analyze`.

## Review Focus

- **Overdue Task Priority Saturation:** Tasks overdue by more than 7 days must be deprioritized so they do not permanently block upcoming active deadlines.
- **Streak Calculation Accuracy:** Alternating-day study patterns must not be rewarded with an infinite streak; streaks strictly require consecutive daily activity.
- **Profile Boundary Auto-Correction:** Updating `dailyStudyGoalMinutes` higher than `dailyWorkloadLimitMinutes` must auto-adjust the limit rather than throwing an unexpected runtime exception.
- **Recommendation Diversity:** `getTopRecommendedSteps` must draw the top step from up to 3 distinct assignments/courses rather than clustering multiple steps from a single assignment.
- **Undated Assignment Prioritization:** Assignments with no due date must receive a calm baseline priority score (20 pts) rather than crashing or claiming top urgency.

---

### Task 1: Refactor `StudyProfile` Model

**Files:**
- Modify: `lib/model/study_profile.dart`
- Test: `test/study_profile_test.dart`

**Interfaces:**
- Consumes: None.
- Produces: `StudyProfile` with getters `dailyStudyGoalMinutes`, `dailyWorkloadLimitMinutes`, `stepDurationMinutes`, `breakDurationMinutes`, and `update(...)`.

- [ ] **Step 1: Write failing unit test for `StudyProfile`**

Create `test/study_profile_test.dart` asserting:
1. Default values: `dailyStudyGoalMinutes` = 120, `dailyWorkloadLimitMinutes` = 240, `stepDurationMinutes` = 25, `breakDurationMinutes` = 5.
2. Updating `dailyStudyGoalMinutes` to 300 when limit is 240 automatically bumps `dailyWorkloadLimitMinutes` to 300.
3. Rejecting invalid boundary inputs (< 5 min step, < 1 min break, goal > 720 min).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/study_profile_test.dart`
Expected: FAIL due to missing new property names.

- [ ] **Step 3: Implement refactored `StudyProfile`**

Update `lib/model/study_profile.dart`:
- Replace confusing attribute names with `dailyStudyGoalMinutes`, `dailyWorkloadLimitMinutes`, `stepDurationMinutes`, and `breakDurationMinutes`.
- In `update()`, if `dailyStudyGoalMinutes` exceeds `dailyWorkloadLimitMinutes`, auto-adjust `dailyWorkloadLimitMinutes = dailyStudyGoalMinutes`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/study_profile_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/model/study_profile.dart test/study_profile_test.dart
git commit -m "refactor(model): rename study profile fields and add break duration"
```

---

### Task 2: Refactor `Assignment` Model for Optional Due Dates

**Files:**
- Modify: `lib/model/assignment.dart`
- Test: `test/assignment_test.dart`

**Interfaces:**
- Consumes: `lib/model/work_step.dart`
- Produces: `Assignment` with nullable `DateTime? dueDate`, updated `isOverdue` getter.

- [ ] **Step 1: Write failing unit test for optional `dueDate`**

Create `test/assignment_test.dart` asserting:
1. `Assignment` can be instantiated with `dueDate: null`.
2. `isOverdue` returns `false` when `dueDate == null`.
3. `isOverdue` returns `true` when `dueDate` is in the past and `isCompleted == false`.
4. Updating `dueDate` to `null` is supported.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/assignment_test.dart`
Expected: FAIL because `dueDate` currently requires non-null `DateTime`.

- [ ] **Step 3: Implement nullable `dueDate` in `Assignment`**

Update `lib/model/assignment.dart`:
- Change `DateTime dueDate` to `DateTime? dueDate`.
- Update `isOverdue` getter: `!_isCompleted && dueDate != null && DateTime.now().isAfter(dueDate!)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/assignment_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/model/assignment.dart test/assignment_test.dart
git commit -m "feat(model): allow optional due date on assignments"
```

---

### Task 3: Create `RecommendedAction` Read Model

**Files:**
- Create: `lib/model/recommended_action.dart`
- Test: `test/recommended_action_test.dart`

**Interfaces:**
- Consumes: `lib/model/work_step.dart`, `lib/model/course.dart`
- Produces: `RecommendedAction` holding step, assignment metadata, course metadata, and priority score.

- [ ] **Step 1: Write failing unit test for `RecommendedAction`**

Create `test/recommended_action_test.dart` testing:
1. Instantiation with `step`, `assignmentId`, `assignmentTitle`, `dueDate`, `courseId`, `courseName`, `courseColor`, `priorityScore`.
2. Value equality and `toString()` representation.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/recommended_action_test.dart`
Expected: FAIL with file not found.

- [ ] **Step 3: Implement `RecommendedAction`**

Create `lib/model/recommended_action.dart`:
```dart
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
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/recommended_action_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/model/recommended_action.dart test/recommended_action_test.dart
git commit -m "feat(model): add recommended action read model"
```

---

### Task 4: Refactor `StudyService` (Coursework & Workload Only)

**Files:**
- Modify: `lib/service/study_service.dart`
- Modify: `test/study_service_test.dart`

**Interfaces:**
- Consumes: `Course`, `Assignment`, `WorkStep`, `StudyProfile`.
- Produces: `StudyService` managing courses, assignments (including optional due dates), steps, workload calculations, and study profile.

- [ ] **Step 1: Write unit tests for `StudyService` coursework operations**

Update `test/study_service_test.dart` asserting:
1. Course creation, retrieval, and cascading deletion.
2. Creating assignment with optional `dueDate: null`.
3. Creating assignment with past `dueDate` (allowed for catching up backlog).
4. Step addition, reordering, and completion cascade.
5. Workload calculation and `isWorkloadOverloaded` against `dailyWorkloadLimitMinutes`.
6. Profile update delegation to `StudyProfile`.

- [ ] **Step 2: Run test to verify failure/compile error**

Run: `flutter test test/study_service_test.dart`
Expected: FAIL due to signature mismatches with old FocusSession methods.

- [ ] **Step 3: Refactor `StudyService`**

Clean `lib/service/study_service.dart`:
- Retain only `Course`, `Assignment`, `WorkStep`, `StudyProfile`, and daily workload operations.
- Remove `FocusSession`, streak, and recommendation logic (moved to `FocusService`).
- Update `createAssignmentForCourse` to accept optional `DateTime? dueDate` and remove the blanket rejection of past dates.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/study_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/service/study_service.dart test/study_service_test.dart
git commit -m "refactor(service): streamline StudyService to coursework and workload domain"
```

---

### Task 5: Implement `FocusService` (Sessions, Streaks, Recommendations)

**Files:**
- Create: `lib/service/focus_service.dart`
- Create: `test/focus_service_test.dart`

**Interfaces:**
- Consumes: `FocusSession`, `RecommendedAction`, `StudyService` (for coursework queries).
- Produces: `FocusService` with session logging, consecutive streaks, and diverse recommendation algorithm.

- [ ] **Step 1: Write failing unit test for `FocusService`**

Create `test/focus_service_test.dart` asserting:
1. `recordFocusSession` stores session and calculates total study minutes by course and date.
2. `recordSessionAndCompleteStep` records session AND marks step finished in one atomic call.
3. Streak test: Consecutive days count properly. If student has not studied yet today, yesterday's streak holds. An alternate-day study pattern breaks the streak.
4. Recommendations: `getTopRecommendedSteps(limit: 3)` returns up to 3 distinct assignments/courses.
5. Undated assignments receive baseline priority (20 pts).
6. Overdue assignments older than 7 days have their urgency capped so current upcoming work is not locked out.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/focus_service_test.dart`
Expected: FAIL with file not found.

- [ ] **Step 3: Implement `FocusService`**

Create `lib/service/focus_service.dart`:
- Inject `StudyService` dependency.
- Implement `recordFocusSession` and `recordSessionAndCompleteStep`.
- Implement `getCurrentStudyStreakDays` using strict consecutive day counting with today-pending grace.
- Implement `calculatePriorityScore` with overdue capping (>7 days old) and baseline scoring for undated tasks.
- Implement `getTopRecommendedSteps` selecting the top pending step from each of the highest-scoring unique assignments.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/focus_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/service/focus_service.dart test/focus_service_test.dart
git commit -m "feat(service): implement FocusService with streak tracking and smart recommendations"
```

---

### Task 6: System Verification and Clean Up

**Files:**
- Modify: `lib/main.dart` (ensure clean entry)
- Review: all files in `lib/` and `test/`

**Interfaces:**
- Consumes: All services and models.
- Produces: Fully green test suite and zero analysis warnings.

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests pass across `study_service_test.dart`, `focus_service_test.dart`, `study_profile_test.dart`, `assignment_test.dart`, and `recommended_action_test.dart`.

- [ ] **Step 2: Run static analyzer**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Final Commit**

```bash
git add -A
git commit -m "chore: verify complete domain and service refactor"
```
