import 'package:atelier/logic/stair_design.dart';
import 'package:atelier/logic/stair_headroom.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2,80 m à monter : 16 hauteurs de 17,5 cm, giron de 28 cm, 15 marches sur 4,20 m
  test('trémie de 2,50 m : on se cogne à partir de la cinquième marche', () {
    final vHeadroom = stairHeadroom(2800, 2500);
    expect(vHeadroom.treads, 15);
    expect(vHeadroom.headroomMm, 1375);
    expect(headroomOk(vHeadroom), isFalse);
    expect(vHeadroom.neededTremieMm, 3080);
    expect(vHeadroom.lowTreads, 3);
    expect(vHeadroom.bumpTread, 5);
    expect(vHeadroom.treadHeadroomMm.take(8).toList(), [
      2425,
      2250,
      2075,
      1900,
      1725,
      1550,
      1375,
      null,
    ]);
  });

  test('trémie juste suffisante : 1,90 m au-dessus de la dernière marche couverte, personne ne se cogne', () {
    final vHeadroom = stairHeadroom(2800, 3080);
    expect(vHeadroom.headroomMm, 1900);
    expect(headroomOk(vHeadroom), isTrue);
    expect(vHeadroom.lowTreads, 0);
    expect(vHeadroom.bumpTread, isNull);
  });

  test('une personne plus grande se cogne plus tôt', () {
    expect(stairHeadroom(2800, 2500, pPersonMm: 2000).bumpTread, 4);
    expect(stairHeadroom(2800, 2500, pFloorMm: 300).headroomMm, 1275);
  });

  test('trémie sur toute la longueur : rien au-dessus des marches', () {
    final vHeadroom = stairHeadroom(2800, 5000);
    expect(vHeadroom.headroomMm, isNull);
    expect(headroomOk(vHeadroom), isTrue);
    expect(vHeadroom.treadHeadroomMm.every((pClear) => pClear == null), isTrue);
    expect(stairHeadroom(1000, 0).neededTremieMm, 1480);
    // Même trémie que la coupe de l'escalier droit
    for (final vRise in [2400, 2600, 2800, 3000]) {
      expect(stairHeadroom(vRise, 0).neededTremieMm, designStair(vRise).tremieMm);
    }
  });
}
