import 'dart:io';

import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/worksite.dart';
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

  test('chantier partagé : fusion du même chantier, ajout des autres', () async {
    await vController.load();
    final vMine = await vController.addWorksite('Maison');
    final vTheirs = vMine.copyWith(rooms: [const Room(id: 'cuisine', name: 'Cuisine')]);
    const vOther = Worksite(id: 'garage', name: 'Garage');

    expect(vController.sharesWorksite([vOther]), isFalse);
    expect(vController.sharesWorksite([vOther, vTheirs]), isTrue);
    final vResult = await vController.mergeImport([vTheirs, vOther], 'autre');

    expect((vResult.added, vResult.merged, vResult.conflicts), (1, 1, 0));
    expect(vController.worksite(vMine.id)!.rooms.single.name, 'Cuisine');
    expect(vController.worksite('garage'), isNotNull);
  });

  test('un import ajoute les chantiers sous de nouveaux identifiants', () async {
    await vController.load();
    final vExisting = await vController.addWorksite('Maison');

    final vCount = await vController.importWorksites([
      vExisting,
      vExisting.copyWith(name: 'Garage'),
    ]);

    expect(vCount, 2);
    expect(vController.worksites, hasLength(3));
    expect(vController.worksites.map((pWorksite) => pWorksite.id).toSet(), hasLength(3));
    expect(vController.worksites.last.name, 'Garage');
  });
}
