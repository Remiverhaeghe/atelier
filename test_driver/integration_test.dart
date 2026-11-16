import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Pilote de `flutter drive` : chaque capture prise sur le téléphone est écrite dans build/.
Future<void> main() => integrationDriver(
  onScreenshot: (pName, pBytes, [pArgs]) async {
    final vFile = File('build/captures-play/$pName.png');
    vFile.parent.createSync(recursive: true);
    vFile.writeAsBytesSync(pBytes);

    return true;
  },
);
