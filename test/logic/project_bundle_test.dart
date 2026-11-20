import 'dart:convert';

import 'package:atelier/logic/project_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vJson = '''
{"formatVersion": 9, "worksites": [{"id": "w", "name": "Maison démo", "rooms": [
  {"id": "r", "touchUps": [{"id": "t", "label": "Fissure", "photoPath": "/a/photos/t-1.jpg"}]}],
  "journal": [{"id": "j", "photoPath": "/a/photos/j.jpg", "beforePath": "/a/photos/j0.jpg",
  "invoicePath": null}],
  "expenses": [{"id": "e", "receiptPath": "/a/photos/ticket.jpg"}]}]}''';

  test('les photos, factures et tickets du chantier sont trouvés', () {
    expect(attachedPaths(jsonDecode(vJson)), {
      '/a/photos/t-1.jpg',
      '/a/photos/j.jpg',
      '/a/photos/j0.jpg',
      '/a/photos/ticket.jpg',
    });
    expect(attachedPaths(null), isEmpty);
  });

  test('un projet complet se relit avec ses photos', () {
    final vText = encodeProjectBundle(vJson, {
      '/a/photos/j.jpg': [1, 2, 3],
    });
    expect(isProjectBundle(vText), isTrue);
    expect(isProjectBundle(vJson), isFalse);
    expect(isProjectBundle('pas du json'), isFalse);
    final vBundle = decodeProjectBundle(vText);
    expect(vBundle.files['/a/photos/j.jpg'], [1, 2, 3]);
    expect(attachedPaths(vBundle.worksites), hasLength(4));
    expect(() => decodeProjectBundle(vJson), throwsFormatException);
    expect(
      () => decodeProjectBundle(jsonEncode({'format': projectBundleFormat})),
      throwsFormatException,
    );
  });

  test('les chemins recopiés remplacent les anciens, les autres restent', () {
    final vMoved = relocatePaths(jsonDecode(vJson), {'/a/photos/j.jpg': '/b/photos/x-j.jpg'});
    final vPaths = attachedPaths(vMoved);
    expect(vPaths, contains('/b/photos/x-j.jpg'));
    expect(vPaths, isNot(contains('/a/photos/j.jpg')));
    expect(vPaths, contains('/a/photos/ticket.jpg'));
    expect(jsonEncode(vMoved), contains('Maison démo'));
  });

  test('le fichier recopié garde son nom, sans caractère gênant', () {
    expect(importedName('/a/photos/t-1.jpg', '17'), '17-t-1.jpg');
    expect(importedName(r'C:\photos\mur nord.jpg', '17'), '17-mur_nord.jpg');
  });
}
