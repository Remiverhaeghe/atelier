/// Chauffage : puissance à installer par pièce, méthode du volume (V × C × ΔT), plus les plexis.
library;

import 'fixtures.dart';
import 'room.dart';
import 'slope.dart';

/// Isolation de la maison, avec son coefficient C courant en W/(m³·K).
enum InsulationLevel {
  recent(0.75),
  good(1.0),
  average(1.4),
  poor(1.8);

  const InsulationLevel(this.coefficient);

  final double coefficient;
}

/// Déperditions en plus d'un plexi par rapport à un double vitrage, en W/(m²·K).
const plexiExtraU = 2.7;

/// Puissances de radiateurs courantes, en W.
const radiatorSizes = [500, 750, 1000, 1250, 1500, 2000];

/// Au-delà de cette hauteur, l'air chaud s'accumule sous le plafond : brasseur d'air.
const destratifyAboveMm = 3500;

typedef HeatNeed = ({int watts, int plexiWatts, List<int> radiators, bool destratify});

/// Puissance de la pièce pour tenir [pIndoorC] quand il fait [pOutdoorC] dehors.
HeatNeed heatNeed(
  Room pRoom,
  InsulationLevel pLevel, {
  double pIndoorC = 19,
  double pOutdoorC = -7,
}) {
  final vDelta = pIndoorC - pOutdoorC;
  final vPlexiM2 = pRoom.fixtures
      .where((pFixture) => pFixture.kind == FixtureKind.roofWindow && pFixture.plexi)
      .fold(0.0, (pSum, pFixture) => pSum + pFixture.areaM2);
  final vPlexi = (vPlexiM2 * plexiExtraU * vDelta).round();
  final vWatts = (roomVolumeM3(pRoom) * pLevel.coefficient * vDelta).round() + vPlexi;
  final rNeed = (
    watts: vWatts,
    plexiWatts: vPlexi,
    radiators: radiatorsFor(vWatts),
    destratify: pRoom.ceilingHeightMm > destratifyAboveMm,
  );

  return rNeed;
}

/// Radiateurs courants qui couvrent [pWatts] : le moins d'appareils, chacun de 2000 W au plus.
List<int> radiatorsFor(int pWatts) {
  if (pWatts <= 0) {
    return const [];
  }
  final vCount = (pWatts / radiatorSizes.last - 1e-9).ceil();
  final vEach = pWatts / vCount;
  final vSize = radiatorSizes.firstWhere(
    (pSize) => pSize >= vEach,
    orElse: () => radiatorSizes.last,
  );
  final rRadiators = List.filled(vCount, vSize);

  return rRadiators;
}
