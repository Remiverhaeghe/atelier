import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/expenses.dart';
import '../logic/goals.dart';
import '../logic/receipt.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';
import 'photos.dart';
import 'shopping_texts.dart';
import 'theme.dart';

/// Dépenses réelles sous le budget prévu : total payé, reste, liste des achats et tickets.
class ExpensesSection extends StatelessWidget {
  const ExpensesSection({
    super.key,
    required this.worksite,
    required this.planned,
    required this.onChanged,
    this.photos,
  });

  final Worksite worksite;

  /// Budget prévu par la liste de courses.
  final double planned;
  final ValueChanged<Worksite> onChanged;
  final PhotoTaker? photos;

  Future<void> _add(BuildContext pContext) async {
    final vExpense = await showDialog<Expense>(
      context: pContext,
      builder: (_) => _ExpenseDialog(photos: photos ?? takePhoto),
    );
    if (vExpense != null) {
      onChanged(worksite.copyWith(expenses: [...worksite.expenses, vExpense]));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vLeft = budgetLeft(planned, worksite.expenses);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.expensesTitle, style: vTheme.textTheme.titleMedium),
            IconLine(
              Icons.payments_outlined,
              vText.expensesSpent(formatEuros(spentTotal(worksite.expenses))),
            ),
            IconLine(
              vLeft < 0 ? Icons.warning_amber : Icons.savings_outlined,
              vLeft < 0
                  ? vText.expensesOver(formatEuros(-vLeft))
                  : vText.expensesLeft(formatEuros(vLeft)),
              color: vLeft < 0 ? vTheme.colorScheme.error : null,
            ),
            for (final vExpense in byDate(worksite.expenses))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: vExpense.receiptPath == null
                    ? const Icon(Icons.receipt_long_outlined)
                    : GestureDetector(
                        onTap: () => showPhoto(context, vExpense.receiptPath!),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(vExpense.receiptPath!),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.receipt_long_outlined),
                          ),
                        ),
                      ),
                title: Text(vExpense.label),
                subtitle: Text(vExpense.date),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(vText.euros(formatEuros(vExpense.amount))),
                    IconButton(
                      tooltip: vText.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onChanged(
                        worksite.copyWith(
                          expenses: [
                            for (final vOther in worksite.expenses)
                              if (vOther.id != vExpense.id) vOther,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add),
              label: Text(vText.expenseAdd),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseDialog extends StatefulWidget {
  const _ExpenseDialog({required this.photos});

  final PhotoTaker photos;

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  final _label = TextEditingController();
  final _amount = TextEditingController();
  final _id = DateTime.now().microsecondsSinceEpoch.toString();
  String? _receipt;
  String? _error;
  String? _date;

  /// Texte du ticket copié depuis la photo : on remplit ce qu'on a su lire.
  Future<void> _paste() async {
    final vText = AppLocalizations.of(context);
    final vData = await Clipboard.getData(Clipboard.kTextPlain);
    final vReading = readReceipt(vData?.text ?? '');
    if (!mounted) {
      return;
    }
    setState(() {
      if (vReading.store != null && _label.text.trim().isEmpty) {
        _label.text = vReading.store!;
      }
      if (vReading.total != null) {
        _amount.text = formatEuros(vReading.total!);
      }
      _date = vReading.date;
      _error = vReading.total == null ? vText.receiptUnread : null;
    });
  }

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final vText = AppLocalizations.of(context);
    final vAmount = parseDecimal(_amount.text);
    if (_label.text.trim().isEmpty || vAmount == null) {
      setState(() => _error = vText.expenseInvalid);
      return;
    }
    Navigator.pop(
      context,
      Expense(
        id: _id,
        label: _label.text.trim(),
        amount: vAmount,
        date: _date ?? goalDate(DateTime.now()),
        receiptPath: _receipt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(vText.expenseAdd),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _label,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: vText.expenseLabel),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: vText.expenseAmount, errorText: _error),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _paste,
              icon: const Icon(Icons.content_paste),
              label: Text(vText.receiptPaste),
            ),
            if (_date != null) Text(vText.receiptDate(_date!)),
            Text(vText.receiptHelp, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final vPath = await widget.photos(_id);
                if (vPath != null) {
                  setState(() => _receipt = vPath);
                }
              },
              icon: Icon(_receipt == null ? Icons.photo_camera_outlined : Icons.check),
              label: Text(_receipt == null ? vText.expenseReceipt : vText.expenseReceiptTaken),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(onPressed: _submit, child: Text(vText.save)),
      ],
    );
  }
}
