import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/tool_safety.dart';
import 'sketch3d.dart';

typedef SafetyScene = ({List<Prism> parts, List<Callout> callouts});

/// Profil d'un disque (lame, meule) dans le plan x-z, de l'angle [pFrom] à [pTo] en degrés.
/// Un arc partiel est fermé par son centre, comme un carter.
List<(double, double)> _disc(
  double pX,
  double pZ,
  double pRadius, {
  double pFrom = 0,
  double pTo = 360,
}) {
  const vSides = 24;
  final vFull = pTo - pFrom >= 360;
  final rProfile = <(double, double)>[
    if (!vFull) (pX, pZ),
    for (var vIndex = 0; vIndex <= (vFull ? vSides - 1 : vSides); vIndex++)
      () {
        final vAngle = (pFrom + (pTo - pFrom) * vIndex / vSides) * math.pi / 180;
        return (pX + pRadius * math.cos(vAngle), pZ + pRadius * math.sin(vAngle));
      }(),
  ];

  return rProfile;
}

/// Schéma en relief de la fiche [pTool] : l'outil en place, et ce qu'il faut y regarder.
SafetyScene safetyScene(AppLocalizations pText, SafetyTool pTool) {
  Callout vLabel(double pX, double pY, double pZ, String pLabel, Offset pShift) =>
      (at: (x: pX, y: pY, z: pZ), text: pLabel, shift: pShift);

  final rScene = switch (pTool) {
    // Lame qui dépasse sous la planche, moitié haute sous le carter
    SafetyTool.circularSaw => (
      parts: [
        Prism.box(0, 80, 0, 30, 0, 4),
        Prism(_disc(40, 6, 12), 4, 5, role: PartRole.highlight),
        Prism(_disc(40, 6, 13.5, pFrom: 0, pTo: 180), 3, 6, role: PartRole.board),
        Prism.box(22, 58, 0, 26, 4, 5.5, role: PartRole.board),
        Prism.box(44, 58, 8, 22, 6, 16, role: PartRole.board),
        Prism.box(30, 44, 10, 14, 20, 26),
      ],
      callouts: [
        vLabel(40, 3, 19.5, pText.toolSafeSawGuard, const Offset(-80, -30)),
        vLabel(40, 4, -6, pText.toolSafeSawDepth, const Offset(70, 30)),
      ],
    ),
    // Défonceuse posée sur la planche, rainure déjà faite derrière elle
    SafetyTool.router => (
      parts: [
        Prism.box(0, 100, 0, 40, 0, 8),
        Prism.box(0, 42, 17, 23, 5, 8.2, role: PartRole.ghost),
        Prism.box(40, 62, 9, 31, 8, 10, role: PartRole.board),
        Prism.box(45, 57, 14, 26, 10, 34, role: PartRole.highlight),
        Prism.box(33, 45, 17, 23, 18, 22),
        Prism.box(57, 69, 17, 23, 18, 22),
      ],
      callouts: [
        vLabel(51, 14, 9, pText.toolSafeRouterBit, const Offset(70, 50)),
        vLabel(20, 17, 8, pText.toolSafeRouterFeed, const Offset(-30, -70)),
      ],
    ),
    // Meuleuse sur un fer plat, carter tourné vers celui qui la tient
    SafetyTool.grinder => (
      parts: [
        Prism.box(0, 100, 8, 22, 0, 6, role: PartRole.board),
        Prism(_disc(40, 13, 11), 14.5, 15.5, role: PartRole.highlight),
        Prism(_disc(40, 13, 12.5, pFrom: 20, pTo: 200), 12.5, 17.5, role: PartRole.board),
        Prism.box(40, 88, 12, 18, 20, 28, role: PartRole.board),
        Prism.box(42, 46, 13, 17, 28, 44),
      ],
      callouts: [
        vLabel(32, 12.5, 23, pText.toolSafeGrinderGuard, const Offset(-70, -40)),
        vLabel(44, 13, 42, pText.toolSafeGrinderHandle, const Offset(80, -10)),
      ],
    ),
    // Échelle contre un mur, pied au quart de la hauteur d'appui
    SafetyTool.ladder => (
      parts: [
        Prism.box(20, 100, 0, 40, -3, 0, role: PartRole.board),
        Prism.box(90, 100, 0, 40, 0, 120, role: PartRole.board),
        for (final vY in [6.0, 30.0]) Prism([(60, 0), (64, 0), (90, 120), (86, 120)], vY, vY + 3),
        for (var vRung = 1; vRung <= 7; vRung++)
          Prism.box(
            61 + vRung * 15 / 4.6,
            63 + vRung * 15 / 4.6,
            9,
            30,
            vRung * 15 - 1,
            vRung * 15 + 1,
          ),
      ],
      callouts: [
        vLabel(62, 6, 0, pText.toolSafeLadderFoot, const Offset(-80, 20)),
        vLabel(88, 6, 118, pText.toolSafeLadderTop, const Offset(-100, -10)),
      ],
    ),
    // Pot refermé, et bocal d'eau pour les chiffons
    SafetyTool.finishes => (
      parts: [
        Prism.box(0, 110, 0, 50, -3, 0, role: PartRole.board),
        Prism.box(10, 40, 10, 40, 0, 36, role: PartRole.highlight),
        Prism.box(8, 42, 8, 42, 36, 39, role: PartRole.board),
        Prism.box(68, 84, 22, 32, 0, 14),
        Prism.box(62, 90, 16, 38, 0, 30, role: PartRole.glass),
      ],
      callouts: [
        vLabel(25, 8, 39, pText.toolSafeFinishesLid, const Offset(-30, -40)),
        vLabel(76, 16, 12, pText.toolSafeFinishesRags, const Offset(60, -50)),
      ],
    ),
  };

  return rScene;
}
