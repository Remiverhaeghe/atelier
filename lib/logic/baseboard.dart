/// Plinthes : morceaux mur par mur, coupes à chaque bout, fixations.
library;

import 'dart:math' as math;

import 'auto_corners.dart';
import 'bar_cutting.dart';
import 'room.dart';

/// Fixation des plinthes.
enum BaseboardFixing { glued, nailed, clips }

/// Coupe d'un bout de plinthe.
enum EndCutKind {
  /// Coupe droite : bout libre, chambranle de porte, passage.
  square,

  /// Coin rentrant : la pointe longue est au dos, contre le mur.
  insideMiter,

  /// Coin sortant : la pointe longue est sur la face, côté pièce.
  outsideMiter,

  /// Jonction de deux morceaux sur un mur trop long, en biseau à 45°.
  scarf,
}

class EndCut {
  const EndCut(this.kind, this.sawAngleDeg, [this.marginDeg = 0]);

  static const square = EndCut(EndCutKind.square, 0);

  final EndCutKind kind;

  /// Angle à régler sur la scie à onglet, 0 pour une coupe droite.
  final double sawAngleDeg;

  /// Incertitude de l'angle de scie, en degrés : non nulle quand l'angle du coin est déduit de
  /// mesures approximatives plutôt que mesuré.
  final double marginDeg;
}

/// Angle de scie d'un coin : la moitié de l'écart à un mur droit (90° donne 45°, 88° donne 46°).
double miterAngle(double pInteriorAngleDeg) => (180 - pInteriorAngleDeg).abs() / 2;

/// Coupe d'un coin d'angle intérieur [pInteriorAngleDeg] ; coupe droite pour un mur dans le prolongement.
EndCut cornerCut(double pInteriorAngleDeg, {double pMarginDeg = 0}) {
  if ((pInteriorAngleDeg - 180).abs() < 0.5) {
    return EndCut.square;
  }
  final rCut = EndCut(
    pInteriorAngleDeg > 180 ? EndCutKind.outsideMiter : EndCutKind.insideMiter,
    miterAngle(pInteriorAngleDeg),
    pMarginDeg,
  );

  return rCut;
}

class BaseboardSettings {
  const BaseboardSettings({
    this.barLengthMm = 2400,
    this.kerfMm = 2,
    this.fixing = BaseboardFixing.glued,
    this.glueMetresPerCartridge = 10,
    this.fixingSpacingMm = 400,
    this.thicknessMm = 15,
    this.fewestBars = false,
  });

  final int barLengthMm;

  /// Épaisseur du trait de scie, perdue à chaque coupe.
  final int kerfMm;
  final BaseboardFixing fixing;

  /// Longueur de plinthe collée par cartouche de colle ou de mastic.
  final double glueMetresPerCartridge;

  /// Écart entre deux clous, vis ou clips.
  final int fixingSpacingMm;

  /// Épaisseur de la plinthe : un onglet déborde de cette épaisseur fois la tangente de l'angle,
  /// côté face pour un coin sortant ou un biseau de jonction.
  final int thicknessMm;

  /// Murs plus longs qu'une barre : barres entières puis un reste, au lieu de morceaux égaux.
  /// Moins de barres, mais un joint à une longueur de barre du coin.
  final bool fewestBars;

  BaseboardSettings copyWith({
    int? barLengthMm,
    int? kerfMm,
    BaseboardFixing? fixing,
    double? glueMetresPerCartridge,
    int? fixingSpacingMm,
    int? thicknessMm,
    bool? fewestBars,
  }) => BaseboardSettings(
    barLengthMm: barLengthMm ?? this.barLengthMm,
    kerfMm: kerfMm ?? this.kerfMm,
    fixing: fixing ?? this.fixing,
    glueMetresPerCartridge: glueMetresPerCartridge ?? this.glueMetresPerCartridge,
    fixingSpacingMm: fixingSpacingMm ?? this.fixingSpacingMm,
    thicknessMm: thicknessMm ?? this.thicknessMm,
    fewestBars: fewestBars ?? this.fewestBars,
  );

  Map<String, Object?> toJson() => {
    'barLengthMm': barLengthMm,
    'kerfMm': kerfMm,
    'fixing': fixing.name,
    'glueMetresPerCartridge': glueMetresPerCartridge,
    'fixingSpacingMm': fixingSpacingMm,
    'thicknessMm': thicknessMm,
    'fewestBars': fewestBars,
  };

  static BaseboardSettings fromJson(Map<String, Object?> pJson) {
    const vBase = BaseboardSettings();
    final rSettings = BaseboardSettings(
      barLengthMm: (pJson['barLengthMm'] as int?) ?? vBase.barLengthMm,
      kerfMm: (pJson['kerfMm'] as int?) ?? vBase.kerfMm,
      fixing: pJson['fixing'] == null
          ? vBase.fixing
          : BaseboardFixing.values.byName(pJson['fixing']! as String),
      glueMetresPerCartridge:
          (pJson['glueMetresPerCartridge'] as num?)?.toDouble() ?? vBase.glueMetresPerCartridge,
      fixingSpacingMm: (pJson['fixingSpacingMm'] as int?) ?? vBase.fixingSpacingMm,
      thicknessMm: (pJson['thicknessMm'] as int?) ?? vBase.thicknessMm,
      fewestBars: (pJson['fewestBars'] as bool?) ?? vBase.fewestBars,
    );

    return rSettings;
  }
}

/// Un morceau de plinthe à couper, mesuré au dos (côté mur).
class BaseboardPiece {
  const BaseboardPiece({
    required this.wallNumber,
    required this.lengthMm,
    required this.startCut,
    required this.endCut,
  });

  final int wallNumber;
  final int lengthMm;
  final EndCut startCut;
  final EndCut endCut;

  /// Longueur à tailler dans la barre : la mesure au dos plus le débord des onglets dont la pointe
  /// longue est sur la face (coin sortant, bout d'un biseau de jonction).
  int stockMm(int pThicknessMm) =>
      lengthMm +
      _faceOverhang(startCut, false, pThicknessMm) +
      _faceOverhang(endCut, true, pThicknessMm);
}

/// Débord de la pointe longue côté face, 0 quand elle est au dos ou que la coupe est droite.
int _faceOverhang(EndCut pCut, bool pIsEnd, int pThicknessMm) {
  final vFaceLonger =
      pCut.kind == EndCutKind.outsideMiter || (pIsEnd && pCut.kind == EndCutKind.scarf);

  return vFaceLonger ? (pThicknessMm * math.tan(pCut.sawAngleDeg * math.pi / 180)).round() : 0;
}

/// Incertitude de l'angle de scie de chaque coin (celui qui suit chaque mur), en degrés. Zéro pour
/// un coin mesuré ou resté à 90° : seuls les angles déduits des longueurs sont incertains. L'angle
/// de scie varie de moitié moins que l'angle du coin.
List<double> cornerMargins(Room pRoom) {
  final vWalls = pRoom.walls;
  final vSpread = vWalls.length == 4
      ? cornerUncertainty([for (final vWall in vWalls) vWall.lengthMm])
      : null;

  return [
    for (final (vIndex, vWall) in vWalls.indexed)
      vWall.angleAuto && vSpread != null ? vSpread[vIndex] / 2 : 0.0,
  ];
}

/// Morceaux de plinthe de toute la pièce, dans l'ordre du tour.
List<BaseboardPiece> baseboardPieces(Room pRoom, BaseboardSettings pSettings) {
  final vWalls = pRoom.walls;
  final vMargins = cornerMargins(pRoom);
  final rPieces = <BaseboardPiece>[];
  for (var vIndex = 0; vIndex < vWalls.length; vIndex++) {
    final vWall = vWalls[vIndex];
    final vHasPrevious = vIndex > 0 || pRoom.closed;
    final vPrevious = vWalls[(vIndex - 1 + vWalls.length) % vWalls.length];
    final vStartCut = vHasPrevious && !vPrevious.freeEndAfter
        ? cornerCut(
            vPrevious.angleToNextDeg,
            pMarginDeg: vMargins[(vIndex - 1 + vWalls.length) % vWalls.length],
          )
        : EndCut.square;
    final vIsLast = vIndex == vWalls.length - 1;
    final vEndCut = vWall.freeEndAfter || (vIsLast && !pRoom.closed)
        ? EndCut.square
        : cornerCut(vWall.angleToNextDeg, pMarginDeg: vMargins[vIndex]);
    for (final vSegment in _segments(vWall, vStartCut, vEndCut)) {
      rPieces.addAll(_splitToBars(vIndex + 1, vSegment, pSettings));
    }
  }

  return rPieces;
}

class _Segment {
  const _Segment(this.lengthMm, this.startCut, this.endCut);

  final int lengthMm;
  final EndCut startCut;
  final EndCut endCut;
}

/// Parties du mur entre les ouvertures ; coupe droite contre chaque chambranle.
List<_Segment> _segments(Wall pWall, EndCut pStartCut, EndCut pEndCut) {
  final vOpenings = [...pWall.openings.where((pOpening) => pOpening.cutsBaseboard)]
    ..sort((pA, pB) => pA.offsetMm.compareTo(pB.offsetMm));
  final rSegments = <_Segment>[];
  var vPosition = 0;
  var vCut = pStartCut;
  for (final vOpening in vOpenings) {
    if (vOpening.offsetMm > vPosition) {
      rSegments.add(_Segment(vOpening.offsetMm - vPosition, vCut, EndCut.square));
    }
    vPosition = vOpening.offsetMm + vOpening.widthMm;
    vCut = EndCut.square;
  }
  if (pWall.lengthMm > vPosition) {
    rSegments.add(_Segment(pWall.lengthMm - vPosition, vCut, pEndCut));
  }

  return rSegments;
}

/// Un mur plus long qu'une barre se fait en morceaux joints en biseau, jamais plus longs qu'une
/// barre une fois le débord des onglets compté : égaux par défaut, ou barres entières et un reste.
List<BaseboardPiece> _splitToBars(int pWallNumber, _Segment pSegment, BaseboardSettings pSettings) {
  final vBar = pSettings.barLengthMm;
  if (vBar <= 0) {
    return _equalPieces(pWallNumber, pSegment, 1);
  }
  if (pSettings.fewestBars) {
    final vFewest = _fewestPieces(pWallNumber, pSegment, pSettings);
    if (vFewest != null) {
      return vFewest;
    }
  }
  var vCount = (pSegment.lengthMm + vBar - 1) ~/ vBar;
  var rPieces = _equalPieces(pWallNumber, pSegment, vCount);
  // Un morceau plus long qu'une barre avec son débord d'onglet : un morceau de plus
  while (vCount < pSegment.lengthMm &&
      rPieces.any((pPiece) => pPiece.stockMm(pSettings.thicknessMm) > vBar)) {
    vCount++;
    rPieces = _equalPieces(pWallNumber, pSegment, vCount);
  }

  return rPieces;
}

const _scarf = EndCut(EndCutKind.scarf, 45);

List<BaseboardPiece> _equalPieces(int pWallNumber, _Segment pSegment, int pCount) {
  final vBase = pSegment.lengthMm ~/ pCount;
  final vExtra = pSegment.lengthMm - vBase * pCount;
  final rPieces = [
    for (var vIndex = 0; vIndex < pCount; vIndex++)
      BaseboardPiece(
        wallNumber: pWallNumber,
        // Les millimètres qui restent vont au premier morceau.
        lengthMm: vBase + (vIndex == 0 ? vExtra : 0),
        startCut: vIndex == 0 ? pSegment.startCut : _scarf,
        endCut: vIndex == pCount - 1 ? pSegment.endCut : _scarf,
      ),
  ];

  return rPieces;
}

/// Barres entières à la suite, le reste au bout ; null si le reste serait trop court pour être
/// posé proprement (moins de [reusableOffcutMm]) : on retombe alors sur des morceaux égaux.
List<BaseboardPiece>? _fewestPieces(
  int pWallNumber,
  _Segment pSegment,
  BaseboardSettings pSettings,
) {
  final vBar = pSettings.barLengthMm;
  final vThickness = pSettings.thicknessMm;
  final rPieces = <BaseboardPiece>[];
  var vLeft = pSegment.lengthMm;
  var vStart = pSegment.startCut;

  while (true) {
    final vLast = BaseboardPiece(
      wallNumber: pWallNumber,
      lengthMm: vLeft,
      startCut: vStart,
      endCut: pSegment.endCut,
    );
    if (vLast.stockMm(vThickness) <= vBar) {
      rPieces.add(vLast);

      return vLeft >= reusableOffcutMm || rPieces.length == 1 ? rPieces : null;
    }
    // Pièce pleine : le débord de son début et de son biseau de jonction est pris sur la barre
    final vFull =
        vBar - _faceOverhang(vStart, false, vThickness) - _faceOverhang(_scarf, true, vThickness);
    if (vFull <= 0 || vFull >= vLeft) {
      return null;
    }
    rPieces.add(
      BaseboardPiece(wallNumber: pWallNumber, lengthMm: vFull, startCut: vStart, endCut: _scarf),
    );
    vLeft -= vFull;
    vStart = _scarf;
  }
}

/// Fournitures de fixation pour une longueur de plinthes.
class FixingNeeds {
  const FixingNeeds({required this.cartridges, required this.points});

  /// Cartouches de colle ou de mastic.
  final int cartridges;

  /// Clous, vis ou clips.
  final int points;
}

FixingNeeds fixingNeeds(List<BaseboardPiece> pPieces, BaseboardSettings pSettings) {
  final vTotal = pPieces.fold<int>(0, (pSum, pPiece) => pSum + pPiece.lengthMm);
  if (pSettings.fixing == BaseboardFixing.glued) {
    final vPerCartridge = pSettings.glueMetresPerCartridge * 1000;
    final rNeeds = FixingNeeds(
      cartridges: vTotal == 0 || vPerCartridge <= 0 ? 0 : (vTotal / vPerCartridge - 1e-9).ceil(),
      points: 0,
    );

    return rNeeds;
  }
  // Une fixation à chaque bout et tous les [fixingSpacingMm] entre les deux.
  final vSpacing = pSettings.fixingSpacingMm <= 0 ? 400 : pSettings.fixingSpacingMm;
  final rNeeds = FixingNeeds(
    cartridges: 0,
    points: pPieces.fold(
      0,
      (pSum, pPiece) => pSum + (pPiece.lengthMm + vSpacing - 1) ~/ vSpacing + 1,
    ),
  );

  return rNeeds;
}
