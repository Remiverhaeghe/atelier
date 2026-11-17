/// Structure d'une mezzanine en bois : solives, lambourde murale, poutre et poteaux.
///
/// Prédimensionnement selon l'Eurocode 5 simplifié : poutres sur deux appuis, flexion à
/// l'état limite ultime, flèche limitée à 1/300 de la portée, poteaux vérifiés au flambement.
/// Il donne un ordre de grandeur pour préparer les achats ; la structure se fait valider par
/// un charpentier ou un bureau d'études, comme le mur qui porte la lambourde et le sol sous
/// les poteaux.
library;

import 'dart:math' as math;

/// Ce qu'on met sur la mezzanine : la charge d'exploitation en dépend.
enum MezzanineUse {
  /// Chambre, bureau, salon : 1,5 kN/m² (150 kg/m²).
  living(liveKnPerM2: 1.5),

  /// Rangement, bibliothèque : 2,5 kN/m².
  storage(liveKnPerM2: 2.5);

  const MezzanineUse({required this.liveKnPerM2});

  final double liveKnPerM2;
}

/// Comment la mezzanine est portée.
enum MezzanineSupport {
  /// Contre un mur : lambourde vissée au mur, poutre sur poteaux de l'autre côté.
  oneWall,

  /// Entre deux murs face à face : une lambourde de chaque côté, aucun poteau.
  twoWalls,

  /// Indépendante : une poutre sur poteaux de chaque côté.
  freestanding,
}

/// Bois massif C24 et lamellé-collé GL24h : résistance en flexion et en compression,
/// modules d'élasticité moyen et au fractile de 5 %, en MPa.
typedef Timber = ({double bendingMpa, double compressionMpa, double meanModulusMpa, double lowModulusMpa});

const c24 = (bendingMpa: 24.0, compressionMpa: 21.0, meanModulusMpa: 11000.0, lowModulusMpa: 7400.0);
const gl24h = (bendingMpa: 24.0, compressionMpa: 24.0, meanModulusMpa: 11500.0, lowModulusMpa: 9600.0);

/// Section rectangulaire : largeur × hauteur, en mm.
typedef Section = ({int widthMm, int heightMm});

/// Sections de solives en C24 vendues couramment, de la plus légère à la plus lourde.
const joistSections = <Section>[
  (widthMm: 45, heightMm: 145),
  (widthMm: 45, heightMm: 170),
  (widthMm: 63, heightMm: 175),
  (widthMm: 45, heightMm: 220),
  (widthMm: 63, heightMm: 200),
  (widthMm: 75, heightMm: 200),
  (widthMm: 63, heightMm: 225),
  (widthMm: 75, heightMm: 225),
  (widthMm: 75, heightMm: 250),
];

/// Poutres en lamellé-collé GL24h.
const beamSections = <Section>[
  (widthMm: 90, heightMm: 225),
  (widthMm: 90, heightMm: 270),
  (widthMm: 115, heightMm: 270),
  (widthMm: 115, heightMm: 315),
  (widthMm: 140, heightMm: 360),
  (widthMm: 160, heightMm: 405),
];

/// Côtés de poteaux carrés en C24.
const postSides = [100, 120, 140, 150];

/// Au-delà de 4 m, une poutre devient lourde à monter et à manier : un poteau de plus.
const maxPostSpacingMm = 4000;

/// Poids propre d'un plancher bois : solives, panneaux et finition, en kN/m².
const deadKnPerM2 = 0.5;

/// Bois à l'intérieur, charges de moyenne durée : kmod 0,8 et coefficient du matériau 1,3.
const _kmod = 0.8;
const _gammaTimber = 1.3;
const _gammaTimberGlulam = 1.25;

/// Une poutre sur deux appuis de [pSpanMm], chargée de [pServiceKnPerM] en service et
/// [pUltimateKnPerM] à l'état limite ultime, tient-elle en flexion et en flèche ?
bool beamHolds(
  Section pSection,
  Timber pTimber,
  int pSpanMm,
  double pServiceKnPerM,
  double pUltimateKnPerM, {
  double pGamma = _gammaTimber,
}) {
  final vB = pSection.widthMm.toDouble();
  final vH = pSection.heightMm.toDouble();
  final vL = pSpanMm.toDouble();
  // kN/m vaut N/mm : les formules restent en newtons et en millimètres
  final vMoment = pUltimateKnPerM * vL * vL / 8;
  final vStress = vMoment / (vB * vH * vH / 6);
  final vInertia = vB * vH * vH * vH / 12;
  final vDeflection = 5 * pServiceKnPerM * math.pow(vL, 4) / (384 * pTimber.meanModulusMpa * vInertia);
  final rHolds = vStress <= _kmod * pTimber.bendingMpa / pGamma && vDeflection <= vL / 300;

  return rHolds;
}

/// Plus légère des [pSections] qui tient la portée, ou null si aucune.
Section? lightestSection(
  List<Section> pSections,
  Timber pTimber,
  int pSpanMm,
  double pServiceKnPerM,
  double pUltimateKnPerM, {
  double pGamma = _gammaTimber,
}) => pSections
    .where(
      (pSection) => beamHolds(pSection, pTimber, pSpanMm, pServiceKnPerM, pUltimateKnPerM, pGamma: pGamma),
    )
    .firstOrNull;

/// Un poteau carré de [pSideMm] et de [pHeightMm] porte-t-il [pLoadKn] sans flamber ?
bool postHolds(int pSideMm, int pHeightMm, double pLoadKn) {
  final vSide = pSideMm.toDouble();
  final vSlenderness = pHeightMm * math.sqrt(12) / vSide;
  final vRelative = vSlenderness / math.pi * math.sqrt(c24.compressionMpa / c24.lowModulusMpa);
  final vK = 0.5 * (1 + 0.2 * (vRelative - 0.3) + vRelative * vRelative);
  final vReduction = math.min(1.0, 1 / (vK + math.sqrt(vK * vK - vRelative * vRelative)));
  final vCapacityN = vReduction * _kmod * c24.compressionMpa / _gammaTimber * vSide * vSide;
  final rHolds = pLoadKn * 1000 <= vCapacityN;

  return rHolds;
}

class Mezzanine {
  const Mezzanine({
    this.lengthMm = 3000,
    this.depthMm = 2000,
    this.postHeightMm = 2200,
    this.joistSpacingMm = 400,
    this.use = MezzanineUse.living,
    this.support = MezzanineSupport.oneWall,
  });

  /// Le long du mur, dans le sens de la poutre.
  final int lengthMm;

  /// Du mur vers le vide : la portée des solives.
  final int depthMm;

  /// Hauteur des poteaux, du sol au-dessous de la poutre.
  final int postHeightMm;

  /// Entre axes de deux solives : 40, 50 ou 60 cm, selon le panneau du plancher.
  final int joistSpacingMm;
  final MezzanineUse use;
  final MezzanineSupport support;

  Mezzanine copyWith({
    int? lengthMm,
    int? depthMm,
    int? postHeightMm,
    int? joistSpacingMm,
    MezzanineUse? use,
    MezzanineSupport? support,
  }) => Mezzanine(
    lengthMm: lengthMm ?? this.lengthMm,
    depthMm: depthMm ?? this.depthMm,
    postHeightMm: postHeightMm ?? this.postHeightMm,
    joistSpacingMm: joistSpacingMm ?? this.joistSpacingMm,
    use: use ?? this.use,
    support: support ?? this.support,
  );

  /// Charge de service et charge ultime (1,35 G + 1,5 Q) par m², en kN.
  double get serviceKnPerM2 => deadKnPerM2 + use.liveKnPerM2;
  double get ultimateKnPerM2 => 1.35 * deadKnPerM2 + 1.5 * use.liveKnPerM2;
}

typedef MezzaninePlan = ({
  int joists,

  /// Section des solives, ou null si la portée est trop grande pour les sections du commerce.
  Section? joist,

  /// Lambourdes vissées au mur : une ou deux selon l'appui.
  int ledgers,

  /// Chevilles chimiques ou goujons dans chaque lambourde, en quinconce.
  int anchorsPerLedger,

  /// Poutres sur poteaux : zéro, une ou deux.
  int beams,
  Section? beam,
  int postsPerBeam,

  /// Entre axes de deux poteaux.
  int postSpacingMm,

  /// Côté du poteau carré, ou null si aucun ne suffit.
  int? postSideMm,

  /// Charge sur le poteau le plus chargé, à l'état limite ultime, en kN.
  double postLoadKn,

  /// Sabots (étriers) : un à chaque bout de chaque solive.
  int hangers,
});

/// Chevilles de lambourde : une tous les 40 cm, au moins trois.
int ledgerAnchors(int pLengthMm) => math.max(3, (pLengthMm / 400).ceil() + 1);

MezzaninePlan planMezzanine(Mezzanine pMezzanine) {
  final vSpacing = pMezzanine.joistSpacingMm <= 0 ? 400 : pMezzanine.joistSpacingMm;
  final vJoists = (pMezzanine.lengthMm / vSpacing).ceil() + 1;
  final vJoist = lightestSection(
    joistSections,
    c24,
    pMezzanine.depthMm,
    pMezzanine.serviceKnPerM2 * vSpacing / 1000,
    pMezzanine.ultimateKnPerM2 * vSpacing / 1000,
  );
  final vLedgers = switch (pMezzanine.support) {
    MezzanineSupport.oneWall => 1,
    MezzanineSupport.twoWalls => 2,
    MezzanineSupport.freestanding => 0,
  };
  final vBeams = 2 - vLedgers;

  // Une poutre de rive reçoit la moitié de la portée des solives
  final vBeamService = pMezzanine.serviceKnPerM2 * pMezzanine.depthMm / 2000;
  final vBeamUltimate = pMezzanine.ultimateKnPerM2 * pMezzanine.depthMm / 2000;
  var vPosts = math.max(2, (pMezzanine.lengthMm / maxPostSpacingMm).ceil() + 1);
  Section? vBeam;
  if (vBeams > 0) {
    // Le moins de poteaux possible : on en ajoute tant qu'aucune poutre ne tient
    while (vPosts <= 12) {
      vBeam = lightestSection(
        beamSections,
        gl24h,
        pMezzanine.lengthMm ~/ (vPosts - 1),
        vBeamService,
        vBeamUltimate,
        pGamma: _gammaTimberGlulam,
      );
      if (vBeam != null) {
        break;
      }
      vPosts++;
    }
  }
  final vPostSpacing = vBeams == 0 ? 0 : pMezzanine.lengthMm ~/ (vPosts - 1);
  // Poteau du bout : une demi-travée. Poteau du milieu d'une poutre continue : 1,25 travée
  final vPostLoad = vBeams == 0
      ? 0.0
      : vBeamUltimate * vPostSpacing / 1000 * (vPosts > 2 ? 1.25 : 0.5);
  final vPostSide = vBeams == 0
      ? null
      : postSides.where((pSide) => postHolds(pSide, pMezzanine.postHeightMm, vPostLoad)).firstOrNull;

  final rPlan = (
    joists: vJoists,
    joist: vJoist,
    ledgers: vLedgers,
    anchorsPerLedger: vLedgers == 0 ? 0 : ledgerAnchors(pMezzanine.lengthMm),
    beams: vBeams,
    beam: vBeams == 0 ? null : vBeam,
    postsPerBeam: vBeams == 0 ? 0 : vPosts,
    postSpacingMm: vPostSpacing,
    postSideMm: vPostSide,
    postLoadKn: vPostLoad,
    hangers: vJoists * 2,
  );

  return rPlan;
}
