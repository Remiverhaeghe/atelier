import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/gestures.dart';
import 'sketch3d.dart';

typedef GestureScene = ({List<Prism> parts, List<Callout> callouts});

/// Image du geste [pGesture] à l'instant [pPhase] : l'outil avance d'une passe par tour.
GestureScene gestureScene(AppLocalizations pText, Gesture pGesture, double pPhase) {
  final vStroke = stroke(pPhase);
  Callout vLabel(double pX, double pY, double pZ, String pText, Offset pShift) =>
      (at: (x: pX, y: pY, z: pZ), text: pText, shift: pShift);

  final rScene = switch (pGesture) {
    Gesture.saw => () {
      // Lame à 45°, qui va et vient le long d'elle-même, côté chute du trait
      final vSlide = (vStroke - 0.5) * 24;
      (double, double) vAlong(double pU, double pAcross) =>
          (62 + 0.71 * (pU + vSlide) - 0.71 * pAcross, 8 + 0.71 * (pU + vSlide) + 0.71 * pAcross);
      return (
        parts: [
          Prism.box(0, 60, 0, 30, 0, 8),
          Prism.box(60, 61.5, 0, 30, 0, 8, role: PartRole.highlight),
          Prism.box(61.5, 100, 0, 30, 0, 8, role: PartRole.board),
          Prism(
            [vAlong(-8, 0), vAlong(40, 0), vAlong(40, 9), vAlong(-8, 4)],
            14,
            15,
            role: PartRole.ghost,
          ),
          Prism([vAlong(40, -2), vAlong(52, -2), vAlong(52, 12), vAlong(40, 12)], 12, 17),
        ],
        callouts: [
          vLabel(60.7, 0, 8, pText.gestureSawLine, const Offset(-70, -60)),
          vLabel(
            vAlong(20, 4).$1,
            14,
            vAlong(20, 4).$2,
            pText.gestureSawAngle,
            const Offset(60, -30),
          ),
        ],
      );
    }(),
    Gesture.plane => () {
      final vX = 6 + vStroke * 70;
      return (
        parts: [
          Prism.box(0, 110, 0, 30, 0, 10),
          Prism.box(4, vX + 4, 11, 19, 10, 10.4, role: PartRole.highlight),
          Prism.box(vX, vX + 30, 11, 19, 10, 16, role: PartRole.board),
          Prism.box(vX + 18, vX + 26, 13.5, 16.5, 16, 24),
          Prism.box(vX + 3, vX + 8, 13.5, 16.5, 16, 21),
        ],
        callouts: [
          vLabel(90, 0, 5, pText.gesturePlaneGrain, const Offset(30, 40)),
          vLabel(vX + 4, 11, 10.2, pText.gesturePlaneShaving, const Offset(-60, -50)),
        ],
      );
    }(),
    Gesture.drill => () {
      final vTip = 14 - vStroke * 10;
      return (
        parts: [
          Prism.box(39.4, 40.6, 19.4, 20.6, vTip, vTip + 14, role: PartRole.ghost),
          Prism.box(0, 80, 0, 40, 0, 10),
          Prism.box(0, 80, 0, 40, -6, 0, role: PartRole.board),
          Prism.box(36, 44, 16, 24, vTip + 14, vTip + 30, role: PartRole.highlight),
          Prism.box(41, 47, 18, 22, vTip + 20, vTip + 26, role: PartRole.board),
        ],
        callouts: [
          vLabel(40, 16, vTip + 22, pText.gestureDrillStraight, const Offset(-80, -20)),
          vLabel(70, 0, -3, pText.gestureDrillBacking, const Offset(30, 40)),
        ],
      );
    }(),
    Gesture.screw => () {
      final vTip = 18 - vStroke * 14;
      return (
        parts: [
          Prism.box(39.5, 40.5, 19.5, 20.5, vTip, vTip + 12, role: PartRole.ghost),
          Prism.box(0, 80, 0, 40, 0, 7),
          Prism.box(0, 80, 0, 40, 7, 14, role: PartRole.board),
          Prism.box(38, 42, 18, 22, vTip + 12, vTip + 13.5, role: PartRole.highlight),
          Prism.box(39.6, 40.4, 19.6, 20.4, vTip + 13.5, vTip + 22, role: PartRole.ghost),
          Prism.box(37, 43, 17, 23, vTip + 22, vTip + 40, role: PartRole.highlight),
        ],
        callouts: [
          vLabel(40, 18, vTip + 13, pText.gestureScrewHead, const Offset(-90, -10)),
          vLabel(70, 0, 7, pText.gestureScrewPieces, const Offset(30, 40)),
        ],
      );
    }(),
    Gesture.sand => () {
      final vX = 6 + vStroke * 64;
      return (
        parts: [
          Prism.box(0, 100, 0, 40, 0, 6),
          Prism.box(6, vX + 20, 13, 27, 6, 6.3, role: PartRole.ghost),
          Prism.box(vX, vX + 22, 12, 28, 6, 9, role: PartRole.board),
          Prism.box(vX + 1, vX + 21, 13, 27, 9, 15, role: PartRole.highlight),
          Prism.box(vX + 8, vX + 14, 18, 22, 15, 20),
        ],
        callouts: [
          vLabel(vX + 11, 12, 12, pText.gestureSandWeight, const Offset(-30, -60)),
          vLabel(90, 0, 3, pText.gestureSandGrain, const Offset(30, 40)),
        ],
      );
    }(),
    Gesture.chisel => () {
      // Un coup de ciseau tous les quelques millimètres, le long du tracé
      final vX = 30 + (pPhase.floor() % 6) * 7.0;
      final vDown = 6 * vStroke;
      return (
        parts: [
          Prism.box(0, 100, 0, 24, 0, 20),
          Prism.box(30, 72, 8, 16, 14, 20.2, role: PartRole.ghost),
          Prism.box(vX, vX + 1.5, 8, 16, 20 - vDown, 46 - vDown, role: PartRole.board),
          Prism.box(vX - 2, vX + 3.5, 9, 15, 46 - vDown, 62 - vDown, role: PartRole.highlight),
        ],
        callouts: [
          vLabel(50, 8, 20, pText.gestureChiselMortise, const Offset(40, 50)),
          vLabel(vX, 8, 30 - vDown, pText.gestureChiselBevel, const Offset(-90, -20)),
        ],
      );
    }(),
    Gesture.caulk => () {
      final vX = 6 + vStroke * 76;
      return (
        parts: [
          Prism.box(0, 100, 0, 30, 0, 4),
          Prism.box(0, 100, 30, 34, 0, 40, role: PartRole.board),
          Prism([(4, 4), (vX, 4), (vX, 7), (4, 7)], 27, 30, role: PartRole.highlight),
          Prism.box(vX, vX + 6, 25, 29, 6, 10, role: PartRole.ghost),
          Prism.box(vX + 6, vX + 30, 23, 31, 8, 16),
        ],
        callouts: [
          vLabel(vX / 2 + 2, 27, 7, pText.gestureCaulkBead, const Offset(-40, -60)),
          vLabel(vX + 18, 23, 16, pText.gestureCaulkSteady, const Offset(40, -40)),
        ],
      );
    }(),
    Gesture.plug => () {
      // Mur vu de face : la cheville entre dans le trou percé au bon diamètre
      final vDepth = vStroke * 7;
      return (
        parts: [
          Prism.box(38.8, 41.2, 0, 8, 28.8, 31.2, role: PartRole.ghost),
          Prism.box(0, 80, 0, 10, 0, 60, role: PartRole.board),
          Prism.box(39, 41, -8 + vDepth, vDepth, 29, 31, role: PartRole.highlight),
          Prism.box(10, 70, -1, 0, 44, 44.6, role: PartRole.ghost),
        ],
        callouts: [
          vLabel(40, -8 + vDepth, 31, pText.gesturePlugFlush, const Offset(-60, -60)),
          vLabel(64, -1, 44.3, pText.gesturePlugDetect, const Offset(30, -40)),
        ],
      );
    }(),
    Gesture.cutBoard => () {
      final vY = vStroke * 52;
      return (
        parts: [
          Prism.box(0, 100, 0, 60, 0, 1.3, role: PartRole.board),
          Prism.box(61, 67, 0, 60, 1.3, 2.3),
          Prism.box(59.8, 60.6, 0, vY + 4, 1.3, 1.5, role: PartRole.highlight),
          Prism.box(57, 61, vY, vY + 8, 1.3, 5, role: PartRole.highlight),
        ],
        callouts: [
          vLabel(64, 30, 2.3, pText.gestureCutBoardRule, const Offset(60, -30)),
          vLabel(60, vY / 2, 1.5, pText.gestureCutBoardSnap, const Offset(-80, 40)),
        ],
      );
    }(),
    Gesture.mitre => () {
      // Fente à 45° de la boîte à onglets : la lame descend dans la plinthe
      final vZ = 14 - vStroke * 8;
      return (
        parts: [
          Prism.box(0, 70, 0, 22, 0, 3, role: PartRole.board),
          Prism.box(0, 70, 0, 2, 3, 14, role: PartRole.board),
          Prism.box(0, 70, 20, 22, 3, 14, role: PartRole.board),
          Prism.box(0, 70, 4, 16, 3, 10),
          for (var vStep = 0; vStep < 11; vStep++)
            Prism.box(
              28 + vStep * 1.4,
              29.4 + vStep * 1.4,
              vStep * 2.0,
              vStep * 2.0 + 2,
              vZ,
              vZ + 10,
              role: PartRole.ghost,
            ),
          Prism.box(43, 50, 20, 24, vZ + 6, vZ + 14, role: PartRole.highlight),
        ],
        callouts: [
          vLabel(36, 0, vZ + 5, pText.gestureMitreSlot, const Offset(-80, -40)),
          vLabel(60, 4, 10, pText.gestureMitreBack, const Offset(40, 40)),
        ],
      );
    }(),
    Gesture.laser => () {
      final vEnd = 20 + vStroke * 80;
      return (
        parts: [
          Prism.box(0, 100, 30, 32, 0, 60, role: PartRole.board),
          Prism.box(10, 16, 6, 12, 0, 22, role: PartRole.ghost),
          Prism.box(9, 17, 5, 13, 22, 28),
          Prism.box(0, vEnd, 29.6, 30, 24.6, 25.4, role: PartRole.highlight),
        ],
        callouts: [
          vLabel(vEnd - 10, 30, 25, pText.gestureLaserLine, const Offset(30, -50)),
          vLabel(13, 5, 26, pText.gestureLaserEyes, const Offset(-60, 40)),
        ],
      );
    }(),
    Gesture.grout => () {
      final vX = vStroke * 50;
      return (
        parts: [
          Prism.box(0, 64, 0, 42, -2, 0, role: PartRole.board),
          for (final vTileX in [0.0, 21.0, 42.0])
            for (final vTileY in [0.0, 21.0])
              Prism.box(vTileX, vTileX + 20, vTileY, vTileY + 20, 0, 2),
          Prism.box(0, vX + 4, 20, 21, 0, 1.8, role: PartRole.highlight),
          Prism.box(20, 21, 0, 42, 0, 1.8 * vStroke, role: PartRole.highlight),
          Prism.box(vX, vX + 14, 12, 30, 2, 4, role: PartRole.ghost),
          Prism.box(vX + 5, vX + 9, 19, 23, 4, 10),
        ],
        callouts: [
          vLabel(vX + 7, 12, 3, pText.gestureGroutDiagonal, const Offset(40, -50)),
          vLabel(8, 20, 1, pText.gestureGroutSponge, const Offset(-60, 40)),
        ],
      );
    }(),
  };

  return rScene;
}
