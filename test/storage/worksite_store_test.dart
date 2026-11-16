import 'dart:io';

import 'package:atelier/logic/worksite.dart';
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
}
