import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/inventory.dart';
import '../logic/shopping.dart';
import '../logic/units.dart';
import '../state/worksites_controller.dart';
import 'guide_view.dart';
import 'parquet_view.dart';
import 'shopping_texts.dart';
import 'worksite_pdf.dart';
import 'theme.dart';

/// Liste de courses du chantier, prix et total, envoi et impression.
class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key, required this.controller, required this.worksiteId});

  final WorksitesController controller;
  final String worksiteId;

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
          body: vLines.isEmpty && vPurchases.isEmpty
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
                    for (final vLine in vLines)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemLabel(vText, vLine.item),
                                style: Theme.of(pContext).textTheme.titleMedium,
                              ),
                              Text(lineDetail(vText, vLine)),
                              if (vLine.inStock > 0) Text(vText.lineInStock(vLine.inStock)),
                              NumberField<int>(
                                key: ValueKey('stock-${vLine.item.name}'),
                                label: vText.stockField,
                                initial: '${vWorksite.stock[vLine.item.name] ?? 0}',
                                parse: parseWhole,
                                onValue: (pStock) => controller.updateWorksite(
                                  vWorksite.copyWith(
                                    stock: {...vWorksite.stock, vLine.item.name: pStock},
                                  ),
                                ),
                              ),
                              NumberField<double>(
                                key: ValueKey(vLine.item),
                                label: vText.unitPrice,
                                initial: priceField(vLine.unitPrice),
                                parse: parseDecimal,
                                onValue: (pPrice) => controller.updateWorksite(
                                  vWorksite.copyWith(
                                    prices: {...vWorksite.prices, vLine.item.name: pPrice},
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
