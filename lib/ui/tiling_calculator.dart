import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/geometry.dart';
import '../logic/room.dart';
import '../logic/tile_patterns.dart';
import '../logic/tiling.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'room_source.dart';
import 'theme.dart';
import 'plan_unit.dart';
import 'room_measure_picker.dart' show lengthText;

/// Carrelage et faïence : calepinage dessiné, coupes de bord, quantités, colle et joint.
class TilingCalculator extends StatefulWidget {
  const TilingCalculator({super.key, this.rooms = const []});

  final List<Room> rooms;

  @override
  State<TilingCalculator> createState() => _TilingCalculatorState();
}

class _TilingCalculatorState extends State<TilingCalculator> {
  var _design = const TilingDesign();
  Room? _room;

  /// Change quand une pièce remplit les champs, pour qu'ils se redessinent avec ses cotes.
  int _source = 0;

  /// La pièce choisie donne son contour, sa longueur et sa largeur (rectangle englobant).
  void _fromRoom(Room? pRoom) => setState(() {
    _room = pRoom;
    _source++;
    if (pRoom == null) {
      _design = _design.copyWith(outline: const []);

      return;
    }
    final vPoints = outline(pRoom);
    final vMinX = vPoints.map((pPoint) => pPoint.x).reduce((pA, pB) => pA < pB ? pA : pB);
    final vMinY = vPoints.map((pPoint) => pPoint.y).reduce((pA, pB) => pA < pB ? pA : pB);
    final vMaxX = vPoints.map((pPoint) => pPoint.x).reduce((pA, pB) => pA > pB ? pA : pB);
    final vMaxY = vPoints.map((pPoint) => pPoint.y).reduce((pA, pB) => pA > pB ? pA : pB);
    _design = _design.copyWith(
      lengthMm: (vMaxX - vMinX).round(),
      widthMm: (vMaxY - vMinY).round(),
      outline: [for (final vPoint in vPoints) PlanPoint(vPoint.x - vMinX, vPoint.y - vMinY)],
    );
  });

  String _patternName(AppLocalizations pText, TilePattern pPattern) => switch (pPattern) {
    TilePattern.straight => pText.patternStraight,
    TilePattern.brick => pText.patternBrick,
    TilePattern.third => pText.patternThird,
    TilePattern.diagonal => pText.patternDiagonal,
    TilePattern.herringbone => pText.patternHerringbone,
    TilePattern.hexagon => pText.patternHexagon,
    TilePattern.mosaic => pText.patternMosaic,
  };

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vNeeds = tilingNeeds(_design);
    void vSet(TilingDesign pDesign) => setState(() => _design = pDesign);
    final vUnit = PlanUnit.of(context);
    String vCuts(AxisLayout pAxis) => pAxis.startCutMm == 0 && pAxis.endCutMm == 0
        ? vText.tilingNoCut(pAxis.fullTiles)
        : pAxis.startCutMm == 0
        ? vText.tilingOneCut(pAxis.fullTiles, lengthText(vText, pAxis.endCutMm, vUnit))
        : vText.tilingCuts(
            pAxis.fullTiles,
            lengthText(vText, pAxis.startCutMm, vUnit),
            lengthText(vText, pAxis.endCutMm, vUnit),
          );

    return Scaffold(
      appBar: AppBar(title: Text(vText.tilingTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          RoomSourcePicker(rooms: widget.rooms, value: _room?.id, onChanged: _fromRoom),
          Semantics(
            label: vText.tilingChart(_patternName(vText, _design.pattern), vNeeds.tiles),
            image: true,
            child: SizedBox(
              height: 220,
              child: CustomPaint(
                size: Size.infinite,
                painter: _TilingPainter(
                  design: _design,
                  needs: vNeeds,
                  colors: AtelierColors.of(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BigFigure(vText.tilingBoxes(vNeeds.boxes)),
                  IconLine(
                    Icons.grid_on,
                    vText.tilingTiles(vNeeds.tiles, formatDecimal(vNeeds.areaM2)),
                  ),
                  if (_design.pattern == TilePattern.mosaic)
                    IconLine(Icons.apps, vText.tilingSheets(vNeeds.sheets))
                  else if (_design.pattern == TilePattern.straight && _design.outline.isEmpty) ...[
                    IconLine(Icons.swap_horiz, vText.tilingAlongLength(vCuts(vNeeds.alongLength))),
                    IconLine(Icons.swap_vert, vText.tilingAlongWidth(vCuts(vNeeds.alongWidth))),
                  ],
                  IconLine(Icons.format_color_fill, vText.tilingGlue(vNeeds.glueKg)),
                  IconLine(Icons.grain, vText.tilingJoint(formatDecimal(vNeeds.jointKg))),
                  IconLine(Icons.add, vText.tilingSpacers(vNeeds.spacers)),
                  const SizedBox(height: 4),
                  Text(vText.tilingHint, style: vTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final vPattern in TilePattern.values)
                ChoiceChip(
                  label: Text(_patternName(vText, vPattern)),
                  selected: _design.pattern == vPattern,
                  onSelected: (_) => vSet(
                    _design.copyWith(
                      pattern: vPattern,
                      marginPercent: recommendedWastePercent(vPattern),
                    ),
                  ),
                ),
            ],
          ),
          if (_design.pattern == TilePattern.straight)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(vText.tilingCentered),
              subtitle: Text(vText.tilingCenteredHelp),
              value: _design.centered,
              onChanged: (pValue) => vSet(_design.copyWith(centered: pValue)),
            ),
          if (_design.pattern == TilePattern.mosaic)
            NumberField(
              label: vText.tilingSheetSize,
              initial: formatCentimetres(_design.sheetMm),
              parse: parseCentimetres,
              onValue: (pValue) => vSet(_design.copyWith(sheetMm: pValue)),
            ),
          for (final (vLabel, vValue, vApply) in [
            (
              vText.tilingLength,
              _design.lengthMm,
              (int pValue) => _design.copyWith(lengthMm: pValue),
            ),
            (vText.tilingWidth, _design.widthMm, (int pValue) => _design.copyWith(widthMm: pValue)),
            (
              vText.tileLength,
              _design.tileLengthMm,
              (int pValue) => _design.copyWith(tileLengthMm: pValue),
            ),
            (
              vText.tileWidth,
              _design.tileWidthMm,
              (int pValue) => _design.copyWith(tileWidthMm: pValue),
            ),
          ])
            NumberField(
              key: ValueKey('$vLabel$_source'),
              label: vLabel,
              initial: formatCentimetres(vValue),
              parse: parseCentimetres,
              onValue: (pValue) => vSet(vApply(pValue)),
            ),
          NumberField(
            label: vText.tilingJointWidth,
            initial: '${_design.jointMm}',
            parse: parseWhole,
            onValue: (pValue) => vSet(_design.copyWith(jointMm: pValue)),
          ),
          NumberField<double>(
            label: vText.tilingBoxArea,
            initial: formatDecimal(_design.boxM2),
            parse: parseDecimal,
            onValue: (pValue) => vSet(_design.copyWith(boxM2: pValue)),
          ),
          NumberField(
            label: vText.wastePercent,
            initial: '${_design.marginPercent}',
            parse: parseWhole,
            onValue: (pValue) => vSet(_design.copyWith(marginPercent: pValue)),
          ),
        ],
      ),
    );
  }
}

/// Carreaux entiers en clair, coupes de bord en plus foncé, comme sur un calepinage papier.
class _TilingPainter extends CustomPainter {
  _TilingPainter({required this.design, required this.needs, required this.colors});

  final TilingDesign design;
  final TilingNeeds needs;
  final AtelierColors colors;

  List<int> _sizes(AxisLayout pAxis, int pTile) => [
    if (pAxis.startCutMm > 0) pAxis.startCutMm,
    for (var vIndex = 0; vIndex < pAxis.fullTiles; vIndex++) pTile,
    if (pAxis.endCutMm > 0) pAxis.endCutMm,
  ];

  @override
  void paint(Canvas pCanvas, Size pSize) {
    if (design.lengthMm <= 0 || design.widthMm <= 0) {
      return;
    }
    final vScale = [
      pSize.width / design.lengthMm,
      pSize.height / design.widthMm,
    ].reduce((pA, pB) => pA < pB ? pA : pB);
    final vLeft = (pSize.width - design.lengthMm * vScale) / 2;
    final vTop = (pSize.height - design.widthMm * vScale) / 2;
    if (design.pattern != TilePattern.straight || design.outline.isNotEmpty) {
      _paintPattern(pCanvas, vScale, vLeft, vTop);

      return;
    }
    final vColumns = _sizes(needs.alongLength, design.tileLengthMm);
    final vRows = _sizes(needs.alongWidth, design.tileWidthMm);
    final vJoint = design.jointMm * vScale;
    var vY = vTop;
    for (var vRow = 0; vRow < vRows.length; vRow++) {
      var vX = vLeft;
      for (var vColumn = 0; vColumn < vColumns.length; vColumn++) {
        final vCut = vColumns[vColumn] != design.tileLengthMm || vRows[vRow] != design.tileWidthMm;
        pCanvas.drawRect(
          Rect.fromLTWH(vX, vY, vColumns[vColumn] * vScale, vRows[vRow] * vScale),
          Paint()..color = vCut ? colors.tape.withValues(alpha: 0.55) : colors.grid,
        );
        vX += vColumns[vColumn] * vScale + vJoint;
      }
      vY += vRows[vRow] * vScale + vJoint;
    }
    pCanvas.drawRect(
      Rect.fromLTWH(vLeft, vTop, design.lengthMm * vScale, design.widthMm * vScale),
      Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// Poses autres que droite, ou pièce non rectangulaire : tous les carreaux, découpés au contour.
  void _paintPattern(Canvas pCanvas, double pScale, double pLeft, double pTop) {
    Offset vToScreen(PlanPoint pPoint) =>
        Offset(pLeft + pPoint.x * pScale, pTop + pPoint.y * pScale);
    final vOutline = design.outline.length >= 3
        ? design.outline
        : [
            const PlanPoint(0, 0),
            PlanPoint(design.lengthMm.toDouble(), 0),
            PlanPoint(design.lengthMm.toDouble(), design.widthMm.toDouble()),
            PlanPoint(0, design.widthMm.toDouble()),
          ];
    final vBorder = Path()..addPolygon([for (final vPoint in vOutline) vToScreen(vPoint)], true);
    final vShapes = tileShapes(design.pattern, design.lengthMm, design.widthMm, design.gauge);
    pCanvas.save();
    pCanvas.clipPath(vBorder);
    pCanvas.drawRect(
      Rect.fromLTWH(pLeft, pTop, design.lengthMm * pScale, design.widthMm * pScale),
      Paint()..color = colors.tape.withValues(alpha: 0.25),
    );
    final vFill = Paint()..color = colors.grid;
    for (final vShape in vShapes) {
      pCanvas.drawPath(
        Path()..addPolygon([for (final vPoint in vShape) vToScreen(vPoint)], true),
        vFill,
      );
    }
    pCanvas.restore();
    pCanvas.drawPath(
      vBorder,
      Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_TilingPainter pOld) => pOld.design != design;
}
