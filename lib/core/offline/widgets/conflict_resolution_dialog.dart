import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../currency/currency_formatter.dart';
import '../conflict.dart';
import '../sync_providers.dart';

class ConflictResolutionDialog extends ConsumerWidget {
  final BucketConflict conflict;

  const ConflictResolutionDialog({
    required this.conflict,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bucketName = _bucketDisplayName(conflict.bucketType);
    final formatter = ref.watch(currencyFormatterProvider);

    return AlertDialog(
      title: Text('Sync Conflict — $bucketName Bucket'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You changed this while offline.\n'
            'The value was updated by someone else at the same time.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildValueRow('Your change:', conflict.localValue, formatter),
          const SizedBox(height: 8),
          _buildValueRow('Current value:', conflict.serverValue, formatter),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () async {
            await _resolveConflict(ref, ConflictResolution.useServer);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Use current value'),
        ),
        FilledButton(
          onPressed: () async {
            await _resolveConflict(ref, ConflictResolution.useLocal);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Keep my change'),
        ),
      ],
    );
  }

  Widget _buildValueRow(String label, double value, CurrencyFormatter formatter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(formatter.formatAmount(value),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _resolveConflict(WidgetRef ref, ConflictResolution resolution) async {
    final syncEngine = ref.read(syncEngineProvider);
    await syncEngine.resolveConflict(conflict.operationId, resolution);
    ref.read(pendingConflictsProvider.notifier).removeConflict(conflict.operationId);
    ref.read(pendingOperationsProvider.notifier).refresh();
  }

  String _bucketDisplayName(String bucketType) {
    switch (bucketType) {
      case 'money':
        return 'Money';
      case 'investment':
        return 'Investment';
      case 'charity':
        return 'Charity';
      default:
        return bucketType;
    }
  }
}

/// Shows conflict resolution dialog when conflicts are detected.
/// Returns a [ProviderSubscription] — caller must close it in dispose().
ProviderSubscription<List<BucketConflict>> showConflictDialogIfNeeded(
    BuildContext context, WidgetRef ref) {
  return ref.listenManual<List<BucketConflict>>(pendingConflictsProvider,
      (prev, next) {
    if (next.isNotEmpty && context.mounted) {
      _showNextConflict(context, next.first);
    }
  });
}

void _showNextConflict(BuildContext context, BucketConflict conflict) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ConflictResolutionDialog(conflict: conflict),
  );
}
