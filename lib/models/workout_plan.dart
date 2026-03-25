

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
    return WorkoutPlan(id: map['id'],name: map['id'], exercises: map['exercises'], sets: map['sets'], reps: map['reps'], restTime: map['restTime'], notes: map['notes'], createdAt: map['createdAt']);
  }


}