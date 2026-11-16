import 'dart:convert';

import 'package:atelier/logic/parquet.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

/// Pièce de 400 cm le long du mur 1 et de [pDepthMm] de profondeur.
Room roomOf(int pDepthMm) => Room(
  id: 'r',
  name: 'R',
  walls: [
    const Wall(lengthMm: 4000),
    Wall(lengthMm: pDepthMm),
    const Wall(lengthMm: 4000),
    Wall(lengthMm: pDepthMm),
  ],
);

void main() {
  group('rangées', () {
    test('la largeur moins le jeu des deux côtés se découpe en lames', () {
      final vSplit = splitRows(rectangleRoom(), const ParquetSettings())!;

      // 3000 - 2 × 8 = 2984 mm, soit 15 lames de 193 mm et une dernière rangée de 89 mm
      expect(vSplit.rowCount, 16);
      expect(vSplit.firstRowWidthMm, 193);
      expect(vSplit.lastRowWidthMm, 89);
      expect(vSplit.balanced, isFalse);
    });

    test('une dernière rangée trop étroite est équilibrée avec la première', () {
      final vSplit = splitRows(roomOf(2941), const ParquetSettings())!;

      // 2925 mm utiles : 15 lames et 30 mm, trop peu ; les deux bords font 111 et 112 mm
      expect(vSplit.rowCount, 16);
      expect(vSplit.balanced, isTrue);
      expect(vSplit.firstRowWidthMm, 111);
      expect(vSplit.lastRowWidthMm, 112);
      expect(vSplit.firstRowWidthMm + vSplit.lastRowWidthMm + 14 * 193, 2925);
    });

    test('poser le long de l\'autre mur change le nombre de rangées', () {
      final vSplit = splitRows(rectangleRoom(), const ParquetSettings(layingWallIndex: 1))!;

      expect(vSplit.rowCount, 21);
      expect(vSplit.lastRowWidthMm, 124);
    });

    test('pièce en L : la largeur prise est la plus grande', () {
      final vSplit = splitRows(lShapedRoom(), const ParquetSettings())!;

      expect(vSplit.rowCount, 21);
    });

    test('une pièce plus étroite qu\'une lame tient en une rangée', () {
      final vSplit = splitRows(roomOf(150), const ParquetSettings())!;

      expect(vSplit.rowCount, 1);
      expect(vSplit.firstRowWidthMm, 134);
      expect(vSplit.lastRowWidthMm, 134);
    });

    test('rien à découper sans pièce ou sans lame', () {
      expect(splitRows(const Room(id: 'r', name: 'R'), const ParquetSettings()), isNull);
      expect(splitRows(rectangleRoom(), const ParquetSettings(plankWidthMm: 0)), isNull);
      expect(splitRows(roomOf(10), const ParquetSettings()), isNull);
    });
  });

  group('quantités', () {
    test('parquet flottant : paquets, lames et sous-couche', () {
      final vEstimate = estimateParquet(rectangleRoom(), const ParquetSettings());

      expect(vEstimate.floorAreaM2, closeTo(12, 0.0001));
      expect(vEstimate.areaWithWasteM2, closeTo(12.6, 0.0001));
      expect(vEstimate.packs, 6);
      expect(vEstimate.planks, 48);
      expect(vEstimate.underlayRolls, 1);
      expect(vEstimate.glueBuckets, 0);
      expect(vEstimate.nailBoxes, 0);
      expect(vEstimate.rows, isNotNull);
    });

    test('un paquet tout juste suffisant ne fait pas acheter le suivant', () {
      final vEstimate = estimateParquet(rectangleRoom(), const ParquetSettings(packAreaM2: 2.1));

      expect(vEstimate.packs, 6);
    });

    test('parquet collé : colle, sans sous-couche', () {
      final vEstimate = estimateParquet(
        rectangleRoom(),
        ParquetSettings.forType(ParquetType.glued),
      );

      expect(vEstimate.underlayRolls, 0);
      expect(vEstimate.glueBuckets, 1);
    });

    test('parquet massif cloué : marge de 7 % et boîtes de clous', () {
      final vSettings = ParquetSettings.forType(ParquetType.nailed);
      final vEstimate = estimateParquet(rectangleRoom(), vSettings);

      expect(vSettings.expansionGapMm, 12);
      expect(vEstimate.packs, 7);
      expect(vEstimate.nailBoxes, 1);
      expect(vEstimate.underlayRolls, 0);
    });

    test('point de Hongrie : lames gauches et droites, pas de rangées', () {
      final vSettings = ParquetSettings.forType(
        ParquetType.herringbone,
        pBase: const ParquetSettings(plankLengthMm: 600, plankWidthMm: 90),
      );
      final vEstimate = estimateParquet(rectangleRoom(), vSettings);

      expect(vSettings.wastePercent, 12);
      expect(vEstimate.planks, 249);
      expect(vEstimate.leftPlanks, 125);
      expect(vEstimate.rightPlanks, 125);
      expect(vEstimate.rows, isNull);
    });

    test('les zones sans parquet réduisent la commande', () {
      final vRoom = rectangleRoom(
        pObstacles: const [
          Obstacle(
            kind: ObstacleKind.cupboard,
            wallIndex: 1,
            offsetMm: 0,
            widthMm: 2000,
            depthMm: 1000,
          ),
        ],
      );

      expect(estimateParquet(vRoom, const ParquetSettings()).packs, 5);
    });

    test('une pièce vide ne demande rien', () {
      final vEstimate = estimateParquet(const Room(id: 'r', name: 'R'), const ParquetSettings());

      expect(vEstimate.packs, 0);
      expect(vEstimate.planks, 0);
      expect(vEstimate.underlayRolls, 0);
    });
  });

  test('changer de type reprend ses valeurs de départ et garde la lame', () {
    final vSettings = ParquetSettings.forType(
      ParquetType.glued,
      pBase: const ParquetSettings(plankLengthMm: 1200, wastePercent: 9),
    );

    expect(vSettings.type, ParquetType.glued);
    expect(vSettings.plankLengthMm, 1200);
    expect(vSettings.wastePercent, 5);
    expect(vSettings.expansionGapMm, 5);
  });

  test('les réglages se relisent depuis le JSON, valeurs absentes comprises', () {
    const vSettings = ParquetSettings(
      type: ParquetType.nailed,
      plankLengthMm: 2000,
      plankWidthMm: 140,
      packAreaM2: 1.68,
      layingWallIndex: 2,
      expansionGapMm: 15,
      wastePercent: 8,
      minJointOffsetMm: 400,
      underlayRollAreaM2: 10,
      glueCoverageM2: 12,
      nailsPerM2: 25,
      nailsPerBox: 1000,
    );
    final vCopy = ParquetSettings.fromJson(
      jsonDecode(jsonEncode(vSettings.toJson())) as Map<String, Object?>,
    );

    expect(jsonEncode(vCopy.toJson()), jsonEncode(vSettings.toJson()));
    expect(ParquetSettings.fromJson({'type': 'floating'}).plankLengthMm, 1380);

    final vRoom = rectangleRoom().copyWith(parquet: vSettings);
    final vRoomCopy = Room.fromJson(jsonDecode(jsonEncode(vRoom.toJson())) as Map<String, Object?>);
    expect(vRoomCopy.parquet.layingWallIndex, 2);
  });

  test('barres de seuil : seulement les ouvertures cochées, selon leur largeur', () {
    final vRoom = rectangleRoom().copyWith(
      walls: [
        const Wall(
          lengthMm: 4000,
          openings: [
            Opening(kind: OpeningKind.door, offsetMm: 200, widthMm: 830, threshold: true),
            Opening(kind: OpeningKind.passage, offsetMm: 1500, widthMm: 1400, threshold: true),
            Opening(kind: OpeningKind.door, offsetMm: 3000, widthMm: 730),
          ],
        ),
        const Wall(lengthMm: 3000),
        const Wall(lengthMm: 4000),
        const Wall(lengthMm: 3000),
      ],
    );

    // 83 cm : une barre de 93 cm ; 140 cm : deux barres
    expect(thresholdBars(vRoom, const ParquetSettings()), 3);
    expect(thresholdBars(vRoom, const ParquetSettings(thresholdBarLengthMm: 0)), 0);
    expect(thresholdBars(vRoom, const ParquetSettings(thresholdBarLengthMm: 1500)), 2);

    final vBack = Room.fromJson(vRoom.toJson());
    expect(vBack.walls.first.openings.map((pOpening) => pOpening.threshold), [true, true, false]);
    expect(
      ParquetSettings.fromJson(
        const ParquetSettings(thresholdBarLengthMm: 1200).toJson(),
      ).thresholdBarLengthMm,
      1200,
    );
  });
}
