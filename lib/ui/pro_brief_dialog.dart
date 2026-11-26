import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/trades.dart';
import 'trades_screen.dart' show tradeName;

/// Travaux qu'on confie : tous ceux qui ne sont pas de niveau facile, du plus délicat au moins.
List<Trade> tradesToHandOver() =>
    [
      for (final vTrade in Trade.values)
        if (vTrade.level != TradeLevel.easy) vTrade,
    ]..sort((pA, pB) => pB.level.index.compareTo(pA.level.index));

/// Choix du métier et des contraintes à écrire sur la fiche ; null si on annule.
Future<({Trade trade, String constraints})?> askProBrief(BuildContext pContext) =>
    showDialog<({Trade trade, String constraints})>(
      context: pContext,
      builder: (_) => const _ProBriefDialog(),
    );

class _ProBriefDialog extends StatefulWidget {
  const _ProBriefDialog();

  @override
  State<_ProBriefDialog> createState() => _ProBriefDialogState();
}

class _ProBriefDialogState extends State<_ProBriefDialog> {
  final _constraints = TextEditingController();
  late Trade _trade = tradesToHandOver().first;

  @override
  void dispose() {
    _constraints.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(vText.proBriefDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Trade>(
              initialValue: _trade,
              decoration: InputDecoration(labelText: vText.proBriefTradeLabel),
              items: [
                for (final vTrade in tradesToHandOver())
                  DropdownMenuItem(value: vTrade, child: Text(tradeName(vText, vTrade))),
              ],
              onChanged: (pTrade) => setState(() => _trade = pTrade ?? _trade),
            ),
            TextField(
              controller: _constraints,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(labelText: vText.proBriefConstraintsLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, (trade: _trade, constraints: _constraints.text.trim())),
          child: Text(vText.save),
        ),
      ],
    );
  }
}
