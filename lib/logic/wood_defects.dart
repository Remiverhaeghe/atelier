/// Défauts du bois à repérer au magasin, et tri d'une planche d'après ce qu'on y mesure.
///
/// Les seuils sont des ordres de grandeur inspirés du classement visuel des bois de
/// structure (déformations mesurées sur 2 m) et des humidités conseillées par usage. Ils sont
/// indicatifs : pour une charpente, le marquage du bois classé fait foi.
library;

/// Défauts courants, dans l'ordre où on les cherche en prenant la planche.
enum WoodDefect { knot, split, check, twist, bow, cup, moisture }

/// Usage de la planche : plus il est visible ou précis, plus on est exigeant.
enum WoodUse {
  /// Meuble, étagère, ouvrage d'intérieur chauffé.
  furniture(moisture: 12, bowMm: 3, twistMm: 2, cupMm: 1, knotShare: 0.25),

  /// Menuiserie : châssis, porte, habillage de fenêtre.
  joinery(moisture: 15, bowMm: 5, twistMm: 3, cupMm: 2, knotShare: 0.3),

  /// Charpente, ossature, mezzanine : bois de structure.
  structure(moisture: 20, bowMm: 10, twistMm: 6, cupMm: 3, knotShare: 0.5);

  const WoodUse({
    required this.moisture,
    required this.bowMm,
    required this.twistMm,
    required this.cupMm,
    required this.knotShare,
  });

  /// Humidité maximale du bois, en %.
  final int moisture;

  /// Flèche en long, gauchissement (coin levé posé à plat) et tuilage tolérés, mesurés
  /// sur 2 m pour les deux premiers et sur la largeur pour le tuilage.
  final int bowMm;
  final int twistMm;
  final int cupMm;

  /// Plus gros nœud admis, en part de la largeur de la face.
  final double knotShare;
}

/// Verdict sur un défaut ou une planche : bonne, à surveiller (coupe ou séchage), à laisser.
enum Verdict { ok, watch, refuse }

/// Points à contrôler en choisissant ses planches, dans l'ordre du geste.
enum ShopCheck { sight, flat, ends, knots, edges, moisture, grain, spare }

/// Ce qu'on a relevé sur une planche.
typedef BoardReading = ({
  int lengthMm,
  int widthMm,
  int bowMm,
  int twistMm,
  int cupMm,
  int knotMm,
  bool looseKnot,
  int splitMm,
  int moisturePercent,
});

typedef BoardFinding = ({WoodDefect defect, Verdict verdict});

/// Marge coupée au-delà du bout d'une fente : elle continue souvent sous la surface.
const splitMarginMm = 50;

/// Un relevé franchit la moitié du seuil : à surveiller ; le seuil : à laisser.
Verdict _graded(int pValue, int pLimit) {
  if (pValue > pLimit) {
    return Verdict.refuse;
  }
  final rVerdict = pValue * 2 > pLimit ? Verdict.watch : Verdict.ok;

  return rVerdict;
}

/// Longueur utile une fois le bout fendu coupé, marge comprise.
int usableLengthMm(BoardReading pBoard) {
  final vCut = pBoard.splitMm <= 0 ? 0 : pBoard.splitMm + splitMarginMm;
  final rLength = pBoard.lengthMm - vCut;

  return rLength < 0 ? 0 : rLength;
}

/// Verdict de chaque défaut relevé ; [pNeededMm] est la longueur dont on a besoin.
List<BoardFinding> inspectBoard(BoardReading pBoard, WoodUse pUse, {int? pNeededMm}) {
  final vKnotLimit = (pBoard.widthMm * pUse.knotShare).round();
  final Verdict vKnot;
  if (pBoard.knotMm <= 0) {
    vKnot = Verdict.ok;
  } else if (pBoard.looseKnot) {
    // Un nœud noir ou qui bouge finit par tomber : passable seulement en structure
    vKnot = pUse == WoodUse.structure ? Verdict.watch : Verdict.refuse;
  } else {
    vKnot = _graded(pBoard.knotMm, vKnotLimit);
  }
  final vUsable = usableLengthMm(pBoard);
  final Verdict vSplit;
  if (pBoard.splitMm <= 0) {
    vSplit = Verdict.ok;
  } else if (pNeededMm != null && vUsable < pNeededMm) {
    vSplit = Verdict.refuse;
  } else {
    vSplit = Verdict.watch;
  }
  // Un peu trop humide, le bois sèche à l'abri ; beaucoup trop, il se déformera en séchant
  final vMoisture = pBoard.moisturePercent <= pUse.moisture
      ? Verdict.ok
      : (pBoard.moisturePercent <= pUse.moisture + 5 ? Verdict.watch : Verdict.refuse);
  final rFindings = <BoardFinding>[
    (defect: WoodDefect.knot, verdict: vKnot),
    (defect: WoodDefect.split, verdict: vSplit),
    (defect: WoodDefect.twist, verdict: _graded(pBoard.twistMm, pUse.twistMm)),
    (defect: WoodDefect.bow, verdict: _graded(pBoard.bowMm, pUse.bowMm)),
    (defect: WoodDefect.cup, verdict: _graded(pBoard.cupMm, pUse.cupMm)),
    (defect: WoodDefect.moisture, verdict: vMoisture),
  ];

  return rFindings;
}

/// Verdict de la planche : le plus sévère de ses défauts.
Verdict boardVerdict(List<BoardFinding> pFindings) {
  var rVerdict = Verdict.ok;
  for (final vFinding in pFindings) {
    if (vFinding.verdict.index > rVerdict.index) {
      rVerdict = vFinding.verdict;
    }
  }

  return rVerdict;
}

/// Contrôles faits sur [pDone] : vrai quand toute la liste est cochée.
bool checklistDone(Set<ShopCheck> pDone) => pDone.containsAll(ShopCheck.values);
