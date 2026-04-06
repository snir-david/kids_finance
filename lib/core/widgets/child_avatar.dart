import 'package:flutter/material.dart';

enum AvatarSize { small, medium, large }

class ChildAvatar extends StatelessWidget {
  const ChildAvatar({
    super.key,
    required this.emoji,
    required this.name,
    this.size = AvatarSize.medium,
    this.isSelected = false,
    this.onTap,
  });

  final String emoji;
  final String name;
  final AvatarSize size;
  final bool isSelected;
  final VoidCallback? onTap;

  double get _circleSize {
    switch (size) {
      case AvatarSize.small:
        return 40;
      case AvatarSize.medium:
        return 56;
      case AvatarSize.large:
        return 80;
    }
  }

  double get _emojiSize {
    switch (size) {
      case AvatarSize.small:
        return 20;
      case AvatarSize.medium:
        return 28;
      case AvatarSize.large:
        return 40;
    }
  }

  bool get _showName => size != AvatarSize.small;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: _circleSize,
      height: _circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade200,
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade400,
          width: isSelected ? 3 : 2,
        ),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: _emojiSize),
        ),
      ),
    );

    Widget child;
    
    if (_showName) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: size == AvatarSize.large ? 18 : 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else {
      child = avatar;
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_circleSize / 2),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: child,
        ),
      );
    }

    return child;
  }
}
