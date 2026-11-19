/// Mesure sur une photo, avec un objet de taille connue posé à plat comme étalon : une carte au
/// format bancaire ou une feuille A4.
library;

import 'geometry.dart';

/// Grand côté d'une carte au format ID-1 (carte bancaire, carte de fidélité).
const cardLongSideMm = 85.6;

/// Étalon posé sur la photo, avec la longueur du côté qu'on touche.
///
/// La feuille A4 est trois fois plus grande que la carte : à erreur de doigt égale, la mesure
/// est trois fois plus juste. Elle sert pour une porte, un mur ou un meuble.
enum MeasureReference {
  card(cardLongSideMm),
  a4Long(297),
  a4Short(210);

  const MeasureReference(this.sideMm);

  final double sideMm;
}

/// Longueur réelle entre [pFrom] et [pTo], d'après le côté de l'étalon touché de [pRefA] à
/// [pRefB] et long de [pReferenceMm] ; null si les deux bouts de l'étalon se confondent.
///
/// Juste seulement si l'objet est dans le même plan que l'étalon et la photo prise de face.
int? photoMeasureMm(
  PlanPoint pRefA,
  PlanPoint pRefB,
  PlanPoint pFrom,
  PlanPoint pTo, {
  double pReferenceMm = cardLongSideMm,
}) {
  final vReference = pRefA.distanceTo(pRefB);
  if (vReference <= 0) {
    return null;
  }

  return (pFrom.distanceTo(pTo) * pReferenceMm / vReference).round();
}

/// Écart possible sur [pMeasuredMm] quand chaque bout de l'étalon, long de [pReferencePx] sur
/// l'écran, est touché à [pTapPx] près ; null si l'étalon est trop petit pour être lu.
int? photoMeasureSpreadMm(int pMeasuredMm, double pReferencePx, {double pTapPx = 3}) {
  if (pReferencePx <= 2 * pTapPx) {
    return null;
  }
  final rSpread = (pMeasuredMm * 2 * pTapPx / pReferencePx).round();

  return rSpread;
}
