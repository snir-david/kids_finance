/// Domain model for an authenticated app user (parent or child).
import 'package:equatable/equatable.dart';

enum AppUserRole {
  parent,
  child,
  unauthenticated;

  String toJson() => name;

  static AppUserRole fromJson(String value) {
    return AppUserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => AppUserRole.unauthenticated,
    );
  }
}

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.familyId,
    this.childId,
  });

  final String id;
  final String email;
  final AppUserRole role;
  final String? familyId;
  final String? childId;

  AppUser copyWith({
    String? id,
    String? email,
    AppUserRole? role,
    String? familyId,
    String? childId,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      familyId: familyId ?? this.familyId,
      childId: childId ?? this.childId,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        role: AppUserRole.fromJson(json['role'] as String),
        familyId: json['familyId'] as String?,
        childId: json['childId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role.toJson(),
        'familyId': familyId,
        'childId': childId,
      };

  @override
  List<Object?> get props => [id, email, role, familyId, childId];
}
