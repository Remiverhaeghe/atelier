/// Papier peint : lés par rouleau selon la hauteur et le raccord, rouleaux et colle.
library;

import 'room.dart';

/// Rouleau courant : 53 cm de large, 10,05 m de long.
const wallpaperRollWidthMm = 530;
const wallpaperRollLengthMm = 10050;

/// Recoupe en haut et en bas de chaque lé.
const wallpaperTrimMm = 100;

/// Un paquet de colle pour papier peint couvre environ cinq rouleaux.
const rollsPerGluePack = 5;

typedef WallpaperPlan = ({int stripMm, int stripsPerRoll, int strips, int rolls, int gluePacks});

/// Lés et rouleaux pour [pLengthMm] de murs à couvrir sur [pHeightMm] de haut ; un lé de plus
/// est compté pour les raccords autour des ouvertures et les erreurs de coupe.
WallpaperPlan planWallpaper(
  int pLengthMm,
  int pHeightMm, {
  int pRepeatMm = 0,
  int pRollWidthMm = wallpaperRollWidthMm,
  int pRollLengthMm = wallpaperRollLengthMm,
}) {
  if (pLengthMm <= 0 || pHeightMm <= 0) {
    return (stripMm: 0, stripsPerRoll: 0, strips: 0, rolls: 0, gluePacks: 0);
  }
  var vStrip = pHeightMm + wallpaperTrimMm;
  if (pRepeatMm > 0) {
    vStrip = (vStrip / pRepeatMm - 1e-9).ceil() * pRepeatMm;
  }
  final vPerRoll = pRollLengthMm ~/ vStrip;
  final vStrips = (pLengthMm / pRollWidthMm - 1e-9).ceil() + 1;
  // Plus haut qu'un rouleau : chaque lé se raboute de deux rouleaux, le reste part en chute
  final vRolls = vPerRoll == 0
      ? vStrips * (vStrip / pRollLengthMm - 1e-9).ceil()
      : (vStrips / vPerRoll - 1e-9).ceil();
  final rPlan = (
    stripMm: vStrip,
    stripsPerRoll: vPerRoll,
    strips: vStrips,
    rolls: vRolls,
    gluePacks: (vRolls / rollsPerGluePack - 1e-9).ceil(),
  );

  return rPlan;
}

/// Longueur de murs à couvrir dans une pièce : le tour, moins la largeur des portes et fenêtres.
int wallpaperLengthMm(Room pRoom) {
  var rLength = 0;
  for (final vWall in pRoom.walls) {
    rLength += vWall.lengthMm;
    for (final vOpening in vWall.openings) {
      rLength -= vOpening.widthMm;
    }
  }

  return rLength < 0 ? 0 : rLength;
}
