import 'dart:io';

import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/storage/backups.dart';
import 'package:atelier/storage/worksite_store.dart';
import 'package:atelier/ui/backups_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';

void main() {
  testWidgets('une sauvegarde se restaure après confirmation', (pTester) async {
    final vFolder = Directory.systemTemp.createTempSync('atelier_');
    addTearDown(() => vFolder.deleteSync(recursive: true));
    final vBackups = Backups(vFolder, pNow: () => DateTime(2026, 11, 15));
    final vStorage = MemoryStorage()..saved = const [Worksite(id: 'n', name: 'Nouveau')];
    final vController = WorksitesController(vStorage);

    await pTester.runAsync(() async {
      await vBackups.record(WorksiteStore.encode(const [Worksite(id: 'a', name: 'Ancien')]));
      await vController.load();
    });
    await pTester.pumpWidget(localized(BackupsScreen(backups: vBackups, controller: vController)));

    expect(find.text('2026-11-15'), findsOneWidget);
    await pTester.tap(find.text('Restaurer'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('remplacés par ceux du 2026-11-15'), findsOneWidget);

    await pTester.tap(find.text('Restaurer').last);
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.name, 'Ancien');
  });
}
