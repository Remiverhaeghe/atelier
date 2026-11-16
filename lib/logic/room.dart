/// Modèle d'une pièce saisie mur par mur, sérialisable en JSON.
library;

import 'baseboard.dart';
import 'parquet.dart';
import 'touch_up.dart';

/// Ouverture dans un mur, sans plinthe sur sa largeur.
enum OpeningKind { door, passage }

/// Élément qui gêne la pose : zone sans parquet ou plinthe interrompue.
enum ObstacleKind { radiator, pipe, cupboard, fireplace, stairFoot }

/// Porte ou passage, placé depuis le début du mur.
class Opening {
  const Opening({required this.kind, required this.offsetMm, required this.widthMm});

  final OpeningKind kind;
  final int offsetMm;
  final int widthMm;

  Map<String, Object?> toJson() => {'kind': kind.name, 'offsetMm': offsetMm, 'widthMm': widthMm};

  static Opening fromJson(Map<String, Object?> pJson) => Opening(
    kind: OpeningKind.values.byName(pJson['kind']! as String),
    offsetMm: pJson['offsetMm']! as int,
    widthMm: pJson['widthMm']! as int,
  );
}

/// Obstacle le long d'un mur ; depthMm > 0 pour une zone sans parquet (placard, cheminée).
class Obstacle {
  const Obstacle({
    required this.kind,
    required this.wallIndex,
    required this.offsetMm,
    required this.widthMm,
    this.depthMm = 0,
  });

  final ObstacleKind kind;
  final int wallIndex;
  final int offsetMm;
  final int widthMm;
  final int depthMm;

  /// Surface retirée au parquet, en mm².
  int get floorAreaMm2 => widthMm * depthMm;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'wallIndex': wallIndex,
    'offsetMm': offsetMm,
    'widthMm': widthMm,
    'depthMm': depthMm,
  };

  static Obstacle fromJson(Map<String, Object?> pJson) => Obstacle(
    kind: ObstacleKind.values.byName(pJson['kind']! as String),
    wallIndex: pJson['wallIndex']! as int,
    offsetMm: pJson['offsetMm']! as int,
    widthMm: pJson['widthMm']! as int,
    depthMm: (pJson['depthMm'] as int?) ?? 0,
  );
}

/// Un mur, avec l'angle intérieur qu'il forme avec le mur suivant (90 rentrant, 270 sortant).
class Wall {
  const Wall({
    required this.lengthMm,
    this.angleToNextDeg = 90,
    this.openings = const [],
    this.freeEndAfter = false,
  });

  final int lengthMm;
  final double angleToNextDeg;
  final List<Opening> openings;

  /// La plinthe s'arrête au bout du mur, sans coin (contre un meuble, pièce ouverte).
  final bool freeEndAfter;

  /// Coin sortant : la pointe longue de la plinthe est côté pièce.
  bool get isOutsideCornerAfter => angleToNextDeg > 180;

  Wall copyWith({
    int? lengthMm,
    double? angleToNextDeg,
    List<Opening>? openings,
    bool? freeEndAfter,
  }) => Wall(
    lengthMm: lengthMm ?? this.lengthMm,
    angleToNextDeg: angleToNextDeg ?? this.angleToNextDeg,
    openings: openings ?? this.openings,
    freeEndAfter: freeEndAfter ?? this.freeEndAfter,
  );

  Map<String, Object?> toJson() => {
    'lengthMm': lengthMm,
    'angleToNextDeg': angleToNextDeg,
    'openings': [for (final vOpening in openings) vOpening.toJson()],
    'freeEndAfter': freeEndAfter,
  };

  static Wall fromJson(Map<String, Object?> pJson) => Wall(
    lengthMm: pJson['lengthMm']! as int,
    angleToNextDeg: (pJson['angleToNextDeg']! as num).toDouble(),
    openings: [
      for (final vOpening in (pJson['openings'] as List<Object?>?) ?? const [])
        Opening.fromJson(vOpening! as Map<String, Object?>),
    ],
    freeEndAfter: (pJson['freeEndAfter'] as bool?) ?? false,
  );
}

/// Pièce : murs dans l'ordre du tour, dans le sens inverse des aiguilles d'une montre.
class Room {
  const Room({
    required this.id,
    required this.name,
    this.walls = const [],
    this.closed = true,
    this.obstacles = const [],
    this.parquet = const ParquetSettings(),
    this.laidRows = const [],
    this.baseboard = const BaseboardSettings(),
    this.cutPieces = const [],
    this.doneSteps = const [],
    this.touchUps = const [],
  });

  final String id;
  final String name;
  final List<Wall> walls;

  /// Le dernier mur rejoint le premier ; sinon la pièce est ouverte sur un côté.
  final bool closed;
  final List<Obstacle> obstacles;
  final ParquetSettings parquet;

  /// Numéros des rangées de parquet déjà posées.
  final List<int> laidRows;
  final BaseboardSettings baseboard;

  /// Index des morceaux de plinthe déjà coupés, dans la liste de baseboardPieces.
  final List<int> cutPieces;

  /// Étapes du guide déjà faites, par nom (voir GuideStep).
  final List<String> doneSteps;

  /// Choses à faire ou à reprendre dans la pièce.
  final List<TouchUp> touchUps;

  Room copyWith({
    String? name,
    List<Wall>? walls,
    bool? closed,
    List<Obstacle>? obstacles,
    ParquetSettings? parquet,
    List<int>? laidRows,
    BaseboardSettings? baseboard,
    List<int>? cutPieces,
    List<String>? doneSteps,
    List<TouchUp>? touchUps,
  }) => Room(
    id: id,
    name: name ?? this.name,
    walls: walls ?? this.walls,
    closed: closed ?? this.closed,
    obstacles: obstacles ?? this.obstacles,
    parquet: parquet ?? this.parquet,
    laidRows: laidRows ?? this.laidRows,
    baseboard: baseboard ?? this.baseboard,
    cutPieces: cutPieces ?? this.cutPieces,
    doneSteps: doneSteps ?? this.doneSteps,
    touchUps: touchUps ?? this.touchUps,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'walls': [for (final vWall in walls) vWall.toJson()],
    'closed': closed,
    'obstacles': [for (final vObstacle in obstacles) vObstacle.toJson()],
    'parquet': parquet.toJson(),
    'laidRows': laidRows,
    'baseboard': baseboard.toJson(),
    'cutPieces': cutPieces,
    'doneSteps': doneSteps,
    'touchUps': [for (final vTouchUp in touchUps) vTouchUp.toJson()],
  };

  static Room fromJson(Map<String, Object?> pJson) => Room(
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
  );
}
