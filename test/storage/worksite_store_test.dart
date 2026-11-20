import 'dart:io';

import 'package:atelier/logic/worksite.dart';
import 'package:atelier/logic/workshop_stock.dart';
import 'package:atelier/storage/photo_store.dart';
import 'package:atelier/storage/worksite_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  late Directory vFolder;

  setUp(() => vFolder = Directory.systemTemp.createTempSync('atelier_'));
  tearDown(() => vFolder.deleteSync(recursive: true));

  test('sans fichier, aucun chantier', () async {
    final vStore = WorksiteStore(File('${vFolder.path}/chantiers.json'));

    expect(await vStore.load(), isEmpty);
  });

  test('les chantiers enregistrés se relisent, sans fichier temporaire restant', () async {
    final vStore = WorksiteStore(File('${vFolder.path}/sous/dossier/chantiers.json'));
    await vStore.save([
      Worksite(id: 'maison', name: 'Maison', rooms: [rectangleRoom()]),
    ]);

    final vLoaded = await vStore.load();

    expect(vLoaded.single.name, 'Maison');
    expect(vLoaded.single.rooms.single.walls, hasLength(4));
    expect(File('${vFolder.path}/sous/dossier/chantiers.json.tmp').existsSync(), isFalse);
  });

  test('un fichier qui n\'est pas un export d\'Atelier est refusé', () {
    expect(() => WorksiteStore.decode('[]'), throwsFormatException);
    expect(() => WorksiteStore.decode('{"autre": 1}'), throwsFormatException);
    expect(() => WorksiteStore.decode('pas du json'), throwsFormatException);
  });

  test('le format enregistré porte sa version', () {
    expect(WorksiteStore.encode(const []), contains('"formatVersion": 1'));
  });

  test('un fichier de la version 1 se relit toujours, et se réécrit sans rien perdre', () {
    final vText = File('test/fixtures/chantiers_v1.json').readAsStringSync();
    final vWorksite = WorksiteStore.decode(vText).single;

    expect(vWorksite.rooms.single.walls.map((pWall) => pWall.lengthMm), [4000, 3000, 4000, 3000]);
    expect(vWorksite.prices['Colle'], 12.5);
    expect(vWorksite.goalsReached, 2);
    expect(vWorksite.expenses.single.amount, 600);
    expect(vWorksite.journal.single.title, 'Pose du parquet');
    expect(vWorksite.reminders.single.dueAt, DateTime(2026, 10, 3, 10));
    final vAgain = WorksiteStore.decode(WorksiteStore.encode([vWorksite])).single;
    expect(vAgain.toJson(), vWorksite.toJson());
  });

  test('un fichier illisible est gardé à part avant d\'être refusé', () async {
    final vFile = File('${vFolder.path}/chantiers.json')
      ..writeAsStringSync('{"formatVersion": 99, "worksites": []}');
    final vStore = WorksiteStore(vFile);

    await expectLater(vStore.load(), throwsFormatException);
    expect(File('${vFile.path}.illisible').readAsStringSync(), contains('"formatVersion": 99'));
  });

  test('sauvegarde complète : le stock de l\'atelier part avec les chantiers', () {
    const vStock = [StockItem(id: 'vis-4x40', name: 'Vis 4 × 40', quantity: 2, minQuantity: 1)];
    final vText = WorksiteStore.encode(const [], pWorkshop: vStock);
    final vBack = WorksiteStore.decodeWorkshop(vText)!;
    expect(vBack.single.id, 'vis-4x40');
    expect(vBack.single.quantity, 2);
    // Les chantiers se relisent comme avant
    expect(WorksiteStore.decode(vText), isEmpty);
  });

  test('un export de chantier ou un ancien fichier n\'a pas de stock', () {
    expect(WorksiteStore.decodeWorkshop(WorksiteStore.encode(const [])), isNull);
    expect(WorksiteStore.decodeWorkshop('[1, 2]'), isNull);
  });

  test('photo effacée du téléphone : rien à lire', () {
    expect(readPhoto('/dossier/qui/nexiste/pas.jpg'), isNull);
  });
}
