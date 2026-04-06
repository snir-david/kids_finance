import 'package:flutter/material.dart';

class PinInputWidget extends StatefulWidget {
  const PinInputWidget({
    super.key,
    required this.onPinComplete,
    this.onPinChanged,
    this.errorMessage,
    this.isLocked = false,
    this.lockMessage,
  });

  final void Function(String pin) onPinComplete;
  final void Function(String pin)? onPinChanged;
  final String? errorMessage;
  final bool isLocked;
  final String? lockMessage;

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  String _pin = '';

  void _onNumberPressed(int number) {
    if (widget.isLocked) return;
    if (_pin.length < 4) {
      setState(() {
        _pin += number.toString();
      });
      widget.onPinChanged?.call(_pin);
      
      if (_pin.length == 4) {
        widget.onPinComplete(_pin);
      }
    }
  }

  void _onBackspacePressed() {
    if (widget.isLocked) return;
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
      widget.onPinChanged?.call(_pin);
    }
  }

  void _onClearPressed() {
    if (widget.isLocked) return;
    setState(() {
      _pin = '';
    });
    widget.onPinChanged?.call(_pin);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PIN dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (index) => Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < _pin.length
                    ? Theme.of(context).colorScheme.primary
                    : null,
                border: Border.all(
                  color: index < _pin.length
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Error message
        if (widget.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              widget.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        
        const SizedBox(height: 24),
        
        // Numpad or lock message
        if (widget.isLocked && widget.lockMessage != null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              widget.lockMessage!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          _buildNumpad(),
      ],
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        // Rows 1-3 (numbers 1-9)
        for (int row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int col = 1; col <= 3; col++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildNumberButton(row * 3 + col),
                  ),
              ],
            ),
          ),
        
        // Bottom row: Clear, 0, Backspace
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildClearButton(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildNumberButton(0),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildBackspaceButton(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberButton(int number) {
    return Material(
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => _onNumberPressed(number),
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Text(
            number.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return Material(
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _onClearPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: const Text(
            'C',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Material(
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _onBackspacePressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: const Icon(
            Icons.backspace_outlined,
            size: 24,
          ),
        ),
      ),
    );
  }
}
