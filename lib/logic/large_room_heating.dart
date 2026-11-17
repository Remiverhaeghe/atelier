/// Chauffer un grand volume (atelier, séjour cathédrale, pièce sous mezzanine) : puissance,
/// pertes dues à l'air chaud qui monte, brasseurs d'air et type de chauffage.
library;

import 'dart:math' as math;

import 'heating.dart';

/// Pertes en plus par mètre de hauteur au-delà de 2,50 m avec un chauffage qui chauffe l'air.
const stratificationPerMetre = 0.05;

/// Surface de sol que brasse un ventilateur de plafond.
const fanFloorM2 = 40.0;

/// Puissances nominales courantes des poêles, en kW.
const stoveSizesKw = [4, 5, 6, 7, 8, 10, 12, 14];

/// Au-delà de cette hauteur, le rayonnement (panneaux, poêle, plancher chauffant) vaut mieux
/// que les convecteurs, qui chauffent surtout le plafond.
const radiantAboveMm = 4000;

typedef LargeRoomHeat = ({
  int watts,
  int stratificationWatts,
  List<int> radiators,
  int fans,
  int fanDiameterMm,
  int stoveKw,
  bool preferRadiant,
});

/// Diamètre d'un ventilateur de plafond pour [pFloorM2] de sol.
int fanDiameterFor(double pFloorM2) => pFloorM2 <= 15 ? 1070 : (pFloorM2 <= 25 ? 1320 : 1520);

/// Grand volume de [pLengthMm] × [pWidthMm] sous [pHeightMm] de hauteur moyenne.
LargeRoomHeat heatLargeRoom({
  required int pLengthMm,
  required int pWidthMm,
  required int pHeightMm,
  required InsulationLevel pLevel,
  double pIndoorC = 19,
  double pOutdoorC = -7,
}) {
  final vFloorM2 = pLengthMm * pWidthMm / 1e6;
  final vVolume = vFloorM2 * pHeightMm / 1000;
  final vBase = vVolume * pLevel.coefficient * (pIndoorC - pOutdoorC);
  final vAbove = math.max(0, pHeightMm - 2500) / 1000;
  final vStratification = (vBase * stratificationPerMetre * vAbove).round();
  final vWatts = vBase.round() + vStratification;
  final vFans = pHeightMm > destratifyAboveMm ? (vFloorM2 / fanFloorM2 - 1e-9).ceil() : 0;
  final rHeat = (
    watts: vWatts,
    stratificationWatts: vStratification,
    radiators: radiatorsFor(vWatts),
    fans: vFans,
    fanDiameterMm: vFans == 0 ? 0 : fanDiameterFor(vFloorM2 / vFans),
    stoveKw: stoveSizesKw.firstWhere(
      (pKw) => pKw * 1000 >= vWatts,
      orElse: () => stoveSizesKw.last,
    ),
    preferRadiant: pHeightMm > radiantAboveMm,
  );

  return rHeat;
}
