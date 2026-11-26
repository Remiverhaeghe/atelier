import 'package:atelier/logic/climate_dispatch.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

/// Relevés fictifs : deux jours, une mesure toutes les 12 h.
String _csv(double pHumidity) => [
  'Timestamp,Temperature_Celsius(°C),Relative_Humidity(%)',
  for (var vHour = 0; vHour < 48; vHour += 12)
    '${DateTime(2026, 12, 1).add(Duration(hours: vHour)).toIso8601String()},20,$pHumidity',
].join('\n');

Worksite _site() => const Worksite(
  id: 'w',
  name: 'Maison',
  rooms: [
    Room(id: 'sdb', name: 'Salle de bain'),
    Room(id: 'ch', name: 'Chambre'),
    Room(id: 'ch2', name: 'Chambre des enfants'),
    Room(id: 'cuis', name: 'Cuisine'),
  ],
);

void main() {
  group('nom du capteur et pièce', () {
    test('le nom est comparé sans extension, accents ni ponctuation', () {
      expect(sensorKey('Salle-de-bain.CSV'), 'salledebain');
      expect(sensorKey('Séjour (capteur 2).txt'), 'sejourcapteur2');
    });

    test('nom identique, sinon le nom de pièce le plus long contenu dans celui du capteur', () {
      final vRooms = _site().rooms;

      expect(roomForSensor('chambre', vRooms)!.id, 'ch');
      expect(roomForSensor('Capteur salle de bain', vRooms)!.id, 'sdb');
      expect(roomForSensor('Chambre des enfants - capteur', vRooms)!.id, 'ch2');
    });

    test('aucune pièce ou deux pièces à égalité : pas de rattachement', () {
      final vRooms = [...(_site().rooms), const Room(id: 'x', name: 'Chambre!')];

      expect(roomForSensor('Garage', vRooms), isNull);
      expect(roomForSensor('', vRooms), isNull);
      expect(roomForSensor('Ma chambre', vRooms), isNull);
    });
  });

  group('lecture des fichiers', () {
    test('un export CSV donne un capteur nommé d\'après le fichier', () {
      final vSensors = readSensorFile('Cuisine.csv', _csv(55));

      expect(vSensors.single.name, 'Cuisine');
      expect(vSensors.single.readings, hasLength(4));
      expect(readSensorFile('vide.csv', 'Date,Temp\n2026-12-01,20'), isEmpty);
    });

    test('le fichier d\'échange JSON se relit tel qu\'il a été écrit', () {
      final vSensors = readSensorFile('cap.csv', _csv(60));
      final vJson = climateExchangeJson(vSensors);
      final vBack = readSensorFile('echange.json', vJson);

      expect(vBack.single.name, 'cap');
      expect(vBack.single.readings.first.humidity, 60);
      expect(vBack.single.readings.first.at, DateTime(2026, 12, 1));
    });

    test('un JSON d\'une autre version ou abîmé est refusé, les relevés invalides sont ignorés', () {
      expect(readSensorFile('a.json', '{"version": 2, "sensors": []}'), isEmpty);
      expect(readSensorFile('a.json', '{pas du json'), isEmpty);
      expect(
        readSensorFile(
          'a.json',
          '{"version": 1, "sensors": [{"name": "Cuisine", "readings": ['
          '{"at": "2026-12-01T08:00:00", "temp": 20, "humidity": 50},'
          '{"at": "pas une date", "temp": 20, "humidity": 50},'
          '{"at": "2026-12-01T09:00:00", "temp": "x", "humidity": 50}]},'
          '{"name": "", "readings": []}]}',
        ).single.readings,
        hasLength(1),
      );
    });
  });

  group('rangement dans le chantier', () {
    test('chaque capteur va dans sa pièce, les autres sont signalés', () {
      final vResult = routeClimate(_site(), [
        ...readSensorFile('Cuisine.csv', _csv(55)),
        ...readSensorFile('Salle de bain.csv', _csv(78)),
        ...readSensorFile('Garage.csv', _csv(40)),
      ]);

      expect(vResult.routed, [
        (sensor: 'Cuisine', room: 'Cuisine', days: 2),
        (sensor: 'Salle de bain', room: 'Salle de bain', days: 2),
      ]);
      expect(vResult.unmatched, ['Garage']);
      Room vRoom(String pId) => vResult.worksite.rooms.firstWhere((pRoom) => pRoom.id == pId);
      expect(vRoom('sdb').climate.days.first.humidity, 78);
      expect(vRoom('cuis').climate.days, hasLength(2));
      expect(vRoom('ch').climate.days, isEmpty);
    });

    test('une pièce imposée reçoit le capteur que le nom ne désigne pas', () {
      final vResult = routeClimate(
        _site(),
        readSensorFile('Garage.csv', _csv(40)),
        pAssigned: const {'Garage': 'ch'},
      );

      expect(vResult.unmatched, isEmpty);
      expect(vResult.worksite.rooms.firstWhere((pRoom) => pRoom.id == 'ch').climate.days, hasLength(2));
    });

    test('un nouvel import du même capteur remplace les journées, sans les doubler', () {
      final vFirst = routeClimate(_site(), readSensorFile('Cuisine.csv', _csv(55)));
      final vSecond = routeClimate(vFirst.worksite, readSensorFile('Cuisine.csv', _csv(65)));
      final vDays = vSecond.worksite.rooms.firstWhere((pRoom) => pRoom.id == 'cuis').climate.days;

      expect(vDays, hasLength(2));
      expect(vDays.first.humidity, 65);
    });
  });
}
