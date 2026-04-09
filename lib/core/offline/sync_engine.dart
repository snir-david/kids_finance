import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/buckets/domain/bucket_repository.dart';
import '../../features/children/domain/child_repository.dart';
import 'conflict.dart';
import 'offline_queue.dart';
import 'pending_operation.dart';

class SyncEngine {
  final OfflineQueue _queue;
  final FirebaseFirestore _firestore;
  final BucketRepository _bucketRepo;
  final ChildRepository _childRepo;

  SyncEngine({
    required OfflineQueue queue,
    FirebaseFirestore? firestore,
    required BucketRepository bucketRepo,
    required ChildRepository childRepo,
  })  : _queue = queue,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _bucketRepo = bucketRepo,
        _childRepo = childRepo;

  static const _bucketConflictTypes = {'setMoney', 'distribute', 'multiply', 'donate'};

  /// Process the offline queue. Returns any conflicts found.
  Future<List<BucketConflict>> syncPending() async {
    final ops = _queue.getPending();
    final conflicts = <BucketConflict>[];

    for (final op in ops) {
      try {
        if (_bucketConflictTypes.contains(op.type)) {
          final conflict = await _checkAndApplyBucketOp(op);
          if (conflict != null) {
            conflicts.add(conflict);
          }
        } else {
          await _applyNonConflictOp(op);
        }
      } catch (_) {
        // Increment retry count and continue
        op.retryCount += 1;
        await op.save();
      }
    }

    await _queue.purgeExpired();
    return conflicts;
  }

  Future<BucketConflict?> _checkAndApplyBucketOp(PendingOperation op) async {
    final p = op.payload;
    final childId = p['childId'] as String;
    final familyId = p['familyId'] as String;

    switch (op.type) {
      case 'setMoney':
        return _handleSingleBucketOp(
          op: op,
          childId: childId,
          familyId: familyId,
          bucketDocId: 'money',
          bucketTypeStr: 'money',
          localValue: (p['newBalance'] as num).toDouble(),
          baseValue: _toDoubleOrNull(p['baseValue']),
          apply: () => _bucketRepo.setMoneyBalance(
            childId: childId,
            familyId: familyId,
            newBalance: (p['newBalance'] as num).toDouble(),
            performedByUid: p['performedByUid'] as String,
            note: p['note'] as String?,
          ),
        );

      case 'multiply':
        final currentBalance = await _readBalance(childId, familyId, 'investment');
        final baseValue = _toDoubleOrNull(p['baseValue']);
        if (baseValue != null && (currentBalance - baseValue).abs() > 0.001) {
          return BucketConflict(
            operationId: op.id,
            bucketType: 'investment',
            localValue: (p['baseValue'] as num).toDouble() * (p['multiplier'] as num).toDouble(),
            serverValue: currentBalance,
          );
        }
        await _bucketRepo.multiplyInvestment(
          childId: childId,
          familyId: familyId,
          multiplier: (p['multiplier'] as num).toDouble(),
          performedByUid: p['performedByUid'] as String,
          note: p['note'] as String?,
        );
        await _queue.remove(op.id);
        return null;

      case 'donate':
        return _handleSingleBucketOp(
          op: op,
          childId: childId,
          familyId: familyId,
          bucketDocId: 'charity',
          bucketTypeStr: 'charity',
          localValue: 0.0,
          baseValue: _toDoubleOrNull(p['baseValue']),
          apply: () => _bucketRepo.donateCharity(
            childId: childId,
            familyId: familyId,
            performedByUid: p['performedByUid'] as String,
            note: p['note'] as String?,
          ),
        );

      case 'distribute':
        return _handleDistributeOp(op);

      default:
        return null;
    }
  }

  Future<BucketConflict?> _handleSingleBucketOp({
    required PendingOperation op,
    required String childId,
    required String familyId,
    required String bucketDocId,
    required String bucketTypeStr,
    required double localValue,
    required double? baseValue,
    required Future<void> Function() apply,
  }) async {
    if (baseValue != null) {
      final serverBalance = await _readBalance(childId, familyId, bucketDocId);
      if ((serverBalance - baseValue).abs() > 0.001) {
        return BucketConflict(
          operationId: op.id,
          bucketType: bucketTypeStr,
          localValue: localValue,
          serverValue: serverBalance,
        );
      }
    }
    await apply();
    await _queue.remove(op.id);
    return null;
  }

  Future<BucketConflict?> _handleDistributeOp(PendingOperation op) async {
    final p = op.payload;
    final childId = p['childId'] as String;
    final familyId = p['familyId'] as String;

    final baseValueMoney = _toDoubleOrNull(p['baseValueMoney']);
    final baseValueInvestment = _toDoubleOrNull(p['baseValueInvestment']);
    final baseValueCharity = _toDoubleOrNull(p['baseValueCharity']);

    if (baseValueMoney != null || baseValueInvestment != null || baseValueCharity != null) {
      if (baseValueMoney != null) {
        final serverMoney = await _readBalance(childId, familyId, 'money');
        if ((serverMoney - baseValueMoney).abs() > 0.001) {
          return BucketConflict(
            operationId: op.id,
            bucketType: 'money',
            localValue: baseValueMoney + (p['moneyAmount'] as num).toDouble(),
            serverValue: serverMoney,
          );
        }
      }
      if (baseValueInvestment != null) {
        final serverInv = await _readBalance(childId, familyId, 'investment');
        if ((serverInv - baseValueInvestment).abs() > 0.001) {
          return BucketConflict(
            operationId: op.id,
            bucketType: 'investment',
            localValue: baseValueInvestment + (p['investmentAmount'] as num).toDouble(),
            serverValue: serverInv,
          );
        }
      }
      if (baseValueCharity != null) {
        final serverCharity = await _readBalance(childId, familyId, 'charity');
        if ((serverCharity - baseValueCharity).abs() > 0.001) {
          return BucketConflict(
            operationId: op.id,
            bucketType: 'charity',
            localValue: baseValueCharity + (p['charityAmount'] as num).toDouble(),
            serverValue: serverCharity,
          );
        }
      }
    }

    await _bucketRepo.distributeFunds(
      familyId: familyId,
      childId: childId,
      moneyAmount: (p['moneyAmount'] as num).toDouble(),
      investmentAmount: (p['investmentAmount'] as num).toDouble(),
      charityAmount: (p['charityAmount'] as num).toDouble(),
      performedByUid: p['performedByUid'] as String,
      note: p['note'] as String?,
    );
    await _queue.remove(op.id);
    return null;
  }

  Future<void> _applyNonConflictOp(PendingOperation op) async {
    final p = op.payload;
    final childId = p['childId'] as String;
    final familyId = p['familyId'] as String;

    switch (op.type) {
      case 'addMoney':
        await _bucketRepo.addMoney(
          childId: childId,
          familyId: familyId,
          amount: (p['amount'] as num).toDouble(),
          performedByUid: p['performedByUid'] as String,
          note: p['note'] as String?,
        );
      case 'removeMoney':
        await _bucketRepo.removeMoney(
          childId: childId,
          familyId: familyId,
          amount: (p['amount'] as num).toDouble(),
          performedByUid: p['performedByUid'] as String,
          note: p['note'] as String?,
        );
      case 'updateChild':
        await _childRepo.updateChild(
          childId: childId,
          familyId: familyId,
          name: p['name'] as String?,
          avatarEmoji: p['avatarEmoji'] as String?,
        );
      case 'archiveChild':
        await _childRepo.archiveChild(
          familyId: familyId,
          childId: childId,
        );
    }
    await _queue.remove(op.id);
  }

  /// Resolve a conflict: apply local value or discard op.
  Future<void> resolveConflict(String opId, ConflictResolution resolution) async {
    if (resolution == ConflictResolution.useServer) {
      await _queue.remove(opId);
      return;
    }

    // useLocal: apply the queued value directly
    final ops = _queue.getPending();
    final op = ops.where((o) => o.id == opId).firstOrNull;
    if (op == null) return;

    final p = op.payload;
    final childId = p['childId'] as String;
    final familyId = p['familyId'] as String;

    switch (op.type) {
      case 'setMoney':
        await _bucketRepo.setMoneyBalance(
          childId: childId,
          familyId: familyId,
          newBalance: (p['newBalance'] as num).toDouble(),
          performedByUid: p['performedByUid'] as String,
          note: p['note'] as String?,
        );
      case 'multiply':
        final localValue = (p['baseValue'] as num).toDouble() * (p['multiplier'] as num).toDouble();
        await _writeBalanceDirectly(childId, familyId, 'investment', localValue);
      case 'donate':
        await _bucketRepo.donateCharity(
          childId: childId,
          familyId: familyId,
          performedByUid: p['performedByUid'] as String,
          note: p['note'] as String?,
        );
      case 'distribute':
        await _bucketRepo.distributeFunds(
          familyId: familyId,
          childId: childId,
          moneyAmount: (p['moneyAmount'] as num).toDouble(),
          investmentAmount: (p['investmentAmount'] as num).toDouble(),
          charityAmount: (p['charityAmount'] as num).toDouble(),
          performedByUid: p['performedByUid'] as String,
          note: p['note'] as String?,
        );
    }
    await _queue.remove(opId);
  }

  Future<double> _readBalance(String childId, String familyId, String bucketId) async {
    final snap = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('buckets')
        .doc(bucketId)
        .get();
    return (snap.data()?['balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> _writeBalanceDirectly(
      String childId, String familyId, String bucketId, double balance) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('children')
        .doc(childId)
        .collection('buckets')
        .doc(bucketId)
        .update({
      'balance': balance,
      'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    return (value as num).toDouble();
  }
}
