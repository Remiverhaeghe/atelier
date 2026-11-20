/// Pièce dessinée d'avance : un rectangle, un L ou un T dont on tape seulement les longueurs.
///
/// Les coins sont d'équerre ; les murs qu'on n'a pas mesurés se déduisent de ceux qu'on a
/// mesurés pour que la pièce se referme. Seule une pièce rectangulaire aux murs opposés
/// différents demande la diagonale, dont l'appli tire les vrais angles.
library;

import 'diagonal.dart';
import 'room.dart';

/// Formes proposées.
enum RoomShape { rectangle, lShape, tShape }

/// Longueurs par défaut, pour dessiner la forme avant toute mesure.
const shapeDefaults = {
  RoomShape.rectangle: [4000, 3000, 4000, 3000],
  RoomShape.lShape: [5000, 2500, 2000, 1500, 3000, 4000],
  // Pied du T, puis le tour : côté du pied, dessous droit de la barre, bout, dessus, bout,
  // dessous gauche, autre côté du pied
  RoomShape.tShape: [1500, 2000, 1500, 2000, 4500, 2000, 1500, 2000],
};

/// Angle à la fin de chaque mur : 90 rentrant, 270 pour le coin sortant du L.
const shapeAngles = {
  RoomShape.rectangle: [90.0, 90.0, 90.0, 90.0],
  RoomShape.lShape: [90.0, 90.0, 270.0, 90.0, 90.0, 90.0],
  RoomShape.tShape: [90.0, 270.0, 90.0, 90.0, 90.0, 90.0, 270.0, 90.0],
};

/// Murs symétriques : non mesuré, un mur prend la longueur de son pendant s'il est mesuré.
const shapeMirrors = {
  RoomShape.tShape: {1: 7, 7: 1, 2: 6, 6: 2, 3: 5, 5: 3},
};

/// Forme reconnue dans des murs déjà saisis (mêmes coins), ou null.
RoomShape? shapeOf(List<Wall> pWalls) {
  for (final vEntry in shapeAngles.entries) {
    final vAngles = vEntry.value;
    if (pWalls.length == vAngles.length &&
        [
          for (var vIndex = 0; vIndex < vAngles.length; vIndex++)
            (pWalls[vIndex].angleToNextDeg - vAngles[vIndex]).abs() < 0.01,
        ].every((pSame) => pSame)) {
      return vEntry.key;
    }
  }

  return null;
}

/// Écart toléré entre deux murs opposés avant de demander la diagonale : 1 cm.
const squareToleranceMm = 10;

/// Pièce calculée : longueur et origine de chaque mur, angles, et ce qui manque.
typedef ShapedRoom = ({
  List<int> lengths,
  List<double> angles,

  /// Murs déduits des autres plutôt que mesurés.
  Set<int> deduced,

  /// Vrai si les murs opposés diffèrent : il faut la diagonale pour les angles.
  bool needsDiagonal,

  /// Vrai si les mesures ne permettent pas de refermer la forme.
  bool impossible,
});

/// Sens de chaque mur sur le plan : +1 ou -1 sur l'axe horizontal (axe 0) ou vertical (axe 1).
List<({int axis, int sign})> _directions(List<double> pAngles) {
  final rDirections = <({int axis, int sign})>[];
  var vQuarter = 0;
  for (final vAngle in pAngles) {
    final vTurn = vQuarter % 4;
    rDirections.add((axis: vTurn.isEven ? 0 : 1, sign: vTurn < 2 ? 1 : -1));
    // Coin rentrant : on tourne d'un quart à gauche ; coin sortant : à droite
    vQuarter += vAngle > 180 ? 3 : 1;
  }

  return rDirections;
}

/// Longueurs de la forme : mesures tapées, le reste déduit pour refermer la pièce.
///
/// Sur chaque axe, ce qui manque se répartit entre les murs non mesurés qui vont dans le
/// même sens, à proportion de leurs longueurs par défaut. [pDiagonalMm] donne les angles
/// d'un rectangle aux murs opposés différents.
ShapedRoom shapeRoom(RoomShape pShape, Map<int, int> pMeasured, {int? pDiagonalMm}) {
  final vDefaults = shapeDefaults[pShape]!;
  final vAngles = [...shapeAngles[pShape]!];
  final vDirections = _directions(vAngles);
  final vLengths = [
    for (var vIndex = 0; vIndex < vDefaults.length; vIndex++)
      pMeasured[vIndex] ?? vDefaults[vIndex],
  ];
  final vDeduced = <int>{};
  // Un mur symétrique d'un mur mesuré lui ressemble : il compte comme connu
  final vKnown = {...pMeasured};
  for (final vEntry in (shapeMirrors[pShape] ?? const <int, int>{}).entries) {
    final vMirror = pMeasured[vEntry.value];
    if (!pMeasured.containsKey(vEntry.key) && vMirror != null) {
      vKnown[vEntry.key] = vMirror;
      vLengths[vEntry.key] = vMirror;
      vDeduced.add(vEntry.key);
    }
  }
  var vImpossible = false;
  var vNeedsDiagonal = false;

  for (final vAxis in [0, 1]) {
    final vWalls = [
      for (var vIndex = 0; vIndex < vLengths.length; vIndex++)
        if (vDirections[vIndex].axis == vAxis) vIndex,
    ];
    final vFree = vWalls.where((pIndex) => !vKnown.containsKey(pIndex)).toList();
    if (vFree.isEmpty) {
      // Tout est mesuré sur cet axe : s'il ne se referme pas, la pièce n'est pas d'équerre
      final vGap = vWalls.fold(
        0,
        (pSum, pIndex) => pSum + vDirections[pIndex].sign * vLengths[pIndex],
      );
      if (vGap.abs() > squareToleranceMm) {
        vNeedsDiagonal = pShape == RoomShape.rectangle;
        vImpossible = pShape != RoomShape.rectangle;
      }
      continue;
    }
    final vFixed = vWalls
        .where((pIndex) => vKnown.containsKey(pIndex))
        .fold(0, (pSum, pIndex) => pSum + vDirections[pIndex].sign * vLengths[pIndex]);
    // Sur l'axe, les murs « aller » doivent égaler les murs « retour ». Les murs libres
    // de retour gardent leur longueur, ceux d'aller comblent ; sans mur libre d'aller,
    // ce sont ceux de retour qui comblent.
    final vForward = vFree.where((pIndex) => vDirections[pIndex].sign == 1).toList();
    final vBackward = vFree.where((pIndex) => vDirections[pIndex].sign == -1).toList();
    final vBackSum = vBackward.fold(0, (pSum, pIndex) => pSum + vLengths[pIndex]);
    final (vSide, vTarget) = vForward.isNotEmpty
        ? (vForward, vBackSum - vFixed)
        : (vBackward, vFixed);
    if (vTarget <= 0) {
      vImpossible = true;
      continue;
    }
    final vTotal = vSide.fold(0, (pSum, pIndex) => pSum + vDefaults[pIndex]);
    var vLeft = vTarget;
    for (final (vPosition, vIndex) in vSide.indexed) {
      final vShare = vPosition == vSide.length - 1
          ? vLeft
          : (vTarget * vDefaults[vIndex] / vTotal).round();
      vLengths[vIndex] = vShare;
      vLeft -= vShare;
      vDeduced.add(vIndex);
    }
  }

  if (vNeedsDiagonal && pDiagonalMm != null) {
    final vAnglesFromDiagonal = anglesFromDiagonal(
      Room(
        id: '',
        name: '',
        closed: true,
        walls: [for (final vLength in vLengths) Wall(lengthMm: vLength)],
      ),
      pDiagonalMm,
    );
    if (vAnglesFromDiagonal == null) {
      vImpossible = true;
    } else {
      vAngles
        ..clear()
        ..addAll(vAnglesFromDiagonal);
      vNeedsDiagonal = false;
    }
  }

  final ShapedRoom rShaped = (
    lengths: vLengths,
    angles: vAngles,
    deduced: vDeduced,
    needsDiagonal: vNeedsDiagonal,
    impossible: vImpossible,
  );

  return rShaped;
}

/// Murs de la pièce dessinée ; les ouvertures des murs déjà saisis sont gardées.
List<Wall> shapeWalls(ShapedRoom pShaped, List<Wall> pPrevious) => [
  for (var vIndex = 0; vIndex < pShaped.lengths.length; vIndex++)
    (vIndex < pPrevious.length ? pPrevious[vIndex] : const Wall(lengthMm: 0)).copyWith(
      lengthMm: pShaped.lengths[vIndex],
      angleToNextDeg: pShaped.angles[vIndex],
      deduced: pShaped.deduced.contains(vIndex),
    ),
];

/// Numéros (à partir de 1) des murs dont la longueur a été déduite sur le dessin.
List<int> wallsToMeasure(Room pRoom) => [
  for (final (vIndex, vWall) in pRoom.walls.indexed)
    if (vWall.deduced) vIndex + 1,
];
