import 'package:freezed_annotation/freezed_annotation.dart';

part 'family.freezed.dart';
part 'family.g.dart';

@freezed
class Family with _$Family {
  const factory Family({
    required String id,
    required String name,
    required List<String> parentIds,
    required List<String> childIds,
    required DateTime createdAt,
    @Default('1.0.0') String schemaVersion,
  }) = _Family;

  factory Family.fromJson(Map<String, dynamic> json) => _$FamilyFromJson(json);
}
