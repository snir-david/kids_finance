import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Goal extends Equatable {
  const Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.createdAt,
    required this.isActive,
    this.completedAt,
  });

  final String id;
  final String name;
  final double targetAmount;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isActive;

  factory Goal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawCreated = data['createdAt'];
    final createdAt = rawCreated is Timestamp
        ? rawCreated.toDate()
        : DateTime.parse(rawCreated as String);

    final rawCompleted = data['completedAt'];
    final completedAt = rawCompleted == null
        ? null
        : rawCompleted is Timestamp
            ? rawCompleted.toDate()
            : DateTime.parse(rawCompleted as String);

    return Goal(
      id: doc.id,
      name: data['name'] as String,
      targetAmount: (data['targetAmount'] as num).toDouble(),
      createdAt: createdAt,
      completedAt: completedAt,
      isActive: data['isActive'] as bool,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'targetAmount': targetAmount,
        'createdAt': Timestamp.fromDate(createdAt),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'isActive': isActive,
      };

  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isActive,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        targetAmount,
        createdAt,
        completedAt,
        isActive,
      ];
}
