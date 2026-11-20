import 'dart:async';
import 'dart:ui';

import 'package:atelier/logic/units.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les tests lisent les textes français : le téléphone simulé parle français, quelle que soit
/// la langue de la machine, et les nombres repartent avec la virgule.
///
/// Un test qui veut l'anglais change la langue dans son propre corps.
Future<void> testExecutable(FutureOr<void> Function() pTestMain) async {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.localesTestValue = const [
      Locale('fr', 'FR'),
    ];
    aDecimalSeparator = ',';
  });
  await pTestMain();
}
