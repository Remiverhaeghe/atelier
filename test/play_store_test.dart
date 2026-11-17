import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Texte d'une section de la fiche, sans les lignes vides du bord.
String _section(String pText, String pTitle) {
  final vStart = pText.indexOf('## $pTitle');
  final vEnd = pText.indexOf('\n## ', vStart + 3);

  return pText.substring(vStart + pTitle.length + 3, vEnd < 0 ? pText.length : vEnd).trim();
}

void main() {
  test('fiche Play Store dans les limites de la console', () {
    final vText = File('docs/play-store/description.md').readAsStringSync();
    final vShort = _section(vText, 'Description courte');
    final vLong = _section(vText, 'Description longue');
    expect(vShort.length, inInclusiveRange(10, 80), reason: vShort);
    expect(vLong.length, inInclusiveRange(200, 4000));
    expect(vLong, isNot(contains('Generated')));
  });
}
