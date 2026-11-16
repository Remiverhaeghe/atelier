import 'dart:io';

import 'package:atelier/logic/worksite.dart';
import 'package:atelier/storage/backups.dart';
import 'package:atelier/storage/worksite_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory vFolder;
  var vNow = DateTime(2026, 11, 16, 9);

  setUp(() {
    vFolder = Directory.systemTemp.createTempSync('atelier_');
    vNow = DateTime(2026, 11, 16, 9);
  });
  tearDown(() => vFolder.deleteSync(recursive: true));

  test('une copie par jour, la première du jour gardée', () async {
    final vBackups = Backups(Directory('${vFolder.path}/sauvegardes'), pNow: () => vNow);
    expect(vBackups.list(), isEmpty);

    await vBackups.record('matin');
    await vBackups.record('soir');
    vNow = DateTime(2026, 11, 17);
    await vBackups.record('lendemain');

    final vList = vBackups.list();
    expect(vList.map((pBackup) => pBackup.day), ['2026-11-17', '2026-11-16']);
    expect(vList.last.file.readAsStringSync(), 'matin');
  });

  test('seules les plus récentes restent', () async {
    final vBackups = Backups(Directory(vFolder.path), keep: 2, pNow: () => vNow);
    File('${vFolder.path}/autre.txt').writeAsStringSync('ignoré');
    for (var vDay = 1; vDay <= 4; vDay++) {
      vNow = DateTime(2026, 11, vDay);
      await vBackups.record('$vDay');
    }

    expect(vBackups.list().map((pBackup) => pBackup.day), ['2026-11-04', '2026-11-03']);
    expect(File('${vFolder.path}/autre.txt').existsSync(), isTrue);
  });

  test('l\'enregistrement des chantiers fait la sauvegarde du jour', () async {
    final vBackups = Backups(Directory('${vFolder.path}/sauvegardes'), pNow: () => vNow);
    final vStore = WorksiteStore(File('${vFolder.path}/chantiers.json'), backups: vBackups);
    await vStore.save(const [Worksite(id: 'm', name: 'Maison')]);

    final vSaved = WorksiteStore.decode(vBackups.list().single.file.readAsStringSync());
    expect(vSaved.single.name, 'Maison');
  });
}
