/// Ce que porte un plancher existant sur solives : charge d'exploitation admise, comparée à
/// ce qu'on veut y poser, et effet des renforts courants.
///
/// Même modèle que la mezzanine (C24, flexion à l'état limite ultime, flèche à 1/300), mais
/// à l'envers : on part des solives mesurées. Un bois ancien, entaillé ou attaqué porte
/// moins : c'est un ordre de grandeur, à faire confirmer avant un poids important.
library;

import 'dart:math' as math;

import 'mezzanine.dart';

/// Ce qu'on veut poser, ramené à une charge répartie sur la zone qu'il occupe, en kN/m².
enum FloorUse {
  /// Pièce d'habitation : la charge de la réglementation.
  living(knPerM2: 1.5),

  /// Baignoire remplie avec la personne dedans, sur environ 1,2 m².
  bath(knPerM2: 3.0),

  /// Bibliothèque pleine contre un mur.
  bookcase(knPerM2: 5.0),

  /// Poêle à bois ou à granulés posé sur sa plaque.
  stove(knPerM2: 4.0),

  /// Lit d'eau, aquarium, poêle de masse : à faire étudier.
  veryHeavy(knPerM2: 10.0);

  const FloorUse({required this.knPerM2});

  final double knPerM2;
}

/// Charge d'exploitation que tiennent des solives de [pJoist] tous les [pSpacingMm] sur
/// [pSpanMm], en kN/m² : la plus petite entre flexion et flèche.
double liveCapacityKnPerM2(Section pJoist, int pSpacingMm, int pSpanMm) {
  if (pSpacingMm <= 0 || pSpanMm <= 0) {
    return 0;
  }
  final vB = pJoist.widthMm.toDouble();
  final vH = pJoist.heightMm.toDouble();
  final vL = pSpanMm.toDouble();
  final vSpacingM = pSpacingMm / 1000;
  // Flexion : moment résistant, puis charge ultime répartie qui le produit (q L² / 8)
  final vMomentNmm = 0.8 * c24.bendingMpa / 1.3 * vB * vH * vH / 6;
  final vUltimate = 8 * vMomentNmm / (vL * vL) / vSpacingM;
  final vFromBending = (vUltimate - 1.35 * deadKnPerM2) / 1.5;
  // Flèche : charge de service qui donne L / 300
  final vInertia = vB * vH * vH * vH / 12;
  final vService = 384 * c24.meanModulusMpa * vInertia / (5 * math.pow(vL, 3) * 300) / vSpacingM;
  final vFromDeflection = vService - deadKnPerM2;
  final rCapacity = math.max(0.0, math.min(vFromBending, vFromDeflection));

  return rCapacity;
}

typedef Reinforcement = ({double doubled, double halfSpacing, double midBeam});

/// Charge admise après chacun des renforts courants : solives doublées (moisées), une
/// solive de plus entre chaque, ou une poutre sous le milieu de la portée.
Reinforcement reinforcements(Section pJoist, int pSpacingMm, int pSpanMm) => (
  doubled: liveCapacityKnPerM2(
    (widthMm: 2 * pJoist.widthMm, heightMm: pJoist.heightMm),
    pSpacingMm,
    pSpanMm,
  ),
  halfSpacing: liveCapacityKnPerM2(pJoist, pSpacingMm ~/ 2, pSpanMm),
  midBeam: liveCapacityKnPerM2(pJoist, pSpacingMm, pSpanMm ~/ 2),
);
