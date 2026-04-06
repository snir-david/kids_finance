import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../data/pin_service.dart';
import '../../children/providers/children_providers.dart';

class ChildPinScreen extends ConsumerStatefulWidget {
  const ChildPinScreen({super.key});

  @override
  ConsumerState<ChildPinScreen> createState() => _ChildPinScreenState();
}

class _ChildPinScreenState extends ConsumerState<ChildPinScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _enteredDigits = [];
  bool _isVerifying = false;
  DateTime? _lockedUntil;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitTapped(String digit) {
    if (_isVerifying || _lockedUntil != null) return;

    if (_enteredDigits.length < 4) {
      setState(() => _enteredDigits.add(digit));
      if (_enteredDigits.length == 4) {
        _submitPin();
      }
    }
  }

  void _onBackspace() {
    if (_isVerifying || _lockedUntil != null) return;

    if (_enteredDigits.isNotEmpty) {
      setState(() => _enteredDigits.removeLast());
    }
  }

  Future<void> _submitPin() async {
    final pin = _enteredDigits.join();
    setState(() => _isVerifying = true);

    try {
      final pinService = ref.read(pinServiceProvider);
      final activeChildId = ref.read(selectedChildProvider);
      final familyId = ref.read(currentFamilyIdProvider).value;

      if (activeChildId == null || familyId == null) {
        throw Exception('No child selected or family not found');
      }

      final result = await pinService.verifyChildPin(
        activeChildId,
        familyId,
        pin,
      );

      if (mounted) {
        switch (result) {
          case PinSuccess():
            // Set active child for session
            ref.read(activeChildProvider.notifier).state = activeChildId;
            context.go('/child-home');
            
          case PinWrongPin(:final attemptsRemaining):
            _showWrongPinError(attemptsRemaining);
            _shakeController.forward(from: 0);
            setState(() => _enteredDigits.clear());
            
          case PinLocked(:final unlocksAt):
            setState(() {
              _lockedUntil = unlocksAt;
              _enteredDigits.clear();
            });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _enteredDigits.clear());
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _showWrongPinError(int attemptsRemaining) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Wrong PIN. $attemptsRemaining tries remaining'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getChildDisplayName() {
    final selectedChildId = ref.watch(selectedChildProvider);
    final familyId = ref.watch(currentFamilyIdProvider).value;

    if (selectedChildId == null || familyId == null) {
      return 'Enter PIN';
    }

    final childAsync = ref.watch(
      childProvider((childId: selectedChildId, familyId: familyId)),
    );

    return childAsync.when(
      data: (child) => child != null
          ? '${child.avatarEmoji} ${child.displayName}'
          : 'Enter PIN',
      loading: () => 'Loading...',
      error: (_, __) => 'Enter PIN',
    );
  }

  Widget _buildPinDots() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final isFilled = index < _enteredDigits.length;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? Colors.green : Colors.transparent,
              border: Border.all(
                color: Colors.green,
                width: 2,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNumpad() {
    if (_lockedUntil != null) {
      final now = DateTime.now();
      if (now.isBefore(_lockedUntil!)) {
        final remaining = _lockedUntil!.difference(now);
        final minutes = remaining.inMinutes;
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Too many attempts.\nTry again in $minutes minute${minutes != 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        );
      } else {
        // Lockout expired
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _lockedUntil = null);
          }
        });
      }
    }

    return Column(
      children: [
        // Row 1: 1, 2, 3
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumpadButton('1'),
            _buildNumpadButton('2'),
            _buildNumpadButton('3'),
          ],
        ),
        const SizedBox(height: 16),
        // Row 2: 4, 5, 6
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumpadButton('4'),
            _buildNumpadButton('5'),
            _buildNumpadButton('6'),
          ],
        ),
        const SizedBox(height: 16),
        // Row 3: 7, 8, 9
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumpadButton('7'),
            _buildNumpadButton('8'),
            _buildNumpadButton('9'),
          ],
        ),
        const SizedBox(height: 16),
        // Row 4: blank, 0, backspace
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80, height: 80), // blank space
            _buildNumpadButton('0'),
            _buildBackspaceButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildNumpadButton(String digit) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Material(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          onTap: _isVerifying ? null : () => _onDigitTapped(digit),
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Material(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          onTap: _isVerifying ? null : _onBackspace,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            child: const Icon(
              Icons.backspace_outlined,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter PIN'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height -
                  MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(height: 32),
                  // Child name and emoji
                  Text(
                    _getChildDisplayName(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // PIN dots
                  _buildPinDots(),
                  const SizedBox(height: 48),
                  // Loading indicator or numpad
                  if (_isVerifying)
                    const CircularProgressIndicator()
                  else
                    _buildNumpad(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
