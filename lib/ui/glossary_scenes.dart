import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/glossary.dart';
import 'sketch3d.dart';

/// Schéma en relief d'un mot du lexique : la pièce dont on parle est surlignée.
({List<Prism> parts, List<Callout> callouts}) termScene(AppLocalizations pText, Term pTerm) {
  PartRole vIf(bool pShown, [PartRole pOther = PartRole.wood]) =>
      pShown ? PartRole.highlight : pOther;
  Callout vLabel(double pX, double pY, double pZ, String pText, Offset pShift) =>
      (at: (x: pX, y: pY, z: pZ), text: pText, shift: pShift);

  final rScene = switch (pTerm) {
    Term.tenon || Term.mortise => (
      parts: [
        // Montant à gauche, mortaise creusée dans son flanc ; traverse à droite, prête à entrer
        Prism.box(0, 20, 0, 20, -30, 50),
        Prism.box(19, 21, 5, 15, 4, 16, role: vIf(pTerm == Term.mortise, PartRole.ghost)),
        Prism.box(45, 105, 0, 20, 0, 20),
        Prism.box(28, 45, 5, 15, 4, 16, role: vIf(pTerm == Term.tenon)),
      ],
      callouts: [
        vLabel(36, 5, 16, pText.termTenon, const Offset(30, -70)),
        vLabel(20, 10, 10, pText.termMortise, const Offset(70, 70)),
      ],
    ),
    Term.frame || Term.stile || Term.rail => (
      parts: [
        Prism.box(0, 6, 0, 5, 0, 50, role: vIf(pTerm != Term.rail)),
        Prism.box(34, 40, 0, 5, 0, 50, role: vIf(pTerm != Term.rail)),
        Prism.box(6, 34, 0, 5, 0, 6, role: vIf(pTerm != Term.stile)),
        Prism.box(6, 34, 0, 5, 44, 50, role: vIf(pTerm != Term.stile)),
        Prism.box(6, 34, 2, 3, 6, 44, role: PartRole.glass),
      ],
      callouts: [
        vLabel(3, 0, 30, pText.termStile, const Offset(-30, -20)),
        vLabel(20, 0, 47, pText.termRail, const Offset(10, -36)),
      ],
    ),
    Term.rebate || Term.glazingBead || Term.setting => (
      parts: [
        // Traverse basse vue en coupe : la feuillure est la marche taillée en haut à droite
        Prism(
          [(0, 0), (40, 0), (40, 18), (22, 18), (22, 30), (0, 30)],
          0,
          60,
          role: vIf(pTerm == Term.rebate),
        ),
        Prism.box(24, 28, 4, 56, 20, 62, role: PartRole.glass),
        Prism.box(23, 29, 10, 16, 18, 20, role: vIf(pTerm == Term.setting, PartRole.ghost)),
        Prism.box(30, 37, 0, 60, 18, 26, role: vIf(pTerm == Term.glazingBead)),
      ],
      callouts: [
        vLabel(31, 0, 18, pText.termRebate, const Offset(90, 70)),
        vLabel(37, 30, 26, pText.termGlazingBead, const Offset(110, -40)),
        vLabel(23, 10, 19, pText.termSetting, const Offset(-120, 60)),
      ],
    ),
    Term.joist => (
      parts: [
        for (final vY in [0.0, 25.0, 50.0])
          Prism.box(0, 90, vY, vY + 5, 0, 12, role: PartRole.highlight),
        Prism.box(0, 40, -2, 57, 12, 14, role: PartRole.board),
      ],
      callouts: [vLabel(70, 0, 6, pText.termJoist, const Offset(20, 30))],
    ),
    Term.plasterboard => (
      parts: [
        for (final vX in [4.0, 30.0, 56.0]) Prism.box(vX, vX + 4, 6, 9, 0, 50),
        Prism.box(0, 64, 0, 2, 0, 50, role: PartRole.highlight),
      ],
      callouts: [vLabel(32, 0, 25, pText.termPlasterboard, const Offset(30, -60))],
    ),
    Term.reveal => (
      parts: [
        Prism.box(0, 20, 0, 24, 0, 60, role: PartRole.board),
        Prism.box(40, 60, 0, 24, 0, 60, role: PartRole.board),
        Prism.box(20, 40, 0, 24, 40, 60, role: PartRole.board),
        Prism.box(20, 40, 0, 24, 0, 20, role: PartRole.board),
        Prism.box(20, 21, 0, 22, 20, 40, role: PartRole.highlight),
        Prism.box(20, 40, 0, 22, 20, 21, role: PartRole.highlight),
        Prism.box(20, 40, 22, 24, 20, 40, role: PartRole.glass),
      ],
      callouts: [vLabel(20, 6, 22, pText.termReveal, const Offset(-50, 50))],
    ),
    Term.header => (
      parts: [
        // Le chevron du milieu est coupé pour la fenêtre : deux chevêtres le reprennent
        for (final vY in [0.0, 40.0]) _rafter(vY, 0, 60),
        _rafter(20, 0, 18),
        _rafter(20, 42, 60),
        Prism.box(18, 22, 4, 40, 40, 48, role: PartRole.highlight),
        Prism.box(38, 42, 4, 40, 54, 62, role: PartRole.highlight),
      ],
      callouts: [vLabel(20, 10, 48, pText.termHeader, const Offset(-30, -50))],
    ),
    Term.carrez => (
      parts: [
        Prism.box(0, 100, 0, 40, -3, 0, role: PartRole.board),
        Prism.box(22, 78, 0, 40, 0, 1, role: PartRole.highlight),
        Prism([(0, 0), (4, 0), (4, 16), (50, 50), (50, 54), (0, 20)], 0, 3),
        Prism([(96, 0), (100, 0), (100, 20), (50, 54), (50, 50), (96, 16)], 0, 3),
      ],
      callouts: [vLabel(50, 20, 1, pText.termCarrez, const Offset(30, 40))],
    ),
    Term.grain || Term.edge => (
      parts: [
        Prism.box(0, 90, 0, 30, 0, 5, role: vIf(pTerm == Term.edge)),
        // Veines le long de la planche : c'est le sens du fil
        for (final vY in [5.0, 12.0, 19.0, 25.0])
          Prism.box(4, 86, vY, vY + 0.8, 5, 5.3, role: vIf(pTerm == Term.grain, PartRole.ghost)),
      ],
      callouts: [
        if (pTerm == Term.grain) vLabel(60, 12, 5, pText.termGrain, const Offset(20, -50)),
        if (pTerm == Term.edge) vLabel(45, 0, 2.5, pText.termEdge, const Offset(10, 40)),
      ],
    ),
    Term.chamfer => (
      parts: [
        Prism([(0, 0), (30, 0), (30, 14), (26, 18), (0, 18)], 0, 60),
        Prism([(26, 18), (30, 14), (30.6, 14.6), (26.6, 18.6)], 0, 60, role: PartRole.highlight),
      ],
      callouts: [vLabel(28, 0, 16, pText.termChamfer, const Offset(60, -40))],
    ),
    Term.kerf => (
      parts: [
        Prism.box(0, 46, 0, 30, 0, 6),
        Prism.box(46, 49, 0, 30, 0, 6, role: PartRole.highlight),
        Prism.box(49, 95, 0, 30, 0, 6, role: PartRole.board),
      ],
      callouts: [vLabel(47.5, 0, 6, pText.termKerf, const Offset(0, -50))],
    ),
    Term.pilotHole || Term.countersink => (
      parts: [
        Prism.box(0, 60, 0, 40, 0, 12),
        Prism.box(29, 31, 19, 21, 0, 10, role: vIf(pTerm == Term.pilotHole, PartRole.ghost)),
        Prism(
          [(26, 12), (34, 12), (31, 9.5), (29, 9.5)],
          17,
          23,
          role: vIf(pTerm == Term.countersink, PartRole.ghost),
        ),
      ],
      callouts: [
        vLabel(30, 20, 5, pText.termPilotHole, const Offset(-80, 40)),
        vLabel(34, 20, 12, pText.termCountersink, const Offset(70, -40)),
      ],
    ),
    Term.furring => (
      parts: [
        Prism.box(0, 90, 0, 60, 30, 34, role: PartRole.board),
        for (final vY in [8.0, 28.0, 48.0])
          Prism.box(0, 90, vY, vY + 5, 24, 27, role: PartRole.highlight),
        for (final vY in [8.0, 28.0, 48.0])
          for (final vX in [20.0, 70.0]) Prism.box(vX, vX + 1, vY + 2, vY + 3, 27, 30),
        Prism.box(0, 90, 0, 60, 22, 24, role: PartRole.ghost),
      ],
      callouts: [vLabel(80, 8, 25.5, pText.termFurring, const Offset(40, 30))],
    ),
    Term.vapourBarrier => (
      parts: [
        for (final vX in [0.0, 40.0, 80.0]) Prism.box(vX, vX + 5, 4, 20, 0, 60),
        Prism.box(5, 40, 6, 20, 0, 60, role: PartRole.ghost),
        Prism.box(45, 80, 6, 20, 0, 60, role: PartRole.ghost),
        Prism.box(0, 85, 2.5, 3.5, 0, 60, role: PartRole.highlight),
        Prism.box(0, 85, 0, 1.5, 0, 60, role: PartRole.board),
      ],
      callouts: [vLabel(60, 3, 40, pText.termVapourBarrier, const Offset(50, -30))],
    ),
    Term.rafter || Term.ridge || Term.slope || Term.kneeWall || Term.spacing => (
      parts: [
        Prism.box(6, 9, -2, 48, 0, 30, role: vIf(pTerm == Term.kneeWall, PartRole.board)),
        for (final vY in [0.0, 20.0, 40.0])
          Prism(
            [(0, 30), (60, 70), (60, 76), (0, 36)],
            vY,
            vY + 4,
            role: vIf(pTerm == Term.rafter || pTerm == Term.spacing),
          ),
        Prism.box(58, 66, -2, 48, 70, 78, role: vIf(pTerm == Term.ridge)),
        Prism(
          [(9, 31), (58, 63.6), (58, 65), (9, 32.4)],
          -2,
          48,
          role: pTerm == Term.slope ? PartRole.highlight : PartRole.ghost,
        ),
      ],
      callouts: [
        if (pTerm == Term.kneeWall) vLabel(9, 0, 15, pText.termKneeWall, const Offset(-50, 30)),
        if (pTerm == Term.rafter) vLabel(30, 0, 53, pText.termRafter, const Offset(-30, -40)),
        if (pTerm == Term.ridge) vLabel(62, 0, 78, pText.termRidge, const Offset(30, -30)),
        if (pTerm == Term.slope) vLabel(30, 0, 47, pText.termSlope, const Offset(-40, 40)),
        if (pTerm == Term.spacing) vLabel(30, 10, 53, pText.termSpacing, const Offset(-30, -50)),
      ],
    ),
  };

  return rScene;
}

/// Chevron en pente, de pFrom à pTo le long de x.
Prism _rafter(double pY, double pFrom, double pTo) {
  double vZ(double pX) => 30 + pX * 40 / 60;

  final rRafter = Prism(
    [(pFrom, vZ(pFrom)), (pTo, vZ(pTo)), (pTo, vZ(pTo) + 6), (pFrom, vZ(pFrom) + 6)],
    pY,
    pY + 4,
  );

  return rRafter;
}

/// Schéma d'un mot, prêt à afficher.
class TermSketch extends StatelessWidget {
  const TermSketch(this.term, {super.key});

  final Term term;

  @override
  Widget build(BuildContext context) {
    final vScene = termScene(AppLocalizations.of(context), term);

    return AspectRatio(
      aspectRatio: 1.5,
      child: Sketch3D(parts: vScene.parts, callouts: vScene.callouts),
    );
  }
}
