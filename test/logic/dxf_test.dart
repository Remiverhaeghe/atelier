import 'package:atelier/logic/dxf.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('noms de calque sans accent ni espace', () {
    expect(dxfLayer('Séjour côté jardin'), 'SEJOUR_COTE_JARDIN');
    expect(dxfLayer('***'), '_');
    expect(dxfLayer(''), 'PIECE');
  });

  test('une ligne par mur, le nom de la pièce, fin de fichier', () {
    final vText = buildDxf([rectangleRoom(), lShapedRoom(), const Room(id: 'v', name: 'Vide')]);
    final vLines = vText.split('\n');
    expect(vLines.where((pLine) => pLine == 'LINE'), hasLength(4 + 6));
    expect(vText, contains('SALON'));
    expect(vText, contains('\n1\nSéjour\n'));
    expect(vLines.first, '0');
    expect(vText.trimRight(), endsWith('EOF'));
    // Le premier mur du salon va de l'origine à 4 m
    expect(vText, contains('10\n0.0\n20\n0.0\n11\n4000.0\n21\n0.0\n'));
  });
}
