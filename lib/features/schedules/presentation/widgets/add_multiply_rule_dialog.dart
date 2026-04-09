import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/models/multiply_rule_model.dart';
import '../../data/repositories/multiply_rule_repository_provider.dart';

class AddMultiplyRuleDialog extends ConsumerStatefulWidget {
  const AddMultiplyRuleDialog({
    super.key,
    required this.familyId,
    required this.childId,
  });

  final String familyId;
  final String childId;

  @override
  ConsumerState<AddMultiplyRuleDialog> createState() =>
      _AddMultiplyRuleDialogState();
}

class _AddMultiplyRuleDialogState extends ConsumerState<AddMultiplyRuleDialog> {
  final _percentController = TextEditingController(text: '5');
  ScheduleFrequency _frequency = ScheduleFrequency.monthly;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _percentController.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    final pct = double.tryParse(_percentController.text.trim());
    if (pct == null || pct <= 0 || pct > 100) {
      setState(() => _error = l10n.mustBePositive);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(multiplyRuleRepositoryProvider).addRule(
            familyId: widget.familyId,
            childId: widget.childId,
            multiplierPercent: pct,
            frequency: _frequency,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pct = double.tryParse(_percentController.text.trim()) ?? 5.0;
    final freqLabel = l10n.frequencyLabel(_frequency.name);

    return AlertDialog(
      title: Text(l10n.addMultiplyRule),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _percentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '${l10n.multiplierPercent} (%)',
                border: const OutlineInputBorder(),
                suffixText: '%',
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            Text(l10n.frequency,
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            DropdownButton<ScheduleFrequency>(
              value: _frequency,
              isExpanded: true,
              items: ScheduleFrequency.values
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(l10n.frequencyLabel(f.name)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _frequency = v);
              },
            ),
            const SizedBox(height: 16),
            // Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withAlpha(60)),
              ),
              child: Text(
                '📈 ${l10n.growsBy(pct.toStringAsFixed(1), freqLabel)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : () => _save(l10n),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.add),
        ),
      ],
    );
  }
}
