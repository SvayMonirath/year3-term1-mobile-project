import 'work_step.dart';

enum AssignmentType {
  homework,
  project,
  exam,
}

class Assignment {
  final String _id;
  final String _courseId;
  String _title;
  DateTime? dueDate;
  AssignmentType type;
  bool _isCompleted;
  final List<WorkStep> _steps;

  Assignment({
    required String id,
    required String courseId,
    required String title,
    this.dueDate,
    this.type = AssignmentType.homework,
    bool isCompleted = false,
    List<WorkStep>? steps,
  }) : _id = id.trim(),
       _courseId = courseId.trim(),
       _title = title.trim(),
       _isCompleted = isCompleted,
       _steps = steps != null ? List<WorkStep>.from(steps) : [] {
    if (_id.isEmpty) {
      throw ArgumentError('assignment id cannot be empty');
    }
    if (_courseId.isEmpty) {
      throw ArgumentError('course id cannot be empty');
    }
    if (_title.isEmpty) {
      throw ArgumentError('assignment title cannot be empty');
    }
  }

  String get id => _id;
  String get courseId => _courseId;
  String get title => _title;
  bool get isCompleted => _isCompleted;

  List<WorkStep> get steps => List.unmodifiable(_steps);

  bool get isOverdue =>
      !_isCompleted && dueDate != null && DateTime.now().isAfter(dueDate!);

  set title(String newTitle) {
    final cleaned = newTitle.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError('assignment title cannot be empty');
    }
    _title = cleaned;
  }

  void addStep(WorkStep step) {
    if (_isCompleted) {
      throw StateError('cannot add steps to a completed assignment');
    }
    final alreadyExists = _steps.any((s) => s.id == step.id);
    if (alreadyExists) {
      throw ArgumentError('step id already exists');
    }
    _steps.add(step);
  }

  bool removeStep(String stepId) {
    final index = _steps.indexWhere((s) => s.id == stepId);
    if (index != -1) {
      _steps.removeAt(index);
      return true;
    }
    return false;
  }

  void reorderStep(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _steps.length) {
      throw RangeError.index(oldIndex, _steps, 'oldIndex');
    }
    if (newIndex < 0 || newIndex >= _steps.length) {
      throw RangeError.index(newIndex, _steps, 'newIndex');
    }
    final step = _steps.removeAt(oldIndex);
    _steps.insert(newIndex, step);
  }

  double get progress {
    if (_steps.isEmpty) {
      return _isCompleted ? 1.0 : 0.0;
    }
    final completedCount = _steps.where((s) => s.isCompleted).length;
    return completedCount / _steps.length;
  }

  List<WorkStep> get pendingSteps {
    return _steps.where((s) => !s.isCompleted).toList();
  }

  int get remainingMinutes {
    var total = 0;
    for (final step in pendingSteps) {
      total += step.estimatedMinutes;
    }
    return total;
  }

  void completeAll() {
    _isCompleted = true;
    for (final step in _steps) {
      step.complete();
    }
  }

  void uncomplete() {
    _isCompleted = false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Assignment && other._id == _id;
  }

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() {
    return 'Assignment(id: $_id, title: $_title, type: ${type.name}, due: $dueDate, done: $_isCompleted, steps: ${_steps.length})';
  }
}
