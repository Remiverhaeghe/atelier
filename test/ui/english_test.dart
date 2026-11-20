import 'dart:convert';
import 'dart:io';

import 'package:atelier/app.dart';
import 'package:atelier/logic/app_settings.dart';
import 'package:atelier/logic/units.dart';
import 'package:atelier/state/settings_controller.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/home_widget_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_storage.dart';
import 'display_settings_test.dart' show MemorySettings;

/// Noms des paramètres d'un texte ARB, hors variantes du pluriel (`=1{…}`, `other{…}`).
Set<String> placeholders(String pText) {
  final vCase = RegExp(r'(=\d+|zero|one|two|few|many|other)$');
  final rNames = {
    for (final vMatch in RegExp(r'\{(\w+)[,}]').allMatches(pText))
      if (!vCase.hasMatch(pText.substring(0, vMatch.start))) vMatch.group(1)!,
  };

  return rNames;
}

Map<String, Object?> readArb(String pName) =>
    jsonDecode(File('lib/l10n/$pName').readAsStringSync()) as Map<String, Object?>;

void main() {
  test('chaque texte français a sa traduction anglaise, avec les mêmes paramètres', () {
    final vFrench = readArb('app_fr.arb');
    final vEnglish = readArb('app_en.arb');
    final vKeys = vFrench.keys.where((pKey) => !pKey.startsWith('@'));
    for (final vKey in vKeys) {
      expect(vEnglish[vKey], isA<String>(), reason: vKey);
      expect(
        placeholders(vEnglish[vKey]! as String),
        placeholders(vFrench[vKey]! as String),
        reason: vKey,
      );
    }
    expect(vEnglish.keys.where((pKey) => !vFrench.containsKey(pKey)), isEmpty);
  });

  testWidgets('téléphone en anglais : appli en anglais, nombres avec un point', (pTester) async {
    pTester.platformDispatcher.localesTestValue = const [Locale('en', 'GB')];
    final vController = WorksitesController(MemoryStorage());
    await vController.load();
    await pTester.pumpWidget(AtelierApp(controller: vController));
    await pTester.pumpAndSettle();

    expect(find.text('My projects'), findsOneWidget);
    expect(formatDecimal(2.5), '2.5');
    expect(formatCentimetres(2455), '245.5');
  });

  testWidgets('le français choisi dans À propos passe avant la langue du téléphone', (
    pTester,
  ) async {
    pTester.platformDispatcher.localesTestValue = const [Locale('en', 'GB')];
    final vStore = MemorySettings()..saved = const AppSettings(language: LanguageChoice.french);
    final vSettings = SettingsController(vStore);
    await vSettings.load();
    final vController = WorksitesController(MemoryStorage());
    await vController.load();
    await pTester.pumpWidget(AtelierApp(controller: vController, settings: vSettings));
    await pTester.pumpAndSettle();

    expect(find.text('Mes chantiers'), findsOneWidget);
    expect(formatDecimal(2.5), '2,5');

    await vSettings.update(const AppSettings(language: LanguageChoice.english));
    await pTester.pumpAndSettle();
    expect(find.text('My projects'), findsOneWidget);
  });

  test('langue gardée dans les réglages, valeur inconnue ramenée à celle du téléphone', () {
    const vSettings = AppSettings(language: LanguageChoice.english);
    expect(AppSettings.fromJson(vSettings.toJson()).language, LanguageChoice.english);
    expect(const AppSettings().toJson().containsKey('language'), isFalse);
    expect(AppSettings.fromJson(const {'language': 'klingon'}).language, LanguageChoice.system);
  });

  test('widget d\'écran d\'accueil : langue du téléphone si connue, sinon français', () {
    expect(widgetLocale(const [Locale('de'), Locale('en', 'US')]), const Locale('en'));
    expect(widgetLocale(const [Locale('fr', 'BE')]), const Locale('fr'));
    expect(widgetLocale(const [Locale('de')]), const Locale('fr'));
  });
}
