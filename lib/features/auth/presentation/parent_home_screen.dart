import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../buckets/domain/bucket.dart';
import '../../buckets/providers/buckets_providers.dart';
import '../../children/domain/child.dart';
import '../../children/providers/children_providers.dart';
import '../../family/providers/family_providers.dart';
import '../providers/auth_providers.dart';

/// State provider for selected child ID in parent dashboard
final selectedChildIdProvider = StateProvider<String?>((ref) => null);

// ─── Available emoji options for new children ────────────────────────────────
const _kAvatarEmojis = [
  '🦁', '🐯', '🐻', '🐼', '🐸', '🦊', '🐶', '🐱',
  '🐮', '🐷', '🦄', '🐙', '🦋', '🐠', '🦕',
];

class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final familyIdAsync = ref.watch(currentFamilyIdProvider);
    final authState = ref.watch(firebaseAuthStateProvider);
    final user = authState.valueOrNull;

    return familyIdAsync.when(
      data: (familyId) {
        if (familyId == null) {
          return const Scaffold(
            body: Center(child: Text('No family found')),
          );
        }

        final familyAsync = ref.watch(familyProvider(familyId));
        final childrenAsync = ref.watch(childrenProvider(familyId));

        return Scaffold(
          appBar: AppBar(
            title: familyAsync.when(
              data: (family) => Text(family?.name ?? 'Family Dashboard'),
              loading: () => const Text('Loading...'),
              error: (_, __) => const Text('Parent Dashboard'),
            ),
            actions: [
              if (user != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      user.email?[0].toUpperCase() ?? 'P',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sign out',
                onPressed: () => _signOut(context),
              ),
            ],
          ),
          body: childrenAsync.when(
            data: (children) => _buildDashboard(context, familyId, children),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading children: $error'),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authServiceProvider).signOut();
    }
  }

  Widget _buildDashboard(BuildContext context, String familyId, List<Child> children) {
    if (children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No children yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('Add your first child to get started'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddChildDialog(context, familyId),
              icon: const Icon(Icons.add),
              label: const Text('Add Child'),
            ),
          ],
        ),
      );
    }

    // Auto-select first child if none selected
    final selectedChildId = ref.watch(selectedChildIdProvider);
    if (selectedChildId == null && children.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedChildIdProvider.notifier).state = children.first.id;
      });
      return const Center(child: CircularProgressIndicator());
    }

    final selectedChild = children.firstWhere(
      (c) => c.id == selectedChildId,
      orElse: () => children.first,
    );

    return Column(
      children: [
        _buildChildSelector(context, familyId, children, selectedChildId),
        const Divider(height: 1),
        Expanded(
          child: _buildChildBuckets(context, familyId, selectedChild),
        ),
      ],
    );
  }

  Widget _buildChildSelector(
    BuildContext context,
    String familyId,
    List<Child> children,
    String? selectedChildId,
  ) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // +1 for the "Add" button at the end
        itemCount: children.length + 1,
        itemBuilder: (context, index) {
          if (index == children.length) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _showAddChildDialog(context, familyId),
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 32, color: Colors.grey.shade500),
                      const SizedBox(height: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final child = children[index];
          final isSelected = child.id == selectedChildId;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                ref.read(selectedChildIdProvider.notifier).state = child.id;
              },
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      child.avatarEmoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      child.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChildBuckets(BuildContext context, String familyId, Child child) {
    final bucketsAsync = ref.watch(childBucketsProvider((
      childId: child.id,
      familyId: familyId,
    )));

    return bucketsAsync.when(
      data: (buckets) {
        Bucket bucket(BucketType t) => buckets.firstWhere(
              (b) => b.type == t,
              orElse: () => Bucket(
                id: '',
                childId: child.id,
                familyId: familyId,
                type: t,
                balance: 0,
                lastUpdatedAt: DateTime.now(),
              ),
            );

        final moneyBucket = bucket(BucketType.money);
        final investmentBucket = bucket(BucketType.investment);
        final charityBucket = bucket(BucketType.charity);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${child.displayName}'s Buckets",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(
                      '/transaction-history',
                      extra: (
                        childId: child.id,
                        familyId: familyId,
                        childName: child.displayName,
                      ),
                    ),
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('History'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Money bucket
              _BucketCard(
                emoji: '💰',
                name: 'Money',
                balance: moneyBucket.balance,
                color: AppTheme.moneyColor,
              ),
              const SizedBox(height: 8),
              _MoneyActionRow(
                bucket: moneyBucket,
                onTapAdd: () => _showMoneyDialog(
                  context,
                  familyId,
                  moneyBucket,
                  mode: _MoneyMode.add,
                ),
                onTapRemove: () => _showMoneyDialog(
                  context,
                  familyId,
                  moneyBucket,
                  mode: _MoneyMode.remove,
                ),
                onTapSet: () => _showMoneyDialog(
                  context,
                  familyId,
                  moneyBucket,
                  mode: _MoneyMode.set,
                ),
              ),

              const SizedBox(height: 16),

              // Investment bucket
              _BucketCard(
                emoji: '📈',
                name: 'Investment',
                balance: investmentBucket.balance,
                color: AppTheme.investmentsColor,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showMultiplyDialog(context, familyId, investmentBucket),
                  icon: const Text('×', style: TextStyle(fontSize: 18)),
                  label: const Text('Multiply Investment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.investmentsColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Charity bucket
              _BucketCard(
                emoji: '❤️',
                name: 'Charity',
                balance: charityBucket.balance,
                color: AppTheme.charityColor,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: charityBucket.balance > 0
                      ? () =>
                          _showDonateDialog(context, familyId, charityBucket)
                      : null,
                  icon: const Text('❤️'),
                  label: const Text('Donate to Charity'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.charityColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading buckets: $error'),
          ],
        ),
      ),
    );
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  void _showAddChildDialog(BuildContext context, String familyId) {
    showDialog(
      context: context,
      builder: (ctx) => _AddChildDialog(familyId: familyId, ref: ref),
    );
  }

  void _showMoneyDialog(
    BuildContext context,
    String familyId,
    Bucket bucket, {
    required _MoneyMode mode,
  }) {
    final authState = ref.read(firebaseAuthStateProvider);
    final uid = authState.valueOrNull?.uid ?? '';
    showDialog(
      context: context,
      builder: (ctx) => _MoneyDialog(
        bucket: bucket,
        mode: mode,
        performedByUid: uid,
        ref: ref,
      ),
    );
  }

  void _showMultiplyDialog(
      BuildContext context, String familyId, Bucket bucket) {
    final authState = ref.read(firebaseAuthStateProvider);
    final uid = authState.valueOrNull?.uid ?? '';
    showDialog(
      context: context,
      builder: (ctx) =>
          _MultiplyDialog(bucket: bucket, performedByUid: uid, ref: ref),
    );
  }

  void _showDonateDialog(
      BuildContext context, String familyId, Bucket bucket) {
    final authState = ref.read(firebaseAuthStateProvider);
    final uid = authState.valueOrNull?.uid ?? '';
    showDialog(
      context: context,
      builder: (ctx) =>
          _DonateDialog(bucket: bucket, performedByUid: uid, ref: ref),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _BucketCard extends StatelessWidget {
  const _BucketCard({
    required this.emoji,
    required this.name,
    required this.balance,
    required this.color,
  });

  final String emoji;
  final String name;
  final double balance;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                '\$${balance.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyActionRow extends StatelessWidget {
  const _MoneyActionRow({
    required this.bucket,
    required this.onTapAdd,
    required this.onTapRemove,
    required this.onTapSet,
  });

  final Bucket bucket;
  final VoidCallback onTapAdd;
  final VoidCallback onTapRemove;
  final VoidCallback onTapSet;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTapAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.moneyColor,
              side: const BorderSide(color: AppTheme.moneyColor),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: bucket.balance > 0 ? onTapRemove : null,
            icon: const Icon(Icons.remove, size: 16),
            label: const Text('Remove'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTapSet,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Set'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Money mode ───────────────────────────────────────────────────────────────

enum _MoneyMode { add, remove, set }

// ─── Add Child Dialog ─────────────────────────────────────────────────────────

class _AddChildDialog extends StatefulWidget {
  const _AddChildDialog({required this.familyId, required this.ref});
  final String familyId;
  final WidgetRef ref;

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<_AddChildDialog> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String _selectedEmoji = _kAvatarEmojis.first;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter a name');
      return;
    }
    if (pin.length < 4 || pin.length > 6 || !RegExp(r'^\d+$').hasMatch(pin)) {
      setState(() => _error = 'PIN must be 4–6 digits');
      return;
    }
    if (pin != confirmPin) {
      setState(() => _error = 'PINs do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pinService = widget.ref.read(pinServiceProvider);
      final pinHash = pinService.hashPin(pin);
      final repo = widget.ref.read(familyRepositoryProvider);
      await repo.addChild(
        familyId: widget.familyId,
        displayName: name,
        avatarEmoji: _selectedEmoji,
        pinHash: pinHash,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Child'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Emoji picker
            const Text('Avatar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kAvatarEmojis.map((e) {
                final isSelected = e == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.08)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // PIN
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN (4–6 digits)',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Add'),
        ),
      ],
    );
  }
}

// ─── Money Dialog (add / remove / set) ───────────────────────────────────────

class _MoneyDialog extends StatefulWidget {
  const _MoneyDialog({
    required this.bucket,
    required this.mode,
    required this.performedByUid,
    required this.ref,
  });
  final Bucket bucket;
  final _MoneyMode mode;
  final String performedByUid;
  final WidgetRef ref;

  @override
  State<_MoneyDialog> createState() => _MoneyDialogState();
}

class _MoneyDialogState extends State<_MoneyDialog> {
  final _controller = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.mode) {
      case _MoneyMode.add:
        return 'Add Money';
      case _MoneyMode.remove:
        return 'Remove Money';
      case _MoneyMode.set:
        return 'Set Money';
    }
  }

  String get _buttonLabel {
    switch (widget.mode) {
      case _MoneyMode.add:
        return 'Add';
      case _MoneyMode.remove:
        return 'Remove';
      case _MoneyMode.set:
        return 'Set';
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_controller.text);
    if (amount == null || amount < 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    if (widget.mode == _MoneyMode.remove && amount > widget.bucket.balance) {
      setState(() => _error = "Can't remove more than current balance");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = widget.ref.read(bucketRepositoryProvider);
      final note =
          _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

      switch (widget.mode) {
        case _MoneyMode.add:
          await repo.addMoney(
            childId: widget.bucket.childId,
            familyId: widget.bucket.familyId,
            amount: amount,
            performedByUid: widget.performedByUid,
            note: note,
          );
          break;
        case _MoneyMode.remove:
          await repo.removeMoney(
            childId: widget.bucket.childId,
            familyId: widget.bucket.familyId,
            amount: amount,
            performedByUid: widget.performedByUid,
            note: note,
          );
          break;
        case _MoneyMode.set:
          await repo.setMoneyBalance(
            childId: widget.bucket.childId,
            familyId: widget.bucket.familyId,
            newBalance: amount,
            performedByUid: widget.performedByUid,
            note: note,
          );
          break;
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefixText =
        widget.mode == _MoneyMode.set ? '\$' : (widget.mode == _MoneyMode.add ? '+\$' : '-\$');

    return AlertDialog(
      title: Text(_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current balance: \$${widget.bucket.balance.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              prefixText: prefixText,
              hintText: '0.00',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.moneyColor,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(_buttonLabel),
        ),
      ],
    );
  }
}

// ─── Multiply Dialog ──────────────────────────────────────────────────────────

class _MultiplyDialog extends StatefulWidget {
  const _MultiplyDialog({
    required this.bucket,
    required this.performedByUid,
    required this.ref,
  });
  final Bucket bucket;
  final String performedByUid;
  final WidgetRef ref;

  @override
  State<_MultiplyDialog> createState() => _MultiplyDialogState();
}

class _MultiplyDialogState extends State<_MultiplyDialog> {
  final _controller = TextEditingController(text: '2');
  final _noteController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final multiplier = double.tryParse(_controller.text);
    if (multiplier == null || multiplier <= 0) {
      setState(() => _error = 'Multiplier must be greater than 0');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = widget.ref.read(bucketRepositoryProvider);
      final note =
          _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
      await repo.multiplyInvestment(
        childId: widget.bucket.childId,
        familyId: widget.bucket.familyId,
        multiplier: multiplier,
        performedByUid: widget.performedByUid,
        note: note,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final multiplier = double.tryParse(_controller.text) ?? 1.0;
    final newBalance = widget.bucket.balance * multiplier;

    return AlertDialog(
      title: const Text('Multiply Investment'),
      content: StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current: \$${widget.bucket.balance.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                onChanged: (_) => setLocal(() {}),
                decoration: const InputDecoration(
                  prefixText: '×',
                  hintText: '2',
                  border: OutlineInputBorder(),
                  helperText: 'e.g. 2 = double, 1.5 = 50% more',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.investmentsColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('📈 Result:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(
                      '\$${newBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.investmentsColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.investmentsColor,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Multiply'),
        ),
      ],
    );
  }
}

// ─── Donate Dialog ────────────────────────────────────────────────────────────

class _DonateDialog extends StatefulWidget {
  const _DonateDialog({
    required this.bucket,
    required this.performedByUid,
    required this.ref,
  });
  final Bucket bucket;
  final String performedByUid;
  final WidgetRef ref;

  @override
  State<_DonateDialog> createState() => _DonateDialogState();
}

class _DonateDialogState extends State<_DonateDialog> {
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = widget.ref.read(bucketRepositoryProvider);
      await repo.donateCharity(
        childId: widget.bucket.childId,
        familyId: widget.bucket.familyId,
        performedByUid: widget.performedByUid,
        note: 'Donated by parent',
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Donate to Charity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will donate all charity funds:',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.charityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('❤️', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Text(
                  '\$${widget.bucket.balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charityColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The charity bucket will be reset to \$0.00.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.charityColor,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Donate ❤️'),
        ),
      ],
    );
  }
}

