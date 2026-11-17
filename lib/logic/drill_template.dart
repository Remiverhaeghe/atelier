/// Gabarit de perçage à imprimer à l'échelle 1 : trous de tourillons, de vis d'assemblage
/// et de taquets, en millimètres depuis le bord avant de la tablette.
library;

import 'shelf.dart';
import 'shelf_joinery.dart';

/// Trou du gabarit : position le long de la profondeur, dans l'épaisseur ou la hauteur, et
/// diamètre du foret.
typedef TemplateHole = ({double alongMm, double acrossMm, int diameterMm});

/// Pas des trous de taquets : le système 32 des meubles en kit.
const pinPitchMm = 32;

/// Trous d'un bout de tablette sur la face du montant : répartis entre les deux marges, au
/// milieu de l'épaisseur de la tablette.
List<TemplateHole> jointHoles(ShelfDesign pDesign, JointAdvice pJoint) {
  final vCount = pJoint.perEnd < 2 ? 2 : pJoint.perEnd;
  final vSpan = pDesign.depthMm - 2 * pJoint.edgeMarginMm;
  final rHoles = [
    for (var vIndex = 0; vIndex < vCount; vIndex++)
      (
        alongMm: pJoint.edgeMarginMm + vSpan * vIndex / (vCount - 1),
        acrossMm: pDesign.thicknessMm / 2,
        diameterMm: pJoint.joint == ShelfJoint.confirmatScrews ? 7 : pJoint.diameterMm,
      ),
  ];

  return rHoles;
}

/// Deux colonnes de trous de taquets sur [pLengthMm] de hauteur, à [pJoint].edgeMarginMm des
/// bords avant et arrière.
List<TemplateHole> pinHoles(ShelfDesign pDesign, JointAdvice pJoint, {int pLengthMm = 256}) {
  final rHoles = [
    for (var vStep = 0; vStep * pinPitchMm <= pLengthMm; vStep++)
      for (final vAlong in [pJoint.edgeMarginMm, pDesign.depthMm - pJoint.edgeMarginMm])
        (
          alongMm: vAlong.toDouble(),
          acrossMm: (vStep * pinPitchMm).toDouble(),
          diameterMm: pJoint.diameterMm,
        ),
  ];

  return rHoles;
}
