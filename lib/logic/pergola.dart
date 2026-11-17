/// Pergola ou auvent en bois : chevrons, poutres, poteaux et plots en béton.
///
/// Mêmes vérifications que la mezzanine (Eurocode 5 simplifié), avec la neige de la région
/// et le poids de la couverture. Le vent soulève une couverture pleine : les poteaux se
/// fixent dans des plots, jamais simplement posés. Prédimensionnement à faire valider.
library;

import 'dart:math' as math;

import 'mezzanine.dart';

/// Neige au sol des régions de la carte française, à moins de 200 m d'altitude, en kN/m².
enum SnowRegion {
  a(groundKnPerM2: 0.45),
  b(groundKnPerM2: 0.55),
  c(groundKnPerM2: 0.65),
  d(groundKnPerM2: 0.90),
  e(groundKnPerM2: 1.40);

  const SnowRegion({required this.groundKnPerM2});

  final double groundKnPerM2;
}

/// Ce qui couvre la pergola : son poids, et si la neige peut s'y poser.
enum PergolaCover {
  /// Lattes ou rien : la neige passe au travers.
  open(deadKnPerM2: 0.05, holdsSnow: false),

  /// Plaques de polycarbonate alvéolaire.
  polycarbonate(deadKnPerM2: 0.15, holdsSnow: true),

  /// Bac acier ou tôle ondulée.
  steelSheet(deadKnPerM2: 0.15, holdsSnow: true),

  /// Tuiles sur liteaux.
  tiles(deadKnPerM2: 0.6, holdsSnow: true);

  const PergolaCover({required this.deadKnPerM2, required this.holdsSnow});

  final double deadKnPerM2;
  final bool holdsSnow;
}

/// Coefficient de forme d'un toit presque plat.
const snowShapeFactor = 0.8;

/// Plot en béton sous chaque poteau : 40 × 40 cm, 50 cm de profondeur (hors gel).
const footingSideMm = 400;
const footingDepthMm = 500;

class Pergola {
  const Pergola({
    this.lengthMm = 4000,
    this.depthMm = 3000,
    this.postHeightMm = 2400,
    this.rafterSpacingMm = 600,
    this.cover = PergolaCover.polycarbonate,
    this.region = SnowRegion.a,
    this.againstWall = true,
  });

  /// Le long de la façade, dans le sens des poutres.
  final int lengthMm;

  /// De la façade vers le jardin : la portée des chevrons.
  final int depthMm;
  final int postHeightMm;
  final int rafterSpacingMm;
  final PergolaCover cover;
  final SnowRegion region;

  /// Adossée : lambourde vissée à la façade et une seule poutre sur poteaux.
  final bool againstWall;

  Pergola copyWith({
    int? lengthMm,
    int? depthMm,
    int? postHeightMm,
    int? rafterSpacingMm,
    PergolaCover? cover,
    SnowRegion? region,
    bool? againstWall,
  }) => Pergola(
    lengthMm: lengthMm ?? this.lengthMm,
    depthMm: depthMm ?? this.depthMm,
    postHeightMm: postHeightMm ?? this.postHeightMm,
    rafterSpacingMm: rafterSpacingMm ?? this.rafterSpacingMm,
    cover: cover ?? this.cover,
    region: region ?? this.region,
    againstWall: againstWall ?? this.againstWall,
  );

  double get snowKnPerM2 => cover.holdsSnow ? snowShapeFactor * region.groundKnPerM2 : 0;

  /// Poids propre : couverture et bois (0,1 kN/m²).
  double get deadKnPerM2 => cover.deadKnPerM2 + 0.1;
  double get serviceKnPerM2 => deadKnPerM2 + snowKnPerM2;
  double get ultimateKnPerM2 => 1.35 * deadKnPerM2 + 1.5 * snowKnPerM2;
}

typedef PergolaPlan = ({
  int rafters,
  Section? rafter,
  int beams,
  Section? beam,
  int postsPerBeam,
  int postSpacingMm,
  int? postSideMm,

  /// Béton des plots, en litres.
  int concreteLitres,
});

PergolaPlan planPergola(Pergola pPergola) {
  final vSpacing = pPergola.rafterSpacingMm <= 0 ? 600 : pPergola.rafterSpacingMm;
  final vRafter = lightestSection(
    joistSections,
    c24,
    pPergola.depthMm,
    pPergola.serviceKnPerM2 * vSpacing / 1000,
    pPergola.ultimateKnPerM2 * vSpacing / 1000,
  );
  final vBeams = pPergola.againstWall ? 1 : 2;
  final vBeamService = pPergola.serviceKnPerM2 * pPergola.depthMm / 2000;
  final vBeamUltimate = pPergola.ultimateKnPerM2 * pPergola.depthMm / 2000;
  var vPosts = math.max(2, (pPergola.lengthMm / maxPostSpacingMm).ceil() + 1);
  Section? vBeam;
  while (vPosts <= 12) {
    vBeam = lightestSection(
      beamSections,
      gl24h,
      pPergola.lengthMm ~/ (vPosts - 1),
      vBeamService,
      vBeamUltimate,
      pGamma: 1.25,
    );
    if (vBeam != null) {
      break;
    }
    vPosts++;
  }
  final vPostSpacing = pPergola.lengthMm ~/ (vPosts - 1);
  final vPostLoad = vBeamUltimate * vPostSpacing / 1000 * (vPosts > 2 ? 1.25 : 0.5);
  final vPostCount = vPosts * vBeams;
  final rPlan = (
    rafters: (pPergola.lengthMm / vSpacing).ceil() + 1,
    rafter: vRafter,
    beams: vBeams,
    beam: vBeam,
    postsPerBeam: vPosts,
    postSpacingMm: vPostSpacing,
    postSideMm: postSides
        .where((pSide) => postHolds(pSide, pPergola.postHeightMm, vPostLoad))
        .firstOrNull,
    concreteLitres: (vPostCount * footingSideMm * footingSideMm * footingDepthMm / 1e6).round(),
  );

  return rPlan;
}
