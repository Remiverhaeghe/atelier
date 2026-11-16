/// Plinthes : morceaux mur par mur, coupes à chaque bout, fixations.
library;

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
  const EndCut(this.kind, this.sawAngleDeg);

  static const square = EndCut(EndCutKind.square, 0);

  final EndCutKind kind;

  /// Angle à régler sur la scie à onglet, 0 pour une coupe droite.
  final double sawAngleDeg;
}

/// Angle de scie d'un coin : la moitié de l'écart à un mur droit (90° donne 45°, 88° donne 46°).
double miterAngle(double pInteriorAngleDeg) => (180 - pInteriorAngleDeg).abs() / 2;

/// Coupe d'un coin d'angle intérieur [pInteriorAngleDeg] ; coupe droite pour un mur dans le prolongement.
EndCut cornerCut(double pInteriorAngleDeg) {
  if ((pInteriorAngleDeg - 180).abs() < 0.5) {
    return EndCut.square;
  }
  final rCut = EndCut(
    pInteriorAngleDeg > 180 ? EndCutKind.outsideMiter : EndCutKind.insideMiter,
    miterAngle(pInteriorAngleDeg),
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
  });

  final int barLengthMm;

  /// Épaisseur du trait de scie, perdue à chaque coupe.
  final int kerfMm;
  final BaseboardFixing fixing;

  /// Longueur de plinthe collée par cartouche de colle ou de mastic.
  final double glueMetresPerCartridge;

  /// Écart entre deux clous, vis ou clips.
  final int fixingSpacingMm;

  BaseboardSettings copyWith({
    int? barLengthMm,
    int? kerfMm,
    BaseboardFixing? fixing,
    double? glueMetresPerCartridge,
    int? fixingSpacingMm,
  }) => BaseboardSettings(
    barLengthMm: barLengthMm ?? this.barLengthMm,
    kerfMm: kerfMm ?? this.kerfMm,
    fixing: fixing ?? this.fixing,
    glueMetresPerCartridge: glueMetresPerCartridge ?? this.glueMetresPerCartridge,
    fixingSpacingMm: fixingSpacingMm ?? this.fixingSpacingMm,
  );

  Map<String, Object?> toJson() => {
    'barLengthMm': barLengthMm,
    'kerfMm': kerfMm,
    'fixing': fixing.name,
    'glueMetresPerCartridge': glueMetresPerCartridge,
    'fixingSpacingMm': fixingSpacingMm,
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
}

/// Morceaux de plinthe de toute la pièce, dans l'ordre du tour.
List<BaseboardPiece> baseboardPieces(Room pRoom, BaseboardSettings pSettings) {
  final vWalls = pRoom.walls;
  final rPieces = <BaseboardPiece>[];
  for (var vIndex = 0; vIndex < vWalls.length; vIndex++) {
    final vWall = vWalls[vIndex];
    final vHasPrevious = vIndex > 0 || pRoom.closed;
    final vPrevious = vWalls[(vIndex - 1 + vWalls.length) % vWalls.length];
    final vStartCut = vHasPrevious && !vPrevious.freeEndAfter
        ? cornerCut(vPrevious.angleToNextDeg)
        : EndCut.square;
    final vIsLast = vIndex == vWalls.length - 1;
    final vEndCut = vWall.freeEndAfter || (vIsLast && !pRoom.closed)
        ? EndCut.square
        : cornerCut(vWall.angleToNextDeg);
    for (final vSegment in _segments(vWall, vStartCut, vEndCut)) {
      rPieces.addAll(_splitToBars(vIndex + 1, vSegment, pSettings.barLengthMm));
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
  final vOpenings = [...pWall.openings]..sort((pA, pB) => pA.offsetMm.compareTo(pB.offsetMm));
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

/// Un mur plus long qu'une barre se fait en morceaux égaux, joints en biseau.
List<BaseboardPiece> _splitToBars(int pWallNumber, _Segment pSegment, int pBarMm) {
  final vCount = pBarMm <= 0 ? 1 : (pSegment.lengthMm + pBarMm - 1) ~/ pBarMm;
  final vBase = pSegment.lengthMm ~/ vCount;
  final vExtra = pSegment.lengthMm - vBase * vCount;
  const vScarf = EndCut(EndCutKind.scarf, 45);
  final rPieces = [
    for (var vIndex = 0; vIndex < vCount; vIndex++)
      BaseboardPiece(
        wallNumber: pWallNumber,
        // Les millimètres qui restent vont au premier morceau.
        lengthMm: vBase + (vIndex == 0 ? vExtra : 0),
        startCut: vIndex == 0 ? pSegment.startCut : vScarf,
        endCut: vIndex == vCount - 1 ? pSegment.endCut : vScarf,
      ),
  ];

  return rPieces;
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
