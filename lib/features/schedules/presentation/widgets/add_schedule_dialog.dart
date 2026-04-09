import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/models/schedule_model.dart';
import '../../data/repositories/schedule_repository_provider.dart';

class AddScheduleDialog extends ConsumerStatefulWidget {
  const AddScheduleDialog({
    super.key,
    required this.familyId,
    required this.childId,
  });

  final String familyId;
  final String childId;

  @override
  ConsumerState<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends ConsumerState<AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  ScheduleFrequency _frequency = ScheduleFrequency.weekly;
  int _dayOfWeek = 1; // Monday default
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<int>> _dayItems(AppLocalizations l10n) {
    if (_frequency == ScheduleFrequency.monthly) {
      return List.generate(
        28,
        (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
      );
    }
    final days = [
      (1, l10n.monday),
      (2, l10n.tuesday),
      (3, l10n.wednesday),
      (4, l10n.thursday),
      (5, l10n.friday),
      (6, l10n.saturday),
      (7, l10n.sunday),
    ];
    return days
        .map((d) => DropdownMenuItem(value: d.$1, child: Text(d.$2)))
        .toList();
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final amount = double.parse(_amountController.text.trim());
      await ref.read(scheduleRepositoryProvider).addSchedule(
            familyId: widget.familyId,
            childId: widget.childId,
            amount: amount,
            frequency: _frequency,
            dayOfWeek: _dayOfWeek,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.addSchedule),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.scheduleAmount,
                prefixText: '  ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.required;
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return l10n.mustBePositive;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Frequency
            Text(l10n.frequency,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            DropdownButton<ScheduleFrequency>(
              isExpanded: true,
              value: _frequency,
              items: [
                DropdownMenuItem(
                    value: ScheduleFrequency.weekly,
                    child: Text(l10n.weekly)),
                DropdownMenuItem(
                    value: ScheduleFrequency.biweekly,
                    child: Text(l10n.biweekly)),
                DropdownMenuItem(
                    value: ScheduleFrequency.monthly,
                    child: Text(l10n.monthly)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _frequency = v;
                  _dayOfWeek = 1;
                });
              },
            ),
            const SizedBox(height: 16),

            // Day picker
            Text(
              _frequency == ScheduleFrequency.monthly
                  ? l10n.dayOfMonth
                  : l10n.dayOfWeek,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            DropdownButton<int>(
              isExpanded: true,
              value: _dayOfWeek,
              items: _dayItems(l10n),
              onChanged: (v) {
                if (v != null) setState(() => _dayOfWeek = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : () => _save(l10n),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
