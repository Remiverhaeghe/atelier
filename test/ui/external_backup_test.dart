import 'package:atelier/logic/app_settings.dart';
import 'package:atelier/logic/whats_new.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/settings_controller.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/worksites_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/memory_settings.dart';

void main() {
  final vNow = DateTime(2026, 11, 16, 10);

  Future<(MemorySettings, List<int>)> pumpList(WidgetTester pTester, DateTime? pLast) async {
    // Nouveautés déjà vues : la fenêtre ne cache pas le rappel de sauvegarde
    final vStore = MemorySettings()
      ..saved = AppSettings(lastExternalBackup: pLast, newsSeen: newsVersion);
    final vSettings = SettingsController(vStore);
    await vSettings.load();
    final vStorage = MemoryStorage()..saved = [const Worksite(id: 'w', name: 'Maison démo')];
    final vController = WorksitesController(vStorage);
    await vController.load();
    final vSent = <int>[];
    await pTester.pumpWidget(
      localized(
        WorksitesScreen(
          controller: vController,
          settings: vSettings,
          now: () => vNow,
          onExternalBackup: (pWorksites, _) async => vSent.add(pWorksites.length),
        ),
      ),
    );
    await pTester.pumpAndSettle();

    return (vStore, vSent);
  }

  testWidgets('jamais sauvegardé : rappel, envoi, puis plus de rappel', (pTester) async {
    final (vStore, vSent) = await pumpList(pTester, null);
    expect(find.textContaining('Jamais faite'), findsOneWidget);

    await pTester.tap(find.text('Sauvegarder'));
    await pTester.pumpAndSettle();
    expect(vSent, [1]);
    expect(vStore.saved.lastExternalBackup, vNow);
    expect(find.text('Sauvegarde hors du téléphone conseillée'), findsNothing);
  });

  testWidgets('rappel au bout de 9 jours, rien au bout de 3', (pTester) async {
    await pumpList(pTester, vNow.subtract(const Duration(days: 9)));
    expect(find.text('Dernière il y a 9 jours.'), findsOneWidget);

    await pumpList(pTester, vNow.subtract(const Duration(days: 3)));
    expect(find.text('Sauvegarde hors du téléphone conseillée'), findsNothing);
  });

  testWidgets('nouveautés montrées une fois à qui avait déjà des chantiers', (pTester) async {
    final vStore = MemorySettings()..saved = AppSettings(lastExternalBackup: vNow);
    final vSettings = SettingsController(vStore);
    await vSettings.load();
    final vController = WorksitesController(
      MemoryStorage()..saved = [const Worksite(id: 'w', name: 'Maison démo')],
    );
    await vController.load();
    Future<void> vShow() async {
      await pTester.pumpWidget(
        localized(WorksitesScreen(controller: vController, settings: vSettings, now: () => vNow)),
      );
      await pTester.pumpAndSettle();
    }

    await vShow();
    expect(find.text('Nouveau dans Atelier'), findsOneWidget);
    expect(vStore.saved.newsSeen, newsVersion);
    await pTester.tap(find.text('C\'est parti'));
    await pTester.pumpAndSettle();

    await vShow();
    expect(find.text('Nouveau dans Atelier'), findsNothing);
  });
}
