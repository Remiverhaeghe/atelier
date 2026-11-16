/// Éléments posés sur le plan d'une pièce et aide à la saisie des mesures.
library;

/// Prise, interrupteur, escalier, mezzanine, fenêtre de toit ou trémie (ouverture dans le sol).
enum FixtureKind { socket, lightSwitch, stairs, mezzanine, roofWindow, stairwell }

/// Les éléments ponctuels n'ont pas de surface sur le plan.
bool hasArea(FixtureKind pKind) =>
    pKind == FixtureKind.stairs ||
    pKind == FixtureKind.mezzanine ||
    pKind == FixtureKind.roofWindow ||
    pKind == FixtureKind.stairwell;

/// Dimensions proposées à la saisie : escalier droit, mezzanine, Velux courant (78 × 98 cm).
({int widthMm, int depthMm}) defaultFixtureSize(FixtureKind pKind) => switch (pKind) {
  FixtureKind.stairs => (widthMm: 800, depthMm: 3000),
  FixtureKind.mezzanine => (widthMm: 3000, depthMm: 2000),
  FixtureKind.roofWindow => (widthMm: 780, depthMm: 980),
  FixtureKind.stairwell => (widthMm: 900, depthMm: 2800),
  FixtureKind.socket || FixtureKind.lightSwitch => (widthMm: 0, depthMm: 0),
};

/// Élément du plan, centré sur (xMm, yMm) dans le repère de la pièce.
class Fixture {
  const Fixture({
    required this.id,
    required this.kind,
    required this.xMm,
    required this.yMm,
    this.widthMm = 0,
    this.depthMm = 0,
    this.riseMm,
    this.count = 1,
    this.plexi = false,
  });

  final String id;
  final FixtureKind kind;
  final int xMm;
  final int yMm;

  /// Largeur (axe x) et profondeur (axe y) des éléments qui ont une surface.
  final int widthMm;
  final int depthMm;

  /// Escalier : hauteur à monter, de sol fini à sol fini. Mezzanine : hauteur de son plancher.
  final int? riseMm;

  /// Prises ou interrupteurs regroupés au même endroit (bloc de deux prises : 2).
  final int count;

  /// Fenêtre de toit fermée par un plexi ou un panneau fixe : point faible, à remplacer.
  final bool plexi;

  double get areaM2 => hasArea(kind) ? widthMm * depthMm / 1e6 : 0;

  Fixture copyWith({
    int? xMm,
    int? yMm,
    int? widthMm,
    int? depthMm,
    int? riseMm,
    int? count,
    bool? plexi,
  }) => Fixture(
    id: id,
    kind: kind,
    xMm: xMm ?? this.xMm,
    yMm: yMm ?? this.yMm,
    widthMm: widthMm ?? this.widthMm,
    depthMm: depthMm ?? this.depthMm,
    riseMm: riseMm ?? this.riseMm,
    count: count ?? this.count,
    plexi: plexi ?? this.plexi,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'xMm': xMm,
    'yMm': yMm,
    if (hasArea(kind)) 'widthMm': widthMm,
    if (hasArea(kind)) 'depthMm': depthMm,
    if (riseMm != null) 'riseMm': riseMm,
    if (count != 1) 'count': count,
    if (plexi) 'plexi': true,
  };

  static Fixture fromJson(Map<String, Object?> pJson) => Fixture(
    id: pJson['id']! as String,
    kind: FixtureKind.values.byName(pJson['kind']! as String),
    xMm: pJson['xMm']! as int,
    yMm: pJson['yMm']! as int,
    widthMm: (pJson['widthMm'] as int?) ?? 0,
    depthMm: (pJson['depthMm'] as int?) ?? 0,
    riseMm: pJson['riseMm'] as int?,
    count: (pJson['count'] as int?) ?? 1,
    plexi: (pJson['plexi'] as bool?) ?? false,
  );
}

/// Nombre total d'éléments d'un type, en comptant les blocs (deux prises côte à côte : 2).
int fixtureCount(List<Fixture> pFixtures, FixtureKind pKind) => pFixtures
    .where((pFixture) => pFixture.kind == pKind)
    .fold(0, (pTotal, pFixture) => pTotal + pFixture.count);

/// Surface des fenêtres de toit, à retirer du plafond à peindre.
double roofWindowsM2(List<Fixture> pFixtures) => pFixtures
    .where((pFixture) => pFixture.kind == FixtureKind.roofWindow)
    .fold(0.0, (pTotal, pFixture) => pTotal + pFixture.areaM2);

/// Surface des trémies : le sol de l'étage s'arrête au-dessus de l'escalier.
int stairwellsMm2(List<Fixture> pFixtures) => pFixtures
    .where((pFixture) => pFixture.kind == FixtureKind.stairwell)
    .fold(0, (pTotal, pFixture) => pTotal + pFixture.widthMm * pFixture.depthMm);

/// Hauteur à monter jusqu'à la première mezzanine dont le plancher est saisi, ou null.
int? mezzanineFloorMm(List<Fixture> pFixtures) => pFixtures
    .where((pFixture) => pFixture.kind == FixtureKind.mezzanine && pFixture.riseMm != null)
    .map((pFixture) => pFixture.riseMm!)
    .firstOrNull;

/// Surface des mezzanines : un second niveau de sol dans la pièce.
double mezzaninesM2(List<Fixture> pFixtures) => pFixtures
    .where((pFixture) => pFixture.kind == FixtureKind.mezzanine)
    .fold(0.0, (pTotal, pFixture) => pTotal + pFixture.areaM2);

/// Escalier droit calculé par la loi de Blondel (2 hauteurs + 1 giron ≈ 63 cm).
typedef StairPlan = ({int risers, int riserMm, int goingMm, int runMm});

/// Hauteur de marche visée : confortable entre 16 et 20 cm.
const targetRiserMm = 175;

/// Giron qui complète la loi de Blondel pour une hauteur de marche donnée.
const blondelMm = 630;

/// Nombre de marches et giron pour monter [pRiseMm] ; la longueur compte une marche de moins
/// que de hauteurs, la dernière étant le palier d'arrivée.
StairPlan stairPlan(int pRiseMm) {
  final vRisers = (pRiseMm / targetRiserMm).round().clamp(1, 1000);
  final vRiser = (pRiseMm / vRisers).round();
  final vGoing = blondelMm - 2 * vRiser;
  final rPlan = (risers: vRisers, riserMm: vRiser, goingMm: vGoing, runMm: (vRisers - 1) * vGoing);

  return rPlan;
}

/// Nom du coin [pIndex] : A, B, C… puis A2, B2… au-delà de 26 coins.
String cornerName(int pIndex) {
  final vLetter = String.fromCharCode(65 + pIndex % 26);
  final vRound = pIndex ~/ 26;
  final rName = vRound == 0 ? vLetter : '$vLetter${vRound + 1}';

  return rName;
}

/// Coins entre lesquels mesurer le mur [pIndex] (base 0) ; le dernier mur d'une pièce
/// fermée revient au coin A.
({String from, String to}) wallCorners(int pIndex, {bool pClosesRoom = false}) =>
    (from: cornerName(pIndex), to: pClosesRoom ? cornerName(0) : cornerName(pIndex + 1));
