import 'package:atelier/logic/quality_checks.dart';
import 'package:atelier/logic/tool_safety.dart';
import 'package:atelier/logic/trades.dart';
import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/quality_screen.dart';
import 'package:atelier/ui/tool_safety_screen.dart';
import 'package:atelier/ui/trades_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('par où commencer : la fiche du carrelage dit le temps, les outils et la location', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Par où commencer');
    await pTester.tap(find.text('Par où commencer'));
    await pTester.pumpAndSettle();
    expect(find.text('À confier à un pro'), findsOneWidget);

    await pTester.tap(find.text('Carrelage'));
    await pTester.pumpAndSettle();
    expect(find.text('Débutant : 24 à 36 h'), findsOneWidget);
    expect(find.text('Malaxeur (à louer)'), findsOneWidget);
    expect(find.text('À louer : 1, 15 à 30 € par jour'), findsOneWidget);
    expect(find.textContaining('axe tracé'), findsOneWidget);
  });

  testWidgets('l\'électricité dit ce qu\'on fait seul et ce qu\'on confie', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const TradeScreen(trade: Trade.electricity)));
    expect(find.text('Ce que tu peux faire, ce qu\'on confie'), findsOneWidget);
    expect(find.text('Testeur de tension (VAT)'), findsOneWidget);
  });

  testWidgets('contrôle coché et photo gardés dans la pièce', (pTester) async {
    tallScreen(pTester);
    var vRoom = rectangleRoom();
    await pTester.pumpWidget(
      localized(
        QualityScreen(
          room: vRoom,
          onChanged: (pRoom) => vRoom = pRoom,
          photos: (pId) async => '/photos/$pId.jpg',
        ),
      ),
    );
    expect(find.text('0 sur 2'), findsNWidgets(4));

    await pTester.tap(find.text('Traçage d\'équerre'));
    await pTester.pump();
    expect(vRoom.doneSteps, contains(qualityKey(QualityCheck.layoutSquare)));
    expect(find.text('1 sur 2'), findsOneWidget);

    await pTester.tap(find.byTooltip('Photo du contrôle').first);
    await pTester.pumpAndSettle();
    expect(vRoom.stepPhotos[qualityKey(QualityCheck.layoutSquare)], hasLength(1));
  });

  testWidgets('une mesure hors tolérance est à reprendre', (pTester) async {
    await pTester.pumpWidget(
      localized(const QualityMeasureDialog(check: QualityCheck.layoutSquare)),
    );
    await pTester.enterText(find.byType(TextField).first, '500');
    await pTester.enterText(find.byType(TextField).last, '499,6');
    await pTester.pump();
    expect(find.text('Bon : 4 mm d\'écart pour 5 mm tolérés'), findsOneWidget);

    await pTester.enterText(find.byType(TextField).last, '498');
    await pTester.pump();
    expect(find.text('À reprendre : 20 mm d\'écart pour 5 mm tolérés'), findsOneWidget);
  });

  testWidgets('sans pièce, pas de photo, et la règle n\'a qu\'un champ', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const QualityScreen()));
    expect(find.byTooltip('Photo du contrôle'), findsNothing);
    expect(find.textContaining('Ouverts depuis le guide'), findsOneWidget);

    await pTester.pumpWidget(localized(const QualityMeasureDialog(check: QualityCheck.floorFlat)));
    expect(find.byType(TextField), findsOneWidget);
    await pTester.enterText(find.byType(TextField), '7');
    await pTester.pump();
    expect(find.text('À reprendre : 7 mm d\'écart pour 5 mm tolérés'), findsOneWidget);
  });

  testWidgets('scie circulaire : prête quand tout est coché', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const ToolSafetyScreen()));
    await pTester.tap(find.text('Scie circulaire'));
    await pTester.pumpAndSettle();
    expect(find.text('Avant de brancher'), findsOneWidget);
    expect(find.textContaining('Pas de gants amples'), findsOneWidget);

    for (var vIndex = 0; vIndex < SafetyTool.circularSaw.checks; vIndex++) {
      await pTester.tap(find.byType(CheckboxListTile).at(vIndex));
    }
    await pTester.pump();
    expect(find.text('Tout est vérifié : tu peux commencer.'), findsOneWidget);
  });

  testWidgets('chaque fiche a autant de textes que sa logique en annonce', (pTester) async {
    tallScreen(pTester);
    for (final vTool in SafetyTool.values) {
      await pTester.pumpWidget(localized(ToolSafetySheet(tool: vTool)));
      expect(find.byType(CheckboxListTile), findsNWidgets(vTool.checks), reason: vTool.name);
      expect(find.byIcon(Icons.block), findsNWidgets(vTool.forbidden), reason: vTool.name);
    }
  });

  testWidgets('échelle : pied au quart et longueur', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const ToolSafetySheet(tool: SafetyTool.ladder)));
    expect(find.text('Avant de monter'), findsOneWidget);
    expect(
      find.textContaining('Pied à 75 cm du mur ; échelle de 309,2 cm au moins, 409,2 cm'),
      findsOneWidget,
    );
  });
}
