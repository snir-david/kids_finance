import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/bucket.dart';
import '../../domain/bucket_repository.dart';
import '../../../buckets/presentation/widgets/celebration_overlay.dart';

// ─── Shared sheet drag-handle widget ─────────────────────────────────────────

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ─── Charity Bottom Sheet ─────────────────────────────────────────────────────

class CharityActionSheet extends StatefulWidget {
  const CharityActionSheet({
    super.key,
    required this.familyId,
    required this.childId,
    required this.charityBalance,
    required this.repo,
    this.onComplete,
  });

  final String familyId;
  final String childId;
  final double charityBalance;
  final BucketRepository repo;
  final VoidCallback? onComplete;

  @override
  State<CharityActionSheet> createState() => _CharityActionSheetState();
}

class _CharityActionSheetState extends State<CharityActionSheet> {
  bool _isLoading = false;

  Future<void> _onDonate() async {
    if (widget.charityBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).noFundsToDonate),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.repo.donateBucket(widget.familyId, widget.childId);
      if (!mounted) return;

      final overlayState = Overlay.of(context);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => CelebrationOverlay(
          type: CelebrationType.charity,
          onComplete: () => entry.remove(),
        ),
      );
      overlayState.insert(entry);
      widget.onComplete?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: 20),
          Text(
            '❤️ ${AppLocalizations.of(context).charity}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${widget.charityBalance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppTheme.charityColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap below to donate your full balance to charity 🌍',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.charityColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : _onDonate,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context).donateAll,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Investment Bottom Sheet ──────────────────────────────────────────────────

class InvestmentActionSheet extends StatefulWidget {
  const InvestmentActionSheet({
    super.key,
    required this.familyId,
    required this.childId,
    required this.investmentBalance,
    required this.repo,
    this.onComplete,
  });

  final String familyId;
  final String childId;
  final double investmentBalance;
  final BucketRepository repo;
  final VoidCallback? onComplete;

  @override
  State<InvestmentActionSheet> createState() => _InvestmentActionSheetState();
}

class _InvestmentActionSheetState extends State<InvestmentActionSheet> {
  late final TextEditingController _drawController;
  final TextEditingController _multiplierController = TextEditingController();
  bool _isDrawLoading = false;
  bool _isMultiplyLoading = false;
  String? _multiplierError;

  @override
  void initState() {
    super.initState();
    _drawController = TextEditingController(
      text: widget.investmentBalance.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _drawController.dispose();
    _multiplierController.dispose();
    super.dispose();
  }

  Future<void> _onDraw() async {
    final amount = double.tryParse(_drawController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (amount > widget.investmentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount exceeds your savings balance!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isDrawLoading = true);
    try {
      await widget.repo.transferBetweenBuckets(
        widget.familyId,
        widget.childId,
        BucketType.investment,
        BucketType.money,
        amount,
      );
      if (!mounted) return;
      widget.onComplete?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isDrawLoading = false);
    }
  }

  Future<void> _onMultiply() async {
    final multiplier = double.tryParse(_multiplierController.text.trim());
    if (multiplier == null || multiplier <= 0) {
      setState(() => _multiplierError = 'Multiplier must be greater than 0');
      return;
    }
    setState(() {
      _multiplierError = null;
      _isMultiplyLoading = true;
    });
    try {
      await widget.repo.multiplyBucket(
        widget.familyId,
        widget.childId,
        BucketType.investment,
        multiplier,
      );
      if (!mounted) return;
      widget.onComplete?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isMultiplyLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SheetHandle()),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '📈 ${AppLocalizations.of(context).savings}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '\$${widget.investmentBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.investmentsColor,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Draw to My Money ──────────────────────────────
            const Divider(),
            Text(
              AppLocalizations.of(context).drawToMyMoney,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _drawController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).amount,
                prefixText: '\$',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.investmentsColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isDrawLoading ? null : _onDraw,
                child: _isDrawLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Draw 💸', style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 20),

            // ── Multiply by Parent ────────────────────────────
            const Divider(),
            Text(
              AppLocalizations.of(context).multiplyByParent,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _multiplierController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '${AppLocalizations.of(context).multiplier} (e.g. 1.5)',
                errorText: _multiplierError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isMultiplyLoading ? null : _onMultiply,
                child: _isMultiplyLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('${AppLocalizations.of(context).multiply} 🚀', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Money Bottom Sheet ───────────────────────────────────────────────────────

class MoneyActionSheet extends StatefulWidget {
  const MoneyActionSheet({
    super.key,
    required this.familyId,
    required this.childId,
    required this.moneyBalance,
    required this.repo,
    this.onComplete,
  });

  final String familyId;
  final String childId;
  final double moneyBalance;
  final BucketRepository repo;
  final VoidCallback? onComplete;

  @override
  State<MoneyActionSheet> createState() => _MoneyActionSheetState();
}

class _MoneyActionSheetState extends State<MoneyActionSheet> {
  final TextEditingController _investController = TextEditingController();
  final TextEditingController _charityController = TextEditingController();
  final TextEditingController _withdrawController = TextEditingController();
  bool _isInvestLoading = false;
  bool _isCharityLoading = false;
  bool _isWithdrawLoading = false;

  @override
  void dispose() {
    _investController.dispose();
    _charityController.dispose();
    _withdrawController.dispose();
    super.dispose();
  }

  Future<void> _onSendToInvestment() async {
    final amount = double.tryParse(_investController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isInvestLoading = true);
    try {
      await widget.repo.transferBetweenBuckets(
        widget.familyId,
        widget.childId,
        BucketType.money,
        BucketType.investment,
        amount,
      );
      if (!mounted) return;
      widget.onComplete?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isInvestLoading = false);
    }
  }

  Future<void> _onSendToCharity() async {
    final amount = double.tryParse(_charityController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isCharityLoading = true);
    try {
      await widget.repo.transferBetweenBuckets(
        widget.familyId,
        widget.childId,
        BucketType.money,
        BucketType.charity,
        amount,
      );
      if (!mounted) return;
      widget.onComplete?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isCharityLoading = false);
    }
  }

  Future<void> _onWithdraw() async {
    final amount = double.tryParse(_withdrawController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isWithdrawLoading = true);
    try {
      await widget.repo.withdrawFromBucket(
        widget.familyId,
        widget.childId,
        amount,
      );
      if (!mounted) return;
      widget.onComplete?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isWithdrawLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SheetHandle()),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '💰 ${AppLocalizations.of(context).myMoney}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '\$${widget.moneyBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.moneyColor,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Section A: Send to Savings ────────────────────
            const Divider(),
            Text(
              AppLocalizations.of(context).sendToSavings,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _investController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).amount,
                prefixText: '\$',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.investmentsColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isInvestLoading ? null : _onSendToInvestment,
                child: _isInvestLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context).sendToSavings,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Section B: Send to Charity ────────────────────
            const Divider(),
            Text(
              AppLocalizations.of(context).sendToCharity,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _charityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).amount,
                prefixText: '\$',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.charityColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isCharityLoading ? null : _onSendToCharity,
                child: _isCharityLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context).sendToCharity,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Section C: Withdraw ───────────────────────────
            const Divider(),
            Text(
              '${AppLocalizations.of(context).withdraw} 💳',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context).simulatePurchase,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _withdrawController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).amount,
                prefixText: '\$',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isWithdrawLoading ? null : _onWithdraw,
                child: _isWithdrawLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        '${AppLocalizations.of(context).withdraw} 💳',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
