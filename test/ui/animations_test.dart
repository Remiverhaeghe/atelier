import 'package:atelier/ui/gesture_scenes.dart';
import 'package:atelier/ui/notebook.dart';
import 'package:atelier/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  test('sciure et copeaux : des grains en l\'air qui retombent, rien quand l\'outil s\'arrête', () {
    final vGrains = dust(0.3, 50, 10, 8, pCount: 6);

    expect(vGrains, hasLength(6));
    expect(dust(0.3, 50, 10, 8, pActive: 0), isEmpty);
    // Plus tard dans sa course, le même grain est plus bas et plus petit
    double vTop(double pPhase) => dust(pPhase, 0, 0, 0, pCount: 1).single.profile.last.$2;
    expect(vTop(0.5), lessThan(vTop(0.1)));
  });

  testWidgets('le résultat change en remontant, puis seul le nouveau reste', (pTester) async {
    final vText = ValueNotifier('12 m²');
    await pTester.pumpWidget(
      localized(ValueListenableBuilder(valueListenable: vText, builder: (_, pValue, _) => BigFigure(pValue))),
    );
    vText.value = '14 m²';
    await pTester.pump(const Duration(milliseconds: 100));

    expect(find.text('12 m²'), findsOneWidget);
    expect(find.text('14 m²'), findsOneWidget);

    await pTester.pumpAndSettle();
    expect(find.text('12 m²'), findsNothing);
    expect(find.text('14 m²'), findsOneWidget);
  });

  testWidgets('page tournée à l\'ouverture d\'un écran, simple fondu si les animations sont coupées', (
    pTester,
  ) async {
    await pTester.pumpWidget(
      localized(
        Builder(
          builder: (pContext) => TextButton(
            onPressed: () => Navigator.push(
              pContext,
              MaterialPageRoute<void>(builder: (_) => const Text('page suivante')),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await pTester.tap(find.text('ouvrir'));
    await pTester.pump(const Duration(milliseconds: 80));
    expect(find.byType(PageTurn), findsWidgets);
    await pTester.pumpAndSettle();
    expect(find.text('page suivante'), findsOneWidget);

    await pTester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: localized(
          Builder(
            builder: (pContext) => TextButton(
              onPressed: () => Navigator.push(
                pContext,
                MaterialPageRoute<void>(builder: (_) => const Text('sans animation')),
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await pTester.tap(find.text('ouvrir'));
    await pTester.pump(const Duration(milliseconds: 80));
    expect(find.byType(PageTurn), findsNothing);
    await pTester.pumpAndSettle();
    expect(find.text('sans animation'), findsOneWidget);
  });
}
