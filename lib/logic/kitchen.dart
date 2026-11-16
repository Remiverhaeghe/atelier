/// Cuisine : meubles bas sur un linéaire, plan de travail et hauteurs de pose.
library;

/// Largeurs courantes des meubles bas, en millimètres.
const kitchenModulesMm = [1200, 900, 800, 600, 500, 450, 400, 300];

/// Longueurs courantes des plans de travail vendus en magasin.
const worktopLengthsMm = [2460, 3000, 3650, 4100];

/// Meubles d'un linéaire : le moins de meubles possible, la place restante en fileur.
typedef ModuleRun = ({List<int> modules, int fillerMm});

ModuleRun fillRun(int pRunMm) {
  const vStep = 50;
  final vSlots = pRunMm < 0 ? 0 : pRunMm ~/ vStep;
  // Nombre de meubles pour remplir exactement chaque longueur, et le dernier meuble posé
  final vCount = List<int?>.filled(vSlots + 1, null)..[0] = 0;
  final vLast = List<int>.filled(vSlots + 1, 0);
  for (var vSlot = 1; vSlot <= vSlots; vSlot++) {
    for (final vModule in kitchenModulesMm) {
      final vBefore = vSlot - vModule ~/ vStep;
      if (vBefore >= 0 && vCount[vBefore] != null) {
        final vTotal = vCount[vBefore]! + 1;
        if (vCount[vSlot] == null || vTotal < vCount[vSlot]!) {
          vCount[vSlot] = vTotal;
          vLast[vSlot] = vModule;
        }
      }
    }
  }
  var vFilled = vSlots;
  while (vCount[vFilled] == null) {
    vFilled--;
  }
  final vModules = <int>[];
  for (var vSlot = vFilled; vSlot > 0; vSlot -= vLast[vSlot] ~/ vStep) {
    vModules.add(vLast[vSlot]);
  }
  vModules.sort((pA, pB) => pB.compareTo(pA));
  final rRun = (modules: vModules, fillerMm: pRunMm - vFilled * vStep);

  return rRun;
}

/// Plans de travail à acheter pour chaque linéaire : la plus courte longueur qui suffit, ou
/// plusieurs plans de la plus grande, joints sur un meuble.
List<int> worktopsFor(List<int> pRunsMm) {
  final rWorktops = <int>[];
  for (final vRun in pRunsMm.where((pRun) => pRun > 0)) {
    var vLeft = vRun;
    while (vLeft > worktopLengthsMm.last) {
      rWorktops.add(worktopLengthsMm.last);
      vLeft -= worktopLengthsMm.last;
    }
    rWorktops.add(worktopLengthsMm.firstWhere((pLength) => pLength >= vLeft));
  }

  return rWorktops;
}

/// Hauteurs conseillées : plan de travail à la moitié de la taille plus 5 cm, meubles hauts
/// 55 cm au-dessus, hotte à 65 cm d'une plaque électrique ou 75 cm d'une plaque gaz.
typedef KitchenHeights = ({int worktopMm, int wallUnitsMm, int hoodMm});

KitchenHeights kitchenHeights(int pPersonMm, {bool pGas = false}) {
  final vWorktop = ((pPersonMm / 2 + 50) / 10).round() * 10;
  final rHeights = (
    worktopMm: vWorktop,
    wallUnitsMm: vWorktop + 550,
    hoodMm: vWorktop + (pGas ? 750 : 650),
  );

  return rHeights;
}
