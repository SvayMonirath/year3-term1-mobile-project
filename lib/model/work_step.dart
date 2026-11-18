class WorkStep {
  static const int defaultMinutes = 25;
  static const int maxMinutes = 480;

  final String _id;
  String _title;
  int _estimatedMinutes;
  bool _isCompleted;

  WorkStep({
    required String id,
    required String title,
    this._estimatedMinutes = defaultMinutes,
    this._isCompleted = false,
  }) : _id = id.trim(),
       _title = title.trim() {
    if (_id.isEmpty) {
      throw ArgumentError('step id cannot be empty');
    }
    if (_title.isEmpty) {
      throw ArgumentError('step title cannot be empty');
    }
    if (_estimatedMinutes <= 0 || _estimatedMinutes > maxMinutes) {
      throw ArgumentError(
        'estimated minutes must be between 1 and $maxMinutes',
      );
    }
  }

  String get id => _id;
  String get title => _title;
  int get estimatedMinutes => _estimatedMinutes;
  bool get isCompleted => _isCompleted;

  set title(String newTitle) {
    final cleaned = newTitle.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError('step title cannot be empty');
    }
    _title = cleaned;
  }

  set estimatedMinutes(int minutes) {
    if (minutes <= 0 || minutes > maxMinutes) {
      throw ArgumentError(
        'estimated minutes must be between 1 and $maxMinutes',
      );
    }
    _estimatedMinutes = minutes;
  }

  void complete() {
    _isCompleted = true;
  }

  void uncomplete() {
    _isCompleted = false;
  }

  // two steps are the same if they have the same id instead of comparing by memory address
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkStep && other._id == _id;
  }

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() {
    return 'WorkStep(id: $_id, title: $_title, minutes: $_estimatedMinutes, done: $_isCompleted)';
  }
}
