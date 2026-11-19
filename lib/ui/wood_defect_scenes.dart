import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/wood_defects.dart';
import 'sketch3d.dart';

/// Planche de démonstration : 1,20 m, 15 cm de large, 3 cm d'épaisseur, défauts exagérés.
const _length = 1200.0;
const _width = 150.0;
const _thick = 30.0;

/// Le défaut [defect] en relief sur une planche, exagéré pour se voir.
class WoodDefectSketch extends StatelessWidget {
  const WoodDefectSketch({super.key, required this.defect});

  final WoodDefect defect;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final (vParts, vCallouts) = switch (defect) {
      WoodDefect.knot => _knot(vText),
      WoodDefect.split => _split(vText),
      WoodDefect.check => _check(vText),
      WoodDefect.twist => _twist(vText),
      WoodDefect.bow => _bow(vText),
      WoodDefect.cup => _cup(vText),
      WoodDefect.moisture => _moisture(vText),
    };

    return Sketch3D(parts: vParts, callouts: vCallouts);
  }

  (List<Prism>, List<Callout>) _knot(AppLocalizations pText) => (
    [
      Prism.box(0, _length, 0, _width, 0, _thick),
      // Nœud sain au milieu, nœud noir près de l'arête : le second fragilise la planche
      Prism.box(400, 440, 50, 90, _thick, _thick + 3, role: PartRole.highlight),
      Prism.box(820, 850, 120, 148, _thick, _thick + 3, role: PartRole.ghost),
    ],
    [
      (
        at: (x: 420.0, y: 70.0, z: _thick + 3),
        text: pText.defectKnotSound,
        shift: const Offset(-40, -50),
      ),
      (
        at: (x: 835.0, y: 134.0, z: _thick + 3),
        text: pText.defectKnotEdge,
        shift: const Offset(40, -45),
      ),
    ],
  );

  (List<Prism>, List<Callout>) _split(AppLocalizations pText) => (
    [
      Prism.box(0, 900, 0, _width, 0, _thick),
      // Bout fendu : deux languettes écartées
      Prism.box(900, _length, 0, _width / 2 - 6, 0, _thick),
      Prism.box(900, _length, _width / 2 + 6, _width, 0, _thick),
      Prism.box(900, 1000, _width / 2 - 6, _width / 2 + 6, 0, _thick, role: PartRole.highlight),
    ],
    [
      (
        at: (x: _length, y: _width / 2, z: _thick),
        text: pText.defectSplitLabel,
        shift: const Offset(30, -50),
      ),
      (at: (x: 850.0, y: 0.0, z: 0.0), text: pText.defectSplitCut, shift: const Offset(-30, 45)),
    ],
  );

  (List<Prism>, List<Callout>) _check(AppLocalizations pText) => (
    [
      Prism.box(0, _length, 0, _width, 0, _thick),
      for (final (vX, vY) in [(150.0, 40.0), (420.0, 90.0), (700.0, 55.0), (950.0, 110.0)])
        Prism.box(vX, vX + 180, vY, vY + 5, _thick, _thick + 1, role: PartRole.highlight),
    ],
    [
      (
        at: (x: 510.0, y: 92.0, z: _thick + 1),
        text: pText.defectCheckLabel,
        shift: const Offset(0, -60),
      ),
    ],
  );

  /// Planche vue en long dans la profondeur : chaque tronçon tourne un peu plus.
  (List<Prism>, List<Callout>) _twist(AppLocalizations pText) {
    const vSegments = 8;
    const vMaxAngle = 18 * math.pi / 180;
    List<(double, double)> vSection(double pAngle) {
      final vCos = math.cos(pAngle);
      final vSin = math.sin(pAngle);
      return [
        for (final (vX, vZ) in [
          (-_width / 2, -_thick / 2),
          (_width / 2, -_thick / 2),
          (_width / 2, _thick / 2),
          (-_width / 2, _thick / 2),
        ])
          (vX * vCos - vZ * vSin + _width / 2, vX * vSin + vZ * vCos + 60),
      ];
    }

    final vStep = _length / vSegments;

    return (
      [
        Prism.box(-40, _width + 40, 0, _length, 0, 10, role: PartRole.board),
        for (var vIndex = 0; vIndex < vSegments; vIndex++)
          Prism(
            vSection(vMaxAngle * vIndex / (vSegments - 1)),
            vIndex * vStep,
            (vIndex + 1) * vStep,
          ),
      ],
      [
        (
          at: (x: _width, y: _length, z: 90.0),
          text: pText.defectTwistLabel,
          shift: const Offset(50, -30),
        ),
        (at: (x: 0.0, y: 0.0, z: 10.0), text: pText.defectFlatFloor, shift: const Offset(-40, 40)),
      ],
    );
  }

  /// Planche en long, cintrée, au-dessus d'une règle droite.
  (List<Prism>, List<Callout>) _bow(AppLocalizations pText) {
    const vSegments = 10;
    const vSag = 80.0;
    final vStep = _length / vSegments;
    double vLift(double pX) => 4 * vSag * (pX / _length) * (1 - pX / _length);

    return (
      [
        Prism.box(0, _length, 0, 20, 0, 8, role: PartRole.ghost),
        for (var vIndex = 0; vIndex < vSegments; vIndex++)
          Prism(
            [
              (vIndex * vStep, 8 + vLift(vIndex * vStep)),
              ((vIndex + 1) * vStep, 8 + vLift((vIndex + 1) * vStep)),
              ((vIndex + 1) * vStep, 8 + _thick + vLift((vIndex + 1) * vStep)),
              (vIndex * vStep, 8 + _thick + vLift(vIndex * vStep)),
            ],
            30,
            30 + _width,
          ),
      ],
      [
        (
          at: (x: _length / 2, y: 30.0, z: 8 + vSag),
          text: pText.defectBowLabel,
          shift: const Offset(0, -70),
        ),
        (at: (x: 100.0, y: 10.0, z: 4.0), text: pText.defectRuler, shift: const Offset(-30, 45)),
      ],
    );
  }

  /// Planche tuilée vue en long : la face se creuse en travers.
  (List<Prism>, List<Callout>) _cup(AppLocalizations pText) {
    const vSteps = 8;
    const vDepth = 25.0;
    double vCurve(double pX) {
      final vU = 2 * pX / _width - 1;
      return vDepth * vU * vU;
    }

    final vTop = [
      for (var vIndex = vSteps; vIndex >= 0; vIndex--)
        (_width * vIndex / vSteps, _thick + vCurve(_width * vIndex / vSteps)),
    ];
    final vBottom = [
      for (var vIndex = 0; vIndex <= vSteps; vIndex++)
        (_width * vIndex / vSteps, vCurve(_width * vIndex / vSteps)),
    ];

    return (
      [
        Prism([...vBottom, ...vTop], 0, _length * 0.7),
      ],
      [
        (
          at: (x: _width / 2, y: 0.0, z: _thick),
          text: pText.defectCupLabel,
          shift: const Offset(-50, -60),
        ),
      ],
    );
  }

  (List<Prism>, List<Callout>) _moisture(AppLocalizations pText) => (
    [
      Prism.box(0, _length, 0, _width, 0, _thick),
      // Humidimètre posé sur la face, ses deux pointes plantées dans le bois
      Prism.box(500, 700, 40, 110, _thick + 8, _thick + 48, role: PartRole.highlight),
      Prism.box(530, 540, 70, 80, _thick, _thick + 8, role: PartRole.board),
      Prism.box(660, 670, 70, 80, _thick, _thick + 8, role: PartRole.board),
    ],
    [
      (
        at: (x: 600.0, y: 75.0, z: _thick + 48),
        text: pText.defectMeterLabel,
        shift: const Offset(0, -55),
      ),
    ],
  );
}
