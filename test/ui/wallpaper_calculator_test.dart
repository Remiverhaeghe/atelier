import 'package:atelier/ui/wallpaper_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('papier peint : rouleaux, puis plafond de 5,50 m', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(WallpaperCalculator(rooms: [rectangleRoom()])));
    expect(find.text('10 rouleaux'), findsOneWidget);
    expect(find.text('3 lés par rouleau'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, '2500'), '5500');
    await pTester.pump();
    expect(find.text('1 lé par rouleau'), findsOneWidget);
    expect(find.text('28 rouleaux'), findsOneWidget);
  });
}
