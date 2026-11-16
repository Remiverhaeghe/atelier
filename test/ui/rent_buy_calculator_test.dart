import 'package:atelier/ui/rent_buy_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('louer ou acheter : seuil et conseil selon les jours', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const RentBuyCalculator()));
    await pTester.enterText(find.widgetWithText(TextField, "Prix d'achat (€)"), '300');
    await pTester.enterText(find.widgetWithText(TextField, 'Location par jour (€)'), '40');
    await pTester.pump();
    expect(find.text('Acheter est rentable à partir de 8 jours'), findsOneWidget);
    expect(find.textContaining('Louez'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, "Jours d'utilisation"), '10');
    await pTester.pump();
    expect(find.textContaining('Achetez'), findsOneWidget);
    expect(find.text('Location : 400,00 €'), findsOneWidget);
  });
}
