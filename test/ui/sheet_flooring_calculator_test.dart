import 'package:atelier/ui/sheet_flooring_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('sol souple : un lé en 4 m, puis deux lés en 2 m', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(SheetFlooringCalculator(rooms: [lShapedRoom()])));
    expect(find.text('310 cm de rouleau à commander'), findsOneWidget);
    expect(find.text('1 lé de 310 cm'), findsOneWidget);

    await pTester.tap(find.text('2 m'));
    await pTester.pumpAndSettle();
    expect(find.text('2 lés de 310 cm'), findsOneWidget);
    expect(find.text('1 joint à souder ou à coller'), findsOneWidget);

    await pTester.tap(find.byType(DropdownButtonFormField<String?>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Séjour').last);
    await pTester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '5000'), findsOneWidget);
  });
}
