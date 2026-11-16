import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/touch_up.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vPaint = TouchUp(id: 'p', label: 'Peinture', passes: 3);

  test('cocher une case coche celles d\'avant, la décocher retire celles d\'après', () {
    final vThird = vPaint.togglePass(2);
    expect(vThird.donePasses, 3);
    expect(vThird.done, isTrue);

    expect(vThird.togglePass(1).donePasses, 1);
    expect(vThird.togglePass(0).donePasses, 0);
    expect(vPaint.togglePass(0).donePasses, 1);
  });

  test('les passages faits ne dépassent jamais les passages prévus', () {
    expect(vPaint.togglePass(7).donePasses, 3);
    expect(vPaint.copyWith(donePasses: 2).copyWith(passes: 1).donePasses, 1);
  });

  test('repère et photo se posent et se retirent', () {
    final vPlaced = vPaint.copyWith(markerXMm: 1200, markerYMm: 800, photoPath: '/p.jpg');
    expect(vPlaced.hasMarker, isTrue);
    expect(vPlaced.photoPath, '/p.jpg');

    final vCleared = vPlaced.copyWith(clearMarker: true, clearPhoto: true);
    expect(vCleared.hasMarker, isFalse);
    expect(vCleared.photoPath, isNull);
  });

  test('une reprise relue depuis le JSON est identique, champs vides omis', () {
    const vFull = TouchUp(
      id: 'f',
      label: 'Enduit',
      passes: 4,
      donePasses: 1,
      note: 'Enduit de lissage',
      toBuy: 'Sac d\'enduit 5 kg',
      markerXMm: 300,
      markerYMm: 450,
      photoPath: '/photos/f.jpg',
    );
    final vRoom = const Room(id: 'r', name: 'Couloir').copyWith(touchUps: [vFull, vPaint]);
    final vBack = Room.fromJson(vRoom.toJson()).touchUps;

    expect(vBack.first.toJson(), vFull.toJson());
    expect(vBack.last.toJson(), {'id': 'p', 'label': 'Peinture', 'passes': 3, 'donePasses': 0});
  });

  test('un JSON abîmé garde au moins un passage', () {
    final vTouchUp = TouchUp.fromJson({'id': 'x', 'label': 'X', 'passes': 0, 'donePasses': 5});

    expect(vTouchUp.passes, 1);
    expect(vTouchUp.donePasses, 1);
  });

  test('passages comptés et achats des reprises pas finies', () {
    final vList = [
      vPaint.copyWith(donePasses: 1, toBuy: 'Pot de peinture'),
      const TouchUp(id: 'g', label: 'Grille', passes: 2, donePasses: 2, toBuy: 'Grille'),
      const TouchUp(id: 'v', label: 'Vis escalier'),
    ];

    expect(touchUpPasses(vList), (done: 3, total: 6));
    expect(touchUpPurchases(vList), ['Pot de peinture']);
  });
}
