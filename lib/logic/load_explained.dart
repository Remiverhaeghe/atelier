/// Ce que porte une étagère, une poutre ou une mezzanine, traduit en objets du quotidien, et
/// la flèche (l'affaissement au milieu) sous une charge donnée.
///
/// Charges réparties sur toute la portée, appuis simples aux deux bouts. Modules d'élasticité
/// pris à long terme pour les panneaux (ils fluent sous une charge qui dure) : ce sont des
/// ordres de grandeur, pas une note de calcul.
library;

import 'dart:math' as math;

import 'floor_capacity.dart';
import 'mezzanine.dart';
import 'shelf.dart';

/// Pesanteur : 1 kg pèse 9,81 N.
const gravity = 9.81;

/// Objets courants et leur poids indicatif.
enum EverydayLoad {
  booksBox(15),
  waterPack(9),
  adult(80),
  cementBag(35),
  washingMachine(70);

  const EverydayLoad(this.kg);

  final int kg;
}

/// Module d'élasticité à long terme d'un panneau de tablette, en MPa.
double shelfModulusMpa(ShelfMaterial pMaterial) => switch (pMaterial) {
  ShelfMaterial.particleBoard => 1800,
  ShelfMaterial.mdf => 2500,
  ShelfMaterial.plywood => 5000,
  ShelfMaterial.solidWood => 9000,
};

/// Flèche admise sous une tablette : au-delà de 1/200 de la portée, elle se voit.
const shelfDeflectionRatio = 200;

/// Flèche admise sous une poutre ou une solive de plancher.
const beamDeflectionRatio = 300;

/// Flèche au milieu, en mm, d'une pièce de portée [pSpanMm] chargée de [pKg] répartis.
double deflectionMm(double pKg, int pSpanMm, double pModulusMpa, double pInertiaMm4) {
  if (pSpanMm <= 0 || pModulusMpa <= 0 || pInertiaMm4 <= 0) {
    return 0;
  }
  final vSpan = pSpanMm.toDouble();
  final rDeflection = 5 * pKg * gravity * math.pow(vSpan, 3) / (384 * pModulusMpa * pInertiaMm4);

  return rDeflection;
}

/// Charge répartie qui donne la flèche [pMaxMm], en kg.
double _kgForDeflection(double pMaxMm, int pSpanMm, double pModulusMpa, double pInertiaMm4) {
  final vUnit = deflectionMm(1, pSpanMm, pModulusMpa, pInertiaMm4);

  return vUnit <= 0 ? 0 : pMaxMm / vUnit;
}

/// Pièce chargée : ce qu'elle porte, sa portée et de quoi calculer sa flèche.
typedef LoadedMember = ({
  double maxKg,
  int spanMm,
  double modulusMpa,
  double inertiaMm4,

  /// Flèche admise, en mm.
  double limitMm,
});

/// Tablette de [pSpanMm] entre appuis, profonde de [pDepthMm], épaisse de [pThicknessMm].
LoadedMember shelfMember(int pSpanMm, int pDepthMm, int pThicknessMm, ShelfMaterial pMaterial) {
  final vInertia = pDepthMm * math.pow(pThicknessMm, 3) / 12;
  final vModulus = shelfModulusMpa(pMaterial);
  final vLimit = pSpanMm / shelfDeflectionRatio;
  final rMember = (
    maxKg: _kgForDeflection(vLimit, pSpanMm, vModulus, vInertia.toDouble()),
    spanMm: pSpanMm,
    modulusMpa: vModulus,
    inertiaMm4: vInertia.toDouble(),
    limitMm: vLimit,
  );

  return rMember;
}

/// Poutre en C24 de section [pSection] sur [pSpanMm] : la plus petite charge entre la
/// flexion (charge pondérée de 1,5, bois à l'intérieur) et la flèche à 1/300.
LoadedMember beamMember(Section pSection, int pSpanMm) {
  final vB = pSection.widthMm.toDouble();
  final vH = pSection.heightMm.toDouble();
  final vInertia = vB * vH * vH * vH / 12;
  final vSpan = pSpanMm.toDouble();
  final vLimit = pSpanMm / beamDeflectionRatio;
  final vFromDeflection = _kgForDeflection(vLimit, pSpanMm, c24.meanModulusMpa, vInertia);
  // Moment résistant, puis charge répartie ultime qui le produit : q L² / 8
  final vMoment = 0.8 * c24.bendingMpa / 1.3 * vB * vH * vH / 6;
  final vFromBending = pSpanMm <= 0 ? 0.0 : 8 * vMoment / vSpan / 1.5 / gravity;
  final rMember = (
    maxKg: math.min(vFromDeflection, vFromBending),
    spanMm: pSpanMm,
    modulusMpa: c24.meanModulusMpa,
    inertiaMm4: vInertia,
    limitMm: vLimit,
  );

  return rMember;
}

/// Mezzanine de [pLengthMm] × [pDepthMm] sur solives de [pJoist] tous les [pSpacingMm] :
/// la charge d'exploitation de `floor_capacity`, sur toute la surface. La flèche est celle
/// d'une solive sous sa bande de plancher.
LoadedMember mezzanineMember(Section pJoist, int pSpacingMm, int pDepthMm, int pLengthMm) {
  final vKnPerM2 = liveCapacityKnPerM2(pJoist, pSpacingMm, pDepthMm);
  final vB = pJoist.widthMm.toDouble();
  final vH = pJoist.heightMm.toDouble();
  final vJoists = pSpacingMm <= 0 ? 1 : (pLengthMm / pSpacingMm).ceil() + 1;
  final rMember = (
    maxKg: vKnPerM2 * pLengthMm * pDepthMm / 1e6 * 1000 / gravity,
    spanMm: pDepthMm,
    modulusMpa: c24.meanModulusMpa,
    // Toutes les solives travaillent ensemble : leur inertie s'additionne
    inertiaMm4: vB * vH * vH * vH / 12 * vJoists,
    limitMm: pDepthMm / beamDeflectionRatio,
  );

  return rMember;
}

/// Combien d'objets [pLoad] la pièce porte, arrondi en dessous.
int objectsHeld(LoadedMember pMember, EverydayLoad pLoad) => (pMember.maxKg / pLoad.kg).floor();

/// Flèche sous [pCount] objets [pLoad], et vrai si elle dépasse ce qui est admis ou si la
/// charge dépasse ce que porte la pièce.
({double deflectionMm, bool tooMuch}) loadedDeflection(
  LoadedMember pMember,
  EverydayLoad pLoad,
  int pCount,
) {
  final vKg = (pLoad.kg * pCount).toDouble();
  final vDeflection = deflectionMm(vKg, pMember.spanMm, pMember.modulusMpa, pMember.inertiaMm4);
  final rResult = (deflectionMm: vDeflection, tooMuch: vKg > pMember.maxKg + 1e-9);

  return rResult;
}

/// Exagération du dessin : la flèche dessinée vaut un dixième de la portée, au plus ×200.
double drawingScale(double pDeflectionMm, int pSpanMm) {
  if (pDeflectionMm <= 0) {
    return 1;
  }
  final rScale = (pSpanMm / 10 / pDeflectionMm).clamp(1.0, 200.0);

  return rScale;
}
