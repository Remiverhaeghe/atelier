import 'dart:async';

import 'package:atelier/ui/laser_link.dart';
import 'package:atelier/ui/laser_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

/// Télémètre fictif : un appareil trouvé, des mesures envoyées à la demande.
class _FakeLink implements LaserLink {
  final measuresOut = StreamController<int>(sync: true);

  @override
  Stream<LaserDevice> scan() => Stream.value((id: 'aa:bb', name: 'GLM 50 C'));

  @override
  Stream<int> measures(String pDeviceId) => measuresOut.stream;
}

void main() {
  testWidgets('télémètre : appareil choisi, mesure reprise', (pTester) async {
    final vLink = _FakeLink();
    int? vResult;
    await pTester.pumpWidget(
      localized(
        Builder(
          builder: (pContext) => TextButton(
            onPressed: () async => vResult = await measureWithLaser(pContext, pLink: vLink),
            child: const Text('mesurer'),
          ),
        ),
      ),
    );
    await pTester.tap(find.text('mesurer'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('GLM 50 C'));
    await pTester.pumpAndSettle();
    expect(find.text('Mesurez avec le bouton du télémètre'), findsOneWidget);

    vLink.measuresOut.add(3214);
    await pTester.pump();
    expect(find.text('321,4 cm'), findsOneWidget);
    await pTester.tap(find.text('Reprendre cette mesure'));
    await pTester.pumpAndSettle();
    expect(vResult, 3214);
  });
}
