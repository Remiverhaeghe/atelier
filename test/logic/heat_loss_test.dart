import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/heat_loss.dart';
import 'package:atelier/logic/renovation_steps.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  const vHouse = Envelope();

  test('pertes paroi par paroi, de la plus grosse à la plus petite', () {
    expect(totalLossWK(vHouse), closeTo(437.1, 1e-6));
    final vLosses = heatLosses(vHouse);
    expect(vLosses.map((pLoss) => pLoss.part), [
      EnvelopePart.walls,
      EnvelopePart.floor,
      EnvelopePart.roof,
      EnvelopePart.air,
      EnvelopePart.windows,
    ]);
    expect(vLosses.first.lossWK, closeTo(210, 1e-9));
    expect(vLosses.first.kwh, closeTo(11088, 1e-6));
    expect(vLosses.first.share, closeTo(210 / 437.1, 1e-9));
    expect(vLosses.fold(0.0, (pSum, pLoss) => pSum + pLoss.share), closeTo(1, 1e-9));
    // Fenêtres plus grandes que les murs : pas de surface de mur négative
    expect(vHouse.copyWith(wallsM2: 10).areaOf(EnvelopePart.walls), 0);
    expect(vHouse.withState(EnvelopePart.roof, 3).stateOf(EnvelopePart.roof), 3);
    expect(vHouse.copyWith(states: const {}).stateOf(EnvelopePart.air), 0);
  });

  test('maison vide : rien ne se divise par zéro', () {
    const vEmpty = Envelope(roofM2: 0, wallsM2: 0, windowsM2: 0, floorM2: 0, volumeM3: 0);
    expect(heatLosses(vEmpty).every((pLoss) => pLoss.share == 0), isTrue);
    expect(bestWorks(vEmpty), isEmpty);
    expect(
      renovationPlan(vEmpty, HeatingSystem.oldBoiler, HeatingSystem.heatPump).first.stepShare,
      0,
    );
  });

  test('travaux les plus rentables d’abord, coûts indicatifs', () {
    final vWorks = bestWorks(vHouse);
    expect(vWorks.map((pWork) => pWork.part), [
      EnvelopePart.walls,
      EnvelopePart.air,
      EnvelopePart.roof,
      EnvelopePart.floor,
      EnvelopePart.windows,
    ]);
    final vWalls = vWorks.first;
    expect((vWalls.fromState, vWalls.toState, vWalls.cost), (0, 3, 8400));
    expect(vWalls.savedKwh, closeTo(9591.12, 1e-6));
    expect(vWalls.savedShare, closeTo(181.65 / 437.1, 1e-9));
    expect(vWorks[1].cost, airWorkCost);
    // Une paroi déjà à l'état visé n'a pas de travaux
    final vDone = vHouse.withState(EnvelopePart.windows, 2).withState(EnvelopePart.walls, 3);
    expect(bestWorks(vDone).map((pWork) => pWork.part), isNot(contains(EnvelopePart.windows)));
    expect(bestWorks(vDone).map((pWork) => pWork.part), isNot(contains(EnvelopePart.walls)));
  });

  test('rénovation pas à pas : effet prudent de chaque étape sur la facture', () {
    final vPlan = renovationPlan(vHouse, HeatingSystem.oldBoiler, HeatingSystem.heatPump);
    expect(vPlan.map((pStep) => pStep.step), RenovationStep.values);
    expect(vPlan.map((pStep) => pStep.stepShare).toList(), [
      closeTo(0.09663, 1e-4),
      closeTo(0.04118, 1e-4),
      closeTo(0.33246, 1e-4),
      closeTo(0.24140, 1e-4),
      closeTo(0.01333, 1e-4),
    ]);
    expect(vPlan.last.remainingShare, closeTo(0.275, 1e-3));
    expect(vPlan.every((pStep) => !pStep.skipped), isTrue);
    expect(roundedPercent(vPlan.first.stepShare), 10);
    expect(roundedPercent(vPlan[2].stepShare), 35);

    // Chauffage qui ne fait pas mieux et parois déjà faites : étapes sautées, sans effet
    final vSame = renovationPlan(
      vHouse.withState(EnvelopePart.roof, 3),
      HeatingSystem.heatPump,
      HeatingSystem.condensingBoiler,
    );
    expect(vSame.first.skipped, isTrue);
    expect(vSame.first.stepShare, 0);
    expect(vSame[3].skipped, isTrue);
    expect(vSame[3].stepShare, 0);
    expect(partOf(RenovationStep.heating), isNull);
    expect(boughtKwh(vHouse, HeatingSystem.electric), closeTo(yearlyKwh(437.1), 1e-6));
  });

  test('enveloppe reprise des pièces saisies', () {
    final vSalon = rectangleRoom().copyWith(
      walls: const [
        Wall(
          lengthMm: 4000,
          openings: [Opening(kind: OpeningKind.window, offsetMm: 1000, widthMm: 1200)],
        ),
        Wall(
          lengthMm: 3000,
          openings: [Opening(kind: OpeningKind.door, offsetMm: 0, widthMm: 800)],
        ),
        Wall(lengthMm: 4000),
        Wall(lengthMm: 3000),
      ],
    );
    final vChambre = rectangleRoom().copyWith(
      id: 'chambre',
      level: 1,
      fixtures: const [
        Fixture(
          id: 'v',
          kind: FixtureKind.roofWindow,
          xMm: 1000,
          yMm: 1000,
          widthMm: 780,
          depthMm: 980,
        ),
      ],
    );
    final vGarage = rectangleRoom().copyWith(id: 'garage', usage: RoomUsage.garage);
    final vEnvelope = envelopeFromRooms([vSalon, vChambre, vGarage]);
    expect(vEnvelope.floorM2, 12);
    expect(vEnvelope.roofM2, 12);
    expect(vEnvelope.windowsM2, 2.3);
    expect(vEnvelope.volumeM3, 60);
    expect(vEnvelope.wallsM2, const Envelope().wallsM2);
    expect(envelopeFromRooms(const []).roofM2, const Envelope().roofM2);
  });
}
