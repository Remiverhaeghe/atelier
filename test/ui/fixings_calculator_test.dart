import 'package:atelier/logic/fixings.dart';
import 'package:atelier/ui/fixings_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('cheville : le conseil suit le support et le poids', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const FixingsCalculator()));

    // 20 kg sur placo : 3 points de 15 kg, chevilles métal
    expect(find.text('Cheville métal à expansion'), findsOneWidget);
    expect(find.text('3 points de fixation au moins'), findsOneWidget);

    await pTester.tap(find.byType(DropdownButtonFormField<WallSupport>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Béton').last);
    await pTester.pumpAndSettle();
    expect(find.text('Cheville nylon universelle'), findsOneWidget);
    expect(find.text('Foret de 8 mm'), findsOneWidget);
  });
}
