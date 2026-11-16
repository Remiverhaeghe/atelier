import 'package:atelier/logic/furniture.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

Furniture _item(String pId, FurnitureKind pKind, int pX, int pY, {bool pTurned = false}) =>
    Furniture(
      id: pId,
      kind: pKind,
      xMm: pX,
      yMm: pY,
      widthMm: pKind.widthMm,
      depthMm: pKind.depthMm,
      turned: pTurned,
    );

List<(FurnitureIssueKind, String, int?, int?, String?)> _issues(Room pRoom) => [
  for (final vIssue in furnitureIssues(pRoom))
    (vIssue.kind, vIssue.furnitureId, vIssue.wallIndex, vIssue.gapMm, vIssue.otherId),
];

void main() {
  test('lit et armoire contre les murs : rien à redire', () {
    final vRoom = rectangleRoom().copyWith(
      furniture: [
        _item('lit', FurnitureKind.doubleBed, 700, 950, pTurned: false),
        _item('armoire', FurnitureKind.wardrobe, 3500, 2700),
      ],
    );

    expect(furnitureIssues(vRoom), isEmpty);
  });

  test('bureau trop près du mur, du lit et de l\'armoire', () {
    final vRoom = rectangleRoom().copyWith(
      furniture: [
        _item('lit', FurnitureKind.doubleBed, 700, 950),
        _item('armoire', FurnitureKind.wardrobe, 3500, 2700),
        _item('bureau', FurnitureKind.desk, 2200, 2300),
      ],
    );
    final vIssues = _issues(vRoom);

    expect(vIssues, contains((FurnitureIssueKind.passage, 'bureau', 2, 400, null)));
    expect(vIssues, contains((FurnitureIssueKind.passage, 'lit', null, 224, 'bureau')));
    expect(vIssues, contains((FurnitureIssueKind.passage, 'armoire', null, 200, 'bureau')));
  });

  test('porte gênée, meuble hors de la pièce, meubles l\'un sur l\'autre', () {
    final vRoom = rectangleRoom().copyWith(
      walls: [
        const Wall(
          lengthMm: 4000,
          openings: [Opening(kind: OpeningKind.door, offsetMm: 2500, widthMm: 830)],
        ),
        ...rectangleRoom().walls.skip(1),
      ],
      furniture: [
        _item('commode', FurnitureKind.chest, 2900, 400),
        _item('canape', FurnitureKind.sofa, 100, 100),
        _item('table', FurnitureKind.table, 1500, 2000),
        _item('table2', FurnitureKind.table, 1600, 2100),
      ],
    );
    final vIssues = _issues(vRoom);

    expect(vIssues, contains((FurnitureIssueKind.door, 'commode', 0, null, null)));
    expect(vIssues, contains((FurnitureIssueKind.outside, 'canape', null, null, null)));
    expect(vIssues, contains((FurnitureIssueKind.overlap, 'table', null, null, 'table2')));
  });

  test('meuble tourné, aller-retour JSON, pièce sans murs', () {
    final vTurned = _item('a', FurnitureKind.desk, 1000, 1000, pTurned: true);
    expect(vTurned.corners.first.x, 700);
    expect(vTurned.corners.first.y, 400);

    final vRoom = rectangleRoom().copyWith(furniture: [vTurned]);
    final vBack = Room.fromJson(vRoom.toJson()).furniture.single;
    expect((vBack.kind, vBack.turned, vBack.widthMm), (FurnitureKind.desk, true, 1200));
    expect(Furniture.fromJson({...vTurned.toJson(), 'kind': 'inconnu'}).kind, FurnitureKind.other);
    expect(rectangleRoom().toJson().containsKey('furniture'), isFalse);
    expect(vTurned.copyWith(xMm: 5).xMm, 5);
    expect(furnitureIssues(const Room(id: 'v', name: 'Vide')), isEmpty);
  });
}
