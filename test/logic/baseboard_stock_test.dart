import 'package:atelier/logic/bar_cutting.dart';
import 'package:atelier/logic/baseboard.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/room_json.dart';
import 'package:atelier/logic/shopping.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

Room openWall(int pLengthMm) => Room(
  id: 'r',
  name: 'R',
  walls: [Wall(lengthMm: pLengthMm)],
  closed: false,
);

void main() {
  group('débord des onglets', () {
    test('un coin sortant déborde côté face de l\'épaisseur fois la tangente', () {
      const vPiece = BaseboardPiece(
        wallNumber: 1,
        lengthMm: 2000,
        startCut: EndCut(EndCutKind.insideMiter, 45),
        endCut: EndCut(EndCutKind.outsideMiter, 45),
      );

      expect(vPiece.stockMm(15), 2015);
      expect(vPiece.stockMm(20), 2020);
    });

    test('un coin rentrant ne déborde pas, la pointe longue est au dos', () {
      const vPiece = BaseboardPiece(
        wallNumber: 1,
        lengthMm: 2000,
        startCut: EndCut(EndCutKind.insideMiter, 45),
        endCut: EndCut(EndCutKind.insideMiter, 45),
      );

      expect(vPiece.stockMm(15), 2000);
    });

    test('un biseau de jonction déborde à sa fin et pas à son début', () {
      const vFirst = BaseboardPiece(
        wallNumber: 1,
        lengthMm: 1600,
        startCut: EndCut.square,
        endCut: EndCut(EndCutKind.scarf, 45),
      );
      const vSecond = BaseboardPiece(
        wallNumber: 1,
        lengthMm: 1600,
        startCut: EndCut(EndCutKind.scarf, 45),
        endCut: EndCut.square,
      );

      expect(vFirst.stockMm(15), 1615);
      expect(vSecond.stockMm(15), 1600);
    });

    test('un angle de 30° déborde moins qu\'un onglet à 45°', () {
      const vPiece = BaseboardPiece(
        wallNumber: 1,
        lengthMm: 1000,
        startCut: EndCut(EndCutKind.outsideMiter, 30),
        endCut: EndCut.square,
      );

      expect(vPiece.stockMm(15), 1009);
    });

    test('un morceau qui tient dans une barre au dos mais plus avec son débord est refusé', () {
      const vPiece = BaseboardPiece(
        wallNumber: 1,
        lengthMm: 2395,
        startCut: EndCut(EndCutKind.outsideMiter, 45),
        endCut: EndCut.square,
      );
      final vPlan = planBars([vPiece.lengthMm], 2400, 2, pStock: [vPiece.stockMm(15)]);

      expect(planBars([vPiece.lengthMm], 2400, 2).tooLong, isEmpty);
      expect(vPlan.tooLong, [0]);
    });

    test('le débord compte dans la place prise par les morceaux d\'une même barre', () {
      final vPlan = planBars([1190, 1190], 2400, 2, pStock: [1205, 1205]);

      // 1205 + 2 + 1205 dépasse 2400 : deux barres, alors que 1190 + 2 + 1190 tiendrait
      expect(vPlan.bars, hasLength(2));
      expect(planBars([1190, 1190], 2400, 2).bars, hasLength(1));
    });

    test('un mur de deux barres exactes passe à trois morceaux : le biseau déborde', () {
      final vPieces = baseboardPieces(openWall(4800), const BaseboardSettings());

      expect(vPieces.map((pPiece) => pPiece.lengthMm), [1600, 1600, 1600]);
      expect(vPieces.every((pPiece) => pPiece.stockMm(15) <= 2400), isTrue);
    });

    test('une épaisseur nulle retrouve la découpe sans débord', () {
      final vPieces = baseboardPieces(openWall(4800), const BaseboardSettings(thicknessMm: 0));

      expect(vPieces.map((pPiece) => pPiece.lengthMm), [2400, 2400]);
    });
  });

  group('moins de barres', () {
    const vFewest = BaseboardSettings(fewestBars: true);

    test('barres entières puis un reste, le débord du biseau pris sur la barre', () {
      final vPieces = baseboardPieces(rectangleRoom(), vFewest);

      expect(vPieces.take(2).map((pPiece) => pPiece.lengthMm), [2385, 1615]);
      expect(vPieces.map((pPiece) => pPiece.wallNumber), [1, 1, 2, 2, 3, 3, 4, 4]);
      expect(vPieces.every((pPiece) => pPiece.stockMm(15) <= 2400), isTrue);
      expect(vPieces.fold<int>(0, (pSum, pPiece) => pSum + pPiece.lengthMm), 14000);
    });

    test('la pièce de 4 × 3 m tient en 6 barres au lieu de 8', () {
      int bars(BaseboardSettings pSettings) {
        final vRoom = rectangleRoom().copyWith(baseboard: pSettings);

        return roomQuantities(vRoom)[ShoppingItem.baseboardBars]!;
      }

      expect(bars(const BaseboardSettings()), 8);
      expect(bars(vFewest), 6);
    });

    test('un reste trop court pour être posé ramène à des morceaux égaux', () {
      final vPieces = baseboardPieces(openWall(2500), vFewest);

      expect(vPieces.map((pPiece) => pPiece.lengthMm), [1250, 1250]);
    });

    test('un mur plus court qu\'une barre reste d\'un seul morceau', () {
      expect(baseboardPieces(openWall(2000), vFewest).map((pPiece) => pPiece.lengthMm), [2000]);
    });
  });

  group('réglages', () {
    test(
      'une pièce neuve coupe en moins de barres, une pièce enregistrée avant garde ses morceaux égaux',
      () {
        final vSaved = roomToJson(rectangleRoom())..remove('baseboard');

        expect(rectangleRoom().baseboard.fewestBars, isTrue);
        expect(roomFromJson(vSaved).baseboard.fewestBars, isFalse);
      },
    );

    test('épaisseur et moins de barres font l\'aller-retour', () {
      const vSettings = BaseboardSettings(thicknessMm: 18, fewestBars: true);
      final vBack = BaseboardSettings.fromJson(vSettings.toJson());

      expect(vBack.thicknessMm, 18);
      expect(vBack.fewestBars, isTrue);
    });

    test('un réglage enregistré avant garde 15 mm et les morceaux égaux', () {
      final vBack = BaseboardSettings.fromJson(const {'barLengthMm': 2400});

      expect(vBack.thicknessMm, 15);
      expect(vBack.fewestBars, isFalse);
    });
  });
}
