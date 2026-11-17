import 'dart:io';

import 'package:atelier/logic/app_settings.dart';
import 'package:atelier/storage/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('réglages : aller-retour JSON, valeurs inconnues ramenées au départ', () {
    const vSettings = AppSettings(theme: ThemeChoice.dark, textScale: 1.3);
    final vBack = AppSettings.fromJson(vSettings.toJson());
    expect(vBack.theme, ThemeChoice.dark);
    expect(vBack.textScale, 1.3);

    final vOdd = AppSettings.fromJson(const {'theme': 'violet', 'textScale': 7});
    expect(vOdd.theme, ThemeChoice.system);
    expect(vOdd.textScale, 1.0);
    expect(const AppSettings().copyWith(textScale: 1.15).theme, ThemeChoice.system);
  });

  test('fichier de réglages : absent, écrit, relu, abîmé', () async {
    final vFolder = Directory.systemTemp.createTempSync('reglages');
    addTearDown(() => vFolder.deleteSync(recursive: true));
    final vStore = SettingsFileStore(File('${vFolder.path}/sous/reglages.json'));

    expect((await vStore.load()).theme, ThemeChoice.system);
    await vStore.save(const AppSettings(theme: ThemeChoice.light));
    expect((await vStore.load()).theme, ThemeChoice.light);
    vStore.file.writeAsStringSync('{pas du json');
    expect((await vStore.load()).textScale, 1.0);
  });

  test('sauvegarde hors du téléphone conseillée au bout de 7 jours', () {
    final vNow = DateTime(2026, 11, 16);
    expect(externalBackupDue(null, vNow), isTrue);
    expect(externalBackupDue(DateTime(2026, 11, 10), vNow), isFalse);
    expect(externalBackupDue(DateTime(2026, 11, 9), vNow), isTrue);

    final vBack = AppSettings.fromJson(AppSettings(lastExternalBackup: vNow).toJson());
    expect(vBack.lastExternalBackup, vNow);
    expect(const AppSettings().toJson().containsKey('lastExternalBackup'), isFalse);
    expect(AppSettings.fromJson(const AppSettings(newsSeen: 3).toJson()).newsSeen, 3);
    expect(const AppSettings().toJson().containsKey('newsSeen'), isFalse);
    expect(vBack.copyWith(theme: ThemeChoice.dark).lastExternalBackup, vNow);
  });
}
