class FocusSession {
  final String _id;
  final String _courseId;
  final String _assignmentId;
  final String _stepId;
  final int _minutesSpent;
  final DateTime _completedAt;

  FocusSession({
    required String id,
    required String courseId,
    required String assignmentId,
    required String stepId,
    required this._minutesSpent,
    DateTime? completedAt,
  }) : _id = id.trim(),
       _courseId = courseId.trim(),
       _assignmentId = assignmentId.trim(),
       _stepId = stepId.trim(),
       _completedAt = completedAt ?? DateTime.now() {
    if (_id.isEmpty) {
      throw ArgumentError('session id cannot be empty');
    }
    if (_courseId.isEmpty) {
      throw ArgumentError('course id cannot be empty');
    }
    if (_assignmentId.isEmpty) {
      throw ArgumentError('assignment id cannot be empty');
    }
    if (_stepId.isEmpty) {
      throw ArgumentError('step id cannot be empty');
    }
    if (_minutesSpent <= 0) {
      throw ArgumentError('minutes spent must be greater than zero');
    }
  }

  String get id => _id;
  String get courseId => _courseId;
  String get assignmentId => _assignmentId;
  String get stepId => _stepId;
  int get minutesSpent => _minutesSpent;
  DateTime get completedAt => _completedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FocusSession && other._id == _id;
  }

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() {
    return 'FocusSession(id: $_id, course: $_courseId, minutes: $_minutesSpent, at: $_completedAt)';
  }
}
