/// Le bon outil pour une tâche : à la main ou électrique, ce que ça coûte, et s'il vaut mieux
/// acheter, louer ou emprunter selon le nombre de jours d'utilisation.
library;

import 'rent_or_buy.dart';
import 'starter_tools.dart';

/// Outils électriques, avec un prix d'achat d'entrée de gamme et un prix de location par jour
/// indicatifs en euros, à vérifier en magasin.
enum PowerTool {
  circularSaw(90, 25),
  jigsaw(60, 20),
  hammerDrill(120, 30),
  drillDriver(100, 15),
  sander(70, 20),
  floorSander(800, 60),
  tileCutter(150, 35),
  mixer(80, 20),
  breaker(300, 50),
  mitreSaw(150, 35);

  const PowerTool(this.buyEuros, this.dayEuros);

  final int buyEuros;
  final int dayEuros;
}

/// Tâches courantes : l'outil à la main quand il existe, jusqu'à combien de jours il suffit,
/// et l'outil électrique qui le remplace.
enum ToolTask {
  cutBoards(StarterTool.handSaw, 2, PowerTool.circularSaw),
  cutCurves(null, 0, PowerTool.jigsaw),
  drillConcrete(null, 0, PowerTool.hammerDrill),
  screwMany(StarterTool.screwdrivers, 1, PowerTool.drillDriver),
  sandFurniture(null, 0, PowerTool.sander),
  sandFloor(null, 0, PowerTool.floorSander),
  cutTiles(null, 0, PowerTool.tileCutter),
  mixPlaster(null, 0, PowerTool.mixer),
  demolish(StarterTool.hammer, 1, PowerTool.breaker),
  mitreCuts(StarterTool.mitreBox, 2, PowerTool.mitreSaw);

  const ToolTask(this.manual, this.manualDays, this.power);

  /// Outil à la main de la caisse du débutant ; null quand il n'y en a pas de raisonnable.
  final StarterTool? manual;

  /// Jours de travail au-delà desquels l'outil à la main fatigue trop ou va trop lentement.
  final int manualDays;
  final PowerTool power;
}

enum ToolChoice { manual, borrow, rent, buy }

typedef ToolAdvice = ({ToolChoice choice, int budgetEuros, int rentEuros, int? breakEvenDays});

/// Au-delà de deux jours, on n'emprunte plus : on garde l'outil d'un proche trop longtemps.
const borrowMaxDays = 2;

/// Conseil pour [pTask] utilisée [pDays] jours : à la main si c'est raisonnable, sinon
/// emprunter quand c'est possible, sinon louer ou acheter selon le seuil de rentabilité.
ToolAdvice adviseTool(
  ToolTask pTask,
  int pDays, {
  bool pOwnsManual = false,
  bool pCanBorrow = false,
}) {
  final vDays = pDays < 1 ? 1 : pDays;
  final vPower = pTask.power;
  final vRent = vPower.dayEuros * vDays;
  final vCompare = rentOrBuy(
    RentOrBuy(
      purchasePrice: vPower.buyEuros.toDouble(),
      dayRate: vPower.dayEuros.toDouble(),
      days: vDays,
    ),
  );
  final vManual = pTask.manual;
  final ToolChoice vChoice;
  final int vBudget;
  if (vManual != null && vDays <= pTask.manualDays) {
    vChoice = ToolChoice.manual;
    vBudget = pOwnsManual ? 0 : ((vManual.minEuros + vManual.maxEuros) / 2).round();
  } else if (pCanBorrow && vDays <= borrowMaxDays) {
    vChoice = ToolChoice.borrow;
    vBudget = 0;
  } else if (vCompare.buy) {
    vChoice = ToolChoice.buy;
    vBudget = vPower.buyEuros;
  } else {
    vChoice = ToolChoice.rent;
    vBudget = vRent;
  }
  final rAdvice = (
    choice: vChoice,
    budgetEuros: vBudget,
    rentEuros: vRent,
    breakEvenDays: vCompare.breakEvenDays,
  );

  return rAdvice;
}
