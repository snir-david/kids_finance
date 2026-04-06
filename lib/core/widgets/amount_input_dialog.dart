import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class AmountInputDialog extends StatefulWidget {
  const AmountInputDialog({
    super.key,
    required this.title,
    required this.onConfirm,
    this.hint = '0.00',
    this.prefixText = '\$',
    this.isMultiplier = false,
    this.minValue = 0.01,
    this.currentValue,
  });

  final String title;
  final void Function(double value) onConfirm;
  final String hint;
  final String prefixText;
  final bool isMultiplier;
  final double minValue;
  final double? currentValue;

  static Future<double?> show(
    BuildContext context, {
    required String title,
    bool isMultiplier = false,
    double? currentValue,
  }) async {
    double? result;
    
    await showDialog<void>(
      context: context,
      builder: (context) => AmountInputDialog(
        title: title,
        isMultiplier: isMultiplier,
        currentValue: currentValue,
        onConfirm: (value) {
          result = value;
          Navigator.of(context).pop();
        },
      ),
    );
    
    return result;
  }

  @override
  State<AmountInputDialog> createState() => _AmountInputDialogState();
}

class _AmountInputDialogState extends State<AmountInputDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentValue?.toString() ?? '',
    );
    _controller.addListener(_validateInput);
    if (widget.currentValue != null) {
      _validateInput();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateInput() {
    final text = _controller.text.trim();
    
    if (text.isEmpty) {
      setState(() {
        _errorText = null;
        _isValid = false;
      });
      return;
    }

    final value = double.tryParse(text);
    
    if (value == null) {
      setState(() {
        _errorText = 'Please enter a valid number';
        _isValid = false;
      });
      return;
    }

    if (widget.isMultiplier) {
      if (value <= 0) {
        setState(() {
          _errorText = 'Multiplier must be greater than 0';
          _isValid = false;
        });
        return;
      }
      
      if (value < AppConstants.investmentMinMultiplier) {
        setState(() {
          _errorText =
              'Multiplier must be at least ${AppConstants.investmentMinMultiplier}';
          _isValid = false;
        });
        return;
      }
    } else {
      if (value < widget.minValue) {
        setState(() {
          _errorText = 'Amount must be at least ${widget.minValue}';
          _isValid = false;
        });
        return;
      }
    }

    setState(() {
      _errorText = null;
      _isValid = true;
    });
  }

  void _handleConfirm() {
    if (!_isValid) return;
    
    final value = double.parse(_controller.text.trim());
    widget.onConfirm(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixText: widget.isMultiplier ? '× ' : widget.prefixText,
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _handleConfirm(),
          ),
          if (widget.isMultiplier) ...[
            const SizedBox(height: 8),
            Text(
              'Example: 2.5 will multiply the investment by 2.5×',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValid ? _handleConfirm : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
