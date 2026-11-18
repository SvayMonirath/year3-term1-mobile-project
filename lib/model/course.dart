import 'assignment.dart';

enum CourseColor {
  blue('#2196F3'),
  green('#4CAF50'),
  orange('#FF9800'),
  purple('#9C27B0'),
  red('#F44336');

  final String hex;
  const CourseColor(this.hex);
}

class Course {
  final String _id;
  String _name;
  CourseColor color;
  final List<Assignment> _assignments;

  Course({
    required String id,
    required String name,
    this.color = CourseColor.blue,
    List<Assignment>? assignments,
  }) : _id = id.trim(),
       _name = name.trim(),
       _assignments = assignments != null
           ? List<Assignment>.from(assignments)
           : [] {
    if (_id.isEmpty) {
      throw ArgumentError('course id cannot be empty');
    }
    if (_name.isEmpty) {
      throw ArgumentError('course name cannot be empty');
    }
  }

  String get id => _id;
  String get name => _name;

  List<Assignment> get assignments => List.unmodifiable(_assignments);

  set name(String newName) {
    final cleaned = newName.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError('course name cannot be empty');
    }
    _name = cleaned;
  }

  void addAssignment(Assignment assignment) {
    // make sure this assignment actually belongs to this course
    if (assignment.courseId != _id) {
      throw ArgumentError('assignment does not belong to this course');
    }

    final alreadyExists = _assignments.any((a) => a.id == assignment.id);
    if (alreadyExists) {
      throw ArgumentError('assignment id already exists');
    }

    _assignments.add(assignment);
  }

  bool removeAssignment(String assignmentId) {
    final index = _assignments.indexWhere((a) => a.id == assignmentId);
    if (index != -1) {
      _assignments.removeAt(index);
      return true;
    }
    return false;
  }

  Assignment? findAssignmentById(String assignmentId) {
    try {
      return _assignments.firstWhere((a) => a.id == assignmentId);
    } catch (_) {
      return null;
    }
  }

  List<Assignment> get activeAssignments {
    return _assignments.where((a) => !a.isCompleted).toList();
  }

  // total steps left across all homework in this class
  int get totalPendingStepsCount {
    var count = 0;
    for (final assignment in activeAssignments) {
      count += assignment.pendingSteps.length;
    }
    return count;
  }

  // total finished steps across all homework in this class
  int get totalCompletedStepsCount {
    var count = 0;
    for (final assignment in _assignments) {
      for (final step in assignment.steps) {
        if (step.isCompleted) {
          count++;
        }
      }
    }
    return count;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other._id == _id;
  }

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() {
    return 'Course(id: $_id, name: $_name, color: ${color.name}, assignments: ${_assignments.length})';
  }
}
