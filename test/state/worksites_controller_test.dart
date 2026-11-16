import 'dart:io';

import 'package:atelier/logic/room.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/storage/worksite_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory vFolder;
  late File vFile;
  late WorksitesController vController;
  var vNext = 0;

  setUp(() {
    vFolder = Directory.systemTemp.createTempSync('atelier_');
    vFile = File('${vFolder.path}/chantiers.json');
    vController = WorksitesController(WorksiteStore(vFile), pNewId: () => 'id${vNext++}');
  });
  tearDown(() => vFolder.deleteSync(recursive: true));

  test('chantiers et pièces sont ajoutés, modifiés, supprimés et enregistrés', () async {
    await vController.load();
    expect(vController.loaded, isTrue);

    final vWorksite = await vController.addWorksite('  Maison  ');
    final vRoom = await vController.addRoom(vWorksite.id, 'Salon');
    await vController.updateRoom(vWorksite.id, vRoom.copyWith(walls: const [Wall(lengthMm: 4000)]));
    final vOther = await vController.addRoom(vWorksite.id, 'Chambre');
    await vController.deleteRoom(vWorksite.id, vOther.id);

    expect(vController.worksite(vWorksite.id)!.name, 'Maison');
    expect(vController.worksite(vWorksite.id)!.rooms.single.walls.single.lengthMm, 4000);

    final vReloaded = WorksitesController(WorksiteStore(vFile));
    await vReloaded.load();
    expect(vReloaded.worksites.single.rooms.single.name, 'Salon');

    await vController.deleteWorksite(vWorksite.id);
    expect(vController.worksites, isEmpty);
    expect(vController.worksite(vWorksite.id), isNull);
  });

  test('un fichier abîmé laisse la liste vide sans planter', () async {
    vFile.writeAsStringSync('{abîmé');

    await vController.load();

    expect(vController.loaded, isTrue);
    expect(vController.worksites, isEmpty);
  });

  test('chaque changement prévient les écrans', () async {
    var vNotified = 0;
    vController.addListener(() => vNotified++);

    await vController.load();
    await vController.addWorksite('Garage');

    expect(vNotified, 2);
  });
}
