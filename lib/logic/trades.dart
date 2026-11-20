/// Par où commencer : pour chaque type de travaux, le niveau, l'outillage minimal, le temps
/// réaliste pour un débutant et ce qu'il coûte de s'équiper.
library;

import 'diy_or_pro.dart';
import 'starter_tools.dart';

/// Facile pour un premier chantier, faisable avec de la méthode, ou à confier à un pro.
enum TradeLevel { easy, medium, pro }

/// Outils propres à un type de travaux, absents de la caisse du débutant : à acheter, ou à
/// louer quand ils servent peu. Prix indicatifs en euros, à l'achat ou par jour de location.
enum TradeTool {
  roller(rent: false, minEuros: 10, maxEuros: 30),
  tapingKnife(rent: false, minEuros: 8, maxEuros: 20),
  notchedTrowel(rent: false, minEuros: 8, maxEuros: 20),
  tileCutter(rent: false, minEuros: 40, maxEuros: 120),
  mixer(rent: true, minEuros: 15, maxEuros: 30),
  boardLifter(rent: true, minEuros: 20, maxEuros: 40),
  pullBar(rent: false, minEuros: 10, maxEuros: 25),
  voltageTester(rent: false, minEuros: 15, maxEuros: 40),
  pipeCutter(rent: false, minEuros: 10, maxEuros: 30),
  jigsaw(rent: false, minEuros: 50, maxEuros: 120),
  insulationKnife(rent: false, minEuros: 10, maxEuros: 25),
  stapler(rent: false, minEuros: 15, maxEuros: 35);

  const TradeTool({required this.rent, required this.minEuros, required this.maxEuros});

  /// Vrai si on le loue plutôt qu'on ne l'achète : prix par jour.
  final bool rent;
  final int minEuros;
  final int maxEuros;
}

/// Types de travaux, du plus abordable au plus délicat.
///
/// [proHours] : temps d'un artisan pour le chantier de référence décrit dans les textes (une
/// pièce de 12 m² environ). Le débutant en met [beginnerFactor] fois plus, souvent davantage.
enum Trade {
  paint(
    level: TradeLevel.easy,
    proHours: 8,
    tools: [StarterTool.tape, StarterTool.cutter, StarterTool.screwdrivers],
    extra: [TradeTool.roller, TradeTool.tapingKnife],
  ),
  baseboards(
    level: TradeLevel.easy,
    proHours: 4,
    tools: [
      StarterTool.tape,
      StarterTool.pencil,
      StarterTool.mitreBox,
      StarterTool.handSaw,
      StarterTool.caulkGun,
      StarterTool.glasses,
    ],
    extra: [],
  ),
  parquet(
    level: TradeLevel.easy,
    proHours: 6,
    tools: [
      StarterTool.tape,
      StarterTool.pencil,
      StarterTool.square,
      StarterTool.handSaw,
      StarterTool.hammer,
      StarterTool.glasses,
    ],
    extra: [TradeTool.pullBar, TradeTool.jigsaw],
  ),
  insulation(
    level: TradeLevel.medium,
    proHours: 8,
    tools: [StarterTool.tape, StarterTool.cutter, StarterTool.dustMask, StarterTool.glasses],
    extra: [TradeTool.insulationKnife, TradeTool.stapler],
  ),
  drywall(
    level: TradeLevel.medium,
    proHours: 12,
    tools: [
      StarterTool.tape,
      StarterTool.pencil,
      StarterTool.cutter,
      StarterTool.spiritLevel,
      StarterTool.drillDriver,
      StarterTool.laserLevel,
    ],
    extra: [TradeTool.tapingKnife, TradeTool.boardLifter],
  ),
  tiling(
    level: TradeLevel.medium,
    proHours: 12,
    tools: [
      StarterTool.tape,
      StarterTool.pencil,
      StarterTool.spiritLevel,
      StarterTool.groutFloat,
      StarterTool.glasses,
    ],
    extra: [TradeTool.notchedTrowel, TradeTool.tileCutter, TradeTool.mixer],
  ),
  joinery(
    level: TradeLevel.medium,
    proHours: 4,
    tools: [
      StarterTool.tape,
      StarterTool.square,
      StarterTool.spiritLevel,
      StarterTool.drillDriver,
      StarterTool.bits,
      StarterTool.plane,
      StarterTool.chisels,
    ],
    extra: [],
  ),
  plumbing(
    level: TradeLevel.pro,
    proHours: 6,
    tools: [StarterTool.tape, StarterTool.drillDriver, StarterTool.caulkGun],
    extra: [TradeTool.pipeCutter],
  ),
  electricity(
    level: TradeLevel.pro,
    proHours: 8,
    tools: [StarterTool.screwdrivers, StarterTool.detector, StarterTool.drillDriver],
    extra: [TradeTool.voltageTester],
  );

  const Trade({
    required this.level,
    required this.proHours,
    required this.tools,
    required this.extra,
  });

  final TradeLevel level;
  final int proHours;

  /// Outils de la caisse du débutant qui servent à ce travail.
  final List<StarterTool> tools;

  /// Outils propres à ce travail, à acheter ou à louer.
  final List<TradeTool> extra;
}

/// Temps réaliste pour un débutant, en heures : deux fois le temps d'un pro au mieux, trois
/// fois quand on découvre le geste.
({int minHours, int maxHours}) beginnerHours(Trade pTrade) {
  final rHours = (
    minHours: (pTrade.proHours * beginnerFactor).ceil(),
    maxHours: (pTrade.proHours * (beginnerFactor + 1)).ceil(),
  );

  return rHours;
}

/// Ce qu'il manque pour s'y mettre quand on a déjà [pOwned] : outils de la caisse et outils
/// propres à acheter (nombre et coût), et outils à louer (coût par jour de location).
typedef TradeBudget = ({
  int toBuy,
  int buyMinEuros,
  int buyMaxEuros,
  int toRent,
  int rentMinEuros,
  int rentMaxEuros,
});

TradeBudget tradeBudget(Trade pTrade, Set<StarterTool> pOwned) {
  var vCount = 0;
  var vMin = 0;
  var vMax = 0;
  var vRented = 0;
  var vRentMin = 0;
  var vRentMax = 0;
  for (final vTool in pTrade.tools.where((pTool) => !pOwned.contains(pTool))) {
    vCount++;
    vMin += vTool.minEuros;
    vMax += vTool.maxEuros;
  }
  for (final vTool in pTrade.extra) {
    if (vTool.rent) {
      vRented++;
      vRentMin += vTool.minEuros;
      vRentMax += vTool.maxEuros;
    } else {
      vCount++;
      vMin += vTool.minEuros;
      vMax += vTool.maxEuros;
    }
  }
  final rBudget = (
    toBuy: vCount,
    buyMinEuros: vMin,
    buyMaxEuros: vMax,
    toRent: vRented,
    rentMinEuros: vRentMin,
    rentMaxEuros: vRentMax,
  );

  return rBudget;
}

/// Travaux rangés par niveau, du plus facile au plus délicat.
Map<TradeLevel, List<Trade>> tradesByLevel() => {
  for (final vLevel in TradeLevel.values)
    vLevel: Trade.values.where((pTrade) => pTrade.level == vLevel).toList(),
};
