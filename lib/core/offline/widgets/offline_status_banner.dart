import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../connectivity_provider.dart';
import '../sync_providers.dart';

class OfflineStatusBanner extends ConsumerStatefulWidget {
  const OfflineStatusBanner({super.key});

  @override
  ConsumerState<OfflineStatusBanner> createState() => _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends ConsumerState<OfflineStatusBanner> {
  bool _showSyncingMessage = false;
  bool _wasOffline = false;

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final pendingOps = ref.watch(pendingOperationsProvider);
    final expiringOps = ref.read(offlineQueueProvider).getExpiring();
    
    // Detect transition from offline to online
    if (_wasOffline && isOnline && pendingOps.isNotEmpty) {
      _showSyncingMessage = true;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showSyncingMessage = false;
          });
        }
      });
    }
    _wasOffline = !isOnline;

    // Determine banner state
    final BannerState bannerState;
    if (_showSyncingMessage && isOnline) {
      bannerState = BannerState.syncing;
    } else if (!isOnline && expiringOps.isNotEmpty) {
      bannerState = BannerState.expiring;
    } else if (!isOnline) {
      bannerState = BannerState.offline;
    } else {
      bannerState = BannerState.online;
    }

    final config = _getBannerConfig(bannerState, pendingOps.length, expiringOps.length);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: config.show ? 40 : 0,
      curve: Curves.easeInOut,
      child: config.show
          ? Container(
              width: double.infinity,
              color: config.color,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (config.icon != null) ...[
                    Icon(config.icon, size: 16, color: config.textColor),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      config.message,
                      style: TextStyle(
                        color: config.textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

enum BannerState { online, offline, expiring, syncing }

class _BannerConfig {
  final bool show;
  final Color color;
  final Color textColor;
  final String message;
  final IconData? icon;

  const _BannerConfig({
    required this.show,
    required this.color,
    required this.textColor,
    required this.message,
    this.icon,
  });
}

_BannerConfig _getBannerConfig(BannerState state, int pendingCount, int expiringCount) {
  switch (state) {
    case BannerState.online:
      return const _BannerConfig(
        show: false,
        color: Colors.transparent,
        textColor: Colors.black,
        message: '',
      );

    case BannerState.offline:
      final message = pendingCount > 0
          ? "You're offline — changes will sync when you reconnect ($pendingCount pending)"
          : "You're offline — changes will sync when you reconnect";
      return _BannerConfig(
        show: true,
        color: Colors.orange.shade700,
        textColor: Colors.white,
        message: message,
        icon: Icons.cloud_off,
      );

    case BannerState.expiring:
      return _BannerConfig(
        show: true,
        color: Colors.red.shade700,
        textColor: Colors.white,
        message: "⚠ Some changes expire in less than 1 hour ($expiringCount expiring)",
        icon: Icons.warning,
      );

    case BannerState.syncing:
      return _BannerConfig(
        show: true,
        color: Colors.green.shade700,
        textColor: Colors.white,
        message: "✓ Syncing $pendingCount changes...",
        icon: Icons.cloud_upload,
      );
  }
}
