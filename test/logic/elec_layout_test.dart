import 'package:atelier/logic/elec_layout.dart';
import 'package:atelier/logic/electricity.dart';
import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/geometry.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

List<(int, int)> _rounded(List<PlanPoint> pPoints) => [
  for (final vPoint in pPoints) (vPoint.x.round(), vPoint.y.round()),
];

void main() {
  test('type de pièce deviné d’après son nom', () {
    expect(guessElecKind('Cuisine'), ElecRoomKind.kitchen);
    expect(guessElecKind("Salle d'eau"), ElecRoomKind.bathroom);
    expect(guessElecKind('Salle de bain'), ElecRoomKind.bathroom);
    expect(guessElecKind('WC'), ElecRoomKind.toilet);
    expect(guessElecKind('Chambre 2'), ElecRoomKind.bedroom);
    expect(guessElecKind('Entrée'), ElecRoomKind.hallway);
    expect(guessElecKind('Salon'), ElecRoomKind.living);
  });

  test('prises minimales, petite cuisine comprise', () {
    expect(requiredSockets(ElecRoomKind.living, 28), 7);
    expect(requiredSockets(ElecRoomKind.kitchen, 3.5), 3);
    expect(requiredSockets(ElecRoomKind.kitchen, 9), 6);
    expect(hasWetZones(ElecRoomKind.bathroom), isTrue);
    expect(hasWetZones(ElecRoomKind.bedroom), isFalse);
  });

  test('prises réparties sur les murs, au milieu de chaque part', () {
    final vRoom = rectangleRoom();
    expect(_rounded(spreadSockets(vRoom, 5)), [
      (1400, 0),
      (4000, 200),
      (4000, 2800),
      (1200, 3000),
      (0, 1400),
    ]);
    expect(spreadSockets(vRoom, 0), isEmpty);
    // Mur trop court pour garder 20 cm de chaque côté : la prise reste au milieu
    final vTiny = rectangleRoom().copyWith(
      walls: const [Wall(lengthMm: 300), Wall(lengthMm: 300), Wall(lengthMm: 300), Wall(lengthMm: 300)],
    );
    expect(_rounded(spreadSockets(vTiny, 1)), [(300, 300)]);
    final vCentre = ceilingCentre(vRoom);
    expect((vCentre.x.round(), vCentre.y.round()), (2000, 1500));
    final vLine = ceilingCentre(const Room(id: 'l', name: 'L', walls: [Wall(lengthMm: 2000)]));
    expect((vLine.x.round(), vLine.y.round()), (1000, 0));
  });

  test('portes laissées libres, interrupteur à côté de la porte', () {
    final vRoom = rectangleRoom().copyWith(
      walls: const [
        Wall(
          lengthMm: 4000,
          openings: [Opening(kind: OpeningKind.door, offsetMm: 1000, widthMm: 800)],
        ),
        Wall(lengthMm: 3000),
        Wall(lengthMm: 4000),
        Wall(lengthMm: 3000),
      ],
    );
    expect(freeSpans(vRoom).take(2).toList(), [
      (wall: 0, fromMm: 0, toMm: 850),
      (wall: 0, fromMm: 1950, toMm: 4000),
    ]);
    final vSwitch = switchPlace(vRoom);
    expect((vSwitch.x.round(), vSwitch.y.round()), (1950, 0));
    // Porte au bout du mur : interrupteur avant la porte
    final vEnd = rectangleRoom().copyWith(
      walls: const [
        Wall(
          lengthMm: 4000,
          openings: [Opening(kind: OpeningKind.door, offsetMm: 3200, widthMm: 800)],
        ),
        Wall(lengthMm: 3000),
        Wall(lengthMm: 4000),
        Wall(lengthMm: 3000),
      ],
    );
    expect(switchPlace(vEnd).x.round(), 3050);
    expect(switchPlace(rectangleRoom()).x.round(), 300);
  });

  test('proposition : ce qui manque, loin des prises déjà posées', () {
    final vRoom = rectangleRoom().copyWith(
      fixtures: const [Fixture(id: 'a', kind: FixtureKind.socket, xMm: 1400, yMm: 0, count: 2)],
    );
    final vProposal = proposeElec(vRoom)!;
    expect(vProposal.kind, ElecRoomKind.living);
    expect((vProposal.requiredSockets, vProposal.existingSockets), (5, 2));
    expect(_rounded(vProposal.newSockets), [(4000, 2800), (1200, 3000), (4000, 200)]);
    expect(vProposal.hasSwitch, isFalse);
    expect(vProposal.lights, 1);

    var vId = 0;
    final vPlaced = withProposal(vRoom, vProposal, pNewId: () => 'n${vId++}');
    expect(vPlaced.fixtures, hasLength(5));
    expect(vPlaced.fixtures.last.kind, FixtureKind.lightSwitch);
    final vAgain = proposeElec(vPlaced)!;
    expect(vAgain.newSockets, isEmpty);
    expect(vAgain.newSwitch, isNull);
    expect(withProposal(vPlaced, vAgain, pNewId: () => 'x').fixtures, hasLength(5));

    expect(proposeElec(const Room(id: 'v', name: 'Vide')), isNull);
    expect(proposeElec(rectangleRoom(), pKind: ElecRoomKind.bedroom)!.requiredSockets, 3);
  });
}
