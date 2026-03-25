

class WorkoutPlan {
  final int? id;
  final String name;
  final String exercises;
  final int sets;
  final int reps;
  final int restTime;
  final String? notes;
  final DateTime createdAt;

  WorkoutPlan({
    this.id,
    required this.name,
    required this.exercises,
    required this.sets,
    required this.reps,
    required this.restTime,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises,
      'sets': sets,
      'reps': reps,
      'restTime': restTime,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];

    DateTime createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.parse(createdAtRaw);
    } else if (createdAtRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else {
      createdAt = DateTime.now();
    }
     return WorkoutPlan(
      id: map['id'] as int?,
      name: map['name'] as String,
      exercises: map['exercises'] as String,
      sets: (map['sets'] as num).toInt(),
      reps: (map['reps'] as num).toInt(),
      restTime: (map['restTime'] as num).toInt(),
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] is String
        ? DateTime.parse(map['createdAt'] as String)
        : DateTime.now());
  }


}