import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/loans.dart';
import '../logic/offcuts.dart';
import '../logic/shopping.dart';
import '../logic/units.dart';
import '../logic/workshop_stock.dart';
import '../state/workshop_controller.dart';
import '../state/worksites_controller.dart';
import 'shopping_texts.dart';
import 'theme.dart';

String stockCategoryLabel(AppLocalizations pText, StockCategory pCategory) => switch (pCategory) {
  StockCategory.screws => pText.stockCatScrews,
  StockCategory.glue => pText.stockCatGlue,
  StockCategory.finish => pText.stockCatFinish,
  StockCategory.abrasive => pText.stockCatAbrasive,
  StockCategory.hardware => pText.stockCatHardware,
  StockCategory.timber => pText.stockCatTimber,
  StockCategory.other => pText.stockCatOther,
};

/// Stock de l'atelier : quantités restantes, alertes de rachat, part réservée aux chantiers,
/// outils prêtés et chutes gardées.
class WorkshopStockScreen extends StatelessWidget {
  const WorkshopStockScreen({
    super.key,
    required this.controller,
    required this.worksiteId,
    this.workshop,
    this.today,
  });

  final WorksitesController controller;

  /// Chantier ouvert : sa part du stock peut lui être réservée.
  final String worksiteId;

  /// Stock de l'appli si absent ; un stock à part dans les tests.
  final WorkshopController? workshop;
  final DateTime? today;

  WorkshopController get _workshop => workshop ?? aWorkshop;

  Future<void> _edit(BuildContext pContext, [StockItem? pItem]) async {
    final vResult = await showDialog<_EditResult>(
      context: pContext,
      builder: (_) => _StockItemDialog(item: pItem),
    );
    if (vResult == null) {
      return;
    }
    if (vResult.delete && pItem != null) {
      await _workshop.remove(pItem.id);
    } else if (vResult.item case final vItem?) {
      await _workshop.upsert(
        StockItem(
          id: pItem?.id ?? controller.newId(),
          name: vItem.name,
          category: vItem.category,
          quantity: vItem.quantity,
          minQuantity: vItem.minQuantity,
          link: vItem.link,
        ),
      );
    }
  }

  Future<void> _reserve(List<StockAllocation> pAllocations) async {
    final vWorksite = controller.worksite(worksiteId);
    if (vWorksite == null) {
      return;
    }
    final vResult = reserveFor(_workshop.items, vWorksite, pAllocations);
    await controller.updateWorksite(vResult.worksite);
    await _workshop.replaceAll(vResult.items);
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vToday = today ?? DateTime.now();

    return ListenableBuilder(
      listenable: Listenable.merge([controller, _workshop]),
      builder: (pContext, _) {
        final vItems = _workshop.items;
        final vWorksites = controller.worksites;
        final vAllocations = allocateStock(vItems, vWorksites);
        final vRestock = restockList(vItems, vAllocations);
        final vHere = [
          for (final vAllocation in vAllocations)
            if (vAllocation.worksiteId == worksiteId) vAllocation,
        ];
        final vLoans = allLoans(vWorksites);
        final vOffcuts = offcutTotals(vWorksites);
        String vName(String pId) => vItems.firstWhere((pItem) => pItem.id == pId).name;

        return Scaffold(
          appBar: AppBar(title: Text(vText.stockTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _edit(pContext),
            icon: const Icon(Icons.add),
            label: Text(vText.stockAdd),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (vItems.isEmpty) IconLine(Icons.inventory_2_outlined, vText.stockEmpty),
              if (vRestock.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: vTheme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vText.stockRestockTitle, style: vTheme.textTheme.titleSmall),
                        for (final vLine in vRestock)
                          IconLine(
                            AtelierIcons.warning,
                            vText.stockRestockLine(vLine.item.name, vLine.toBuy),
                          ),
                      ],
                    ),
                  ),
                ),
              if (vHere.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vText.stockForWorksite, style: vTheme.textTheme.titleSmall),
                        for (final vAllocation in vHere)
                          IconLine(
                            Icons.shopping_basket_outlined,
                            vText.stockAllocation(
                              vName(vAllocation.itemId),
                              vAllocation.fromStock,
                              vAllocation.toBuy,
                            ),
                          ),
                        if (vHere.any((pAllocation) => pAllocation.fromStock > 0))
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.tonalIcon(
                              onPressed: () => _reserve(vAllocations),
                              icon: const Icon(Icons.move_down),
                              label: Text(vText.stockReserve),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              for (final vCategory in StockCategory.values)
                if (vItems.any((pItem) => pItem.category == vCategory)) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      stockCategoryLabel(vText, vCategory),
                      style: vTheme.textTheme.titleMedium,
                    ),
                  ),
                  for (final vItem in vItems.where((pItem) => pItem.category == vCategory))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(vItem.name),
                      subtitle: Text(
                        vText.stockItemLine(
                          vItem.quantity,
                          vItem.minQuantity,
                          projectedQuantity(vItem, vAllocations),
                        ),
                        style: needsRestock(vItem)
                            ? TextStyle(color: vTheme.colorScheme.error)
                            : null,
                      ),
                      onTap: () => _edit(pContext, vItem),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: vText.stockUsed,
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: vItem.quantity <= 0
                                ? null
                                : () => _workshop.upsert(
                                    vItem.copyWith(quantity: vItem.quantity - 1),
                                  ),
                          ),
                          IconButton(
                            tooltip: vText.stockBought,
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () =>
                                _workshop.upsert(vItem.copyWith(quantity: vItem.quantity + 1)),
                          ),
                        ],
                      ),
                    ),
                ],
              const SizedBox(height: 12),
              Text(vText.stockLoansTitle, style: vTheme.textTheme.titleMedium),
              if (vLoans.isEmpty) Text(vText.stockNoLoan, style: vTheme.textTheme.bodySmall),
              for (final vLine in vLoans)
                IconLine(
                  loanOverdue(vLine.loan, vToday) ? AtelierIcons.warning : Icons.handshake_outlined,
                  vText.stockLoanLine(
                    vLine.loan.tool,
                    vLine.loan.person,
                    vLine.worksite,
                    loanDays(vLine.loan, vToday),
                  ),
                ),
              const SizedBox(height: 12),
              Text(vText.stockOffcutsTitle, style: vTheme.textTheme.titleMedium),
              if (vOffcuts.isEmpty) Text(vText.stockNoOffcut, style: vTheme.textTheme.bodySmall),
              for (final vEntry in vOffcuts.entries)
                IconLine(
                  Icons.recycling,
                  vText.stockOffcutLine(
                    vEntry.key == OffcutMaterial.plank
                        ? vText.stockOffcutPlank
                        : vText.stockOffcutBaseboard,
                    vEntry.value.count,
                    formatCentimetres(vEntry.value.lengthMm),
                  ),
                ),
              const SizedBox(height: 12),
              Text(vText.stockHint, style: vTheme.textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}

/// Article saisi, ou demande de suppression.
typedef _EditResult = ({StockItem? item, bool delete});

class _StockItemDialog extends StatefulWidget {
  const _StockItemDialog({this.item});

  final StockItem? item;

  @override
  State<_StockItemDialog> createState() => _StockItemDialogState();
}

class _StockItemDialogState extends State<_StockItemDialog> {
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _quantity = TextEditingController(text: '${widget.item?.quantity ?? 1}');
  late final _min = TextEditingController(text: '${widget.item?.minQuantity ?? 0}');
  late var _category = widget.item?.category ?? StockCategory.screws;
  late String? _link = widget.item?.link;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _min.dispose();
    super.dispose();
  }

  void _submit() {
    final vQuantity = parseWhole(_quantity.text);
    final vMin = parseWhole(_min.text);
    if (_name.text.trim().isEmpty || vQuantity == null || vMin == null) {
      setState(() => _error = AppLocalizations.of(context).invalidNumber);
      return;
    }
    Navigator.pop<_EditResult>(context, (
      item: StockItem(
        id: '',
        name: _name.text.trim(),
        category: _category,
        quantity: vQuantity,
        minQuantity: vMin,
        link: _link,
      ),
      delete: false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.item == null ? vText.stockAdd : vText.stockEdit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: widget.item == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: vText.stockName, errorText: _error),
            ),
            DropdownButtonFormField<StockCategory>(
              initialValue: _category,
              decoration: InputDecoration(labelText: vText.stockCategory),
              items: [
                for (final vCategory in StockCategory.values)
                  DropdownMenuItem(
                    value: vCategory,
                    child: Text(stockCategoryLabel(vText, vCategory)),
                  ),
              ],
              onChanged: (pValue) => setState(() => _category = pValue ?? _category),
            ),
            TextField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: vText.stockQuantity),
            ),
            TextField(
              controller: _min,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: vText.stockMin),
            ),
            DropdownButtonFormField<String?>(
              initialValue: _link,
              isExpanded: true,
              decoration: InputDecoration(labelText: vText.stockLink),
              items: [
                DropdownMenuItem(child: Text(vText.stockLinkNone)),
                for (final vItem in ShoppingItem.values)
                  DropdownMenuItem(
                    value: vItem.name,
                    child: Text(itemLabel(vText, vItem), overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (pValue) => setState(() => _link = pValue),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.item != null)
          TextButton(
            onPressed: () => Navigator.pop<_EditResult>(context, (item: null, delete: true)),
            child: Text(vText.delete),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(onPressed: _submit, child: Text(vText.save)),
      ],
    );
  }
}
