import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'notebook.dart';
import 'theme.dart';

/// Point de l'espace : x vers la droite, y vers le fond, z vers le haut.
typedef P3 = ({double x, double y, double z});

/// Rôle d'une pièce dans un schéma : il donne sa couleur.
enum PartRole { wood, highlight, glass, board, ghost }

/// Pièce d'un schéma : un profil dans le plan x-z, poussé le long de y (une planche, un
/// chevron, une vitre). Une boîte est un profil rectangulaire.
class Prism {
  Prism(this.profile, this.y0, this.y1, {this.role = PartRole.wood});

  /// Boîte de x0 à x1, y0 à y1, z0 à z1.
  factory Prism.box(
    double pX0,
    double pX1,
    double pY0,
    double pY1,
    double pZ0,
    double pZ1, {
    PartRole role = PartRole.wood,
  }) => Prism(
    [(pX0, pZ0), (pX1, pZ0), (pX1, pZ1), (pX0, pZ1)],
    pY0,
    pY1,
    role: role,
  );

  /// Profil en (x, z), dans un sens ou dans l'autre.
  final List<(double, double)> profile;
  final double y0;
  final double y1;
  final PartRole role;
}

/// Étiquette écrite à la main, avec une flèche vers le point visé.
typedef Callout = ({P3 at, String text, Offset shift});

/// Perspective cavalière, comme sur un croquis de menuisier : face avant de vraie grandeur,
/// profondeur fuyant en haut à droite à moitié de sa longueur. On voit le devant, le dessus
/// et le côté droit des pièces.
Offset project(P3 pPoint) {
  const vDepthX = 0.5 * 0.82;
  const vDepthY = 0.5 * 0.57;

  return Offset(pPoint.x + pPoint.y * vDepthX, -pPoint.z - pPoint.y * vDepthY);
}

/// Schéma en relief : pièces de bois ombrées, contours au crayon, étiquettes à la main.
class Sketch3D extends StatelessWidget {
  const Sketch3D({super.key, required this.parts, this.callouts = const []});

  final List<Prism> parts;
  final List<Callout> callouts;

  @override
  Widget build(BuildContext context) {
    final vTheme = Theme.of(context);
    final vColors = AtelierColors.of(context);

    return CustomPaint(
      painter: _Sketch3DPainter(
        parts: parts,
        callouts: callouts,
        ink: vColors.ink,
        wood: vColors.woodLaid,
        highlight: vColors.tape,
        glass: vTheme.colorScheme.primary,
        board: vTheme.colorScheme.surfaceContainerHigh,
        style: TextStyle(fontFamily: handFont, fontSize: 19, color: vColors.ink),
      ),
    );
  }
}

typedef _Face = ({List<P3> points, Color color, double depth});

class _Sketch3DPainter extends CustomPainter {
  _Sketch3DPainter({
    required this.parts,
    required this.callouts,
    required this.ink,
    required this.wood,
    required this.highlight,
    required this.glass,
    required this.board,
    required this.style,
  });

  final List<Prism> parts;
  final List<Callout> callouts;
  final Color ink;
  final Color wood;
  final Color highlight;
  final Color glass;
  final Color board;
  final TextStyle style;

  Color _base(PartRole pRole) => switch (pRole) {
    PartRole.wood => wood,
    PartRole.highlight => highlight,
    PartRole.glass => glass.withValues(alpha: 0.35),
    PartRole.board => board,
    PartRole.ghost => wood.withValues(alpha: 0.25),
  };

  /// Faces visibles de toutes les pièces, de la plus lointaine à la plus proche.
  List<_Face> _faces() {
    final rFaces = <_Face>[];
    for (final vPart in parts) {
      final vBase = _base(vPart.role);
      final vProfile = vPart.profile;
      var vArea = 0.0;
      for (var vIndex = 0; vIndex < vProfile.length; vIndex++) {
        final (vX0, vZ0) = vProfile[vIndex];
        final (vX1, vZ1) = vProfile[(vIndex + 1) % vProfile.length];
        vArea += vX0 * vZ1 - vX1 * vZ0;
      }
      final vSign = vArea >= 0 ? 1.0 : -1.0;
      Color vShade(double pFactor) =>
          Color.lerp(Colors.black, vBase, pFactor)!.withValues(alpha: vBase.a);
      // Les pièces du fond d'abord, puis de bas en haut et de gauche à droite
      double vDepth(List<P3> pPoints) {
        var vSum = 0.0;
        for (final vPoint in pPoints) {
          vSum += -vPoint.y * 4 + vPoint.z + vPoint.x;
        }

        return vSum / pPoints.length;
      }

      // Côtés du profil : visibles s'ils regardent vers le haut ou vers la droite
      for (var vIndex = 0; vIndex < vProfile.length; vIndex++) {
        final (vX0, vZ0) = vProfile[vIndex];
        final (vX1, vZ1) = vProfile[(vIndex + 1) % vProfile.length];
        final vNormalX = (vZ1 - vZ0) * vSign;
        final vNormalZ = -(vX1 - vX0) * vSign;
        if (vNormalZ <= 0 && vNormalX <= 0) {
          continue;
        }
        final vPoints = <P3>[
          (x: vX0, y: vPart.y0, z: vZ0),
          (x: vX1, y: vPart.y0, z: vZ1),
          (x: vX1, y: vPart.y1, z: vZ1),
          (x: vX0, y: vPart.y1, z: vZ0),
        ];
        final vLength = math.sqrt(vNormalX * vNormalX + vNormalZ * vNormalZ);
        // Dessus éclairé, côté droit dans l'ombre
        final vLight = vNormalZ > 0 ? 1.0 - 0.15 * (vNormalX / vLength).abs() : 0.7;
        rFaces.add((points: vPoints, color: vShade(vLight), depth: vDepth(vPoints) - 0.1));
      }
      // Face avant, vers le spectateur (y le plus petit)
      final vFront = [for (final (vX, vZ) in vProfile) (x: vX, y: vPart.y0, z: vZ)];
      rFaces.add((points: vFront, color: vShade(0.86), depth: vDepth(vFront) + 0.05));
    }
    rFaces.sort((pA, pB) => pA.depth.compareTo(pB.depth));

    return rFaces;
  }

  @override
  void paint(Canvas pCanvas, Size pSize) {
    if (parts.isEmpty) {
      return;
    }
    final vFaces = _faces();
    final vAll = [for (final vFace in vFaces) ...vFace.points.map(project)];
    final vLeft = vAll.map((pPoint) => pPoint.dx).reduce(math.min);
    final vRight = vAll.map((pPoint) => pPoint.dx).reduce(math.max);
    final vTop = vAll.map((pPoint) => pPoint.dy).reduce(math.min);
    final vBottom = vAll.map((pPoint) => pPoint.dy).reduce(math.max);
    const vMargin = 30.0;
    final vScale = math.min(
      (pSize.width - 2 * vMargin) / math.max(1, vRight - vLeft),
      (pSize.height - 2 * vMargin) / math.max(1, vBottom - vTop),
    );
    final vOrigin = Offset(
      (pSize.width - (vRight - vLeft) * vScale) / 2 - vLeft * vScale,
      (pSize.height - (vBottom - vTop) * vScale) / 2 - vTop * vScale,
    );
    Offset vAt(P3 pPoint) => vOrigin + project(pPoint) * vScale;

    final vPencil = Paint()
      ..color = ink
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final vFace in vFaces) {
      final vPoints = [for (final vPoint in vFace.points) vAt(vPoint)];
      pCanvas.drawPath(Path()..addPolygon(vPoints, true), Paint()..color = vFace.color);
      for (var vIndex = 0; vIndex < vPoints.length; vIndex++) {
        pencilLine(pCanvas, vPoints[vIndex], vPoints[(vIndex + 1) % vPoints.length], vPencil);
      }
    }

    final vArrow = Paint()
      ..color = ink
      ..strokeWidth = 1.2;
    for (final vCallout in callouts) {
      final vTarget = vAt(vCallout.at);
      final vLabel = vTarget + vCallout.shift;
      pCanvas.drawLine(vLabel, vTarget, vArrow);
      pCanvas.drawCircle(vTarget, 2.5, vArrow);
      final vBelow = vCallout.shift.dy < 0 ? -10.0 : 10.0;
      sketchLabel(pCanvas, vCallout.text, vLabel + Offset(0, vBelow), style);
    }
  }

  @override
  bool shouldRepaint(_Sketch3DPainter pOld) => pOld.parts != parts || pOld.ink != ink;
}
