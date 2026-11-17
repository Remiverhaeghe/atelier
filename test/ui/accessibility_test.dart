import 'package:atelier/app.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/worksite_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

/// Règles d'accessibilité d'Android et de Flutter : boutons nommés pour TalkBack, cibles d'au
/// moins 48 dp, texte lisible sur son fond.
Future<void> _checkGuidelines(WidgetTester pTester) async {
  final vHandle = pTester.ensureSemantics();
  await expectLater(pTester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(pTester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(pTester, meetsGuideline(textContrastGuideline));
  vHandle.dispose();
}

void main() {
  testWidgets('accueil vide', (pTester) async {
    final vController = WorksitesController(MemoryStorage());
    await vController.load();
    await pTester.pumpWidget(AtelierApp(controller: vController));
    await pTester.pumpAndSettle();
    await _checkGuidelines(pTester);
  });

  testWidgets('chantier avec une pièce', (pTester) async {
    tallScreen(pTester);
    final vController = WorksitesController(
      MemoryStorage()
        ..saved = [
          Worksite(id: 'w', name: 'Maison démo', rooms: [rectangleRoom()]),
        ],
    );
    await vController.load();
    await pTester.pumpWidget(
      localized(
        WorksiteScreen(controller: vController, worksiteId: 'w', today: DateTime(2026, 11, 17)),
      ),
    );
    await pTester.pumpAndSettle();
    await _checkGuidelines(pTester);
  });

  testWidgets('calculs', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.pumpAndSettle();
    await _checkGuidelines(pTester);
  });
}
