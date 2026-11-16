import 'package:atelier/logic/hidden_networks.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

const _cable = HiddenRun(
  id: 'c',
  kind: NetworkKind.electric,
  wallIndex: 0,
  fromAlongMm: 1000,
  fromHeightMm: 300,
  toAlongMm: 1000,
  toHeightMm: 1100,
);
const _pipe = HiddenRun(
  id: 'e',
  kind: NetworkKind.water,
  wallIndex: 1,
  fromAlongMm: 0,
  fromHeightMm: 500,
  toAlongMm: 1000,
  toHeightMm: 500,
);

void main() {
  final vRoom = rectangleRoom().copyWith(
    walls: [
      const Wall(
        lengthMm: 4000,
        openings: [Opening(kind: OpeningKind.door, offsetMm: 2500, widthMm: 830)],
      ),
      ...rectangleRoom().walls.skip(1),
    ],
    networks: const [_cable, _pipe],
  );

  test('trop près d\'une gaine relevée : on ne perce pas', () {
    final vCheck = checkDrill(vRoom, 0, 1050, 700);

    expect(vCheck.tooClose, isTrue);
    expect(vCheck.nearest!.id, 'c');
    expect(vCheck.distanceMm, 50);
  });

  test('loin des réseaux et hors des bandes techniques : on peut percer', () {
    final vCheck = checkDrill(vRoom, 0, 2000, 1200);

    expect(vCheck.tooClose, isFalse);
    expect(vCheck.distanceMm, 1005);
    expect(vCheck.technicalZone, isFalse);
    expect(checkDrill(vRoom, 2, 2000, 1200).nearest, isNull);
  });

  test('bandes techniques : angle, sol, plafond, huisserie', () {
    expect(inTechnicalZone(vRoom, 0, 100, 1200), isTrue);
    expect(inTechnicalZone(vRoom, 0, 2000, 150), isTrue);
    expect(inTechnicalZone(vRoom, 0, 2000, 2400), isTrue);
    expect(inTechnicalZone(vRoom, 0, 2550, 1200), isTrue);
    expect(inTechnicalZone(vRoom, 0, 3900, 1200), isTrue);
    expect(inTechnicalZone(vRoom, 9, 2000, 1200), isFalse);
  });

  test('longueurs par réseau, aller-retour JSON', () {
    expect(networkLengths(vRoom.networks), {NetworkKind.electric: 800, NetworkKind.water: 1000});
    final vBack = Room.fromJson(vRoom.toJson()).networks;
    expect(vBack.first.toAlongMm, 1000);
    expect(vBack.last.kind, NetworkKind.water);
    expect(HiddenRun.fromJson({..._cable.toJson(), 'kind': 'inconnu'}).kind, NetworkKind.electric);
    expect(rectangleRoom().toJson().containsKey('networks'), isFalse);
    const vPoint = HiddenRun(
      id: 'p',
      kind: NetworkKind.gas,
      wallIndex: 0,
      fromAlongMm: 0,
      fromHeightMm: 0,
      toAlongMm: 0,
      toHeightMm: 0,
    );
    expect(vPoint.distanceTo(30, 40), 50);
  });
}
