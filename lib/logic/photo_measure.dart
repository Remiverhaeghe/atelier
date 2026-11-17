/// Mesure sur une photo, avec une carte au format bancaire posée à plat comme étalon.
library;

import 'geometry.dart';

/// Grand côté d'une carte au format ID-1 (carte bancaire, carte de fidélité).
const cardLongSideMm = 85.6;

/// Longueur réelle entre [pFrom] et [pTo], d'après le grand côté de la carte touché de
/// [pCardA] à [pCardB] ; null si les deux bouts de la carte se confondent.
///
/// Juste seulement si l'objet est dans le même plan que la carte et la photo prise de face.
int? photoMeasureMm(PlanPoint pCardA, PlanPoint pCardB, PlanPoint pFrom, PlanPoint pTo) {
  final vCard = pCardA.distanceTo(pCardB);
  if (vCard <= 0) {
    return null;
  }

  return (pFrom.distanceTo(pTo) * cardLongSideMm / vCard).round();
}
