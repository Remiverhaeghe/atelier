import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/fixtures.dart';
import '../logic/geometry.dart';
import '../logic/room.dart';
import '../logic/room_shapes.dart';
import '../logic/units.dart';
import 'fixtures_section.dart';
import 'laser_screen.dart';
import 'parquet_view.dart' show NumberField;
import 'quick_walls_screen.dart';
import 'room_plan.dart' show PlanFrame;
import 'slope_editor.dart';
import 'theme.dart';

/// Dessine la pièce d'après une forme et renvoie la pièce mise à jour, ou null si on annule.
Future<Room?> sketchRoom(BuildContext pContext, Room pRoom) => Navigator.push(
  pContext,
  MaterialPageRoute<Room>(builder: (_) => RoomSketchScreen(room: pRoom)),
);

/// Lettre du coin [pIndex] : A, B, C…
String cornerLetter(int pIndex) => String.fromCharCode(65 + pIndex);

/// La pièce part d'une forme toute faite, rectangle, L ou T, aux numéros de murs sur le plan.
/// On touche un mur, on tape sa longueur ; les murs non mesurés se déduisent des autres et
/// restent en pointillés. Les angles se calculent : la diagonale suffit quand la pièce n'est
/// pas d'équerre. « Autre forme » ouvre la saisie libre, avec les angles.
class RoomSketchScreen extends StatefulWidget {
  const RoomSketchScreen({super.key, required this.room});

  final Room room;

  @override
  State<RoomSketchScreen> createState() => _RoomSketchScreenState();
}

class _RoomSketchScreenState extends State<RoomSketchScreen> {
  late RoomShape _shape = shapeOf(widget.room.walls) ?? RoomShape.rectangle;

  /// Longueurs tapées, par numéro de mur à partir de 0.
  late final Map<int, int> _measured = {
    if (shapeOf(widget.room.walls) != null)
      for (final (vIndex, vWall) in widget.room.walls.indexed) vIndex: vWall.lengthMm,
  };
  int? _diagonal;
  int _selected = 0;
  late Room _room = widget.room;
  final _length = TextEditingController();

  @override
  void initState() {
    super.initState();
    _length.text = _lengthText(0);
  }

  @override
  void dispose() {
    _length.dispose();
    super.dispose();
  }

  ShapedRoom get _shaped => shapeRoom(_shape, _measured, pDiagonalMm: _diagonal);

  String _lengthText(int pIndex) =>
      _measured[pIndex] == null ? '' : formatCentimetres(_measured[pIndex]!);

  /// Pièce dessinée : murs de la forme, ouvertures gardées, hauteur et rampants à jour.
  Room get _drawn => _room.copyWith(walls: shapeWalls(_shaped, widget.room.walls), closed: true);

  void _select(int pIndex) => setState(() {
    _selected = pIndex;
    _length.text = _lengthText(pIndex);
  });

  void _typed(String pText) {
    final vLength = parseCentimetres(pText);
    setState(() {
      if (vLength == null || vLength == 0) {
        _measured.remove(_selected);
      } else {
        _measured[_selected] = vLength;
      }
    });
  }

  void _changeShape(RoomShape pShape) => setState(() {
    _shape = pShape;
    _measured.clear();
    _diagonal = null;
    _selected = 0;
    _length.clear();
  });

  /// Mezzanine, escalier, trémie ou fenêtre de toit, posé au milieu de la pièce puis réglé.
  Future<void> _addFixture(FixtureKind pKind) async {
    final vPoints = outline(_drawn);
    final vXs = vPoints.map((pPoint) => pPoint.x);
    final vYs = vPoints.map((pPoint) => pPoint.y);
    final vSize = defaultFixtureSize(pKind);
    final vFixture = await editFixture(
      context,
      Fixture(
        id: 'f${DateTime.now().microsecondsSinceEpoch}',
        kind: pKind,
        xMm: ((vXs.reduce(math.min) + vXs.reduce(math.max)) / 2).round(),
        yMm: ((vYs.reduce(math.min) + vYs.reduce(math.max)) / 2).round(),
        widthMm: vSize.widthMm,
        depthMm: vSize.depthMm,
      ),
    );
    if (vFixture != null && mounted) {
      setState(() => _room = _room.copyWith(fixtures: [..._room.fixtures, vFixture]));
    }
  }

  Future<void> _editFixture(Fixture pFixture) async {
    final vFixture = await editFixture(context, pFixture);
    if (vFixture != null && mounted) {
      setState(
        () => _room = _room.copyWith(
          fixtures: [
            for (final vOld in _room.fixtures) vOld.id == pFixture.id ? vFixture : vOld,
          ],
        ),
      );
    }
  }

  Future<void> _freeShape() async {
    final vWalls = await editAllWalls(context, _drawn);
    if (vWalls != null && mounted) {
      Navigator.pop(context, _room.copyWith(walls: vWalls, closed: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vShaped = _shaped;
    final vCount = vShaped.lengths.length;
    final vDone = _measured.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(vText.sketchTitle),
        actions: [
          TextButton(
            onPressed: vShaped.impossible ? null : () => Navigator.pop(context, _drawn),
            child: Text(vText.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Wrap(
            spacing: 6,
            children: [
              for (final vShape in RoomShape.values)
                ChoiceChip(
                  label: Text(switch (vShape) {
                    RoomShape.rectangle => vText.sketchRectangle,
                    RoomShape.lShape => vText.sketchLShape,
                    RoomShape.tShape => vText.sketchTShape,
                  }),
                  selected: _shape == vShape,
                  onSelected: (_) => _changeShape(vShape),
                ),
              ActionChip(
                avatar: const Icon(Icons.architecture, size: 18),
                label: Text(vText.sketchFree),
                onPressed: _freeShape,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(vText.sketchHelp, style: vTheme.textTheme.bodyMedium),
          AspectRatio(
            aspectRatio: 1.2,
            child: ShapeSketch(
              room: _drawn,
              measured: _measured.keys.toSet(),
              selected: _selected,
              onTapWall: _select,
            ),
          ),
          Text(
            vText.sketchProgress(vDone, vCount),
            style: vTheme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vText.sketchWall(
                      _selected + 1,
                      cornerLetter(_selected),
                      cornerLetter((_selected + 1) % vCount),
                    ),
                    style: vTheme.textTheme.titleMedium,
                  ),
                  if (!_measured.containsKey(_selected))
                    Text(
                      vShaped.deduced.contains(_selected)
                          ? vText.sketchDeduced(formatCentimetres(vShaped.lengths[_selected]))
                          : vText.sketchToMeasure,
                      style: vTheme.textTheme.bodySmall,
                    ),
                  TextField(
                    key: ValueKey('mur-$_selected'),
                    controller: _length,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    onChanged: _typed,
                    onSubmitted: (_) => _select((_selected + 1) % vCount),
                    decoration: InputDecoration(
                      labelText: vText.wallLength,
                      suffixText: vText.unitCm,
                      helperText: vText.sketchUnits,
                      suffixIcon: IconButton(
                        tooltip: vText.laserMeasure,
                        icon: const Icon(Icons.straighten),
                        onPressed: () async {
                          final vMm = await measureWithLaser(context);
                          if (vMm != null && mounted) {
                            _length.text = formatCentimetres(vMm);
                            _typed(_length.text);
                          }
                        },
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _select((_selected + 1) % vCount),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(vText.nextWall),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (vShaped.impossible)
            IconLine(Icons.error_outline, vText.sketchImpossible, color: vTheme.colorScheme.error),
          if (vShaped.needsDiagonal || _diagonal != null) ...[
            const SizedBox(height: 12),
            IconLine(Icons.call_made, vText.sketchDiagonal),
            NumberField<int>(
              label: vText.sketchDiagonalField,
              initial: _diagonal == null ? '' : formatCentimetres(_diagonal!),
              parse: parseCentimetres,
              onValue: (pValue) => setState(() => _diagonal = pValue == 0 ? null : pValue),
            ),
            if (_diagonal != null && !vShaped.impossible)
              IconLine(
                Icons.architecture,
                vText.sketchAngles(
                  [
                    for (final (vIndex, vAngle) in vShaped.angles.indexed)
                      '${cornerLetter((vIndex + 1) % vCount)} ${formatDecimal(vAngle)}°',
                  ].join(', '),
                ),
              ),
          ],
          const SizedBox(height: 16),
          NumberField<int>(
            label: vText.ceilingHeight,
            initial: formatCentimetres(_room.ceilingHeightMm),
            parse: parseCentimetres,
            onValue: (pValue) {
              if (pValue > 0) {
                setState(() => _room = _room.copyWith(ceilingHeightMm: pValue));
              }
            },
          ),
          const SizedBox(height: 12),
          Text(vText.sketchAlso, style: vTheme.textTheme.titleSmall),
          Wrap(
            spacing: 6,
            children: [
              for (final vKind in [
                FixtureKind.mezzanine,
                FixtureKind.stairs,
                FixtureKind.stairwell,
                FixtureKind.roofWindow,
              ])
                ActionChip(
                  avatar: Icon(fixtureIcon(vKind), size: 18),
                  label: Text(fixtureLabel(vText, vKind)),
                  onPressed: () => _addFixture(vKind),
                ),
            ],
          ),
          for (final vFixture in _room.fixtures.where((pFixture) => hasArea(pFixture.kind)))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(fixtureIcon(vFixture.kind)),
              title: Text(fixtureLabel(vText, vFixture.kind)),
              subtitle: Text(
                vText.sketchFixtureSize(
                  formatCentimetres(vFixture.widthMm),
                  formatCentimetres(vFixture.depthMm),
                  formatSquareMetres(vFixture.areaM2),
                ),
              ),
              onTap: () => _editFixture(vFixture),
              trailing: IconButton(
                tooltip: vText.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(
                  () => _room = _room.copyWith(
                    fixtures: [..._room.fixtures]..remove(vFixture),
                  ),
                ),
              ),
            ),
          SlopeEditor(
            room: _drawn,
            onChanged: (pRoom) => setState(
              () => _room = _room.copyWith(
                slope: pRoom.slope,
                clearSlope: pRoom.slope == null,
                slope2: pRoom.slope2,
                clearSlope2: pRoom.slope2 == null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plan de la forme : murs mesurés en trait plein, déduits en pointillés, mur en cours en
/// couleur du mètre ruban ; numéros des murs au milieu, lettres des coins aux sommets.
class ShapeSketch extends StatelessWidget {
  const ShapeSketch({
    super.key,
    required this.room,
    required this.measured,
    required this.selected,
    required this.onTapWall,
  });

  final Room room;
  final Set<int> measured;
  final int selected;
  final ValueChanged<int> onTapWall;

  @override
  Widget build(BuildContext context) {
    final vColors = AtelierColors.of(context);

    return LayoutBuilder(
      builder: (pContext, pBox) {
        final vSize = pBox.biggest;
        final vPainter = _ShapePainter(
          room: room,
          points: outline(room),
          measured: measured,
          selected: selected,
          ink: vColors.ink,
          tape: vColors.tape,
          onTape: vColors.onTape,
          paper: Theme.of(context).colorScheme.surface,
        );

        return GestureDetector(
          onTapUp: (pDetails) {
            final vWall = vPainter.wallAt(pDetails.localPosition, vSize);
            if (vWall != null) {
              onTapWall(vWall);
            }
          },
          child: CustomPaint(size: vSize, painter: vPainter),
        );
      },
    );
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter({
    required this.room,
    required this.points,
    required this.measured,
    required this.selected,
    required this.ink,
    required this.tape,
    required this.onTape,
    required this.paper,
  });

  final Room room;
  final List<PlanPoint> points;
  final Set<int> measured;
  final int selected;
  final Color ink;
  final Color tape;
  final Color onTape;
  final Color paper;

  static const _margin = 36.0;

  /// Passage du plan à l'écran, le même que celui du plan de la pièce.
  PlanFrame _frame(Size pSize) => PlanFrame(room, pSize, pMargin: _margin);

  /// Sommets à l'écran : la forme centrée, à la plus grande échelle qui tient.
  List<Offset> _screen(Size pSize) {
    final vFrame = _frame(pSize);

    return [for (final vPoint in points) vFrame.toScreen(vPoint.x, vPoint.y)];
  }

  /// Mur le plus proche d'un toucher, à 40 points au plus ; null sinon.
  int? wallAt(Offset pAt, Size pSize) {
    final vPoints = _screen(pSize);
    int? rWall;
    var vBest = 40.0;
    for (var vIndex = 0; vIndex < vPoints.length - 1; vIndex++) {
      final vDistance = _distanceToSegment(pAt, vPoints[vIndex], vPoints[vIndex + 1]);
      if (vDistance < vBest) {
        vBest = vDistance;
        rWall = vIndex;
      }
    }

    return rWall;
  }

  static double _distanceToSegment(Offset pAt, Offset pFrom, Offset pTo) {
    final vSegment = pTo - pFrom;
    final vLength = vSegment.distanceSquared;
    final vT = vLength == 0
        ? 0.0
        : (((pAt - pFrom).dx * vSegment.dx + (pAt - pFrom).dy * vSegment.dy) / vLength).clamp(
            0.0,
            1.0,
          );

    return (pAt - (pFrom + vSegment * vT)).distance;
  }

  @override
  void paint(Canvas pCanvas, Size pSize) {
    final vPoints = _screen(pSize);
    final vCentre = vPoints.reduce((pA, pB) => pA + pB) / vPoints.length.toDouble();
    for (var vIndex = 0; vIndex < vPoints.length - 1; vIndex++) {
      final vFrom = vPoints[vIndex];
      final vTo = vPoints[vIndex + 1];
      final vSelected = vIndex == selected;
      final vPaint = Paint()
        ..color = vSelected ? tape : ink
        ..strokeWidth = vSelected ? 6 : 3
        ..strokeCap = StrokeCap.round;
      if (measured.contains(vIndex) || vSelected) {
        pCanvas.drawLine(vFrom, vTo, vPaint);
      } else {
        _dashed(pCanvas, vFrom, vTo, vPaint);
      }
      // Numéro du mur, posé au milieu, un peu vers l'intérieur
      final vMiddle = (vFrom + vTo) / 2;
      final vInward = vCentre - vMiddle;
      final vBadge = vMiddle + vInward / math.max(vInward.distance, 1) * 22;
      pCanvas.drawCircle(vBadge, 15, Paint()..color = vSelected ? tape : paper);
      pCanvas.drawCircle(
        vBadge,
        15,
        Paint()
          ..color = vSelected ? tape : ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _label(pCanvas, '${vIndex + 1}', vBadge, vSelected ? onTape : ink, 15, FontWeight.w700);
    }
    // Mezzanine, escalier, trémie : leur contour en tirets fins, à l'échelle du plan
    final vFrame = _frame(pSize);
    final vThin = Paint()
      ..color = ink.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    for (final vFixture in room.fixtures.where((pFixture) => hasArea(pFixture.kind))) {
      final vOutline = [for (final (vX, vY) in vFixture.outlineMm()) vFrame.toScreen(vX, vY)];
      for (var vIndex = 0; vIndex < vOutline.length; vIndex++) {
        _dashed(pCanvas, vOutline[vIndex], vOutline[(vIndex + 1) % vOutline.length], vThin);
      }
    }
    // Lettres des coins, juste à l'extérieur
    for (var vIndex = 0; vIndex < vPoints.length - 1; vIndex++) {
      final vOutward = vPoints[vIndex] - vCentre;
      final vAt = vPoints[vIndex] + vOutward / math.max(vOutward.distance, 1) * 16;
      _label(pCanvas, String.fromCharCode(65 + vIndex), vAt, ink, 14, FontWeight.w400);
    }
  }

  void _dashed(Canvas pCanvas, Offset pFrom, Offset pTo, Paint pPaint) {
    final vLength = (pTo - pFrom).distance;
    if (vLength < 1) {
      return;
    }
    final vStep = (pTo - pFrom) / vLength;
    for (var vDone = 0.0; vDone < vLength; vDone += 14) {
      pCanvas.drawLine(pFrom + vStep * vDone, pFrom + vStep * math.min(vDone + 7, vLength), pPaint);
    }
  }

  void _label(
    Canvas pCanvas,
    String pText,
    Offset pAt,
    Color pColor,
    double pSize,
    FontWeight pWeight,
  ) {
    final vPainter = TextPainter(
      text: TextSpan(
        text: pText,
        style: TextStyle(fontFamily: handFont, fontSize: pSize, color: pColor, fontWeight: pWeight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    vPainter.paint(pCanvas, pAt - Offset(vPainter.width / 2, vPainter.height / 2));
  }

  @override
  bool shouldRepaint(_ShapePainter pOld) =>
      pOld.room != room || pOld.selected != selected || pOld.measured != measured;
}
