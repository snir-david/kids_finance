import 'package:freezed_annotation/freezed_annotation.dart';

part 'bucket.freezed.dart';
part 'bucket.g.dart';

enum BucketType {
  @JsonValue('money')
  money,
  @JsonValue('investment')
  investment,
  @JsonValue('charity')
  charity,
}

@freezed
class Bucket with _$Bucket {
  const factory Bucket({
    required String id,
    required String childId,
    required String familyId,
    required BucketType type,
    required double balance,
    required DateTime lastUpdatedAt,
  }) = _Bucket;

  factory Bucket.fromJson(Map<String, dynamic> json) => _$BucketFromJson(json);
}
