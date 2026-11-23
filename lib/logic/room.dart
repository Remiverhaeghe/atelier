/// Modèle d'une pièce saisie mur par mur, sérialisable en JSON.
library;

import 'baseboard.dart';
import 'climate_history.dart';
import 'fixtures.dart';
import 'furniture.dart';
import 'hidden_networks.dart';
import 'house_book.dart';
import 'paint.dart';
import 'parquet.dart';
import 'room_json.dart';
import 'slope.dart';
import 'touch_up.dart';

/// Ouverture dans un mur, sans plinthe sur sa largeur.
enum OpeningKind { door, passage, window }

/// Hauteur de départ d'une ouverture, modifiable : porte standard, fenêtre courante.
int defaultOpeningHeightMm(OpeningKind pKind) => pKind == OpeningKind.window ? 1250 : 2040;

/// Allège d'une fenêtre courante : hauteur du bas de la fenêtre au-dessus du sol.
const defaultSillMm = 900;

/// Élément qui gêne la pose : zone sans parquet ou plinthe interrompue.
/// Usage de la pièce, qui décide de ce qui compte en surface habitable et en Loi Carrez.
enum RoomUsage {
  habitable,

  /// Combles non aménagés : hors surface habitable, comptés en Loi Carrez au-dessus de 1,80 m.
  attic,
  cellar,
  garage,
  veranda,

  /// Balcon, terrasse ou loggia.
  outdoor,
}

enum ObstacleKind { radiator, pipe, cupboard, fireplace, stairFoot }

/// Porte, passage ou fenêtre, placé depuis le début du mur.
class Opening {
  const Opening({
    required this.kind,
    required this.offsetMm,
    required this.widthMm,
    this.threshold = false,
    this.heightMm,
    this.sillMm,
  });

  final OpeningKind kind;
  final int offsetMm;
  final int widthMm;

  /// Hauteur de l'ouverture ; valeur courante si non saisie.
  final int? heightMm;

  /// Allège d'une fenêtre ; une porte ou un passage part du sol.
  final int? sillMm;

  int get height => heightMm ?? defaultOpeningHeightMm(kind);
  int get sill => kind == OpeningKind.window ? (sillMm ?? defaultSillMm) : 0;

  /// Une fenêtre laisse passer la plinthe ; une porte ou un passage la coupe.
  bool get cutsBaseboard => kind != OpeningKind.window;

  /// Barre de seuil sous l'ouverture, comptée dans cette pièce seulement : une porte entre deux
  /// pièces est saisie des deux côtés, la barre ne doit être achetée qu'une fois.
  final bool threshold;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'offsetMm': offsetMm,
    'widthMm': widthMm,
    if (threshold) 'threshold': true,
    if (heightMm != null) 'heightMm': heightMm,
    if (sillMm != null) 'sillMm': sillMm,
  };

  static Opening fromJson(Map<String, Object?> pJson) => Opening(
    kind: OpeningKind.values.byName(pJson['kind']! as String),
    offsetMm: pJson['offsetMm']! as int,
    widthMm: pJson['widthMm']! as int,
    threshold: (pJson['threshold'] as bool?) ?? false,
    heightMm: pJson['heightMm'] as int?,
    sillMm: pJson['sillMm'] as int?,
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
    this.deduced = false,
  });

  final int lengthMm;

  /// Longueur déduite des autres murs sur le dessin de la pièce, pas encore mesurée.
  final bool deduced;
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
    bool? deduced,
  }) => Wall(
    lengthMm: lengthMm ?? this.lengthMm,
    angleToNextDeg: angleToNextDeg ?? this.angleToNextDeg,
    openings: openings ?? this.openings,
    freeEndAfter: freeEndAfter ?? this.freeEndAfter,
    // Une longueur retapée ailleurs que sur le dessin est une mesure
    deduced: deduced ?? (lengthMm == null && this.deduced),
  );

  Map<String, Object?> toJson() => {
    'lengthMm': lengthMm,
    'angleToNextDeg': angleToNextDeg,
    'openings': [for (final vOpening in openings) vOpening.toJson()],
    'freeEndAfter': freeEndAfter,
    if (deduced) 'deduced': true,
  };

  static Wall fromJson(Map<String, Object?> pJson) => Wall(
    lengthMm: pJson['lengthMm']! as int,
    angleToNextDeg: (pJson['angleToNextDeg']! as num).toDouble(),
    openings: [
      for (final vOpening in (pJson['openings'] as List<Object?>?) ?? const [])
        Opening.fromJson(vOpening! as Map<String, Object?>),
    ],
    freeEndAfter: (pJson['freeEndAfter'] as bool?) ?? false,
    deduced: (pJson['deduced'] as bool?) ?? false,
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
    this.ceilingHeightMm = 2500,
    this.paint = const PaintSettings(),
    this.houseXMm = 0,
    this.houseYMm = 0,
    this.houseQuarterTurns = 0,
    this.fixtures = const [],
    this.slope,
    this.slope2,
    this.level = 0,
    this.usage = RoomUsage.habitable,
    this.furniture = const [],
    this.networks = const [],
    this.stepPhotos = const {},
    this.behindWalls = const BehindWalls(),
    this.climate = const ClimateLog(),
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

  /// Hauteur sous plafond, la même pour toute la pièce.
  final int ceilingHeightMm;
  final PaintSettings paint;

  /// Place de la pièce dans le plan de la maison : décalage de son origine et quarts de tour.
  final int houseXMm;
  final int houseYMm;
  final int houseQuarterTurns;

  /// Prises, interrupteurs, escalier, mezzanine et fenêtres de toit posés sur le plan.
  final List<Fixture> fixtures;

  /// Plafond rampant ; null pour un plafond plat.
  final Slope? slope;

  /// Second pan, sur un autre mur : combles avec une pente de chaque côté.
  final Slope? slope2;

  /// Niveau de la maison : 0 pour le rez-de-chaussée, 1 pour le premier étage, -1 pour le sous-sol.
  final int level;

  /// Usage de la pièce : habitable par défaut.
  final RoomUsage usage;

  /// Meubles posés sur le plan pour vérifier la place avant l'achat.
  final List<Furniture> furniture;

  /// Gaines, tuyaux et câbles relevés dans les murs, pour savoir où ne pas percer.
  final List<HiddenRun> networks;

  /// Photos prises à chaque étape du guide, pour se faire ses propres tutos : étape, puis chemins.
  final Map<String, List<String>> stepPhotos;

  /// Solives et photos d'avant fermeture : ce qui reste caché derrière le placo.
  final BehindWalls behindWalls;

  /// Humidité suivie jour par jour d'après les relevés importés, et date des travaux.
  final ClimateLog climate;

  Room copyWith({
    String? id,
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
    int? ceilingHeightMm,
    PaintSettings? paint,
    int? houseXMm,
    int? houseYMm,
    int? houseQuarterTurns,
    List<Fixture>? fixtures,
    Slope? slope,
    bool clearSlope = false,
    Slope? slope2,
    bool clearSlope2 = false,
    int? level,
    RoomUsage? usage,
    List<Furniture>? furniture,
    List<HiddenRun>? networks,
    Map<String, List<String>>? stepPhotos,
    BehindWalls? behindWalls,
    ClimateLog? climate,
  }) => Room(
    id: id ?? this.id,
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
    ceilingHeightMm: ceilingHeightMm ?? this.ceilingHeightMm,
    paint: paint ?? this.paint,
    houseXMm: houseXMm ?? this.houseXMm,
    houseYMm: houseYMm ?? this.houseYMm,
    houseQuarterTurns: (houseQuarterTurns ?? this.houseQuarterTurns) % 4,
    fixtures: fixtures ?? this.fixtures,
    slope: clearSlope ? null : (slope ?? this.slope),
    slope2: clearSlope2 ? null : (slope2 ?? this.slope2),
    level: level ?? this.level,
    usage: usage ?? this.usage,
    furniture: furniture ?? this.furniture,
    networks: networks ?? this.networks,
    stepPhotos: stepPhotos ?? this.stepPhotos,
    behindWalls: behindWalls ?? this.behindWalls,
    climate: climate ?? this.climate,
  );

  Map<String, Object?> toJson() => roomToJson(this);

  static Room fromJson(Map<String, Object?> pJson) => roomFromJson(pJson);
}
