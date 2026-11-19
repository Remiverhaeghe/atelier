/// Diagnostic thermique simple : où la maison perd sa chaleur, paroi par paroi, et quels
/// travaux rapportent le plus pour leur coût.
///
/// Les coefficients et les coûts sont des ordres de grandeur courants, indicatifs : ils ne
/// remplacent ni un audit énergétique ni des devis.
library;

import 'fixtures.dart';
import 'geometry.dart';
import 'room.dart';
import 'slope.dart';

/// Ce par quoi la chaleur s'en va : quatre parois et le renouvellement d'air.
enum EnvelopePart {
  /// Toiture ou plancher des combles.
  roof([2.5, 0.8, 0.35, 0.14], 3, 40),

  /// Murs donnant dehors, fenêtres déduites.
  walls([2.0, 1.0, 0.5, 0.27], 3, 80),
  windows([5.8, 2.9, 1.4, 0.9], 2, 700),

  /// Plancher bas sur vide sanitaire, cave ou terre-plein.
  floor([1.5, 0.8, 0.45, 0.27], 3, 50),

  /// Fuites et ventilation, en volumes renouvelés par heure.
  air([1.0, 0.7, 0.5, 0.3], 3, 0);

  const EnvelopePart(this.levels, this.targetState, this.costPerM2);

  /// Du pire état (0) au meilleur (3) : U en W/(m²·K), ou renouvellement d'air en vol/h.
  final List<double> levels;

  /// État visé par des travaux courants : double vitrage récent pour les fenêtres, le meilleur
  /// ailleurs.
  final int targetState;

  /// Coût indicatif des travaux par un artisan, en € par m² de paroi.
  final int costPerM2;
}

/// Coût indicatif d'une reprise d'étanchéité à l'air avec une VMC hygroréglable.
const airWorkCost = 1500;

/// Le sol n'est pas dehors : un vide sanitaire ou une cave restent moins froids que l'air.
const floorTemperatureFactor = 0.6;

/// Degrés-jours de chauffage d'une année moyenne en France, base 18 °C (indicatif).
const defaultDegreeDays = 2200;

/// Surfaces de l'enveloppe, volume chauffé et état de chaque paroi (0 à 3).
class Envelope {
  const Envelope({
    this.roofM2 = 80,
    this.wallsM2 = 120,
    this.windowsM2 = 15,
    this.floorM2 = 80,
    this.volumeM3 = 200,
    this.states = const {
      EnvelopePart.roof: 1,
      EnvelopePart.walls: 0,
      EnvelopePart.windows: 1,
      EnvelopePart.floor: 0,
      EnvelopePart.air: 1,
    },
  });

  final double roofM2;

  /// Murs donnant dehors, fenêtres comprises.
  final double wallsM2;
  final double windowsM2;
  final double floorM2;
  final double volumeM3;
  final Map<EnvelopePart, int> states;

  int stateOf(EnvelopePart pPart) => (states[pPart] ?? 0).clamp(0, 3);

  /// Surface de la paroi ; pour l'air, le volume chauffé.
  double areaOf(EnvelopePart pPart) => switch (pPart) {
    EnvelopePart.roof => roofM2,
    EnvelopePart.walls => wallsM2 > windowsM2 ? wallsM2 - windowsM2 : 0,
    EnvelopePart.windows => windowsM2,
    EnvelopePart.floor => floorM2,
    EnvelopePart.air => volumeM3,
  };

  Envelope copyWith({
    double? roofM2,
    double? wallsM2,
    double? windowsM2,
    double? floorM2,
    double? volumeM3,
    Map<EnvelopePart, int>? states,
  }) => Envelope(
    roofM2: roofM2 ?? this.roofM2,
    wallsM2: wallsM2 ?? this.wallsM2,
    windowsM2: windowsM2 ?? this.windowsM2,
    floorM2: floorM2 ?? this.floorM2,
    volumeM3: volumeM3 ?? this.volumeM3,
    states: states ?? this.states,
  );

  /// Même maison, une paroi passée à l'état [pState].
  Envelope withState(EnvelopePart pPart, int pState) =>
      copyWith(states: {...states, pPart: pState});
}

/// Déperdition d'une paroi dans un état donné, en W/K.
double partLossWK(Envelope pEnvelope, EnvelopePart pPart, [int? pState]) {
  final vValue = pPart.levels[(pState ?? pEnvelope.stateOf(pPart)).clamp(0, 3)];
  final vArea = pEnvelope.areaOf(pPart);
  final rLoss = switch (pPart) {
    // 0,34 Wh/(m³·K) : chaleur emportée par un mètre cube d'air
    EnvelopePart.air => 0.34 * vValue * vArea,
    EnvelopePart.floor => vValue * vArea * floorTemperatureFactor,
    _ => vValue * vArea,
  };

  return rLoss;
}

/// Énergie perdue sur une année pour une déperdition de [pLossWK], en kWh.
double yearlyKwh(double pLossWK, {int pDegreeDays = defaultDegreeDays}) =>
    pLossWK * pDegreeDays * 24 / 1000;

typedef PartLoss = ({EnvelopePart part, double lossWK, double share, double kwh});

/// Pertes de chaque paroi, de la plus grosse à la plus petite, avec leur part du total.
List<PartLoss> heatLosses(Envelope pEnvelope, {int pDegreeDays = defaultDegreeDays}) {
  final vTotal = totalLossWK(pEnvelope);
  final rLosses = [
    for (final vPart in EnvelopePart.values)
      (
        part: vPart,
        lossWK: partLossWK(pEnvelope, vPart),
        share: vTotal == 0 ? 0.0 : partLossWK(pEnvelope, vPart) / vTotal,
        kwh: yearlyKwh(partLossWK(pEnvelope, vPart), pDegreeDays: pDegreeDays),
      ),
  ]..sort((pA, pB) => pB.lossWK.compareTo(pA.lossWK));

  return rLosses;
}

double totalLossWK(Envelope pEnvelope) =>
    EnvelopePart.values.fold(0.0, (pSum, pPart) => pSum + partLossWK(pEnvelope, pPart));

/// Travaux sur une paroi : gain par an, part des pertes évitée, coût indicatif et gain pour
/// 1000 € dépensés, qui sert à les classer.
typedef Work = ({
  EnvelopePart part,
  int fromState,
  int toState,
  double savedKwh,
  double savedShare,
  int cost,
  double kwhPer1000,
});

/// Coût indicatif des travaux d'une paroi.
int workCost(Envelope pEnvelope, EnvelopePart pPart) =>
    pPart == EnvelopePart.air ? airWorkCost : (pEnvelope.areaOf(pPart) * pPart.costPerM2).round();

/// Travaux utiles, les plus rentables d'abord ; une paroi déjà à l'état visé n'en a pas.
List<Work> bestWorks(Envelope pEnvelope, {int pDegreeDays = defaultDegreeDays}) {
  final vTotal = totalLossWK(pEnvelope);
  final rWorks = <Work>[];
  for (final vPart in EnvelopePart.values) {
    final vFrom = pEnvelope.stateOf(vPart);
    if (vFrom >= vPart.targetState || pEnvelope.areaOf(vPart) <= 0) {
      continue;
    }
    final vSaved = partLossWK(pEnvelope, vPart) - partLossWK(pEnvelope, vPart, vPart.targetState);
    final vKwh = yearlyKwh(vSaved, pDegreeDays: pDegreeDays);
    final vCost = workCost(pEnvelope, vPart);
    rWorks.add((
      part: vPart,
      fromState: vFrom,
      toState: vPart.targetState,
      savedKwh: vKwh,
      savedShare: vTotal == 0 ? 0.0 : vSaved / vTotal,
      cost: vCost,
      kwhPer1000: vCost == 0 ? 0.0 : vKwh / vCost * 1000,
    ));
  }
  rWorks.sort((pA, pB) => pB.kwhPer1000.compareTo(pA.kwhPer1000));

  return rWorks;
}

/// Enveloppe reprise des pièces habitables saisies : sol du niveau le plus bas, plafond du plus
/// haut, fenêtres et volume. Les murs donnant dehors ne se devinent pas : [pWallsM2] reste.
Envelope envelopeFromRooms(List<Room> pRooms, {Envelope pBase = const Envelope()}) {
  final vRooms = [
    for (final vRoom in pRooms)
      if (vRoom.usage == RoomUsage.habitable && vRoom.walls.length >= 3) vRoom,
  ];
  if (vRooms.isEmpty) {
    return pBase;
  }
  final vLow = vRooms.map((pRoom) => pRoom.level).reduce((pA, pB) => pA < pB ? pA : pB);
  final vHigh = vRooms.map((pRoom) => pRoom.level).reduce((pA, pB) => pA > pB ? pA : pB);
  var vFloor = 0.0;
  var vRoof = 0.0;
  var vWindows = 0.0;
  var vVolume = 0.0;
  for (final vRoom in vRooms) {
    if (vRoom.level == vLow) {
      vFloor += floorAreaM2(vRoom);
    }
    if (vRoom.level == vHigh) {
      vRoof += ceilingAreaMm2(vRoom) / 1e6;
    }
    vVolume += roomVolumeM3(vRoom);
    for (final vWall in vRoom.walls) {
      for (final vOpening in vWall.openings) {
        if (vOpening.kind == OpeningKind.window) {
          vWindows += vOpening.widthMm * vOpening.height / 1e6;
        }
      }
    }
    for (final vFixture in vRoom.fixtures) {
      if (vFixture.kind == FixtureKind.roofWindow) {
        vWindows += vFixture.areaM2;
      }
    }
  }
  double vRound(double pValue) => (pValue * 10).round() / 10;
  final rEnvelope = pBase.copyWith(
    roofM2: vRound(vRoof),
    floorM2: vRound(vFloor),
    windowsM2: vRound(vWindows),
    volumeM3: vRound(vVolume),
  );

  return rEnvelope;
}
