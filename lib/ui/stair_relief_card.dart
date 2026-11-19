import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/stair_design.dart';
import '../logic/stair_headroom.dart';
import '../logic/turning_stair.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'sketch3d.dart';
import 'theme.dart';

/// Épaisseur dessinée d'une marche.
const _treadMm = 40.0;

/// Escalier en relief : marches, plancher du haut, trémie et échappée, avec l'alerte quand
/// on se cogne la tête.
class StairReliefCard extends StatefulWidget {
  const StairReliefCard({
    super.key,
    required this.riseMm,
    required this.widthMm,
    required this.shape,
    this.tremieMm,
  });

  final int riseMm;
  final int widthMm;
  final StairShape shape;

  /// Trémie saisie ; sans elle, celle qui donne juste l'échappée.
  final int? tremieMm;

  @override
  State<StairReliefCard> createState() => _StairReliefCardState();
}

class _StairReliefCardState extends State<StairReliefCard> {
  var _personMm = defaultPersonMm;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vNeeded = stairHeadroom(widget.riseMm, 0).neededTremieMm;
    final vTremie = widget.tremieMm ?? vNeeded;
    final vHeadroom = stairHeadroom(widget.riseMm, vTremie, pPersonMm: _personMm);
    final vPlan = vHeadroom.plan;
    final vOk = headroomOk(vHeadroom);
    String vCm(int pMm) => formatCentimetres(pMm);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.stairReliefTitle, style: vTheme.textTheme.titleMedium),
            AspectRatio(
              aspectRatio: 1.3,
              child: StairSketch(
                headroom: vHeadroom,
                riseMm: widget.riseMm,
                widthMm: widget.widthMm,
                shape: widget.shape,
                tremieMm: vTremie,
                personMm: _personMm,
              ),
            ),
            IconLine(
              Icons.stairs_outlined,
              vText.stairReliefSteps(vCm(vPlan.goingMm), vCm(vPlan.riserMm)),
            ),
            IconLine(
              vOk ? Icons.check : AtelierIcons.warning,
              vHeadroom.headroomMm == null
                  ? vText.stairReliefOpen
                  : vText.stairReliefHeadroom(vCm(vHeadroom.headroomMm!)),
              color: vOk ? null : vTheme.colorScheme.error,
            ),
            if (!vOk)
              IconLine(
                Icons.open_in_full,
                vText.stairReliefNeeded(vCm(vHeadroom.neededTremieMm)),
                color: vTheme.colorScheme.error,
              ),
            if (vHeadroom.bumpTread case final vTread?)
              IconLine(
                AtelierIcons.warning,
                vText.stairReliefBump(vCm(_personMm), vTread),
                color: vTheme.colorScheme.error,
              ),
            if (widget.shape != StairShape.straight)
              Text(vText.stairReliefTurningHint, style: vTheme.textTheme.bodySmall),
            NumberField<int>(
              label: vText.stairReliefPerson,
              initial: vCm(_personMm),
              parse: parseCentimetres,
              onValue: (pValue) => setState(() => _personMm = pValue),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marches d'un escalier droit, quart tournant ou demi-tournant, avec le plancher du haut
/// pour l'escalier droit. Le tournant est dessiné en marches droites : c'est un croquis.
class StairSketch extends StatelessWidget {
  const StairSketch({
    super.key,
    required this.headroom,
    required this.riseMm,
    required this.widthMm,
    required this.shape,
    required this.tremieMm,
    required this.personMm,
  });

  final StairHeadroom headroom;
  final int riseMm;
  final int widthMm;
  final StairShape shape;
  final int tremieMm;
  final int personMm;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vPlan = headroom.plan;
    final vGoing = vPlan.goingMm.toDouble();
    final vRiser = vPlan.riserMm.toDouble();
    final vWidth = widthMm.toDouble();
    final vTreads = headroom.treads;
    final vParts = <Prism>[];
    final vCallouts = <Callout>[];
    double vTop(int pIndex) => (pIndex + 1) * vRiser;

    if (shape == StairShape.straight) {
      for (var vIndex = 0; vIndex < vTreads; vIndex++) {
        final vX = vIndex * vGoing;
        vParts.add(
          Prism.box(vX - noseMm, vX + vGoing, 0, vWidth, vTop(vIndex) - _treadMm, vTop(vIndex)),
        );
      }
      final vRun = vTreads * vGoing;
      // Limon côté mur, le long de la ligne des marches
      vParts.add(
        Prism(
          [(0, 0), (vRun, riseMm - vRiser), (vRun, riseMm - vRiser + 250), (0, 250)],
          vWidth,
          vWidth + 40,
        ),
      );
      final vUnder = (riseMm - upperFloorMm).toDouble();
      final vEdge = vRun - tremieMm;
      if (vEdge > 0) {
        vParts.add(
          Prism.box(
            math.max(-400.0, vEdge - 1500),
            vEdge,
            0,
            vWidth,
            vUnder,
            riseMm.toDouble(),
            role: headroomOk(headroom) ? PartRole.board : PartRole.highlight,
          ),
        );
      }
      vParts.add(
        Prism.box(vRun, vRun + 900, 0, vWidth, vUnder, riseMm.toDouble(), role: PartRole.board),
      );
      // Silhouette sur la marche où l'on se cogne, sinon sous le bord de la trémie
      final vStand = headroom.bumpTread ?? math.max(1, math.min(vTreads, (vEdge / vGoing).floor()));
      if (vTreads > 0) {
        final vX = (vStand - 1) * vGoing + vGoing / 2;
        vParts.add(
          Prism.box(
            vX - 120,
            vX + 120,
            vWidth / 2 - 150,
            vWidth / 2 + 150,
            vTop(vStand - 1),
            vTop(vStand - 1) + personMm,
            role: PartRole.ghost,
          ),
        );
      }
      vCallouts.addAll([
        (
          at: (x: vGoing * 1.5, y: 0.0, z: vTop(1)),
          text: vText.stairReliefGoingLabel(formatCentimetres(vPlan.goingMm)),
          shift: const Offset(-30, 60),
        ),
        (
          at: (x: vGoing * 3, y: 0.0, z: vTop(2) - vRiser / 2),
          text: vText.stairReliefRiserLabel(formatCentimetres(vPlan.riserMm)),
          shift: const Offset(40, 70),
        ),
        if (headroom.headroomMm case final vClear?)
          (
            at: (x: vEdge, y: 0.0, z: vUnder),
            text: vText.stairReliefHeadroomLabel(formatCentimetres(vClear)),
            shift: const Offset(-70, -40),
          ),
        (
          at: (x: math.max(0.0, vEdge) + tremieMm / 2, y: vWidth, z: riseMm.toDouble()),
          text: vText.stairReliefTremieLabel,
          shift: const Offset(20, -50),
        ),
      ]);
    } else {
      final vTurning = math.max(
        1,
        designTurningStair(riseMm, shape, pWidthMm: widthMm).turningTreads,
      );
      final vStraight = math.max(0, vTreads - vTurning);
      final vFirst = vStraight ~/ 2;
      final vSecond = vStraight - vFirst;
      final vCorner = vFirst * vGoing;
      var vStep = 0;
      for (var vIndex = 0; vIndex < vFirst; vIndex++, vStep++) {
        final vX = vIndex * vGoing;
        vParts.add(Prism.box(vX, vX + vGoing, 0, vWidth, vTop(vStep) - _treadMm, vTop(vStep)));
      }
      final vDepth = shape == StairShape.quarterTurn ? vWidth : 2 * vWidth;
      // Tournant : bandes dans le palier, en travers pour un quart, en long pour un demi
      for (var vIndex = 0; vIndex < vTurning; vIndex++, vStep++) {
        final vFrom = vIndex / vTurning;
        final vTo = (vIndex + 1) / vTurning;
        vParts.add(
          shape == StairShape.quarterTurn
              ? Prism.box(
                  vCorner + vFrom * vWidth,
                  vCorner + vTo * vWidth,
                  0,
                  vWidth,
                  vTop(vStep) - _treadMm,
                  vTop(vStep),
                )
              : Prism.box(
                  vCorner,
                  vCorner + vWidth,
                  vFrom * vDepth,
                  vTo * vDepth,
                  vTop(vStep) - _treadMm,
                  vTop(vStep),
                ),
        );
      }
      for (var vIndex = 0; vIndex < vSecond; vIndex++, vStep++) {
        vParts.add(
          shape == StairShape.quarterTurn
              ? Prism.box(
                  vCorner,
                  vCorner + vWidth,
                  vWidth + vIndex * vGoing,
                  vWidth + (vIndex + 1) * vGoing,
                  vTop(vStep) - _treadMm,
                  vTop(vStep),
                )
              : Prism.box(
                  vCorner - (vIndex + 1) * vGoing,
                  vCorner - vIndex * vGoing,
                  vWidth,
                  2 * vWidth,
                  vTop(vStep) - _treadMm,
                  vTop(vStep),
                ),
        );
      }
      vCallouts.add((
        at: (x: vCorner + vWidth / 2, y: vDepth / 2, z: vTop(vFirst + vTurning ~/ 2)),
        text: vText.stairReliefTurnLabel,
        shift: const Offset(60, -40),
      ));
    }

    return Sketch3D(parts: vParts, callouts: vCallouts);
  }
}
