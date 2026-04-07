/// Riverpod providers for bucket-related functionality.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/bucket.dart';
import '../domain/bucket_repository.dart';
import '../data/firebase_bucket_repository.dart';
import '../../badges/data/services/badge_evaluation_service.dart';
import '../../../core/offline/connectivity_provider.dart';
import '../../../core/offline/sync_providers.dart';

/// Repository provider
final bucketRepositoryProvider = Provider<BucketRepository>((ref) {
  return FirebaseBucketRepository(
    connectivity: ref.watch(connectivityServiceProvider),
    queue: ref.watch(offlineQueueProvider),
    badgeService: ref.watch(badgeEvaluationServiceProvider),
  );
});

/// Stream provider for all buckets of a specific child
final childBucketsProvider = StreamProvider.family<List<Bucket>,
    ({String childId, String familyId})>((ref, params) {
  final repository = ref.watch(bucketRepositoryProvider);
  return repository.getBucketsStream(
    childId: params.childId,
    familyId: params.familyId,
  );
});

/// Provider for total wealth (sum of all buckets) for a child
final totalWealthProvider =
    Provider.family<double, ({String childId, String familyId})>(
        (ref, params) {
  final bucketsAsync = ref.watch(childBucketsProvider(params));

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
});

/// Provider to get a specific bucket by type
final bucketByTypeProvider = Provider.family<Bucket?,
    ({String childId, String familyId, BucketType type})>((ref, params) {
  final bucketsAsync = ref.watch(childBucketsProvider((
    childId: params.childId,
    familyId: params.familyId,
  )));

  return bucketsAsync.whenOrNull(
    data: (buckets) {
      try {
        return buckets.firstWhere((bucket) => bucket.type == params.type);
      } catch (_) {
        return null;
      }
    },
  );
});
