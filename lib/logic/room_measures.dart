/// Cotes d'une pièce déjà saisie, à reprendre dans un calcul sans les retaper.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'room.dart';
import 'units.dart';

/// Cotes proposées : longueur et largeur hors tout, hauteur, tour, surfaces et volume.
enum RoomMeasureKey { length, width, height, perimeter, floor, walls, volume }

/// Une cote : longueur en millimètres, surface en m², volume en m³ selon [kind].
typedef RoomMeasure = ({RoomMeasureKey key, double value});

/// Unité de chaque cote : longueur, surface ou volume.
FieldUnit measureUnit(RoomMeasureKey pKey) => switch (pKey) {
  RoomMeasureKey.floor || RoomMeasureKey.walls => FieldUnit.m2,
  RoomMeasureKey.volume => FieldUnit.m3,
  _ => FieldUnit.mm,
};

/// Cotes de [pRoom] ; vide si ses murs ne suffisent pas à dessiner un contour.
List<RoomMeasure> roomMeasures(Room pRoom) {
  if (pRoom.walls.length < 3) {
    return const [];
  }
  final vPoints = outline(pRoom);
  final vXs = vPoints.map((pPoint) => pPoint.x);
  final vYs = vPoints.map((pPoint) => pPoint.y);
  final vSpanX = vXs.reduce(math.max) - vXs.reduce(math.min);
  final vSpanY = vYs.reduce(math.max) - vYs.reduce(math.min);
  final vHeight = pRoom.ceilingHeightMm;
  final vOpenings = pRoom.walls
      .expand((pWall) => pWall.openings)
      .fold(0.0, (pSum, pOpening) => pSum + pOpening.widthMm * pOpening.height / 1e6);
  final vFloor = floorAreaM2(pRoom);
  final rMeasures = <RoomMeasure>[
    (key: RoomMeasureKey.length, value: math.max(vSpanX, vSpanY).roundToDouble()),
    (key: RoomMeasureKey.width, value: math.min(vSpanX, vSpanY).roundToDouble()),
    (key: RoomMeasureKey.height, value: vHeight.toDouble()),
    (key: RoomMeasureKey.perimeter, value: perimeterMm(pRoom).toDouble()),
    (key: RoomMeasureKey.floor, value: vFloor),
    (
      key: RoomMeasureKey.walls,
      value: math.max(0, perimeterMm(pRoom) * vHeight / 1e6 - vOpenings),
    ),
    (key: RoomMeasureKey.volume, value: vFloor * vHeight / 1000),
  ];

  return rMeasures;
}

/// Vrai si la cote convient à un champ de cette unité : une longueur dans un champ de longueur.
bool fitsField(RoomMeasureKey pKey, FieldUnit pUnit) {
  final vUnit = measureUnit(pKey);
  final rFits = isLengthUnit(vUnit) ? isLengthUnit(pUnit) : vUnit == pUnit;

  return rFits;
}

/// Cote écrite dans l'unité du champ.
String measureInUnit(RoomMeasure pMeasure, FieldUnit pUnit) {
  final rText = isLengthUnit(pUnit)
      ? lengthInUnit(pMeasure.value.round(), pUnit)
      : formatDecimal(pMeasure.value);

  return rText;
}
