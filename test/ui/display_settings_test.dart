import 'package:atelier/app.dart';
import 'package:atelier/logic/app_settings.dart';
import 'package:atelier/state/settings_controller.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/storage/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_storage.dart';

/// Réglages en mémoire.
class MemorySettings implements SettingsStorage {
  AppSettings saved = const AppSettings();

  @override
  Future<AppSettings> load() async => saved;

  @override
  Future<void> save(AppSettings pSettings) async => saved = pSettings;
}

void main() {
  testWidgets('thème sombre et grand texte choisis dans À propos', (pTester) async {
    final vStore = MemorySettings();
    final vSettings = SettingsController(vStore);
    await vSettings.load();
    final vController = WorksitesController(MemoryStorage());
    await vController.load();
    await pTester.pumpWidget(AtelierApp(controller: vController, settings: vSettings));
    await pTester.pumpAndSettle();
    expect(pTester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.system);

    await pTester.tap(find.byTooltip('À propos'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Sombre'));
    await pTester.pumpAndSettle();
    expect(pTester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);
    expect(vStore.saved.theme, ThemeChoice.dark);

    await pTester.tap(find.text('Très grand'));
    await pTester.pumpAndSettle();
    expect(vStore.saved.textScale, 1.3);
    final vContext = pTester.element(find.text('Affichage'));
    expect(MediaQuery.textScalerOf(vContext).scale(10), closeTo(13, 1e-9));

    await pTester.tap(find.text('Clair'));
    await pTester.pumpAndSettle();
    expect(pTester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.light);
  });
}
