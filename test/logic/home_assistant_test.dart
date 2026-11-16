import 'dart:convert';

import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/home_assistant.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('identifiants sans accent ni espace', () {
    expect(haSlug('Salle de bain'), 'salle_de_bain');
    expect(haSlug('  Entrée / Couloir '), 'entree_couloir');
    expect(haSlug('Cœur'), 'coeur');
    expect(haSlug('!!'), 'piece');
  });

  test('icône devinée d\'après le nom', () {
    expect(haIcon('Chambre de Léa'), 'mdi:bed');
    expect(haIcon('Cuisine'), 'mdi:stove');
    expect(haIcon('Salle de bain'), 'mdi:shower');
    expect(haIcon('Pièce inconnue'), 'mdi:floor-plan');
  });

  test('étages et zones, doublons renommés, prises comptées', () {
    final vExport = exportHomeAssistant(
      Worksite(
        id: 'w',
        name: 'Maison démo',
        rooms: [
          rectangleRoom().copyWith(
            fixtures: const [
              Fixture(id: 'p', kind: FixtureKind.socket, xMm: 0, yMm: 0, count: 2),
              Fixture(id: 'i', kind: FixtureKind.lightSwitch, xMm: 0, yMm: 0),
            ],
          ),
          rectangleRoom().copyWith(level: 1),
          const Room(id: 'cave', name: 'Cave', level: -2),
        ],
      ),
    );
    expect(jsonDecode(jsonEncode(vExport)), vExport);
    expect(vExport['format'], 'atelier-home-assistant');

    final vFloors = vExport['floors']! as List;
    expect([for (final vFloor in vFloors) (vFloor as Map)['name']], [
      'Sous-sol 2',
      'Rez-de-chaussée',
      '1er étage',
    ]);
    final vAreas = [for (final vArea in vExport['areas']! as List) vArea as Map<String, Object?>];
    expect([for (final vArea in vAreas) vArea['area_id']], ['salon', 'salon_2', 'cave']);
    expect(vAreas.first['sockets'], 2);
    expect(vAreas.first['switches'], 1);
    expect(vAreas.first['area_m2'], 12.0);
    expect(vAreas[1]['floor_id'], 'niveau_1');
    expect(vAreas.last.containsKey('area_m2'), isFalse);
    expect(vAreas.last['icon'], 'mdi:stairs-down');
  });

  test('noms d\'étages au-delà du premier', () {
    final vExport = exportHomeAssistant(
      Worksite(id: 'w', name: 'Tour', rooms: [rectangleRoom().copyWith(level: 3), rectangleRoom().copyWith(level: -1)]),
    );
    final vNames = [for (final vFloor in vExport['floors']! as List) (vFloor as Map)['name']];
    expect(vNames, ['Sous-sol', 'Rez-de-chaussée', '3e étage']);
  });
}
