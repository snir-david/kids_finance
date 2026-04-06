import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../children/domain/child.dart';
import '../../children/providers/children_providers.dart';
import '../providers/auth_providers.dart';

class ChildPickerScreen extends ConsumerWidget {
  const ChildPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyIdAsync = ref.watch(currentFamilyIdProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: familyIdAsync.when(
            data: (familyId) {
              if (familyId == null) {
                return _buildError('No family found. Please sign in.');
              }
              return _buildChildrenGrid(context, ref, familyId);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
            error: (error, stack) => _buildError('Error: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildChildrenGrid(BuildContext context, WidgetRef ref, String familyId) {
    final childrenAsync = ref.watch(childrenProvider(familyId));

    return childrenAsync.when(
      data: (children) {
        if (children.isEmpty) {
          return _buildNoChildren(context);
        }
        return _buildChildrenList(context, ref, children);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
      error: (error, stack) => _buildError('Error loading children: $error'),
    );
  }

  Widget _buildChildrenList(BuildContext context, WidgetRef ref, List<Child> children) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Text(
          'Who are you? 🌟',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: children.length == 1
                  ? _buildSingleChildCard(context, ref, children.first)
                  : _buildChildrenGrid2Column(context, ref, children),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleChildCard(BuildContext context, WidgetRef ref, Child child) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: _buildChildCard(context, ref, child),
    );
  }

  Widget _buildChildrenGrid2Column(BuildContext context, WidgetRef ref, List<Child> children) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => _buildChildCard(context, ref, children[index]),
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, WidgetRef ref, Child child) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedChildProvider.notifier).state = child.id;
        context.go('/child-pin');
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              child.avatarEmoji,
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 16),
            Text(
              child.displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoChildren(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '👆',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 24),
            Text(
              'No children found.',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontSize: 28,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Ask a parent to add you!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white70,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
