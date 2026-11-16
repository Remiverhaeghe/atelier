/// Quelle cheville, quelle vis : selon le support et la charge à accrocher.
library;

enum WallSupport { drywall, concrete, solidBrick, hollowBrick, aeratedBlock, wood }

/// Charge par point de fixation : un cadre, une étagère, un meuble haut ou une télévision.
enum FixingLoad {
  light(5),
  medium(15),
  heavy(40);

  const FixingLoad(this.kgPerPoint);

  final int kgPerPoint;
}

enum PlugKind { none, universalNylon, drywallMetal, drywallToggle, longNylon, chemical, aeratedSpiral }

/// Conseil de fixation : cheville, foret, vis (diamètre × longueur) et nombre de points.
typedef FixingAdvice = ({PlugKind plug, int drillMm, int screwDiameterMm, int screwLengthMm});

/// Fixation conseillée pour [pLoad] dans [pSupport], à vérifier sur l'emballage des chevilles.
FixingAdvice adviseFixing(WallSupport pSupport, FixingLoad pLoad) => switch ((pSupport, pLoad)) {
  (WallSupport.wood, FixingLoad.light) => (plug: PlugKind.none, drillMm: 2, screwDiameterMm: 4, screwLengthMm: 30),
  (WallSupport.wood, FixingLoad.medium) => (plug: PlugKind.none, drillMm: 3, screwDiameterMm: 5, screwLengthMm: 50),
  (WallSupport.wood, FixingLoad.heavy) => (plug: PlugKind.none, drillMm: 4, screwDiameterMm: 6, screwLengthMm: 70),
  (WallSupport.drywall, FixingLoad.light) => (plug: PlugKind.drywallMetal, drillMm: 8, screwDiameterMm: 4, screwLengthMm: 32),
  (WallSupport.drywall, FixingLoad.medium) => (plug: PlugKind.drywallMetal, drillMm: 10, screwDiameterMm: 5, screwLengthMm: 52),
  (WallSupport.drywall, FixingLoad.heavy) => (plug: PlugKind.drywallToggle, drillMm: 12, screwDiameterMm: 6, screwLengthMm: 60),
  (WallSupport.concrete || WallSupport.solidBrick, FixingLoad.light) => (plug: PlugKind.universalNylon, drillMm: 6, screwDiameterMm: 4, screwLengthMm: 40),
  (WallSupport.concrete || WallSupport.solidBrick, FixingLoad.medium) => (plug: PlugKind.universalNylon, drillMm: 8, screwDiameterMm: 5, screwLengthMm: 50),
  (WallSupport.concrete || WallSupport.solidBrick, FixingLoad.heavy) => (plug: PlugKind.universalNylon, drillMm: 10, screwDiameterMm: 6, screwLengthMm: 70),
  (WallSupport.hollowBrick, FixingLoad.light) => (plug: PlugKind.longNylon, drillMm: 6, screwDiameterMm: 4, screwLengthMm: 50),
  (WallSupport.hollowBrick, FixingLoad.medium) => (plug: PlugKind.longNylon, drillMm: 8, screwDiameterMm: 5, screwLengthMm: 70),
  (WallSupport.hollowBrick, FixingLoad.heavy) => (plug: PlugKind.chemical, drillMm: 12, screwDiameterMm: 8, screwLengthMm: 80),
  (WallSupport.aeratedBlock, FixingLoad.light) => (plug: PlugKind.aeratedSpiral, drillMm: 6, screwDiameterMm: 4, screwLengthMm: 40),
  (WallSupport.aeratedBlock, FixingLoad.medium) => (plug: PlugKind.aeratedSpiral, drillMm: 8, screwDiameterMm: 5, screwLengthMm: 60),
  (WallSupport.aeratedBlock, FixingLoad.heavy) => (plug: PlugKind.chemical, drillMm: 12, screwDiameterMm: 8, screwLengthMm: 80),
};

/// Points de fixation pour un objet de [pWeightKg] : au moins deux, avec une marge de deux.
int fixingPoints(double pWeightKg, FixingLoad pLoad) {
  final vNeeded = (pWeightKg * 2 / pLoad.kgPerPoint - 1e-9).ceil();
  final rPoints = vNeeded < 2 ? 2 : vNeeded;

  return rPoints;
}

/// Charge par point à choisir pour un objet de [pWeightKg] posé sur [pPoints] fixations.
FixingLoad loadFor(double pWeightKg, int pPoints) {
  final vPerPoint = pWeightKg * 2 / (pPoints < 1 ? 1 : pPoints);
  final rLoad = FixingLoad.values.firstWhere(
    (pLoad) => pLoad.kgPerPoint >= vPerPoint,
    orElse: () => FixingLoad.heavy,
  );

  return rLoad;
}
