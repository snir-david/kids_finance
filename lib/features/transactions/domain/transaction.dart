import 'package:freezed_annotation/freezed_annotation.dart';
import '../../buckets/domain/bucket.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType {
  @JsonValue('moneySet')
  moneySet,
  @JsonValue('investmentMultiplied')
  investmentMultiplied,
  @JsonValue('charityDonated')
  charityDonated,
  @JsonValue('moneyAdded')
  moneyAdded,
  @JsonValue('moneyRemoved')
  moneyRemoved,
}

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String familyId,
    required String childId,
    required BucketType bucketType,
    required TransactionType type,
    required double amount,
    double? multiplier,
    required double previousBalance,
    required double newBalance,
    String? note,
    required String performedByUid,
    required DateTime performedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
}
