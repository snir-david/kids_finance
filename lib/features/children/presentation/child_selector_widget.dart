import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/child.dart';

/// Reusable widget for selecting a child in parent mode.
/// Displays a horizontal scrollable row of child avatar cards.
class ChildSelectorWidget extends ConsumerWidget {
  const ChildSelectorWidget({
    super.key,
    required this.familyId,
    required this.selectedChildId,
    required this.onChildSelected,
    this.children = const [],
  });

  final String familyId;
  final String? selectedChildId;
  final ValueChanged<String> onChildSelected;
  final List<Child> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

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
            child: _ChildAvatarCard(
              child: child,
              isSelected: isSelected,
              onTap: () => onChildSelected(child.id),
            ),
          );
        },
      ),
    );
  }
}

class _ChildAvatarCard extends StatelessWidget {
  const _ChildAvatarCard({
    required this.child,
    required this.isSelected,
    required this.onTap,
  });

  final Child child;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar emoji with animated scale
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.1 : 1.0,
              child: Text(
                child.avatarEmoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 4),
            // Child name
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
    );
  }
}
