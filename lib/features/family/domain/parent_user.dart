import 'package:freezed_annotation/freezed_annotation.dart';

part 'parent_user.freezed.dart';
part 'parent_user.g.dart';

@freezed
class ParentUser with _$ParentUser {
  const factory ParentUser({
    required String uid,
    required String displayName,
    required String familyId,
    required bool isOwner,
    required DateTime createdAt,
  }) = _ParentUser;

  factory ParentUser.fromJson(Map<String, dynamic> json) => _$ParentUserFromJson(json);
}
