/// Carnet de la maison, côté caché : solives, photos des murs avant fermeture, fenêtres et
/// références posées, rassemblés pièce par pièce pour un dossier de revente.
library;

import 'fixtures.dart';
import 'hidden_networks.dart';
import 'journal.dart';
import 'room.dart';
import 'worksite.dart';

/// Solives du plancher (sous les pieds) ou du plafond (au-dessus de la tête).
enum JoistPlace { floor, ceiling }

/// Série de solives parallèles, repérées le long d'un mur qu'elles croisent à angle droit.
class JoistSet {
  const JoistSet({
    required this.id,
    required this.place,
    required this.wallIndex,
    required this.firstMm,
    required this.spacingMm,
    this.widthMm = 75,
    this.heightMm = 200,
  });

  final String id;
  final JoistPlace place;

  /// Mur le long duquel on mesure : les solives le croisent.
  final int wallIndex;

  /// Axe de la première solive depuis le début du mur, puis entraxe.
  final int firstMm;
  final int spacingMm;

  /// Section d'une solive : largeur vue du dessous et hauteur.
  final int widthMm;
  final int heightMm;

  Map<String, Object?> toJson() => {
    'id': id,
    'place': place.name,
    'wallIndex': wallIndex,
    'firstMm': firstMm,
    'spacingMm': spacingMm,
    'widthMm': widthMm,
    'heightMm': heightMm,
  };

  static JoistSet fromJson(Map<String, Object?> pJson) => JoistSet(
    id: pJson['id']! as String,
    place: JoistPlace.values.asNameMap()[pJson['place']] ?? JoistPlace.floor,
    wallIndex: pJson['wallIndex']! as int,
    firstMm: pJson['firstMm']! as int,
    spacingMm: pJson['spacingMm']! as int,
    widthMm: (pJson['widthMm'] as int?) ?? 75,
    heightMm: (pJson['heightMm'] as int?) ?? 200,
  );
}

/// Photo d'un mur, du sol ou du plafond prise avant de fermer, pour retrouver ce qu'il y a
/// derrière sans ouvrir. [wallIndex] vaut -1 pour le sol, -2 pour le plafond.
class ClosingPhoto {
  const ClosingPhoto({
    required this.id,
    required this.wallIndex,
    required this.path,
    required this.day,
    this.note = '',
  });

  final String id;
  final int wallIndex;
  final String path;

  /// Jour de la photo, au format AAAA-MM-JJ.
  final String day;
  final String note;

  Map<String, Object?> toJson() => {
    'id': id,
    'wallIndex': wallIndex,
    'path': path,
    'day': day,
    if (note.isNotEmpty) 'note': note,
  };

  static ClosingPhoto fromJson(Map<String, Object?> pJson) => ClosingPhoto(
    id: pJson['id']! as String,
    wallIndex: pJson['wallIndex']! as int,
    path: pJson['path']! as String,
    day: pJson['day']! as String,
    note: (pJson['note'] as String?) ?? '',
  );
}

const floorPhotoIndex = -1;
const ceilingPhotoIndex = -2;

/// Ce qui est caché dans une pièce, en plus des réseaux relevés.
class BehindWalls {
  const BehindWalls({this.joists = const [], this.photos = const []});

  final List<JoistSet> joists;
  final List<ClosingPhoto> photos;

  bool get isEmpty => joists.isEmpty && photos.isEmpty;

  BehindWalls copyWith({List<JoistSet>? joists, List<ClosingPhoto>? photos}) =>
      BehindWalls(joists: joists ?? this.joists, photos: photos ?? this.photos);

  Map<String, Object?> toJson() => {
    if (joists.isNotEmpty) 'joists': [for (final vJoist in joists) vJoist.toJson()],
    if (photos.isNotEmpty) 'photos': [for (final vPhoto in photos) vPhoto.toJson()],
  };

  static BehindWalls fromJson(Map<String, Object?> pJson) => BehindWalls(
    joists: [
      for (final vJoist in (pJson['joists'] as List<Object?>?) ?? const [])
        JoistSet.fromJson(vJoist! as Map<String, Object?>),
    ],
    photos: [
      for (final vPhoto in (pJson['photos'] as List<Object?>?) ?? const [])
        ClosingPhoto.fromJson(vPhoto! as Map<String, Object?>),
    ],
  );
}

/// Entraxes courants des solives, en mm : 40 cm en plancher léger, 50 et 60 cm ailleurs.
const joistSpacingsMm = [400, 500, 600];

/// Axes des solives le long de leur mur, du début à la fin ; vide si le mur n'existe pas.
List<int> joistAxes(Room pRoom, JoistSet pJoists) {
  if (pJoists.wallIndex >= pRoom.walls.length || pJoists.spacingMm <= 0) {
    return const [];
  }
  final vLength = pRoom.walls[pJoists.wallIndex].lengthMm;
  final rAxes = [
    for (var vAxis = pJoists.firstMm; vAxis <= vLength; vAxis += pJoists.spacingMm) vAxis,
  ];

  return rAxes;
}

/// Fenêtre de la pièce, mur par mur, ou fenêtre de toit posée sur le plan (mur 0).
typedef WindowNote = ({int wallNumber, int widthMm, int heightMm, int sillMm, bool roof});

List<WindowNote> windowsOf(Room pRoom) => [
  for (final (vIndex, vWall) in pRoom.walls.indexed)
    for (final vOpening in vWall.openings)
      if (vOpening.kind == OpeningKind.window)
        (
          wallNumber: vIndex + 1,
          widthMm: vOpening.widthMm,
          heightMm: vOpening.height,
          sillMm: vOpening.sill,
          roof: false,
        ),
  for (final vFixture in pRoom.fixtures)
    if (vFixture.kind == FixtureKind.roofWindow)
      (
        wallNumber: 0,
        widthMm: vFixture.widthMm,
        heightMm: vFixture.depthMm,
        sillMm: 0,
        roof: true,
      ),
];

/// Murs où des réseaux sont relevés mais sans photo avant fermeture : à photographier avant
/// de poser le placo.
List<int> wallsToPhotograph(Room pRoom) {
  final vPhotographed = {for (final vPhoto in pRoom.behindWalls.photos) vPhoto.wallIndex};
  final rWalls = {
    for (final vRun in pRoom.networks)
      if (!vPhotographed.contains(vRun.wallIndex)) vRun.wallIndex,
  }.toList()..sort();

  return rWalls;
}

/// Page du dossier pour une pièce.
typedef RoomBook = ({
  Room room,
  Map<NetworkKind, int> networkLengths,
  List<WindowNote> windows,
  List<JournalEntry> references,
  List<int> toPhotograph,
});

/// Une page par pièce qui a quelque chose à transmettre : réseaux, solives, photos, fenêtres
/// ou travaux notés avec une référence.
List<RoomBook> houseBook(Worksite pWorksite) {
  final rPages = <RoomBook>[];
  for (final vRoom in pWorksite.rooms) {
    final vReferences = [
      for (final vEntry in journalOf(pWorksite.journal, pRoomId: vRoom.id))
        if (vEntry.reference.isNotEmpty || vEntry.product.isNotEmpty) vEntry,
    ];
    final vWindows = windowsOf(vRoom);
    final vEmpty =
        vRoom.networks.isEmpty &&
        vRoom.behindWalls.isEmpty &&
        vWindows.isEmpty &&
        vReferences.isEmpty;
    if (vEmpty) {
      continue;
    }
    rPages.add((
      room: vRoom,
      networkLengths: networkLengths(vRoom.networks),
      windows: vWindows,
      references: vReferences,
      toPhotograph: wallsToPhotograph(vRoom),
    ));
  }

  return rPages;
}
