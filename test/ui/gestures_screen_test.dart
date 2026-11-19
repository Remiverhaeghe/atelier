import 'package:atelier/logic/gestures.dart';
import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/gestures_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('gestes : raboter, son croquis animé et le mot « fil du bois »', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.tap(find.text('Gestes de base'));
    await pTester.pumpAndSettle();
    expect(find.text('Creuser une mortaise'), findsOneWidget);

    await pTester.tap(find.text('Raboter'));
    // L'animation joue quelques passes puis s'arrête : pumpAndSettle finit
    await pTester.pumpAndSettle();
    expect(find.byType(GestureSketch), findsOneWidget);
    expect(find.textContaining('1. Règle le fer'), findsOneWidget);
    expect(find.textContaining('contre-fil'), findsWidgets);
    expect(find.text('À porter'), findsNothing);

    await pTester.tap(find.text('Rejouer le geste'));
    await pTester.pump(const Duration(milliseconds: 500));
    expect(pTester.binding.hasScheduledFrame, isTrue);
    await pTester.pumpAndSettle();

    await pTester.ensureVisible(find.widgetWithText(ActionChip, 'Fil du bois'));
    await pTester.tap(find.widgetWithText(ActionChip, 'Fil du bois'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('à contre-fil, il s\'arrache'), findsOneWidget);
  });

  testWidgets('percer : lunettes, et pas de gants avec un outil qui tourne', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const GestureScreen(gesture: Gesture.drill)));
    await pTester.pumpAndSettle();
    expect(find.text('Lunettes'), findsOneWidget);
    expect(find.textContaining('Pas de gants'), findsOneWidget);
  });

  testWidgets('chaque geste se dessine, du début à la fin de son animation', (pTester) async {
    tallScreen(pTester);
    for (final vGesture in Gesture.values) {
      await pTester.pumpWidget(localized(GestureScreen(key: ValueKey(vGesture), gesture: vGesture)));
      for (var vStep = 0; vStep < 8; vStep++) {
        await pTester.pump(gesturePassDuration ~/ 4);
      }
      await pTester.pumpAndSettle();
      expect(pTester.takeException(), isNull, reason: vGesture.name);
    }
  });

  testWidgets('animations coupées sur le téléphone : l\'outil est montré au bout du geste', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(
      localized(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: GestureScreen(gesture: Gesture.saw),
        ),
      ),
    );
    await pTester.pump();
    expect(pTester.binding.hasScheduledFrame, isFalse);
  });
}
