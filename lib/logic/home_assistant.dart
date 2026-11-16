/// Export pour Home Assistant : étages et zones (pièces) à créer, avec prises et interrupteurs.
///
/// Le format est décrit dans docs/home-assistant.md.
library;

import 'fixtures.dart';
import 'geometry.dart';
import 'house.dart';
import 'worksite.dart';

const homeAssistantFormat = 'atelier-home-assistant';
const homeAssistantVersion = 1;

/// Identifiant à la manière de Home Assistant : minuscules sans accent, mots reliés par « _ ».
String haSlug(String pName) {
  const vAccents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ÿ': 'y',
    'œ': 'oe', 'æ': 'ae',
  };
  final vPlain = pName.toLowerCase().split('').map((pChar) => vAccents[pChar] ?? pChar).join();
  final rSlug = vPlain
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  return rSlug.isEmpty ? 'piece' : rSlug;
}

/// Icône Material Design de Home Assistant devinée d'après le nom de la pièce.
String haIcon(String pName) {
  final vName = haSlug(pName);
  const vIcons = [
    ('cuisine', 'mdi:stove'),
    ('salon', 'mdi:sofa'),
    ('sejour', 'mdi:sofa'),
    ('chambre', 'mdi:bed'),
    ('bain', 'mdi:shower'),
    ('douche', 'mdi:shower'),
    ('wc', 'mdi:toilet'),
    ('toilette', 'mdi:toilet'),
    ('bureau', 'mdi:desk'),
    ('garage', 'mdi:garage'),
    ('entree', 'mdi:door'),
    ('couloir', 'mdi:door'),
    ('cellier', 'mdi:washing-machine'),
    ('buanderie', 'mdi:washing-machine'),
    ('jardin', 'mdi:flower'),
    ('terrasse', 'mdi:table-chair'),
    ('grenier', 'mdi:home-roof'),
    ('combles', 'mdi:home-roof'),
    ('cave', 'mdi:stairs-down'),
  ];
  for (final (vWord, vIcon) in vIcons) {
    if (vName.contains(vWord)) {
      return vIcon;
    }
  }

  return 'mdi:floor-plan';
}

/// Nom d'étage lisible : rez-de-chaussée, étage n, sous-sol n.
String _floorName(int pLevel) => switch (pLevel) {
  0 => 'Rez-de-chaussée',
  1 => '1er étage',
  > 1 => '${pLevel}e étage',
  -1 => 'Sous-sol',
  _ => 'Sous-sol ${-pLevel}',
};

/// Étages et zones du chantier, identifiants uniques même pour deux pièces de même nom.
Map<String, Object?> exportHomeAssistant(Worksite pWorksite) {
  final vUsed = <String>{};
  String vUnique(String pSlug) {
    var rSlug = pSlug;
    for (var vNumber = 2; vUsed.contains(rSlug); vNumber++) {
      rSlug = '${pSlug}_$vNumber';
    }
    vUsed.add(rSlug);

    return rSlug;
  }

  final vLevels = houseLevels(pWorksite.rooms);
  final rExport = {
    'format': homeAssistantFormat,
    'version': homeAssistantVersion,
    'name': pWorksite.name,
    'floors': [
      for (final vLevel in vLevels)
        {'floor_id': 'niveau_$vLevel', 'name': _floorName(vLevel), 'level': vLevel},
    ],
    'areas': [
      for (final vRoom in pWorksite.rooms)
        {
          'area_id': vUnique(haSlug(vRoom.name)),
          'name': vRoom.name,
          'floor_id': 'niveau_${vRoom.level}',
          'icon': haIcon(vRoom.name),
          if (vRoom.walls.length >= 3) 'area_m2': (floorAreaM2(vRoom) * 100).round() / 100,
          'sockets': fixtureCount(vRoom.fixtures, FixtureKind.socket),
          'switches': fixtureCount(vRoom.fixtures, FixtureKind.lightSwitch),
        },
    ],
  };

  return rExport;
}
