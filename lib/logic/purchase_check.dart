/// Contrôle avant achat : ce que le stock couvre déjà, et les outils qu'il vaut mieux louer.
library;

import 'right_tool.dart';
import 'shopping.dart';
import 'worksite.dart';

/// Un outil à louer ou à acheter pour un travail du chantier, avec l'économie du bon choix.
typedef ToolSaving = ({
  ToolTask task,
  ToolChoice choice,
  int days,
  int chosenEuros,
  int otherEuros,
  int savingEuros,
});

typedef PurchaseCheck = ({
  int stockLines,
  int stockUnits,
  double stockValueEuros,
  List<ToolSaving> tools,
  int toolSavingEuros,
});

/// Packs de parquet posés en une journée avec une scie.
const packsPerDay = 8;

/// Barres de plinthe coupées à l'onglet en une journée.
const barsPerDay = 25;

int _days(int pQuantity, int pPerDay) => ((pQuantity - 1) ~/ pPerDay) + 1;

/// Contrôle d'un chantier : les articles pris dans le stock (avec leur valeur si les prix sont
/// saisis) et, pour les travaux prévus, les outils à louer plutôt qu'acheter, ou l'inverse
/// quand la durée rend l'achat plus sûr. Les durées sont des estimations.
PurchaseCheck purchaseCheck(Worksite pWorksite) {
  final vLines = shoppingList(pWorksite);
  final vStocked = vLines.where((pLine) => pLine.inStock > 0).toList();
  var vValue = 0.0;
  for (final vLine in vStocked) {
    vValue += (vLine.unitPrice ?? 0) * vLine.inStock;
  }
  int vTotal(ShoppingItem pItem) => vLines
      .where((pLine) => pLine.item == pItem)
      .fold(0, (pSum, pLine) => pSum + pLine.quantity + pLine.inStock);
  final vTasks = <ToolTask, int>{
    if (vTotal(ShoppingItem.parquetPacks) > 0)
      ToolTask.cutBoards: _days(vTotal(ShoppingItem.parquetPacks), packsPerDay),
    if (vTotal(ShoppingItem.baseboardBars) > 0)
      ToolTask.mitreCuts: _days(vTotal(ShoppingItem.baseboardBars), barsPerDay),
  };
  final vTools = <ToolSaving>[];
  vTasks.forEach((pTask, pDays) {
    final vAdvice = adviseTool(pTask, pDays);
    if (vAdvice.choice != ToolChoice.rent && vAdvice.choice != ToolChoice.buy) {
      return;
    }
    final vBuy = pTask.power.buyEuros;
    final vRent = vAdvice.rentEuros;
    vTools.add((
      task: pTask,
      choice: vAdvice.choice,
      days: pDays,
      chosenEuros: vAdvice.choice == ToolChoice.rent ? vRent : vBuy,
      otherEuros: vAdvice.choice == ToolChoice.rent ? vBuy : vRent,
      savingEuros: (vBuy - vRent).abs(),
    ));
  });

  return (
    stockLines: vStocked.length,
    stockUnits: vStocked.fold(0, (pSum, pLine) => pSum + pLine.inStock),
    stockValueEuros: vValue,
    tools: vTools,
    toolSavingEuros: vTools.fold(0, (pSum, pTool) => pSum + pTool.savingEuros),
  );
}
