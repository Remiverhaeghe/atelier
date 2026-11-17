/// Assemblage d'une étagère : épaisseur conseillée selon la charge, assemblage des tablettes,
/// équerres d'une tablette murale, fixation au mur et contreventement.
///
/// Règles de menuiserie courantes, pour un usage domestique : un meuble lourd ou destiné
/// à un lieu public se dimensionne avec les données du fabricant.
library;

import 'dart:math' as math;

import 'fixings.dart';
import 'shelf.dart';

/// Ce que porte l'étagère : la portée admise baisse quand la charge monte.
enum ShelfLoad {
  /// Bibelots, linge, boîtes vides.
  light(spanFactor: 1.3, kgPerMetre: 10),

  /// Livres, vaisselle : le cas courant.
  books(spanFactor: 1, kgPerMetre: 40),

  /// Outillage, vinyles, conserves.
  heavy(spanFactor: 0.75, kgPerMetre: 60);

  const ShelfLoad({required this.spanFactor, required this.kgPerMetre});

  final double spanFactor;

  /// Poids posé par mètre de tablette, pour une profondeur d'environ 30 cm.
  final int kgPerMetre;
}

/// Épaisseurs vendues couramment en grande surface.
const standardThicknessesMm = [16, 18, 19, 22, 25, 30];

/// Masse volumique des panneaux, pour le poids propre de la tablette.
int densityKgPerM3(ShelfMaterial pMaterial) => switch (pMaterial) {
  ShelfMaterial.particleBoard => 650,
  ShelfMaterial.mdf => 750,
  ShelfMaterial.plywood => 550,
  ShelfMaterial.solidWood => 600,
};

/// Portée qu'une tablette de [pThicknessMm] tient sans fléchir à l'œil sous [pLoad].
int shelfSpanMm(ShelfMaterial pMaterial, int pThicknessMm, ShelfLoad pLoad) =>
    (pMaterial.spanPer18Mm * pThicknessMm / 18 * pLoad.spanFactor).floor();

/// Épaisseur conseillée : la plus fine du commerce qui tient la portée. Sans épaisseur qui
/// suffise, un montant au milieu coupe la portée en deux.
typedef ThicknessAdvice = ({int thicknessMm, bool middleUpright, int spanMm});

ThicknessAdvice adviseThickness(ShelfMaterial pMaterial, int pSpanMm, ShelfLoad pLoad) {
  int? vFit(int pSpan) => standardThicknessesMm
      .where((pThickness) => shelfSpanMm(pMaterial, pThickness, pLoad) >= pSpan)
      .firstOrNull;

  final vThickness = vFit(pSpanMm);
  final ThicknessAdvice rAdvice;
  if (vThickness != null) {
    rAdvice = (thicknessMm: vThickness, middleUpright: false, spanMm: pSpanMm);
  } else {
    // Le montant du milieu prend une épaisseur de panneau sur la largeur
    final vHalf = (pSpanMm - 18) ~/ 2;
    rAdvice = (
      thicknessMm: vFit(vHalf) ?? standardThicknessesMm.last,
      middleUpright: true,
      spanMm: vHalf,
    );
  }

  return rAdvice;
}

/// Façon de tenir chaque bout de tablette sur les montants.
enum ShelfJoint {
  /// Tourillons collés : solide et invisible dans le contreplaqué et le bois massif.
  dowels,

  /// Vis d'assemblage (confirmat 7 × 50) : elles tiennent dans l'aggloméré et le MDF, où une
  /// vis à bois ordinaire arrache les fibres.
  confirmatScrews,

  /// Taquets dans des trous espacés de 32 mm : tablette réglable, non collée.
  shelfPins,
}

typedef JointAdvice = ({
  ShelfJoint joint,

  /// Tourillons, vis ou taquets à chaque bout de tablette.
  int perEnd,

  /// Diamètre du tourillon, du taquet ou du foret pilote de la vis.
  int diameterMm,

  /// Longueur du tourillon ou de la vis.
  int lengthMm,

  /// Profondeur de perçage dans la face du montant ; 0 pour une vis qui le traverse.
  int holeInSideMm,

  /// Profondeur de perçage dans le chant de la tablette.
  int holeInShelfMm,

  /// Distance du premier et du dernier trou au bord avant ou arrière.
  int edgeMarginMm,
});

/// Assemblage conseillé pour les tablettes fixes de [pDesign], ou réglables avec [pAdjustable].
JointAdvice adviseJoint(ShelfDesign pDesign, {bool pAdjustable = false}) {
  const vMargin = 30;
  final vPerEnd = ((pDesign.depthMm - 2 * vMargin) / 120).ceil() + 1;
  final vCount = vPerEnd < 2 ? 2 : vPerEnd;
  final JointAdvice rAdvice;

  if (pAdjustable) {
    rAdvice = (
      joint: ShelfJoint.shelfPins,
      perEnd: 2,
      diameterMm: 5,
      lengthMm: 16,
      holeInSideMm: 10,
      holeInShelfMm: 0,
      edgeMarginMm: 37,
    );
  } else if (pDesign.material == ShelfMaterial.particleBoard ||
      pDesign.material == ShelfMaterial.mdf) {
    rAdvice = (
      joint: ShelfJoint.confirmatScrews,
      perEnd: vCount,
      diameterMm: 5,
      lengthMm: 50,
      holeInSideMm: 0,
      holeInShelfMm: 45,
      edgeMarginMm: vMargin,
    );
  } else {
    // Tourillon d'environ le tiers de l'épaisseur, percé aux deux tiers du montant au plus
    final vDiameter = pDesign.thicknessMm >= 25 ? 10 : (pDesign.thicknessMm >= 18 ? 8 : 6);
    final vLength = switch (vDiameter) {
      10 => 40,
      8 => 35,
      _ => 30,
    };
    final vInSide = pDesign.thicknessMm * 2 ~/ 3;
    rAdvice = (
      joint: ShelfJoint.dowels,
      perEnd: vCount,
      diameterMm: vDiameter,
      lengthMm: vLength,
      holeInSideMm: vInSide,
      // 2 mm de plus que la longueur restante : la colle a de la place au fond du trou
      holeInShelfMm: vLength - vInSide + 2,
      edgeMarginMm: vMargin,
    );
  }

  return rAdvice;
}

/// Tenue d'une étagère posée au sol.
typedef StabilityAdvice = ({
  /// À fixer au mur : au-delà d'un mètre, ou plus de trois fois plus haute que profonde.
  bool fixToWall,

  /// Sans fond, l'étagère se déforme en parallélogramme : traverse haute et équerres d'angle.
  bool brace,
});

StabilityAdvice adviseStability(ShelfDesign pDesign) => (
  fixToWall: pDesign.heightMm >= 1000 || pDesign.heightMm > 3 * pDesign.depthMm,
  brace: !pDesign.back,
);

/// Tablette murale posée sur des équerres.
class WallShelf {
  const WallShelf({
    this.lengthMm = 1200,
    this.depthMm = 250,
    this.thicknessMm = 18,
    this.material = ShelfMaterial.plywood,
    this.load = ShelfLoad.books,
    this.wall = WallSupport.concrete,
  });

  final int lengthMm;
  final int depthMm;
  final int thicknessMm;
  final ShelfMaterial material;
  final ShelfLoad load;
  final WallSupport wall;

  WallShelf copyWith({
    int? lengthMm,
    int? depthMm,
    int? thicknessMm,
    ShelfMaterial? material,
    ShelfLoad? load,
    WallSupport? wall,
  }) => WallShelf(
    lengthMm: lengthMm ?? this.lengthMm,
    depthMm: depthMm ?? this.depthMm,
    thicknessMm: thicknessMm ?? this.thicknessMm,
    material: material ?? this.material,
    load: load ?? this.load,
    wall: wall ?? this.wall,
  );
}

/// Longueurs de bras d'équerre vendues couramment.
const bracketArmsMm = [100, 125, 150, 200, 250, 300, 350, 400];

typedef BracketPlan = ({
  int brackets,

  /// Entre axes de deux équerres.
  int spacingMm,

  /// Débord de la tablette au-delà de la première et de la dernière équerre.
  int overhangMm,

  /// Bras d'équerre conseillé : au moins les deux tiers de la profondeur.
  int armMm,

  /// Tablette chargée, poids propre compris.
  double totalKg,
  double kgPerBracket,

  /// Traction sur la vis du haut : l'équerre fait levier, elle tire plus que le poids.
  double pullKg,
  FixingAdvice fixing,
});

/// Équerres d'une tablette murale : nombre, écart, débord, bras et chevilles.
BracketPlan planBrackets(WallShelf pShelf) {
  // Une épaisseur saisie à zéro ne doit pas donner un écart nul
  final vSpan = math.max(shelfSpanMm(pShelf.material, pShelf.thicknessMm, pShelf.load), 100);
  // Dans une cloison en plaques, une équerre sur montant tous les 60 cm au plus
  final vMaxSpacing = pShelf.wall == WallSupport.drywall && vSpan > 600 ? 600 : vSpan;
  final vOverhangMax = math.min(vMaxSpacing ~/ 4, 150);
  final vUsable = pShelf.lengthMm - 2 * vOverhangMax;
  final vNeeded = vUsable <= 0 ? 2 : (vUsable / vMaxSpacing - 1e-9).ceil() + 1;
  final vBrackets = vNeeded < 2 ? 2 : vNeeded;
  final vSpacing = vUsable <= 0 ? 0 : vUsable ~/ (vBrackets - 1);
  final vArmMin = (pShelf.depthMm * 2 / 3).ceil();
  final vArm = bracketArmsMm.firstWhere(
    (pArm) => pArm >= vArmMin,
    orElse: () => bracketArmsMm.last,
  );
  final vOwnKg =
      pShelf.lengthMm * pShelf.depthMm * pShelf.thicknessMm * densityKgPerM3(pShelf.material) / 1e9;
  final vTotal = pShelf.load.kgPerMetre * pShelf.lengthMm / 1000 + vOwnKg;
  final vPerBracket = vTotal / vBrackets;
  // Charge au milieu de la profondeur, vis du haut à 80 % de la hauteur du bras vertical
  final vPull = vPerBracket * (pShelf.depthMm / 2) / (0.8 * vArm);
  final rPlan = (
    brackets: vBrackets,
    spacingMm: vSpacing,
    overhangMm: vOverhangMax,
    armMm: vArm,
    totalKg: vTotal,
    kgPerBracket: vPerBracket,
    pullKg: vPull,
    fixing: adviseFixing(pShelf.wall, loadFor(vPull, 1)),
  );

  return rPlan;
}
