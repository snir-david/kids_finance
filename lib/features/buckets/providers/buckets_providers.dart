import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/bucket.dart';
import '../domain/bucket_repository.dart';
import '../data/firebase_bucket_repository.dart';

part 'buckets_providers.g.dart';

/// Repository provider
@riverpod
BucketRepository bucketRepository(BucketRepositoryRef ref) {
  return FirebaseBucketRepository(firestore: FirebaseFirestore.instance);
}

/// Stream provider for all buckets of a specific child
@riverpod
Stream<List<Bucket>> childBuckets(ChildBucketsRef ref, {
  required String childId,
  required String familyId,
}) {
  final repository = ref.watch(bucketRepositoryProvider);
  return repository.getBucketsStream(
    childId: childId,
    familyId: familyId,
  );
}

/// Provider for total wealth (sum of all buckets) for a child
@riverpod
double totalWealth(TotalWealthRef ref, {
  required String childId,
  required String familyId,
}) {
  final bucketsAsync = ref.watch(childBucketsProvider(
    childId: childId,
    familyId: familyId,
  ));

  return bucketsAsync.when(
    data: (buckets) {
      return buckets.fold<double>(
        0.0,
        (sum, bucket) => sum + bucket.balance,
      );
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
}

/// Provider to get a specific bucket by type
@riverpod
Bucket? bucketByType(BucketByTypeRef ref, {
  required String childId,
  required String familyId,
  required BucketType type,
}) {
  final bucketsAsync = ref.watch(childBucketsProvider(
    childId: childId,
    familyId: familyId,
  ));

  return bucketsAsync.whenOrNull(
    data: (buckets) {
      try {
        return buckets.firstWhere((bucket) => bucket.type == type);
      } catch (_) {
        return null;
      }
    },
  );
}
