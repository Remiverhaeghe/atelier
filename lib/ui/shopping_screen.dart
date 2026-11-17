import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/inventory.dart';
import '../logic/shopping.dart';
import '../state/worksites_controller.dart';
import 'budget_schedule_card.dart';
import 'delivery_card.dart';
import 'expenses_section.dart';
import 'extra_items_card.dart';
import 'guide_view.dart';
import 'photos.dart';
import 'shopping_line_card.dart';
import 'shopping_texts.dart';
import 'store_compare_screen.dart';
import 'worksite_pdf.dart';
import 'theme.dart';

/// Liste de courses du chantier, prix et total, envoi et impression.
class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({
    super.key,
    required this.controller,
    required this.worksiteId,
    this.photos,
    this.now,
  });

  final WorksitesController controller;
  final String worksiteId;

  /// Photo des tickets ; remplaçable dans les tests.
  final PhotoTaker? photos;

  /// Mois de départ de l'échéancier ; aujourd'hui si absent, fixé dans les tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (pContext, _) {
        final vWorksite = controller.worksite(worksiteId);
        if (vWorksite == null) {
          return const Scaffold();
        }
        final vLines = shoppingList(vWorksite);
        final vPurchases = worksitePurchases(vWorksite);
        final vTools = worksiteMissingTools(vWorksite);

        return Scaffold(
          appBar: AppBar(
            title: Text(vText.shoppingTitle),
            actions: [
              IconButton(
                tooltip: vText.storeCompareTitle,
                icon: const Icon(Icons.compare_arrows),
                onPressed: () => Navigator.push(
                  pContext,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        StoreCompareScreen(controller: controller, worksiteId: worksiteId),
                  ),
                ),
              ),
              IconButton(
                tooltip: vText.shortListShare,
                icon: const Icon(Icons.sms_outlined),
                onPressed: vLines.isEmpty
                    ? null
                    : () => SharePlus.instance.share(
                        ShareParams(text: shortShoppingText(vText, vWorksite)),
                      ),
              ),
              IconButton(
                tooltip: vText.shareList,
                icon: const Icon(Icons.share),
                onPressed: vLines.isEmpty && vPurchases.isEmpty
                    ? null
                    : () => SharePlus.instance.share(
                        ShareParams(text: shoppingText(vText, vWorksite)),
                      ),
              ),
              IconButton(
                tooltip: vText.printSheet,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: () => Printing.layoutPdf(
                  name: vWorksite.name,
                  onLayout: (_) => buildWorksitePdf(vText, vWorksite),
                ),
              ),
            ],
          ),
          body: vLines.isEmpty && vPurchases.isEmpty && vWorksite.extras.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(vText.shoppingEmpty, textAlign: TextAlign.center),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BigFigure(vText.budgetTotal(formatEuros(budgetTotal(vLines)))),
                          if (budgetIncomplete(vLines)) Text(vText.budgetIncomplete),
                        ],
                      ),
                    ),
                    if (vWorksite.extras.isNotEmpty)
                      ExtraItemsCard(worksite: vWorksite, onChanged: controller.updateWorksite),
                    ExpensesSection(
                      worksite: vWorksite,
                      planned: budgetTotal(vLines),
                      onChanged: controller.updateWorksite,
                      photos: photos,
                    ),
                    BudgetScheduleCard(
                      worksite: vWorksite,
                      planned: budgetTotal(vLines),
                      onChanged: controller.updateWorksite,
                      now: now,
                    ),
                    DeliveryCard(
                      worksite: vWorksite,
                      lines: vLines,
                      onChanged: controller.updateWorksite,
                    ),
                    if (leftoverStock(vWorksite) case final vLeft when vLeft.isNotEmpty)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.inventory_outlined),
                          title: Text(vText.leftoverTitle),
                          subtitle: Text(
                            [
                              for (final vEntry in vLeft.entries)
                                vText.leftoverLine(itemLabel(vText, vEntry.key), vEntry.value),
                              vText.leftoverHint,
                            ].join('\n'),
                          ),
                        ),
                      ),
                    for (final vGroup in groupByStore(vLines, vWorksite.stores)) ...[
                      if (vGroup.store.isNotEmpty || vWorksite.stores.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.storefront_outlined),
                          title: Text(
                            vGroup.store.isEmpty ? vText.noStore : vGroup.store,
                            style: Theme.of(pContext).textTheme.titleMedium,
                          ),
                        ),
                      for (final vLine in vGroup.lines)
                        ShoppingLineCard(
                          line: vLine,
                          worksite: vWorksite,
                          onChanged: controller.updateWorksite,
                        ),
                    ],
                    if (vTools.isNotEmpty)
                      ListTile(
                        title: Text(
                          vText.toolsToGet,
                          style: Theme.of(pContext).textTheme.titleMedium,
                        ),
                      ),
                    for (final vTool in vTools)
                      ListTile(
                        leading: Icon(toolIcon(vTool)),
                        title: Text(toolLabel(vText, vTool)),
                      ),
                    if (vPurchases.isNotEmpty)
                      ListTile(
                        title: Text(
                          vText.touchUpsToBuyTitle,
                          style: Theme.of(pContext).textTheme.titleMedium,
                        ),
                      ),
                    for (final vPurchase in vPurchases)
                      ListTile(
                        leading: const Icon(Icons.shopping_cart_outlined),
                        title: Text(vPurchase.item),
                        subtitle: Text(vPurchase.room),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
