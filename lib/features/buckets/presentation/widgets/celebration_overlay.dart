import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum CelebrationType {
  money,
  investment,
  charity,
}

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.type,
    required this.onComplete,
  });

  final CelebrationType type;
  final VoidCallback onComplete;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss after animation completes
    Future.delayed(_animationDuration, () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  Duration get _animationDuration {
    switch (widget.type) {
      case CelebrationType.money:
        return const Duration(milliseconds: 2500);
      case CelebrationType.investment:
        return const Duration(milliseconds: 3500);
      case CelebrationType.charity:
        return const Duration(milliseconds: 4500);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      child: Stack(
        children: [
          // Tap to dismiss
          GestureDetector(
            onTap: widget.onComplete,
            child: Container(color: Colors.transparent),
          ),
          // Animation based on type
          switch (widget.type) {
            CelebrationType.money => _buildMoneyAnimation(),
            CelebrationType.investment => _buildInvestmentAnimation(),
            CelebrationType.charity => _buildCharityAnimation(),
          },
        ],
      ),
    );
  }

  Widget _buildMoneyAnimation() {
    return Stack(
      children: [
        // Message
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              '💰 Money added!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          )
              .animate()
              .scale(
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: const Duration(milliseconds: 200)),
        ),
        // Falling coins
        ..._buildFallingCoins(),
      ],
    );
  }

  List<Widget> _buildFallingCoins() {
    final coins = <Widget>[];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    for (var i = 0; i < 12; i++) {
      final leftPosition = (i * screenWidth / 12) + (i % 3) * 20;
      final delay = i * 150;

      coins.add(
        Positioned(
          left: leftPosition,
          top: -50,
          child: const Text(
            '🪙',
            style: TextStyle(fontSize: 32),
          )
              .animate()
              .moveY(
                begin: 0,
                end: screenHeight + 100,
                duration: const Duration(milliseconds: 2000),
                delay: Duration(milliseconds: delay),
                curve: Curves.easeIn,
              )
              .fadeIn(duration: const Duration(milliseconds: 200))
              .fadeOut(
                duration: const Duration(milliseconds: 300),
                delay: const Duration(milliseconds: 1700),
              ),
        ),
      );
    }

    return coins;
  }

  Widget _buildInvestmentAnimation() {
    return Stack(
      children: [
        // Message
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              '📈 Investment multiplied!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          )
              .animate()
              .scale(
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: const Duration(milliseconds: 200)),
        ),
        // Confetti burst
        ..._buildConfetti(),
      ],
    );
  }

  List<Widget> _buildConfetti() {
    final confetti = <Widget>[];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final centerX = screenWidth / 2;
    final centerY = screenHeight / 2;

    const confettiColors = ['🎊', '🎉', '⭐', '✨', '💫'];

    for (var i = 0; i < 20; i++) {
      final distance = 200.0 + (i % 5) * 30.0;
      final endX = centerX + (distance * (i % 2 == 0 ? 1 : -1));
      final endY = centerY + (distance * ((i % 4) < 2 ? 1 : -1));

      confetti.add(
        Positioned(
          left: centerX,
          top: centerY,
          child: Text(
            confettiColors[i % confettiColors.length],
            style: const TextStyle(fontSize: 28),
          )
              .animate()
              .moveX(
                begin: 0,
                end: endX - centerX,
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOut,
              )
              .moveY(
                begin: 0,
                end: endY - centerY,
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOut,
              )
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.2, 1.2),
                duration: const Duration(milliseconds: 800),
              )
              .then()
              .fadeOut(duration: const Duration(milliseconds: 700)),
        ),
      );
    }

    return confetti;
  }

  Widget _buildCharityAnimation() {
    return Stack(
      children: [
        // Message
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              '❤️ Donated!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          )
              .animate()
              .scale(
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: const Duration(milliseconds: 200)),
        ),
        // Floating hearts
        ..._buildFloatingHearts(),
      ],
    );
  }

  List<Widget> _buildFloatingHearts() {
    final hearts = <Widget>[];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const heartEmojis = ['❤️', '💖', '💗', '💝', '💕'];

    for (var i = 0; i < 15; i++) {
      final leftPosition = (i * screenWidth / 15) + (i % 4) * 25;
      final delay = i * 200;

      hearts.add(
        Positioned(
          left: leftPosition,
          bottom: -50,
          child: Text(
            heartEmojis[i % heartEmojis.length],
            style: const TextStyle(fontSize: 36),
          )
              .animate()
              .moveY(
                begin: 0,
                end: -(screenHeight + 100),
                duration: const Duration(milliseconds: 4000),
                delay: Duration(milliseconds: delay),
                curve: Curves.easeOut,
              )
              .fadeIn(duration: const Duration(milliseconds: 300))
              .fadeOut(
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 3500),
              )
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.3, 1.3),
                duration: const Duration(milliseconds: 2000),
              ),
        ),
      );
    }

    return hearts;
  }
}
