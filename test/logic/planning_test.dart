import 'package:atelier/logic/baseboard.dart';
import 'package:atelier/logic/paint.dart';
import 'package:atelier/logic/planning.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/touch_up.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  final vFull = rectangleRoom().copyWith(
    touchUps: const [TouchUp(id: 'e', label: 'Enduit', passes: 2)],
    paint: const PaintSettings(walls: true, ceiling: true, woodwork: true),
  );

  test('phases dans l\'ordre : reprises, plafond, murs, boiseries, parquet, plinthes, joints', () {
    expect(roomPhases(vFull).map((pState) => pState.phase), WorkPhase.values);
    expect(roomPhases(vFull).every((pState) => !pState.done), isTrue);
    expect(nextPhase(vFull), (next: WorkPhase.touchUps, after: null));
  });

  test('la phase suivante rappelle le séchage de la précédente', () {
    final vRoom = vFull.copyWith(
      touchUps: const [TouchUp(id: 'e', label: 'Enduit', passes: 2, donePasses: 2)],
      doneSteps: const [ceilingPaintedStep],
    );

    expect(nextPhase(vRoom), (next: WorkPhase.walls, after: WorkPhase.ceiling));
    expect(dryingHours[WorkPhase.ceiling], isPositive);
  });

  test('tout fait : plus de phase ; sur clips, pas de joint', () {
    final vDone = rectangleRoom().copyWith(
      laidRows: [for (var vRow = 1; vRow <= 16; vRow++) vRow],
      cutPieces: [for (var vIndex = 0; vIndex < 8; vIndex++) vIndex],
      doneSteps: const [sealedStep],
    );
    expect(nextPhase(vDone), isNull);

    final vClips = rectangleRoom().copyWith(
      baseboard: const BaseboardSettings(fixing: BaseboardFixing.clips),
    );
    expect(roomPhases(vClips).map((pState) => pState.phase), [
      WorkPhase.parquet,
      WorkPhase.baseboards,
    ]);
    expect(roomPhases(const Room(id: 'z', name: 'Zone')), isEmpty);
  });
}
