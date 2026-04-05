import 'package:freezed_annotation/freezed_annotation.dart';

part 'child.freezed.dart';
part 'child.g.dart';

@freezed
class Child with _$Child {
  const factory Child({
    required String id,
    required String familyId,
    required String displayName,
    required String avatarEmoji,
    required String pinHash,
    DateTime? sessionExpiresAt,
    required DateTime createdAt,
  }) = _Child;

  factory Child.fromJson(Map<String, dynamic> json) => _$ChildFromJson(json);
}
