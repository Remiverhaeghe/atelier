/// Relevés de plusieurs thermo-hygromètres rangés d'un coup dans les pièces du chantier : chaque
/// capteur est rattaché à la pièce qui porte son nom, et ses journées s'ajoutent au suivi de la
/// pièce. Les capteurs sont lus dans un export CSV ou dans un fichier d'échange JSON, que le futur
/// projet de domotique pourra écrire (format décrit dans `docs/echange-climat.md`).
library;

import 'dart:convert';

import 'climate_history.dart';
import 'indoor_climate.dart';
import 'room.dart';
import 'worksite.dart';

/// Version du fichier d'échange JSON.
const climateExchangeVersion = 1;

/// Relevés d'un capteur, avec le nom qu'il porte.
typedef SensorReadings = ({String name, List<ClimateReading> readings});

/// Nom comparable : sans extension, accents ni ponctuation, en minuscules.
String sensorKey(String pName) {
  const vFrom = 'àâäçéèêëîïôöùûüÿœ';
  const vTo = 'aaaceeeeiioouuuyo';
  final vName = pName.toLowerCase().replaceFirst(RegExp(r'\.(csv|txt|json)$'), '');
  final rKey = StringBuffer();
  for (final vRune in vName.runes) {
    final vChar = String.fromCharCode(vRune);
    final vAt = vFrom.indexOf(vChar);
    rKey.write(vAt >= 0 ? vTo[vAt] : vChar);
  }

  return rKey.toString().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

/// Pièce qui porte le nom du capteur : nom identique, sinon le nom le plus long contenu dans celui
/// du capteur (« Capteur salle de bain » va à « Salle de bain »). Null si aucune pièce ne
/// convient ou si deux pièces conviennent aussi bien.
Room? roomForSensor(String pSensor, List<Room> pRooms) {
  final vSensor = sensorKey(pSensor);
  if (vSensor.isEmpty) {
    return null;
  }
  final vKeyed = [
    for (final vRoom in pRooms)
      if (sensorKey(vRoom.name).isNotEmpty) (room: vRoom, key: sensorKey(vRoom.name)),
  ];
  final vExact = vKeyed.where((pEntry) => pEntry.key == vSensor).toList();
  if (vExact.isNotEmpty) {
    return vExact.length == 1 ? vExact.single.room : null;
  }
  final vInside = vKeyed.where((pEntry) => vSensor.contains(pEntry.key)).toList()
    ..sort((pA, pB) => pB.key.length.compareTo(pA.key.length));
  final rRoom = vInside.isEmpty || (vInside.length > 1 && vInside[0].key.length == vInside[1].key.length)
      ? null
      : vInside.first.room;

  return rRoom;
}

/// Capteurs d'un fichier : un seul pour un export CSV (nommé d'après le fichier), plusieurs pour
/// un fichier d'échange JSON. Liste vide si le fichier n'est pas lisible.
List<SensorReadings> readSensorFile(String pFileName, String pText) {
  final vText = pText.trimLeft();
  if (pFileName.toLowerCase().endsWith('.json') || vText.startsWith('{')) {
    return _readExchange(pText);
  }
  final vImport = parseClimateCsv(pText);
  if (vImport == null || vImport.readings.isEmpty) {
    return const [];
  }

  return [(name: pFileName.replaceFirst(RegExp(r'\.[A-Za-z0-9]+$'), ''), readings: vImport.readings)];
}

List<SensorReadings> _readExchange(String pText) {
  try {
    final vJson = jsonDecode(pText);
    if (vJson is! Map<String, Object?> || vJson['version'] != climateExchangeVersion) {
      return const [];
    }
    final rSensors = <SensorReadings>[];
    for (final vSensor in (vJson['sensors'] as List<Object?>?) ?? const []) {
      if (vSensor is! Map<String, Object?>) {
        continue;
      }
      final vReadings = <ClimateReading>[];
      for (final vReading in (vSensor['readings'] as List<Object?>?) ?? const []) {
        if (vReading is! Map<String, Object?>) {
          continue;
        }
        final vAt = DateTime.tryParse('${vReading['at']}');
        final vTemp = vReading['temp'];
        final vHumidity = vReading['humidity'];
        if (vAt != null && vTemp is num && vHumidity is num) {
          vReadings.add((at: vAt, tempC: vTemp.toDouble(), humidity: vHumidity.toDouble()));
        }
      }
      final vName = '${vSensor['name'] ?? ''}'.trim();
      if (vName.isNotEmpty && vReadings.isNotEmpty) {
        rSensors.add((name: vName, readings: vReadings));
      }
    }

    return rSensors;
  } on FormatException {
    return const [];
  }
}

/// Fichier d'échange JSON des capteurs : ce que la domotique écrit, ce que l'appli relit.
String climateExchangeJson(List<SensorReadings> pSensors) => jsonEncode({
  'version': climateExchangeVersion,
  'sensors': [
    for (final vSensor in pSensors)
      {
        'name': vSensor.name,
        'readings': [
          for (final vReading in vSensor.readings)
            {
              'at': vReading.at.toIso8601String(),
              'temp': vReading.tempC,
              'humidity': vReading.humidity,
            },
        ],
      },
  ],
});

/// Capteur rangé dans une pièce : le nom du capteur, la pièce et les journées ajoutées.
typedef RoutedSensor = ({String sensor, String room, int days});

/// Résultat du rangement : le chantier mis à jour, les capteurs rangés et ceux sans pièce.
typedef ClimateRouting = ({Worksite worksite, List<RoutedSensor> routed, List<String> unmatched});

/// Range chaque capteur dans sa pièce. [pAssigned] impose la pièce (identifiant) d'un capteur que
/// le nom ne désigne pas ; les journées d'un capteur déjà vu sont remplacées, pas doublées.
ClimateRouting routeClimate(
  Worksite pWorksite,
  List<SensorReadings> pSensors, {
  Map<String, String> pAssigned = const {},
}) {
  var vRooms = pWorksite.rooms;
  final vRouted = <RoutedSensor>[];
  final vUnmatched = <String>[];
  for (final vSensor in pSensors) {
    final vAssigned = vRooms.where((pRoom) => pRoom.id == pAssigned[vSensor.name]).firstOrNull;
    final vRoom = vAssigned ?? roomForSensor(vSensor.name, vRooms);
    if (vRoom == null) {
      vUnmatched.add(vSensor.name);
      continue;
    }
    final vDays = dailyClimate(vSensor.readings);
    final vUpdated = vRoom.copyWith(
      climate: vRoom.climate.copyWith(days: mergeClimateDays(vRoom.climate.days, vDays)),
    );
    vRooms = [for (final vOther in vRooms) vOther.id == vRoom.id ? vUpdated : vOther];
    vRouted.add((sensor: vSensor.name, room: vRoom.name, days: vDays.length));
  }

  return (worksite: pWorksite.copyWith(rooms: vRooms), routed: vRouted, unmatched: vUnmatched);
}
