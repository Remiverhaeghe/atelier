import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/heating.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('pièce de 30 m³ moyennement isolée, 19 °C par −7 °C', () {
    final vNeed = heatNeed(rectangleRoom(), InsulationLevel.average);

    expect(vNeed.watts, 1092);
    expect(vNeed.radiators, [1250]);
    expect(vNeed.plexiWatts, 0);
    expect(vNeed.destratify, isFalse);
  });

  test('plexi de toit et grande hauteur', () {
    final vRoom = rectangleRoom().copyWith(
      ceilingHeightMm: 5500,
      fixtures: const [
        Fixture(
          id: 'p',
          kind: FixtureKind.roofWindow,
          xMm: 1000,
          yMm: 1000,
          widthMm: 780,
          depthMm: 980,
          plexi: true,
        ),
      ],
    );
    final vNeed = heatNeed(vRoom, InsulationLevel.average);

    expect(vNeed.plexiWatts, 54);
    expect(vNeed.watts, 2402 + 54);
    expect(vNeed.radiators, [1250, 1250]);
    expect(vNeed.destratify, isTrue);
  });

  test('radiateurs courants', () {
    expect(radiatorsFor(0), isEmpty);
    expect(radiatorsFor(480), [500]);
    expect(radiatorsFor(2000), [2000]);
    expect(radiatorsFor(4100), [1500, 1500, 1500]);
    expect(
      heatNeed(rectangleRoom(), InsulationLevel.recent, pIndoorC: 20, pOutdoorC: 0).watts,
      450,
    );
  });
}
