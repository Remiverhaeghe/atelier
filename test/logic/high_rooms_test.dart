import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/living_area.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/slope.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

const _mezzanine = Fixture(
  id: 'm',
  kind: FixtureKind.mezzanine,
  xMm: 1000,
  yMm: 1500,
  widthMm: 2000,
  depthMm: 3000,
  riseMm: 2700,
);

void main() {
  test('mezzanine sous 5,50 m comptée en surface habitable', () {
    final vRoom = rectangleRoom().copyWith(ceilingHeightMm: 5500, fixtures: const [_mezzanine]);

    expect(mezzanineLivingM2(vRoom), closeTo(6, 1e-9));
    expect(roomLivingArea(vRoom).habitable, closeTo(18, 1e-9));
    expect(mezzanineFloorMm(vRoom.fixtures), 2700);
  });

  test('mezzanine trop près du plafond, ou sans hauteur saisie : pas comptée', () {
    final vLow = rectangleRoom().copyWith(ceilingHeightMm: 4000, fixtures: const [_mezzanine]);
    expect(mezzanineLivingM2(vLow), 0);

    expect(
      mezzanineLivingM2(
        rectangleRoom().copyWith(
          fixtures: const [
            Fixture(id: 'n', kind: FixtureKind.mezzanine, xMm: 0, yMm: 0, widthMm: 1000, depthMm: 1000),
          ],
        ),
      ),
      0,
    );
    expect(mezzanineFloorMm(const []), isNull);
  });

  test('volume : pièce droite, puis sous une pente', () {
    expect(roomVolumeM3(rectangleRoom().copyWith(ceilingHeightMm: 5500)), closeTo(66, 1e-9));
    final vAttic = rectangleRoom().copyWith(
      slope: const Slope(wallIndex: 0, lowMm: 1000, runMm: 2000),
    );
    // 12 m² × 2,50 m moins 8 m² × 0,75 m sous la pente
    expect(roomVolumeM3(vAttic), closeTo(24, 1e-6));
    expect(roomVolumeM3(const Room(id: 'v', name: 'Vide')), 0);
  });
}
