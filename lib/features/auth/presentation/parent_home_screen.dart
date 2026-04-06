import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../buckets/domain/bucket.dart';
import '../../buckets/providers/buckets_providers.dart';
import '../../children/domain/child.dart';
import '../../children/providers/children_providers.dart';
import '../../family/providers/family_providers.dart';
import '../providers/auth_providers.dart';

/// State provider for selected child ID in parent dashboard
final selectedChildIdProvider = StateProvider<String?>((ref) => null);

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
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      user.email?[0].toUpperCase() ?? 'P',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
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
              onPressed: () {
                // TODO: Navigate to add child screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add child feature coming soon')),
                );
              },
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
        // Child selector
        _buildChildSelector(context, children, selectedChildId),
        const Divider(height: 1),
        
        // Selected child's buckets
        Expanded(
          child: _buildChildBuckets(context, familyId, selectedChild),
        ),
      ],
    );
  }

  Widget _buildChildSelector(BuildContext context, List<Child> children, String? selectedChildId) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        itemBuilder: (context, index) {
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
                  color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
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
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppTheme.primaryColor : Colors.black87,
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
        final moneyBucket = buckets.firstWhere(
          (b) => b.type == BucketType.money,
          orElse: () => Bucket(
            id: '',
            childId: child.id,
            familyId: familyId,
            type: BucketType.money,
            balance: 0,
            lastUpdatedAt: DateTime.now(),
          ),
        );
        final investmentBucket = buckets.firstWhere(
          (b) => b.type == BucketType.investment,
          orElse: () => Bucket(
            id: '',
            childId: child.id,
            familyId: familyId,
            type: BucketType.investment,
            balance: 0,
            lastUpdatedAt: DateTime.now(),
          ),
        );
        final charityBucket = buckets.firstWhere(
          (b) => b.type == BucketType.charity,
          orElse: () => Bucket(
            id: '',
            childId: child.id,
            familyId: familyId,
            type: BucketType.charity,
            balance: 0,
            lastUpdatedAt: DateTime.now(),
          ),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${child.displayName}'s Buckets",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              _buildBucketCard(
                context,
                emoji: '💰',
                name: 'Money',
                balance: moneyBucket.balance,
                color: AppTheme.moneyColor,
              ),
              const SizedBox(height: 12),
              
              _buildBucketCard(
                context,
                emoji: '📈',
                name: 'Investment',
                balance: investmentBucket.balance,
                color: AppTheme.investmentsColor,
              ),
              const SizedBox(height: 12),
              
              _buildBucketCard(
                context,
                emoji: '❤️',
                name: 'Charity',
                balance: charityBucket.balance,
                color: AppTheme.charityColor,
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              _buildActionButtons(context, moneyBucket, investmentBucket, charityBucket),
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

  Widget _buildBucketCard(
    BuildContext context, {
    required String emoji,
    required String name,
    required double balance,
    required Color color,
  }) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Bucket moneyBucket,
    Bucket investmentBucket,
    Bucket charityBucket,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showSetMoneyDialog(context, moneyBucket),
            icon: const Text('💰'),
            label: const Text('Set Money'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.moneyColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showMultiplyDialog(context, investmentBucket),
            icon: const Text('×'),
            label: const Text('Invest'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.investmentsColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showDonateDialog(context, charityBucket),
            icon: const Text('❤️'),
            label: const Text('Donate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.charityColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showSetMoneyDialog(BuildContext context, Bucket moneyBucket) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Money Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: \$${moneyBucket.balance.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: '\$',
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount >= 0) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Setting money to \$${amount.toStringAsFixed(2)}'),
                    backgroundColor: AppTheme.moneyColor,
                  ),
                );
                // TODO: Wire to repository in Phase 3
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showMultiplyDialog(BuildContext context, Bucket investmentBucket) {
    final controller = TextEditingController(text: '2.0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Multiply Investment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: \$${investmentBucket.balance.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: '×',
                hintText: '2.0',
                border: OutlineInputBorder(),
                helperText: 'Multiplier must be > 0',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final multiplier = double.tryParse(controller.text);
              if (multiplier != null && multiplier > 0) {
                final newBalance = investmentBucket.balance * multiplier;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Multiplying by ×$multiplier = \$${newBalance.toStringAsFixed(2)}',
                    ),
                    backgroundColor: AppTheme.investmentsColor,
                  ),
                );
                // TODO: Wire to repository in Phase 3
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Multiplier must be greater than 0'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Multiply'),
          ),
        ],
      ),
    );
  }

  void _showDonateDialog(BuildContext context, Bucket charityBucket) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                  Expanded(
                    child: Text(
                      '\$${charityBucket.balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.charityColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The charity bucket will be reset to \$0.00',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Donated \$${charityBucket.balance.toStringAsFixed(2)} to charity!',
                  ),
                  backgroundColor: AppTheme.charityColor,
                ),
              );
              // TODO: Wire to repository in Phase 3
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.charityColor,
            ),
            child: const Text('Donate'),
          ),
        ],
      ),
    );
  }
}
