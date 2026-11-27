import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/purchase_check.dart';
import '../logic/right_tool.dart';
import '../logic/worksite.dart';
import 'right_tool_screen.dart';
import 'shopping_texts.dart';
import 'theme.dart';

/// Contrôle avant achat : ce que le stock couvre et les outils à louer plutôt qu'acheter.
class PurchaseCheckCard extends StatelessWidget {
  const PurchaseCheckCard({super.key, required this.worksite});

  final Worksite worksite;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vCheck = purchaseCheck(worksite);
    if (vCheck.stockLines == 0 && vCheck.tools.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.purchaseCheckTitle, style: Theme.of(context).textTheme.titleMedium),
            if (vCheck.stockLines > 0)
              IconLine(
                Icons.inventory_2_outlined,
                vCheck.stockValueEuros > 0
                    ? vText.purchaseCheckStockValue(
                        vCheck.stockLines,
                        vCheck.stockUnits,
                        formatEuros(vCheck.stockValueEuros),
                      )
                    : vText.purchaseCheckStock(vCheck.stockLines, vCheck.stockUnits),
              ),
            for (final vTool in vCheck.tools)
              IconLine(
                vTool.choice == ToolChoice.rent
                    ? Icons.handyman_outlined
                    : Icons.shopping_bag_outlined,
                (vTool.choice == ToolChoice.rent
                    ? vText.purchaseCheckRent
                    : vText.purchaseCheckBuy)(
                  toolTaskName(vText, vTool.task),
                  vTool.days,
                  vTool.chosenEuros,
                  vTool.otherEuros,
                  vTool.savingEuros,
                ),
              ),
            if (vCheck.toolSavingEuros > 0)
              Text(
                vText.purchaseCheckSaving(vCheck.toolSavingEuros),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            EstimateNote(vText.purchaseCheckEstimate),
          ],
        ),
      ),
    );
  }
}
