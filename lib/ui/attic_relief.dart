import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/attic_section.dart';
import 'sketch3d.dart';

/// La pièce sous rampants en relief : la coupe tirée sur la longueur de la pièce, la bande où
/// l'on tient debout surlignée au sol, et la ligne des 1,80 m de chaque côté.
class AtticRelief extends StatelessWidget {
  const AtticRelief({
    super.key,
    required this.section,
    required this.widthMm,
    required this.kneeMm,
    required this.lengthMm,
    required this.twoPitches,
  });

  final AtticSection section;
  final int widthMm;
  final int kneeMm;
  final int lengthMm;
  final bool twoPitches;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vWidth = math.max(widthMm, 1).toDouble();
    // Pièce très longue : raccourcie, le relief reste lisible et la coupe ne change pas
    final vLength = math.min(math.max(lengthMm, 1), widthMm).toDouble();
    final vKnee = kneeMm.toDouble();
    final vTop = math.max(section.topMm, kneeMm).toDouble();
    final vSides = twoPitches ? 2 : 1;
    final vRun = (vWidth - section.flatWidthMm) / vSides;
    final vThick = vWidth / 60;
    final vLow = section.lowStripMm.toDouble();
    final vStanding = section.usableWidthMm > 0;
    final vRight = twoPitches ? vWidth - vLow : vWidth;

    return Sketch3D(
      parts: [
        Prism.box(0, vWidth, 0, vLength, -vThick, 0, role: PartRole.board),
        if (vStanding) Prism.box(vLow, vRight, 0, vLength, 0, vThick / 3, role: PartRole.highlight),
        Prism.box(-vThick, 0, 0, vLength, 0, vKnee, role: PartRole.board),
        Prism.box(
          vWidth,
          vWidth + vThick,
          0,
          vLength,
          0,
          twoPitches ? vKnee : vTop,
          role: PartRole.board,
        ),
        Prism(
          [(0, vKnee), (vRun, vTop), (vRun, vTop + vThick), (0, vKnee + vThick)],
          0,
          vLength,
          role: PartRole.ghost,
        ),
        if (twoPitches)
          Prism(
            [
              (vWidth - vRun, vTop),
              (vWidth, vKnee),
              (vWidth, vKnee + vThick),
              (vWidth - vRun, vTop + vThick),
            ],
            0,
            vLength,
            role: PartRole.ghost,
          ),
        if (section.flatWidthMm > 0)
          Prism.box(
            vRun,
            vRun + section.flatWidthMm,
            0,
            vLength,
            vTop,
            vTop + vThick,
            role: PartRole.ghost,
          ),
        if (vStanding)
          for (final vX in [vLow, if (twoPitches) vRight])
            Prism.box(
              vX - vThick / 4,
              vX + vThick / 4,
              0,
              0.5,
              0,
              carrezHeightMm.toDouble(),
              role: PartRole.glass,
            ),
      ],
      callouts: [
        (
          at: (x: -vThick, y: 0.0, z: vKnee / 2),
          text: vText.termKneeWall,
          shift: const Offset(-40, 20),
        ),
        (
          at: (x: vRun / 2, y: vLength, z: (vKnee + vTop) / 2 + vThick),
          text: vText.termSlope,
          shift: const Offset(-40, -40),
        ),
        if (vStanding) ...[
          (
            at: (x: (vLow + vRight) / 2, y: 0.0, z: 0.0),
            text: vText.atticReliefStanding,
            shift: const Offset(0, 40),
          ),
          (
            at: (x: vLow, y: 0.0, z: carrezHeightMm.toDouble()),
            text: vText.atticReliefCarrez,
            shift: const Offset(-50, -30),
          ),
        ],
      ],
    );
  }
}
