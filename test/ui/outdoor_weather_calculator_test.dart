import 'package:atelier/ui/outdoor_weather_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('météo : la pluie retire le jour et la veille', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const OutdoorWeatherCalculator()));
    expect(find.text('Jours possibles : 1, 2, 3, 4, 5'), findsOneWidget);

    await pTester.tap(find.byType(Switch).at(2));
    await pTester.pump();
    expect(find.text('Jours possibles : 1, 4, 5'), findsOneWidget);
    expect(find.text('pluie juste après'), findsOneWidget);

    await pTester.enterText(find.byKey(const ValueKey('min-0')), '-3');
    await pTester.pump();
    expect(find.text('Jours possibles : 4, 5'), findsOneWidget);
  });
}
