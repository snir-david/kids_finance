// Shared test helpers for Sprint 5D integration tests.
// These fakes allow tests to run without a real device or Firebase emulator.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kids_finance/core/offline/connectivity_service.dart';
import 'package:kids_finance/core/offline/offline_queue.dart';
import 'package:kids_finance/core/offline/pending_operation.dart';

// flutter_secure_storage v10 exports AppleOptions for both iOS and macOS.
// Re-export so individual test files don't need to import the package directly.
export 'package:flutter_secure_storage/flutter_secure_storage.dart'
    show AndroidOptions, LinuxOptions, WebOptions, WindowsOptions;

// ---------------------------------------------------------------------------
// Connectivity fakes
// ---------------------------------------------------------------------------

/// Always reports online. Overrides the Connectivity platform channel.
class FakeOnlineConnectivity extends ConnectivityService {
  @override
  Future<bool> get isOnline async => true;

  @override
  Stream<bool> get isOnlineStream => Stream.value(true);
}

/// Always reports offline. Overrides the Connectivity platform channel.
class FakeOfflineConnectivity extends ConnectivityService {
  @override
  Future<bool> get isOnline async => false;

  @override
  Stream<bool> get isOnlineStream => Stream.value(false);
}

// ---------------------------------------------------------------------------
// In-memory offline queue (replaces Hive-backed queue in tests)
// ---------------------------------------------------------------------------

class InMemoryOfflineQueue extends OfflineQueue {
  final Map<String, PendingOperation> _ops = {};

  int get count => _ops.length;

  @override
  Future<void> enqueue(PendingOperation op) async {
    _ops[op.id] = op;
  }

  @override
  List<PendingOperation> getPending() {
    final ops = _ops.values.toList();
    ops.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ops;
  }

  @override
  Future<void> remove(String id) async {
    _ops.remove(id);
  }

  @override
  List<PendingOperation> getExpiring() {
    return _ops.values
        .where((op) => DateTime.now().difference(op.createdAt).inHours >= 23)
        .toList();
  }

  @override
  Future<void> purgeExpired() async {
    _ops.removeWhere(
        (_, op) => DateTime.now().difference(op.createdAt).inHours >= 24);
  }

  void clear() => _ops.clear();
}

// ---------------------------------------------------------------------------
// Fake secure storage (replaces FlutterSecureStorage in tests)
// ---------------------------------------------------------------------------

/// In-memory secure storage for testing PinAttemptTracker and PinService.
class FakeSecureStorage extends FlutterSecureStorage {
  const FakeSecureStorage() : super();

  // Backing store shared across all instances in a test run.
  // Tests that need isolation should call _globalStore.clear() in setUp.
  static final Map<String, String> _globalStore = {};

  static void clearAll() => _globalStore.clear();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _globalStore[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _globalStore[key] = value;
    } else {
      _globalStore.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _globalStore.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _globalStore.clear();
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      Map.from(_globalStore);

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _globalStore.containsKey(key);
}

// ---------------------------------------------------------------------------
// Firestore seed helpers
// ---------------------------------------------------------------------------

/// Seeds the three bucket documents for a child in FakeFirebaseFirestore.
/// The repository uses `transaction.update()` which requires docs to exist.
Future<void> seedBuckets(
  FakeFirebaseFirestore firestore, {
  required String familyId,
  required String childId,
  double money = 0.0,
  double investment = 0.0,
  double charity = 0.0,
}) async {
  final base = firestore
      .collection('families')
      .doc(familyId)
      .collection('children')
      .doc(childId)
      .collection('buckets');

  for (final entry in {
    'money': money,
    'investment': investment,
    'charity': charity,
  }.entries) {
    await base.doc(entry.key).set({
      'childId': childId,
      'familyId': familyId,
      'type': entry.key,
      'balance': entry.value,
      'lastUpdatedAt': DateTime.now().toIso8601String(),
    });
  }
}

/// Seeds a child document in FakeFirebaseFirestore.
Future<void> seedChild(
  FakeFirebaseFirestore firestore, {
  required String familyId,
  required String childId,
  required String displayName,
  String avatarEmoji = '🧒',
  String pinHash = r'$2b$10$placeholder',
  bool archived = false,
}) async {
  await firestore
      .collection('families')
      .doc(familyId)
      .collection('children')
      .doc(childId)
      .set({
    'id': childId,
    'familyId': familyId,
    'displayName': displayName,
    'avatarEmoji': avatarEmoji,
    'pinHash': pinHash,
    'archived': archived,
    'createdAt': DateTime.now().toIso8601String(),
  });
}

/// Reads the current balance of a single bucket from FakeFirebaseFirestore.
Future<double> readBalance(
  FakeFirebaseFirestore firestore, {
  required String familyId,
  required String childId,
  required String bucketType,
}) async {
  final doc = await firestore
      .collection('families')
      .doc(familyId)
      .collection('children')
      .doc(childId)
      .collection('buckets')
      .doc(bucketType)
      .get();
  return (doc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
}
