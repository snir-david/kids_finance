import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/offline/sync_providers.dart';
import '../../../core/offline/widgets/conflict_resolution_dialog.dart';
import '../../../core/offline/widgets/offline_status_banner.dart';
import '../../../core/theme/app_theme.dart';
import '../../buckets/domain/bucket.dart';
import '../../buckets/presentation/widgets/celebration_overlay.dart';
import '../../buckets/providers/buckets_providers.dart';
import '../../children/domain/child.dart';
import '../../children/providers/children_providers.dart';
import '../../family/providers/family_providers.dart';
import '../providers/auth_providers.dart';

/// Notifier for selected child ID in parent dashboard
class SelectedChildIdNotifier extends Notifier<String?> {
  SelectedChildIdNotifier([this._initial]);
  final String? _initial;

  @override
  String? build() => _initial;

  void setState(String? value) => state = value;
}

final selectedChildIdProvider =
    NotifierProvider<SelectedChildIdNotifier, String?>(SelectedChildIdNotifier.new);

Bucket _createEmptyBucket(BucketType type, String childId, String familyId) {
  return Bucket(
    id: '',
    childId: childId,
    familyId: familyId,
    type: type,
    balance: 0,
    lastUpdatedAt: DateTime.now(),
  );
}

// ─── Available emoji options for new children ────────────────────────────────
const _kAvatarEmojis = [
  '🦁', '🐯', '🐻', '🐼', '🐸', '🦊', '🐶', '🐱',
  '🐮', '🐷', '🦄', '🐙', '🦋', '🐠', '🦕',
];

// PIN constraints
const int _kMinPinLength = 4;
const int _kMaxPinLength = 6;

class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> with WidgetsBindingObserver {
  bool _hasShownExpiryWarning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Set up conflict dialog listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showConflictDialogIfNeeded(context, ref);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasShownExpiryWarning) {
      final expiringOps = ref.read(offlineQueueProvider).getExpiring();
      if (expiringOps.isNotEmpty && mounted) {
        _hasShownExpiryWarning = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠ You have offline changes that will be lost in less than 1 hour. Connect to sync.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyIdAsync = ref.watch(currentFamilyIdProvider);
    final authState = ref.watch(firebaseAuthStateProvider);
    final user = authState.value;

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
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'family_settings') {
                    _showFamilySettingsDialog(context, ref, familyId);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'family_settings',
                    child: ListTile(
                      leading: Icon(Icons.group_add),
                      title: Text('Invite Another Parent'),
                    ),
                  ),
                ],
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

    final selectedChildId = ref.watch(selectedChildIdProvider);
    final effectiveChildId = selectedChildId ?? children.first.id;

    // Auto-select first child if none selected
    if (selectedChildId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
        ref.read(selectedChildIdProvider.notifier).setState(children.first.id);
        }
      });
    }

    final selectedChild = children.firstWhere(
      (c) => c.id == effectiveChildId,
      orElse: () => children.first,
    );

    return Column(
      children: [
        const OfflineStatusBanner(),
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
                ref.read(selectedChildIdProvider.notifier).setState(child.id);
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
              orElse: () => _createEmptyBucket(t, child.id, familyId),
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
              const SizedBox(height: 16),

              // Action bar at the top
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showDistributeFundsDialog(
                        context,
                        familyId,
                        child,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showBucketActionDialog(
                        context,
                        familyId,
                        child,
                        buckets,
                        mode: _BucketActionMode.remove,
                      ),
                      icon: const Icon(Icons.remove, size: 18),
                      label: const Text('Remove'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showEditChildDialog(
                        context,
                        familyId,
                        child,
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Three buckets below - display only
              _BucketCard(
                emoji: '💰',
                name: 'Money',
                balance: moneyBucket.balance,
                color: AppTheme.moneyColor,
              ),
              const SizedBox(height: 12),
              _BucketCard(
                emoji: '📈',
                name: 'Investment',
                balance: investmentBucket.balance,
                color: AppTheme.investmentsColor,
              ),
              const SizedBox(height: 12),
              _BucketCard(
                emoji: '❤️',
                name: 'Charity',
                balance: charityBucket.balance,
                color: AppTheme.charityColor,
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

  void _showBucketActionDialog(
    BuildContext context,
    String familyId,
    Child child,
    List<Bucket> buckets,
    {required _BucketActionMode mode}
  ) {
    final authState = ref.read(firebaseAuthStateProvider);
    final uid = authState.value?.uid ?? '';
    showDialog(
      context: context,
      builder: (ctx) => _BucketActionDialog(
        familyId: familyId,
        child: child,
        buckets: buckets,
        mode: mode,
        performedByUid: uid,
        ref: ref,
      ),
    );
  }

  void _showDistributeFundsDialog(
    BuildContext context,
    String familyId,
    Child child,
  ) {
    final authState = ref.read(firebaseAuthStateProvider);
    final uid = authState.value?.uid ?? '';
    showDialog(
      context: context,
      builder: (ctx) => _DistributeFundsDialog(
        familyId: familyId,
        child: child,
        performedByUid: uid,
        ref: ref,
      ),
    );
  }

  void _showEditChildDialog(
    BuildContext context,
    String familyId,
    Child child,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _EditChildDialog(
        familyId: familyId,
        child: child,
        ref: ref,
      ),
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

// ─── Bucket action mode ───────────────────────────────────────────────────────

enum _BucketActionMode { add, remove }

// ─── Firestore error → human-readable message ─────────────────────────────────
/// Returns a user-friendly error string for any Firestore / platform failure.
/// Never exposes raw exception internals to the user.
String _firestoreErrorMessage(Object e) {
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return 'You don\'t have permission to do that. Please sign out and sign back in.';
      case 'not-found':
        return 'The record wasn\'t found. Please refresh and try again.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Network error — check your connection and try again.';
      case 'already-exists':
        return 'This already exists. Please refresh and try again.';
      case 'resource-exhausted':
        return 'Too many requests. Please wait a moment and try again.';
      default:
        return 'Something went wrong (${e.code}). Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}

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
    if (pin.length < _kMinPinLength || pin.length > _kMaxPinLength || !RegExp(r'^\d+$').hasMatch(pin)) {
      setState(() => _error = 'PIN must be $_kMinPinLength–$_kMaxPinLength digits');
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
      final msg = _firestoreErrorMessage(e);
      if (mounted) {
        setState(() => _error = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
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
              maxLength: _kMaxPinLength,
              decoration: InputDecoration(
                labelText: 'PIN ($_kMinPinLength–$_kMaxPinLength digits)',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: _kMaxPinLength,
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

// ─── Bucket Action Dialog (unified add/remove for all buckets) ───────────────

class _BucketActionDialog extends StatefulWidget {
  const _BucketActionDialog({
    required this.familyId,
    required this.child,
    required this.buckets,
    required this.mode,
    required this.performedByUid,
    required this.ref,
  });
  final String familyId;
  final Child child;
  final List<Bucket> buckets;
  final _BucketActionMode mode;
  final String performedByUid;
  final WidgetRef ref;

  @override
  State<_BucketActionDialog> createState() => _BucketActionDialogState();
}

class _BucketActionDialogState extends State<_BucketActionDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  BucketType _selectedBucket = BucketType.money; // Default to Money
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Bucket get _currentBucket {
    return widget.buckets.firstWhere(
      (b) => b.type == _selectedBucket,
      orElse: () => _createEmptyBucket(
        _selectedBucket,
        widget.child.id,
        widget.familyId,
      ),
    );
  }

  String get _title {
    switch (widget.mode) {
      case _BucketActionMode.add:
        return 'Add to Bucket';
      case _BucketActionMode.remove:
        return 'Remove from Bucket';
    }
  }

  String get _buttonLabel {
    switch (widget.mode) {
      case _BucketActionMode.add:
        return 'Add';
      case _BucketActionMode.remove:
        return 'Remove';
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Amount must be greater than 0');
      return;
    }

    final currentBucket = _currentBucket;
    
    if (widget.mode == _BucketActionMode.remove && amount > currentBucket.balance) {
      setState(() => _error = "Can't remove more than current balance");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = widget.ref.read(bucketRepositoryProvider);
      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();

      switch (_selectedBucket) {
        case BucketType.money:
          if (widget.mode == _BucketActionMode.add) {
            await repo.addMoney(
              childId: widget.child.id,
              familyId: widget.familyId,
              amount: amount,
              performedByUid: widget.performedByUid,
              note: note,
            );
          } else {
            await repo.removeMoney(
              childId: widget.child.id,
              familyId: widget.familyId,
              amount: amount,
              performedByUid: widget.performedByUid,
              note: note,
            );
          }
          break;

        case BucketType.investment:
          // Investment uses multiply, not direct add/remove
          // For Add: use multiplier based on current balance
          // For Remove: not supported - show error
          if (widget.mode == _BucketActionMode.add) {
            if (currentBucket.balance == 0) {
              setState(() => _error = 'Investment is empty. Add money first, then multiply it.');
              setState(() => _isLoading = false);
              return;
            }
            // Calculate multiplier: (current + amount) / current
            final multiplier = (currentBucket.balance + amount) / currentBucket.balance;
            await repo.multiplyInvestment(
              childId: widget.child.id,
              familyId: widget.familyId,
              multiplier: multiplier,
              performedByUid: widget.performedByUid,
              note: note ?? 'Added \$${amount.toStringAsFixed(2)} via multiplier',
            );
          } else {
            setState(() => _error = 'Investment can only be multiplied, not removed directly');
            setState(() => _isLoading = false);
            return;
          }
          break;

        case BucketType.charity:
          // Charity: can add (via distribute or money transfer), but removing not supported
          if (widget.mode == _BucketActionMode.add) {
            // Use distributeFunds with charity amount only
            await repo.distributeFunds(
              familyId: widget.familyId,
              childId: widget.child.id,
              moneyAmount: 0,
              investmentAmount: 0,
              charityAmount: amount,
              performedByUid: widget.performedByUid,
              note: note,
            );
          } else {
            setState(() => _error = 'Charity can only be donated (which resets to zero), not removed partially');
            setState(() => _isLoading = false);
            return;
          }
          break;
      }

      if (mounted) {
        Navigator.pop(context);
        // Show celebration for add operations
        if (widget.mode == _BucketActionMode.add) {
          final celebrationType = switch (_selectedBucket) {
            BucketType.money => CelebrationType.money,
            BucketType.investment => CelebrationType.investment,
            BucketType.charity => CelebrationType.charity,
          };
          _showCelebration(context, celebrationType);
        }
      }
    } catch (e) {
      final msg = _firestoreErrorMessage(e);
      if (mounted) {
        setState(() => _error = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBucket = _currentBucket;
    final amount = double.tryParse(_amountController.text);
    final isAmountInvalid = amount == null || amount <= 0;

    return AlertDialog(
      title: Text(_title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bucket selector
            const Text(
              'Which bucket?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SegmentedButton<BucketType>(
              segments: const [
                ButtonSegment(
                  value: BucketType.money,
                  label: Text('💰 Money'),
                ),
                ButtonSegment(
                  value: BucketType.investment,
                  label: Text('📈 Investment'),
                ),
                ButtonSegment(
                  value: BucketType.charity,
                  label: Text('❤️ Charity'),
                ),
              ],
              selected: {_selectedBucket},
              onSelectionChanged: (Set<BucketType> selected) {
                setState(() {
                  _selectedBucket = selected.first;
                  _error = null; // Clear error when bucket changes
                });
              },
            ),
            const SizedBox(height: 16),

            // Current balance
            Text(
              'Current balance: \$${currentBucket.balance.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            // Amount input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixText: widget.mode == _BucketActionMode.add ? '+\$' : '-\$',
                hintText: '0.00',
                labelText: 'Amount',
                border: const OutlineInputBorder(),
                helperText: isAmountInvalid ? 'Amount must be greater than 0' : null,
                helperStyle: TextStyle(color: isAmountInvalid ? Colors.red : null),
              ),
            ),
            const SizedBox(height: 12),

            // Note field
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
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
          onPressed: (_isLoading || isAmountInvalid) ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: widget.mode == _BucketActionMode.add
                ? AppTheme.primaryColor
                : Colors.orange,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_buttonLabel),
        ),
      ],
    );
  }
}

// ─── Distribute Funds Dialog ──────────────────────────────────────────────────

class _DistributeFundsDialog extends StatefulWidget {
  const _DistributeFundsDialog({
    required this.familyId,
    required this.child,
    required this.performedByUid,
    required this.ref,
  });
  final String familyId;
  final Child child;
  final String performedByUid;
  final WidgetRef ref;

  @override
  State<_DistributeFundsDialog> createState() => _DistributeFundsDialogState();
}

class _DistributeFundsDialogState extends State<_DistributeFundsDialog> {
  static const double _moneyPercent = 0.70;
  static const double _investPercent = 0.20;
  static const double _charityPercent = 0.10;

  final _totalController = TextEditingController();
  final _moneyController = TextEditingController();
  final _investmentController = TextEditingController();
  final _charityController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _totalController.dispose();
    _moneyController.dispose();
    _investmentController.dispose();
    _charityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _totalAmount => double.tryParse(_totalController.text) ?? 0.0;
  double get _moneyAmount => double.tryParse(_moneyController.text) ?? 0.0;
  double get _investmentAmount => double.tryParse(_investmentController.text) ?? 0.0;
  double get _charityAmount => double.tryParse(_charityController.text) ?? 0.0;
  double get _allocatedTotal => _moneyAmount + _investmentAmount + _charityAmount;
  double get _remaining => _totalAmount - _allocatedTotal;

  bool get _moneyFilled => _moneyController.text.trim().isNotEmpty;
  bool get _investmentFilled => _investmentController.text.trim().isNotEmpty;
  bool get _charityFilled => _charityController.text.trim().isNotEmpty;
  int get _filledCount =>
      (_moneyFilled ? 1 : 0) + (_investmentFilled ? 1 : 0) + (_charityFilled ? 1 : 0);

  void _updateFields() => setState(() {});

  void _autoDistribute() {
    if (_totalAmount <= 0) return;
    final money = double.parse((_totalAmount * _moneyPercent).toStringAsFixed(2));
    final invest = double.parse((_totalAmount * _investPercent).toStringAsFixed(2));
    final charity = double.parse((_totalAmount * _charityPercent).toStringAsFixed(2));
    // Rounding remainder goes to money
    final remainder = double.parse((_totalAmount - money - invest - charity).toStringAsFixed(2));
    setState(() {
      _moneyController.text = (money + remainder).toStringAsFixed(2);
      _investmentController.text = invest.toStringAsFixed(2);
      _charityController.text = charity.toStringAsFixed(2);
    });
  }

  ({double money, double invest, double charity})? _resolvedAmounts() {
    if (_filledCount == 0) {
      // Auto-distribute
      final money = double.parse((_totalAmount * _moneyPercent).toStringAsFixed(2));
      final invest = double.parse((_totalAmount * _investPercent).toStringAsFixed(2));
      final charity = double.parse((_totalAmount * _charityPercent).toStringAsFixed(2));
      final remainder = double.parse((_totalAmount - money - invest - charity).toStringAsFixed(2));
      return (money: money + remainder, invest: invest, charity: charity);
    }

    final moneyAmt = _moneyFilled ? _moneyAmount : 0.0;
    final investAmt = _investmentFilled ? _investmentAmount : 0.0;
    final charityAmt = _charityFilled ? _charityAmount : 0.0;

    if ((_moneyFilled && moneyAmt <= 0) ||
        (_investmentFilled && investAmt <= 0) ||
        (_charityFilled && charityAmt <= 0)) {
      setState(() => _error = 'Each entered bucket amount must be greater than 0');
      return null;
    }

    // All 3 filled: sum must match total
    if (_filledCount == 3 && (moneyAmt + investAmt + charityAmt - _totalAmount).abs() > 0.005) {
      final diff = _totalAmount - (moneyAmt + investAmt + charityAmt);
      setState(() => _error =
          'Bucket totals must equal \$${_totalAmount.toStringAsFixed(2)} '
          '(${diff > 0 ? '\$${diff.toStringAsFixed(2)} remaining' : '\$${(-diff).toStringAsFixed(2)} over'})');
      return null;
    }

    // Partial fill: must not exceed total
    if (moneyAmt + investAmt + charityAmt > _totalAmount + 0.005) {
      setState(() => _error =
          'Bucket totals exceed total by \$${(moneyAmt + investAmt + charityAmt - _totalAmount).toStringAsFixed(2)}');
      return null;
    }

    return (money: moneyAmt, invest: investAmt, charity: charityAmt);
  }

  Future<void> _submit() async {
    if (_totalAmount <= 0) {
      setState(() => _error = 'Total amount must be greater than 0');
      return;
    }

    final amounts = _resolvedAmounts();
    if (amounts == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = widget.ref.read(bucketRepositoryProvider);
      final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

      await repo.distributeFunds(
        familyId: widget.familyId,
        childId: widget.child.id,
        moneyAmount: amounts.money,
        investmentAmount: amounts.invest,
        charityAmount: amounts.charity,
        performedByUid: widget.performedByUid,
        note: note,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Added to ${widget.child.displayName}\'s buckets!'),
            backgroundColor: Colors.green,
          ),
        );
        _showCelebration(context, CelebrationType.money);
      }
    } catch (e) {
      final msg = _firestoreErrorMessage(e);
      if (mounted) {
        setState(() => _error = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTotal = _totalAmount > 0;

    return AlertDialog(
      title: Text('Add Funds for ${widget.child.displayName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Amount',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _totalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              onChanged: (_) => _updateFields(),
              decoration: const InputDecoration(
                prefixText: '\$',
                hintText: '0.00',
                labelText: 'Total amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Per Bucket (optional)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _moneyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _updateFields(),
              decoration: const InputDecoration(
                prefixText: '\$',
                hintText: '0.00',
                labelText: '💰 Money',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _investmentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _updateFields(),
              decoration: const InputDecoration(
                prefixText: '\$',
                hintText: '0.00',
                labelText: '📈 Investment',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _charityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _updateFields(),
              decoration: const InputDecoration(
                prefixText: '\$',
                hintText: '0.00',
                labelText: '❤️ Charity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Remaining indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _remaining == 0
                    ? Colors.green.shade50
                    : _remaining > 0
                        ? Colors.orange.shade50
                        : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _remaining == 0
                      ? Colors.green.shade300
                      : _remaining > 0
                          ? Colors.orange.shade300
                          : Colors.red.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Remaining:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '\$${_remaining.abs().toStringAsFixed(2)}'
                    '${_remaining > 0 ? ' left' : _remaining < 0 ? ' over' : ' ✓'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _remaining == 0
                          ? Colors.green.shade700
                          : _remaining > 0
                              ? Colors.orange.shade700
                              : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: (_isLoading || !hasTotal) ? null : _autoDistribute,
          child: const Text('Auto-Distribute'),
        ),
        FilledButton(
          onPressed: (_isLoading || !hasTotal) ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Add Funds'),
        ),
      ],
    );
  }
}

// ─── Edit Child Dialog ────────────────────────────────────────────────────────

class _EditChildDialog extends StatefulWidget {
  const _EditChildDialog({
    required this.familyId,
    required this.child,
    required this.ref,
  });
  final String familyId;
  final Child child;
  final WidgetRef ref;

  @override
  State<_EditChildDialog> createState() => _EditChildDialogState();
}

class _EditChildDialogState extends State<_EditChildDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emojiController;
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.displayName);
    _emojiController = TextEditingController(text: widget.child.avatarEmoji);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final emoji = _emojiController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter a name');
      return;
    }

    if (emoji.isEmpty) {
      setState(() => _error = 'Please enter an emoji');
      return;
    }

    // PIN validation only if they're trying to change it
    if (newPin.isNotEmpty || confirmPin.isNotEmpty) {
      if (newPin.length < _kMinPinLength || newPin.length > _kMaxPinLength || !RegExp(r'^\d+$').hasMatch(newPin)) {
        setState(() => _error = 'PIN must be $_kMinPinLength–$_kMaxPinLength digits');
        return;
      }
      if (newPin != confirmPin) {
        setState(() => _error = 'PINs do not match');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = widget.ref.read(childRepositoryProvider);
      
      await repo.updateChild(
        childId: widget.child.id,
        familyId: widget.familyId,
        name: name != widget.child.displayName ? name : null,
        avatarEmoji: emoji != widget.child.avatarEmoji ? emoji : null,
        newPin: newPin.isNotEmpty ? newPin : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final msg = _firestoreErrorMessage(e);
      if (mounted) {
        setState(() => _error = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showArchiveConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Child?'),
        content: Text(
          "Are you sure? ${widget.child.displayName}'s data will be preserved but they'll be removed from your family.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _archiveChild();
    }
  }

  Future<void> _archiveChild() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = widget.ref.read(childRepositoryProvider);
      await repo.archiveChild(
        familyId: widget.familyId,
        childId: widget.child.id,
      );

      if (mounted) {
        // Close the edit dialog
        Navigator.pop(context);
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.child.displayName} has been archived'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      final msg = _firestoreErrorMessage(e);
      if (mounted) {
        setState(() => _error = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Child'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emojiController,
              decoration: const InputDecoration(
                labelText: 'Avatar Emoji',
                border: OutlineInputBorder(),
                hintText: '🦁',
              ),
            ),
            const SizedBox(height: 16),

            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Change PIN (optional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _newPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: _kMaxPinLength,
              decoration: InputDecoration(
                labelText: 'New PIN ($_kMinPinLength–$_kMaxPinLength digits)',
                border: const OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: _kMaxPinLength,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Archive button
            TextButton.icon(
              onPressed: _isLoading ? null : _showArchiveConfirmation,
              icon: const Icon(Icons.archive_outlined, color: Colors.red),
              label: const Text(
                'Archive Child',
                style: TextStyle(color: Colors.red),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
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
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ─── Family Settings Dialog ────────────────────────────────────────────────────

void _showFamilySettingsDialog(BuildContext context, WidgetRef ref, String familyId) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.group_add, color: Colors.deepPurple),
          SizedBox(width: 8),
          Text('Invite Another Parent'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share this Family Code with another parent.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'They must sign up first, then enter this code.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.shade200),
            ),
            child: Column(
              children: [
                const Text(
                  'Family Code',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  familyId,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

// ─── Celebration Overlay Helper ────────────────────────────────────────────────

void _showCelebration(BuildContext context, CelebrationType type) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, _, __) => CelebrationOverlay(
        type: type,
        onComplete: () => Navigator.of(ctx).pop(),
      ),
    ),
  );
}

