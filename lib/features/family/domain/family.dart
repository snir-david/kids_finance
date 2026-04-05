/// Domain model for a family unit containing parents and children.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Family extends Equatable {
  const Family({
    required this.id,
    required this.name,
    required this.parentIds,
    required this.childIds,
    required this.createdAt,
    this.schemaVersion = '1.0.0',
  });

  final String id;
  final String name;
  final List<String> parentIds;
  final List<String> childIds;
  final DateTime createdAt;
  final String schemaVersion;

  Family copyWith({
    String? id,
    String? name,
    List<String>? parentIds,
    List<String>? childIds,
    DateTime? createdAt,
    String? schemaVersion,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      parentIds: parentIds ?? this.parentIds,
      childIds: childIds ?? this.childIds,
      createdAt: createdAt ?? this.createdAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  factory Family.fromJson(Map<String, dynamic> json) => Family(
        id: json['id'] as String,
        name: json['name'] as String,
        parentIds: List<String>.from(json['parentIds'] as List),
        childIds: List<String>.from(json['childIds'] as List),
        createdAt: (json['createdAt'] as Timestamp).toDate(),
        schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parentIds': parentIds,
        'childIds': childIds,
        'createdAt': Timestamp.fromDate(createdAt),
        'schemaVersion': schemaVersion,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        parentIds,
        childIds,
        createdAt,
        schemaVersion,
      ];
}
