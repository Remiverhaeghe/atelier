/// Salle d'eau : volumes de sécurité électrique autour de la douche, pente du receveur,
/// étanchéité liquide sous carrelage et ventilation.
///
/// Repères courants de la norme NF C 15-100 et des notices de fabricants, à vérifier dans les
/// textes à jour avant les travaux.
library;

import 'bathroom.dart';
import 'ventilation.dart';

/// Hauteur du volume 1 au-dessus du sol, et largeur du volume 2 autour du volume 1.
const zone1HeightMm = 2250;
const zone2WidthMm = 600;
const zone2HeightMm = 3000;

/// Douche sans receveur ni paroi : le volume 1 s'étend à 1,20 m de la pomme de douche fixe.
const walkInZone1RadiusMm = 1200;

/// Volume de sécurité, de l'intérieur de la douche vers le reste de la pièce.
enum BathZone { zone0, zone1, zone2, outside }

/// Ce qui est admis dans chaque volume, en résumé ; à afficher, pas à appliquer à la lettre.
typedef ZoneRule = ({String ip, bool sockets, bool lights, bool switches});

ZoneRule zoneRule(BathZone pZone) => switch (pZone) {
  BathZone.zone0 => (ip: 'IPX7', sockets: false, lights: false, switches: false),
  BathZone.zone1 => (ip: 'IPX4', sockets: false, lights: false, switches: false),
  BathZone.zone2 => (ip: 'IPX4', sockets: false, lights: true, switches: false),
  BathZone.outside => (ip: 'IPX1', sockets: true, lights: true, switches: true),
};

/// Emprise au sol des volumes 1 et 2, en mm, pour une douche contre [Shower.walls] murs.
typedef ZonePlan = ({int zone1WidthMm, int zone1DepthMm, int zone2WidthMm, int zone2DepthMm});

ZonePlan zonePlan(Shower pShower, {bool pWalkIn = false}) {
  // Sans receveur ni paroi, le volume 1 se compte depuis la pomme de douche
  final vWidth = pWalkIn ? 2 * walkInZone1RadiusMm : pShower.widthMm;
  final vDepth = pWalkIn ? walkInZone1RadiusMm : pShower.depthMm;
  final vWalls = pShower.walls.clamp(1, 3);
  // Le devant est toujours ouvert ; les côtés le sont sans mur
  final vOpenSides = vWalls >= 3 ? 0 : (vWalls == 2 ? 1 : 2);
  final rPlan = (
    zone1WidthMm: vWidth,
    zone1DepthMm: vDepth,
    zone2WidthMm: vWidth + vOpenSides * zone2WidthMm,
    zone2DepthMm: vDepth + zone2WidthMm,
  );

  return rPlan;
}

/// Volume d'un point placé à [pDistanceMm] du bord du volume 1 (0 ou moins : dedans), à
/// [pHeightMm] du sol.
BathZone zoneAt(int pDistanceMm, int pHeightMm) {
  if (pHeightMm > zone2HeightMm) {
    return BathZone.outside;
  }
  if (pDistanceMm <= 0) {
    return pHeightMm > zone1HeightMm ? BathZone.zone2 : BathZone.zone1;
  }

  return pDistanceMm <= zone2WidthMm ? BathZone.zone2 : BathZone.outside;
}

/// Pente d'un receveur à carreler : 1 % au moins pour que l'eau parte, 3 % au plus pour ne pas
/// glisser (repères courants).
const minShowerSlopePercent = 1.0;
const maxShowerSlopePercent = 3.0;

enum SlopeVerdict { tooFlat, good, tooSteep }

/// Pente en % d'un receveur qui descend de [pDropMm] sur [pRunMm].
double slopePercent(int pDropMm, int pRunMm) => pRunMm <= 0 ? 0 : pDropMm * 100 / pRunMm;

SlopeVerdict slopeVerdict(double pPercent) => pPercent < minShowerSlopePercent
    ? SlopeVerdict.tooFlat
    : (pPercent > maxShowerSlopePercent ? SlopeVerdict.tooSteep : SlopeVerdict.good);

/// Système d'étanchéité liquide (SEL) : deux couches croisées, environ 1,3 kg par m² en tout,
/// pots de 5 kg (indicatif : la notice du produit fait foi).
const selKgPerM2 = 1.3;
const selPotKg = 5;

/// Manchettes à poser autour de chaque tuyau qui traverse la zone étanchée : arrivées d'eau
/// chaude et froide, évacuation.
const showerSleeves = 3;

typedef SealPlan = ({double areaM2, double kg, int pots, double bandM, int sleeves});

/// Étanchéité liquide de la douche, sol et murs, d'après le plan de [showerPlan].
SealPlan sealPlan(Shower pShower) {
  final vPlan = showerPlan(pShower);
  final vArea = vPlan.specFloorM2 + vPlan.specWallM2;
  final vKg = vArea * selKgPerM2;
  final rPlan = (
    areaM2: vArea,
    kg: vKg,
    pots: vArea <= 0 ? 0 : (vKg / selPotKg - 1e-9).ceil(),
    bandM: vPlan.cornerBandM,
    sleeves: showerSleeves,
  );

  return rPlan;
}

/// Ventilation de la salle d'eau : débit extrait de pointe, renouvellement du volume par heure
/// et détalonnage de la porte.
typedef BathAir = ({int flowM3h, double changesPerHour, int undercutMm});

BathAir bathAir({required int pMainRooms, required double pVolumeM3}) {
  final vFlow = extractionFor(pMainRooms).bathroom;
  final rAir = (
    flowM3h: vFlow,
    changesPerHour: pVolumeM3 <= 0 ? 0.0 : vFlow / pVolumeM3,
    undercutMm: undercutMm,
  );

  return rAir;
}
