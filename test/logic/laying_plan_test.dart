import 'package:atelier/logic/laying_plan.dart';
import 'package:atelier/logic/parquet.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

/// Joints (fins de morceaux sauf la dernière) d'une longueur de pose, depuis le mur.
List<int> joints(RowRun pRun) {
  final rJoints = <int>[];
  var vPosition = 0;
  for (final vPiece in pRun.pieces.take(pRun.pieces.length - 1)) {
    vPosition += vPiece;
    rJoints.add(vPosition);
  }

  return rJoints;
}

void main() {
  test('pièce rectangulaire : lames de 138 cm, joints décalés, chutes réutilisées', () {
    final vPlan = planLaying(rectangleRoom(), const ParquetSettings())!;

    expect(vPlan.rows, hasLength(16));
    expect(vPlan.rows.first.widthMm, 193);
    expect(vPlan.rows.last.widthMm, 89);
    expect(vPlan.rows[0].runs.single.pieces, [1380, 1380, 1224]);
    // Le dernier morceau de 14,4 cm serait trop court : la première lame est raccourcie
    expect(vPlan.rows[1].runs.single.pieces, [924, 1380, 1380, 300]);
    expect(vPlan.rows[2].runs.single.pieces, [456, 1380, 1380, 768]);
    expect(vPlan.rows[2].runs.single.startsWithOffcut, isTrue);
    expect(vPlan.planksUsed, 54);
    expect(vPlan.problemRows, isEmpty);
    for (final vRow in vPlan.rows) {
      expect(vRow.runs.single.lengthMm, 3984);
      expect(vRow.runs.single.pieces.every((pPiece) => pPiece >= minPieceMm), isTrue);
    }
  });

  test('deux rangées voisines n\'ont jamais de joints à moins de 30 cm', () {
    final vPlan = planLaying(rectangleRoom(), const ParquetSettings())!;

    for (var vIndex = 1; vIndex < vPlan.rows.length; vIndex++) {
      for (final vJoint in joints(vPlan.rows[vIndex].runs.single)) {
        for (final vPrevious in joints(vPlan.rows[vIndex - 1].runs.single)) {
          expect((vJoint - vPrevious).abs(), greaterThanOrEqualTo(300));
        }
      }
    }
  });

  test('pièce en L : les rangées hautes sont plus courtes', () {
    final vPlan = planLaying(lShapedRoom(), const ParquetSettings())!;

    expect(vPlan.rows, hasLength(21));
    expect(vPlan.rows[0].runs.single.pieces, [1380, 1380, 1380, 844]);
    expect(vPlan.rows[9].runs.single.lengthMm, 4984);
    expect(vPlan.rows[10].runs.single.pieces, [1080, 1380, 524]);
    expect(vPlan.rows[10].runs.single.startsWithOffcut, isTrue);
    expect(vPlan.planksUsed, 65);
    expect(vPlan.problemRows, isEmpty);
  });

  test('des lames trop courtes ne permettent pas toujours de tenir les règles', () {
    const vRoom = Room(
      id: 'r',
      name: 'Couloir',
      walls: [Wall(lengthMm: 4000), Wall(lengthMm: 595), Wall(lengthMm: 4000), Wall(lengthMm: 595)],
    );
    final vPlan = planLaying(vRoom, const ParquetSettings(plankLengthMm: 600))!;

    expect(vPlan.rows, hasLength(3));
    expect(vPlan.rows[1].runs.single.pieces.last, 84);
    expect(vPlan.problemRows, [2]);
  });

  test('une longueur plus courte qu\'une lame se pose d\'un seul morceau, chute comprise', () {
    const vRoom = Room(
      id: 'r',
      name: 'Placard',
      walls: [Wall(lengthMm: 1016), Wall(lengthMm: 402), Wall(lengthMm: 1016), Wall(lengthMm: 402)],
    );
    final vPlan = planLaying(vRoom, const ParquetSettings())!;

    expect(vPlan.rows, hasLength(2));
    expect(vPlan.rows[0].runs.single.pieces, [1000]);
    expect(vPlan.rows[0].runs.single.newPlanks, 1);
    expect(vPlan.rows[1].runs.single.newPlanks, 1);
    expect(vPlan.planksUsed, 2);
  });

  test('une chute assez longue sert à une longueur courte', () {
    const vRoom = Room(
      id: 'r',
      name: 'Entrée',
      walls: [Wall(lengthMm: 516), Wall(lengthMm: 402), Wall(lengthMm: 516), Wall(lengthMm: 402)],
    );
    final vPlan = planLaying(vRoom, const ParquetSettings())!;

    // 1380 - 500 laisse 880 : la seconde rangée y est taillée sans entamer de lame
    expect(vPlan.rows[1].runs.single.startsWithOffcut, isTrue);
    expect(vPlan.planksUsed, 1);
  });

  test('pas de plan en point de Hongrie ni sans pièce', () {
    expect(planLaying(rectangleRoom(), ParquetSettings.forType(ParquetType.herringbone)), isNull);
    expect(planLaying(const Room(id: 'r', name: 'R'), const ParquetSettings()), isNull);
    expect(planLaying(rectangleRoom(), const ParquetSettings(plankLengthMm: 0)), isNull);
  });

  test('écart entre joints', () {
    expect(jointsFarEnough(924, 1380, 1380, 300), isTrue);
    expect(jointsFarEnough(1080, 1380, 1380, 300), isTrue);
    expect(jointsFarEnough(1200, 1380, 1380, 300), isFalse);
    // 100 et 1300 sont à 200 mm près une fois les lames enchaînées
    expect(jointsFarEnough(100, 1300, 1380, 300), isFalse);
    expect(jointsFarEnough(500, null, 1380, 300), isTrue);
  });

  test('les rangées posées se relisent depuis le JSON', () {
    final vRoom = rectangleRoom().copyWith(laidRows: const [1, 2, 5]);

    expect(Room.fromJson(vRoom.toJson()).laidRows, [1, 2, 5]);
    expect(Room.fromJson({'id': 'r', 'name': 'R'}).laidRows, isEmpty);
  });
}
