import 'package:atelier/logic/auto_corners.dart';
import 'package:atelier/logic/baseboard.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  group('angle de coupe', () {
    test('la moitié de l\'écart à un mur droit', () {
      expect(miterAngle(90), 45);
      expect(miterAngle(88), 46);
      expect(miterAngle(93), 43.5);
      expect(miterAngle(270), 45);
      expect(miterAngle(135), 22.5);
    });

    test('rentrant, sortant ou droit', () {
      expect(cornerCut(90).kind, EndCutKind.insideMiter);
      expect(cornerCut(270).kind, EndCutKind.outsideMiter);
      expect(cornerCut(180).kind, EndCutKind.square);
      expect(cornerCut(180).sawAngleDeg, 0);
    });
  });

  test('pièce rectangulaire : murs plus longs qu\'une barre coupés en deux, en biseau', () {
    final vPieces = baseboardPieces(rectangleRoom(), const BaseboardSettings());

    expect(vPieces, hasLength(8));
    expect(vPieces.map((pPiece) => pPiece.lengthMm), [
      2000,
      2000,
      1500,
      1500,
      2000,
      2000,
      1500,
      1500,
    ]);
    expect(vPieces.first.startCut.kind, EndCutKind.insideMiter);
    expect(vPieces.first.startCut.sawAngleDeg, 45);
    expect(vPieces.first.endCut.kind, EndCutKind.scarf);
    expect(vPieces[1].startCut.kind, EndCutKind.scarf);
    expect(vPieces[1].endCut.kind, EndCutKind.insideMiter);
    expect(vPieces.map((pPiece) => pPiece.wallNumber), [1, 1, 2, 2, 3, 3, 4, 4]);
  });

  test('un mur plus court qu\'une barre reste d\'un seul morceau', () {
    final vPieces = baseboardPieces(rectangleRoom(), const BaseboardSettings(barLengthMm: 5000));

    expect(vPieces, hasLength(4));
    expect(vPieces.every((pPiece) => pPiece.startCut.kind == EndCutKind.insideMiter), isTrue);
  });

  test('les millimètres qui restent vont au premier morceau', () {
    final vPieces = baseboardPieces(
      const Room(id: 'r', name: 'R', walls: [Wall(lengthMm: 4801)], closed: false),
      const BaseboardSettings(),
    );

    expect(vPieces.map((pPiece) => pPiece.lengthMm), [1601, 1600, 1600]);
  });

  test('une porte coupe la plinthe, coupe droite contre le chambranle', () {
    final vRoom = rectangleRoom();
    final vWithDoor = vRoom.copyWith(
      walls: [...vRoom.walls]
        ..[0] = const Wall(
          lengthMm: 4000,
          openings: [Opening(kind: OpeningKind.door, offsetMm: 300, widthMm: 830)],
        ),
    );
    final vPieces = baseboardPieces(vWithDoor, const BaseboardSettings());

    expect(vPieces.take(3).map((pPiece) => pPiece.lengthMm), [300, 1435, 1435]);
    expect(vPieces[0].startCut.kind, EndCutKind.insideMiter);
    expect(vPieces[0].endCut.kind, EndCutKind.square);
    expect(vPieces[1].startCut.kind, EndCutKind.square);
    expect(vPieces[2].endCut.kind, EndCutKind.insideMiter);
  });

  test('une porte au bout du mur ne laisse pas de morceau vide', () {
    const vRoom = Room(
      id: 'r',
      name: 'R',
      closed: false,
      walls: [
        Wall(
          lengthMm: 1000,
          openings: [Opening(kind: OpeningKind.passage, offsetMm: 0, widthMm: 1000)],
        ),
      ],
    );

    expect(baseboardPieces(vRoom, const BaseboardSettings()), isEmpty);
  });

  test('coin sortant de la pièce en L', () {
    final vPieces = baseboardPieces(lShapedRoom(), const BaseboardSettings(barLengthMm: 6000));

    expect(vPieces[2].endCut.kind, EndCutKind.outsideMiter);
    expect(vPieces[3].startCut.kind, EndCutKind.outsideMiter);
    expect(vPieces[1].endCut.kind, EndCutKind.insideMiter);
  });

  test('pièce ouverte et bout libre : coupes droites', () {
    final vOpen = rectangleRoom().copyWith(closed: false);
    final vOpenPieces = baseboardPieces(vOpen, const BaseboardSettings(barLengthMm: 5000));

    expect(vOpenPieces.first.startCut.kind, EndCutKind.square);
    expect(vOpenPieces.last.endCut.kind, EndCutKind.square);

    final vRoom = rectangleRoom();
    final vFree = vRoom.copyWith(
      walls: [...vRoom.walls]..[1] = const Wall(lengthMm: 3000, freeEndAfter: true),
    );
    final vFreePieces = baseboardPieces(vFree, const BaseboardSettings(barLengthMm: 5000));

    expect(vFreePieces[1].endCut.kind, EndCutKind.square);
    expect(vFreePieces[2].startCut.kind, EndCutKind.square);
  });

  test('un coin pas d\'équerre donne son propre angle', () {
    final vRoom = rectangleRoom();
    final vSkewed = vRoom.copyWith(
      walls: [...vRoom.walls]..[0] = const Wall(lengthMm: 4000, angleToNextDeg: 88),
    );
    final vPieces = baseboardPieces(vSkewed, const BaseboardSettings(barLengthMm: 5000));

    expect(vPieces[0].endCut.sawAngleDeg, 46);
    expect(vPieces[1].startCut.sawAngleDeg, 46);
  });

  group('fixations', () {
    test('colle : une cartouche pour 10 m de plinthe', () {
      final vPieces = baseboardPieces(rectangleRoom(), const BaseboardSettings());
      final vNeeds = fixingNeeds(vPieces, const BaseboardSettings());

      expect(vNeeds.cartridges, 2);
      expect(vNeeds.points, 0);
      expect(fixingNeeds(const [], const BaseboardSettings()).cartridges, 0);
    });

    test('clous ou clips : un à chaque bout et tous les 40 cm', () {
      const vSettings = BaseboardSettings(fixing: BaseboardFixing.nailed);
      final vNeeds = fixingNeeds(baseboardPieces(rectangleRoom(), vSettings), vSettings);

      expect(vNeeds.points, 44);
      expect(vNeeds.cartridges, 0);
    });
  });

  test('réglages et coupes faites se relisent depuis le JSON', () {
    const vSettings = BaseboardSettings(
      barLengthMm: 2200,
      kerfMm: 3,
      fixing: BaseboardFixing.clips,
      glueMetresPerCartridge: 8,
      fixingSpacingMm: 500,
    );
    final vRoom = rectangleRoom().copyWith(baseboard: vSettings, cutPieces: const [0, 3]);
    final vCopy = Room.fromJson(vRoom.toJson());

    expect(vCopy.baseboard.toJson(), vSettings.toJson());
    expect(vCopy.cutPieces, [0, 3]);
    expect(BaseboardSettings.fromJson(const {}).barLengthMm, 2400);
    expect(Room.fromJson({'id': 'r', 'name': 'R'}).cutPieces, isEmpty);
  });

  group('marge d\'erreur des coupes', () {
    Room irregular() => refitRoom(
      const Room(
        id: 'r',
        name: 'Salon',
        walls: [
          Wall(lengthMm: 3089),
          Wall(lengthMm: 4225),
          Wall(lengthMm: 2831),
          Wall(lengthMm: 4163),
        ],
      ),
    );

    test('une pièce mesurée à angles droits n\'a aucune incertitude', () {
      expect(cornerMargins(rectangleRoom()), everyElement(0));
      for (final vPiece in baseboardPieces(rectangleRoom(), const BaseboardSettings())) {
        expect(vPiece.startCut.marginDeg, 0);
        expect(vPiece.endCut.marginDeg, 0);
      }
    });

    test('des angles déduits de mesures approximatives gardent une marge', () {
      final vMargins = cornerMargins(irregular());

      expect(vMargins, hasLength(4));
      expect(vMargins.any((pMargin) => pMargin > 0), isTrue);
    });

    test('la marge est portée par les coupes des coins déduits', () {
      final vCuts = [
        for (final vPiece in baseboardPieces(irregular(), const BaseboardSettings()))
          ...[vPiece.startCut, vPiece.endCut],
      ].where((pCut) => pCut.kind != EndCutKind.scarf);

      expect(vCuts.any((pCut) => pCut.marginDeg > 0), isTrue);
    });

    test('une coupe droite n\'a pas de marge', () {
      expect(cornerCut(180, pMarginDeg: 1).marginDeg, 0);
      expect(cornerCut(88, pMarginDeg: 0.4).marginDeg, 0.4);
    });
  });
}
