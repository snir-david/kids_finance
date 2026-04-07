import 'dart:math';
import 'package:hive/hive.dart';
import 'pending_operation.dart';

class OfflineQueue {
  Box<PendingOperation> get _box => Hive.box<PendingOperation>('pending_operations');

  String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> enqueue(PendingOperation op) async {
    await _box.put(op.id, op);
  }

  List<PendingOperation> getPending() {
    final ops = _box.values.toList();
    ops.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ops;
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  // Returns ops expiring within 1 hour (to warn user)
  List<PendingOperation> getExpiring() {
    return _box.values
        .where((op) => DateTime.now().difference(op.createdAt).inHours >= 23)
        .toList();
  }

  Future<void> purgeExpired() async {
    final expired = _box.values
        .where((op) => DateTime.now().difference(op.createdAt).inHours >= 24)
        .toList();
    for (final op in expired) {
      await _box.delete(op.id);
    }
  }

  String generateId() => _generateId();
}
