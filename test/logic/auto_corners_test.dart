import 'package:atelier/logic/auto_corners.dart';
import 'package:atelier/logic/geometry.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

Room _room(List<Wall> pWalls) => Room(id: 'r', name: 'Pièce', walls: pWalls);

void main() {
  const vMeasured = [3089, 4225, 2831, 4163];

  test('quatre murs mesurés au mètre : les angles se déduisent et le contour se referme', () {
    final vWalls = withFittedCorners([for (final vLength in vMeasured) Wall(lengthMm: vLength)]);

    expect(closesProperly(_room(vWalls)), isTrue);
    for (final vWall in vWalls) {
      expect(vWall.angleToNextDeg, inInclusiveRange(85, 95));
    }
    expect(vWalls.map((pWall) => pWall.angleToNextDeg).reduce((a, b) => a + b), closeTo(360, 0.01));
  });

  test('un vrai rectangle reste à 90 degrés', () {
    final vWalls = [
      for (final vLength in [4000, 3000, 4000, 3000]) Wall(lengthMm: vLength),
    ];

    expect(withFittedCorners(vWalls), same(vWalls));
  });

  test('un angle saisi à la main n\'est jamais écrasé', () {
    final vWalls = [
      const Wall(lengthMm: 3089, angleToNextDeg: 80),
      for (final vLength in vMeasured.skip(1)) Wall(lengthMm: vLength),
    ];

    expect(withFittedCorners(vWalls), same(vWalls));
  });

  test('pas quatre murs, ou longueurs impossibles : rien n\'est ajusté', () {
    final vThree = [
      for (final vLength in [3000, 4000, 5000]) Wall(lengthMm: vLength),
    ];
    final vImpossible = [
      for (final vLength in [1000, 1000, 1000, 5000]) Wall(lengthMm: vLength),
    ];

    expect(withFittedCorners(vThree), same(vThree));
    expect(withFittedCorners(vImpossible), same(vImpossible));
    expect(bestFitCorners([1000, 1000, 1000, 5000]), isNull);
    expect(bestFitCorners([1, 2, 3]), isNull);
    expect(bestFitCorners([1000, 0, 1000, 1000]), isNull);
  });

  group('angles recalculés', () {
    List<Wall> measured([List<int> pLengths = vMeasured]) => [
      for (final vLength in pLengths) Wall(lengthMm: vLength),
    ];

    test('les angles calculés sont marqués automatiques', () {
      final vWalls = withFittedCorners(measured());

      expect(vWalls.every((pWall) => pWall.angleAuto), isTrue);
    });

    test('une longueur corrigée recalcule les angles', () {
      final vFirst = withFittedCorners(measured());
      final vEdited = [vFirst[0].copyWith(lengthMm: 3200), ...vFirst.skip(1)];

      final vSecond = withFittedCorners(vEdited);

      expect(vSecond[0].angleToNextDeg, isNot(closeTo(vFirst[0].angleToNextDeg, 0.01)));
      expect(closesProperly(_room(vSecond)), isTrue);
      expect(vSecond.every((pWall) => pWall.angleAuto), isTrue);
    });

    test('des longueurs devenues celles d\'un rectangle redonnent 90 degrés', () {
      final vFirst = withFittedCorners(measured());
      final vEdited = [
        for (final (vIndex, vWall) in vFirst.indexed)
          vWall.copyWith(lengthMm: [4000, 3000, 4000, 3000][vIndex]),
      ];

      final vSecond = withFittedCorners(vEdited);

      expect(vSecond.every((pWall) => pWall.angleToNextDeg == 90 && !pWall.angleAuto), isTrue);
    });

    test('un mur à bout libre ou déduit du dessin n\'est pas ajusté', () {
      final vFree = [const Wall(lengthMm: 3089, freeEndAfter: true), ...measured().skip(1)];
      final vDeduced = [const Wall(lengthMm: 3089, deduced: true), ...measured().skip(1)];

      expect(withFittedCorners(vFree), same(vFree));
      expect(withFittedCorners(vDeduced), same(vDeduced));
    });

    test('un angle retapé à la main arrête le calcul automatique', () {
      final vFirst = withFittedCorners(measured());
      final vTyped = [vFirst[0].copyWith(angleToNextDeg: 80), ...vFirst.skip(1)];

      expect(vTyped[0].angleAuto, isFalse);
      expect(withFittedCorners(vTyped), same(vTyped));
    });

    test('l\'angle automatique est enregistré, et absent des anciens fichiers', () {
      const vWall = Wall(lengthMm: 3000, angleToNextDeg: 88.5, angleAuto: true);

      expect(Wall.fromJson(vWall.toJson()).angleAuto, isTrue);
      expect(const Wall(lengthMm: 3000).toJson().containsKey('angleAuto'), isFalse);
      expect(Wall.fromJson(const Wall(lengthMm: 3000).toJson()).angleAuto, isFalse);
    });
  });

  group('reprise d\'une pièce déjà saisie', () {
    Room saved({bool pClosed = true, List<int> pLengths = vMeasured}) => Room(
      id: 'r',
      name: 'Salon',
      closed: pClosed,
      walls: [for (final vLength in pLengths) Wall(lengthMm: vLength)],
    );

    test('les angles se déduisent des longueurs déjà saisies, sans rien retaper', () {
      final vRefit = refitRoom(saved());

      expect(closesProperly(vRefit), isTrue);
      expect(vRefit.walls.every((pWall) => pWall.angleAuto), isTrue);
      expect(vRefit.name, 'Salon');
    });

    test('une pièce déjà reprise est rendue telle quelle', () {
      final vRefit = refitRoom(saved());

      expect(refitRoom(vRefit), same(vRefit));
    });

    test('une pièce ouverte, rectangulaire ou à angles saisis n\'est pas touchée', () {
      final vOpen = saved(pClosed: false);
      final vRectangle = saved(pLengths: [4000, 3000, 4000, 3000]);
      final vManual = Room(
        id: 'r',
        name: 'Salon',
        walls: [const Wall(lengthMm: 3089, angleToNextDeg: 80), ...saved().walls.skip(1)],
      );

      expect(refitRoom(vOpen), same(vOpen));
      expect(refitRoom(vRectangle), same(vRectangle));
      expect(refitRoom(vManual), same(vManual));
    });

    test('une pièce reprise qui devient rectangulaire revient à 90 degrés', () {
      final vFitted = refitRoom(saved());
      final vEdited = vFitted.copyWith(
        walls: [
          for (final (vIndex, vWall) in vFitted.walls.indexed)
            vWall.copyWith(lengthMm: [4000, 3000, 4000, 3000][vIndex]),
        ],
      );

      final vBack = refitRoom(vEdited);

      expect(vBack.walls.every((pWall) => pWall.angleToNextDeg == 90), isTrue);
      expect(vBack.walls.any((pWall) => pWall.angleAuto), isFalse);
    });
  });

  group('marge d\'erreur', () {
    test('chaque angle varie de quelques degrés au plus avec une précision de 1 cm', () {
      final vSpread = cornerUncertainty(vMeasured)!;

      expect(vSpread, hasLength(4));
      for (final vAngle in vSpread) {
        expect(vAngle, inInclusiveRange(0.01, 5));
      }
    });

    test('plus la précision est faible, plus la marge est grande', () {
      final vFine = cornerUncertainty(vMeasured, pToleranceMm: 5)!;
      final vRough = cornerUncertainty(vMeasured, pToleranceMm: 30)!;

      expect(vRough.reduce((a, b) => a > b ? a : b), greaterThan(vFine.reduce((a, b) => a > b ? a : b)));
    });

    test('sans précision supposée, la marge est nulle', () {
      expect(cornerUncertainty(vMeasured, pToleranceMm: 0)!.every((pAngle) => pAngle == 0), isTrue);
    });

    test('des longueurs impossibles n\'ont pas de marge', () {
      expect(cornerUncertainty([1000, 1000, 1000, 5000]), isNull);
    });

    test('une variation qui rend le quadrilatère impossible est ignorée', () {
      // Quatre longueurs presque dégénérées : certaines variations n'ont plus de solution
      expect(cornerUncertainty([1000, 1000, 1000, 1990], pToleranceMm: 10), isNotNull);
    });
  });
}
