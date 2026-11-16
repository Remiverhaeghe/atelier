/// Lecture et écriture JSON d'une pièce, à part du modèle pour le garder lisible.
library;

import 'baseboard.dart';
import 'fixtures.dart';
import 'furniture.dart';
import 'hidden_networks.dart';
import 'paint.dart';
import 'parquet.dart';
import 'room.dart';
import 'slope.dart';
import 'touch_up.dart';

/// Pièce en JSON ; les champs à leur valeur par défaut sont omis pour garder les fichiers courts.
Map<String, Object?> roomToJson(Room pRoom) => {
  'id': pRoom.id,
  'name': pRoom.name,
  'walls': [for (final vWall in pRoom.walls) vWall.toJson()],
  'closed': pRoom.closed,
  'obstacles': [for (final vObstacle in pRoom.obstacles) vObstacle.toJson()],
  'parquet': pRoom.parquet.toJson(),
  'laidRows': pRoom.laidRows,
  'baseboard': pRoom.baseboard.toJson(),
  'cutPieces': pRoom.cutPieces,
  'doneSteps': pRoom.doneSteps,
  'touchUps': [for (final vTouchUp in pRoom.touchUps) vTouchUp.toJson()],
  'ceilingHeightMm': pRoom.ceilingHeightMm,
  'paint': pRoom.paint.toJson(),
  'houseXMm': pRoom.houseXMm,
  'houseYMm': pRoom.houseYMm,
  'houseQuarterTurns': pRoom.houseQuarterTurns,
  if (pRoom.fixtures.isNotEmpty) 'fixtures': [for (final vFixture in pRoom.fixtures) vFixture.toJson()],
  if (pRoom.slope != null) 'slope': pRoom.slope!.toJson(),
  if (pRoom.slope2 != null) 'slope2': pRoom.slope2!.toJson(),
  if (pRoom.level != 0) 'level': pRoom.level,
  if (pRoom.usage != RoomUsage.habitable) 'usage': pRoom.usage.name,
  if (pRoom.furniture.isNotEmpty) 'furniture': [for (final vItem in pRoom.furniture) vItem.toJson()],
  if (pRoom.networks.isNotEmpty) 'networks': [for (final vRun in pRoom.networks) vRun.toJson()],
  if (pRoom.stepPhotos.isNotEmpty) 'stepPhotos': pRoom.stepPhotos,
};

/// Pièce relue ; un champ absent prend sa valeur par défaut, pour lire les anciens fichiers.
Room roomFromJson(Map<String, Object?> pJson) => Room(
  id: pJson['id']! as String,
  name: pJson['name']! as String,
  walls: [
    for (final vWall in (pJson['walls'] as List<Object?>?) ?? const [])
      Wall.fromJson(vWall! as Map<String, Object?>),
  ],
  closed: (pJson['closed'] as bool?) ?? true,
  obstacles: [
    for (final vObstacle in (pJson['obstacles'] as List<Object?>?) ?? const [])
      Obstacle.fromJson(vObstacle! as Map<String, Object?>),
  ],
  parquet: pJson['parquet'] == null
      ? const ParquetSettings()
      : ParquetSettings.fromJson(pJson['parquet']! as Map<String, Object?>),
  laidRows: [for (final vRow in (pJson['laidRows'] as List<Object?>?) ?? const []) vRow! as int],
  baseboard: pJson['baseboard'] == null
      ? const BaseboardSettings()
      : BaseboardSettings.fromJson(pJson['baseboard']! as Map<String, Object?>),
  cutPieces: [
    for (final vPiece in (pJson['cutPieces'] as List<Object?>?) ?? const []) vPiece! as int,
  ],
  doneSteps: [
    for (final vStep in (pJson['doneSteps'] as List<Object?>?) ?? const []) vStep! as String,
  ],
  touchUps: [
    for (final vTouchUp in (pJson['touchUps'] as List<Object?>?) ?? const [])
      TouchUp.fromJson(vTouchUp! as Map<String, Object?>),
  ],
  ceilingHeightMm: (pJson['ceilingHeightMm'] as int?) ?? 2500,
  paint: pJson['paint'] == null
      ? const PaintSettings()
      : PaintSettings.fromJson(pJson['paint']! as Map<String, Object?>),
  houseXMm: (pJson['houseXMm'] as int?) ?? 0,
  houseYMm: (pJson['houseYMm'] as int?) ?? 0,
  houseQuarterTurns: ((pJson['houseQuarterTurns'] as int?) ?? 0) % 4,
  fixtures: [
    for (final vFixture in (pJson['fixtures'] as List<Object?>?) ?? const [])
      Fixture.fromJson(vFixture! as Map<String, Object?>),
  ],
  slope: pJson['slope'] == null ? null : Slope.fromJson(pJson['slope']! as Map<String, Object?>),
  slope2: pJson['slope2'] == null
      ? null
      : Slope.fromJson(pJson['slope2']! as Map<String, Object?>),
  level: (pJson['level'] as int?) ?? 0,
  usage: RoomUsage.values.asNameMap()[pJson['usage']] ?? RoomUsage.habitable,
  furniture: [
    for (final vItem in (pJson['furniture'] as List<Object?>?) ?? const [])
      Furniture.fromJson(vItem! as Map<String, Object?>),
  ],
  networks: [
    for (final vRun in (pJson['networks'] as List<Object?>?) ?? const [])
      HiddenRun.fromJson(vRun! as Map<String, Object?>),
  ],
  stepPhotos: {
    for (final vEntry in ((pJson['stepPhotos'] as Map<String, Object?>?) ?? const {}).entries)
      vEntry.key: (vEntry.value! as List<Object?>).cast<String>(),
  },
);
