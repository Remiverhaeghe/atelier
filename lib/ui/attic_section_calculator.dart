import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/attic_section.dart';
import '../logic/units.dart';
import 'level_screen.dart';
import 'notebook.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Pièce sous rampants vue en coupe : ce qu'on tient debout, ce qu'on habille de placo.
class AtticSectionCalculator extends StatefulWidget {
  const AtticSectionCalculator({super.key});

  @override
  State<AtticSectionCalculator> createState() => _AtticSectionCalculatorState();
}

class _AtticSectionCalculatorState extends State<AtticSectionCalculator> {
  var _widthMm = 6000;
  var _kneeMm = 800;
  var _slopeDeg = 40;
  var _ceilingMm = 0;
  var _lengthMm = 4200;
  var _twoPitches = true;

  // Augmenté quand une valeur change hors des champs (mesure au téléphone, croquis) : les
  // champs sont recréés avec la nouvelle valeur, sans perdre la saisie en cours sinon
  var _outside = 0;

  Future<void> _measure() async {
    final vAngle = await measureAngle(context);
    if (vAngle != null && mounted) {
      setState(() {
        _slopeDeg = vAngle.round().clamp(1, 89);
        _outside++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    String vCm(int pMm) => formatCentimetres(pMm);
    String vM2(double pValue) => formatDecimal((pValue * 10).round() / 10);
    final vSection = atticSection(
      pWidthMm: _widthMm,
      pKneeWallMm: _kneeMm,
      pSlopeDeg: _slopeDeg.toDouble(),
      pTwoPitches: _twoPitches,
      pCeilingMm: _ceilingMm > 0 ? _ceilingMm : null,
    );
    final vLength = _lengthMm / 1000;
    final vUsableM2 = vSection.usableWidthMm / 1000 * vLength;
    final vFloorM2 = _widthMm / 1000 * vLength;
    final vBoardM2 = vSection.boardM2PerMetre * vLength;

    return Scaffold(
      appBar: AppBar(title: Text(vText.atticTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            margin: EdgeInsets.zero,
            // Carte translucide : le croquis reste posé sur le quadrillage du carnet
            color: vTheme.colorScheme.surfaceContainerLow.withValues(alpha: 0.7),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.7,
                    child: AtticSketch(
                      section: vSection,
                      widthMm: _widthMm,
                      kneeMm: _kneeMm,
                      twoPitches: _twoPitches,
                      onKnee: (pMm) => setState(() {
                        _kneeMm = pMm;
                        _outside++;
                      }),
                      onSlope: (pDeg) => setState(() {
                        _slopeDeg = pDeg;
                        _outside++;
                      }),
                    ),
                  ),
                  Text(vText.atticDragHint, style: vTheme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  BigFigure(vText.atticUsable(vM2(vUsableM2))),
                  IconLine(Icons.square_foot, vText.atticFloor(vM2(vFloorM2))),
                  IconLine(Icons.height, vText.atticTop(vCm(vSection.topMm))),
                  IconLine(Icons.straighten, vText.atticRafter(vCm(vSection.rafterLengthMm))),
                  IconLine(Icons.layers_outlined, vText.atticBoard(vM2(vBoardM2))),
                ],
              ),
            ),
          ),
          WhyCard(
            title: vText.whyTitle,
            steps: [
              vText.atticWhyTop(vCm(_kneeMm), vCm(vSection.topMm)),
              vText.atticWhyLow(vCm(vSection.lowStripMm)),
              vText.atticWhyUsable(vCm(vSection.usableWidthMm), vM2(vUsableM2)),
              vText.atticWhyBoard(vM2(vSection.boardM2PerMetre), vM2(vBoardM2)),
            ],
          ),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(vText.atticTwoPitches)),
              ButtonSegment(value: false, label: Text(vText.atticOnePitch)),
            ],
            selected: {_twoPitches},
            onSelectionChanged: (pSelection) => setState(() => _twoPitches = pSelection.first),
          ),
          NumberField(
            label: vText.atticWidth,
            initial: vCm(_widthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _widthMm = pValue),
          ),
          NumberField(
            key: ValueKey('knee-$_outside'),
            label: vText.atticKnee,
            initial: vCm(_kneeMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _kneeMm = pValue),
          ),
          Row(
            children: [
              Expanded(
                child: NumberField(
                  key: ValueKey('slope-$_outside'),
                  label: vText.atticSlope,
                  initial: '$_slopeDeg',
                  parse: parseWhole,
                  onValue: (pValue) => setState(() => _slopeDeg = pValue.clamp(1, 89)),
                ),
              ),
              IconButton.filledTonal(
                tooltip: vText.atticMeasure,
                icon: const Icon(Icons.screen_rotation_alt),
                onPressed: _measure,
              ),
            ],
          ),
          NumberField(
            label: vText.atticCeiling,
            initial: _ceilingMm > 0 ? vCm(_ceilingMm) : '',
            parse: (pText) => pText.trim().isEmpty ? 0 : parseCentimetres(pText),
            onValue: (pValue) => setState(() => _ceilingMm = pValue),
          ),
          NumberField(
            label: vText.atticLength,
            initial: vCm(_lengthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _lengthMm = pValue),
          ),
        ],
      ),
    );
  }
}

/// Croquis coté de la coupe, à l'échelle, tracé au crayon sur le carnet. Il se dessine à
/// l'ouverture, et se modifie au doigt : la poignée de la jambette règle sa hauteur, celle du
/// sommet règle l'angle du rampant.
class AtticSketch extends StatefulWidget {
  const AtticSketch({
    super.key,
    required this.section,
    required this.widthMm,
    required this.kneeMm,
    required this.twoPitches,
    this.onKnee,
    this.onSlope,
  });

  final AtticSection section;
  final int widthMm;
  final int kneeMm;
  final bool twoPitches;
  final ValueChanged<int>? onKnee;
  final ValueChanged<int>? onSlope;

  @override
  State<AtticSketch> createState() => _AtticSketchState();
}

enum _Handle { knee, top }

class _AtticSketchState extends State<AtticSketch> with SingleTickerProviderStateMixin {
  late final _drawing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  _Handle? _dragging;
  // Hauteurs suivies pendant le glissé, en millimètres
  double _kneeMm = 0;
  double _topMm = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Une seule animation, à l'ouverture ; aucune si le téléphone demande de les réduire
    if (MediaQuery.disableAnimationsOf(context)) {
      _drawing.value = 1;
    } else if (_drawing.status == AnimationStatus.dismissed) {
      _drawing.forward();
    }
  }

  @override
  void dispose() {
    _drawing.dispose();
    super.dispose();
  }

  _AtticGeometry _geometry(Size pSize) => _AtticGeometry(
    size: pSize,
    section: widget.section,
    widthMm: widget.widthMm,
    kneeMm: widget.kneeMm,
    twoPitches: widget.twoPitches,
  );

  void _start(DragStartDetails pDetails, Size pSize) {
    final vGeometry = _geometry(pSize);
    final vKnee = (pDetails.localPosition - vGeometry.kneeHandle).distance;
    final vTop = (pDetails.localPosition - vGeometry.topHandle).distance;
    _kneeMm = widget.kneeMm.toDouble();
    _topMm = widget.section.topMm.toDouble();
    _dragging = vKnee < 36 && vKnee <= vTop
        ? _Handle.knee
        : vTop < 36
        ? _Handle.top
        : null;
  }

  void _update(DragUpdateDetails pDetails, Size pSize) {
    final vScale = _geometry(pSize).scale;
    final vRun = widget.twoPitches ? widget.widthMm / 2 : widget.widthMm.toDouble();
    switch (_dragging) {
      case _Handle.knee:
        _kneeMm = (_kneeMm - pDetails.delta.dy / vScale).clamp(0, 2500);
        // Arrondi au centimètre, comme on le mesurerait
        widget.onKnee?.call((_kneeMm / 10).round() * 10);
      case _Handle.top:
        _topMm = (_topMm - pDetails.delta.dy / vScale).clamp(widget.kneeMm + 50.0, 9000);
        final vDeg = math.atan((_topMm - widget.kneeMm) / math.max(1, vRun)) * 180 / math.pi;
        widget.onSlope?.call(vDeg.round().clamp(1, 89));
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vColors = AtelierColors.of(context);
    final vText = AppLocalizations.of(context);
    final vInk = vColors.ink;

    return LayoutBuilder(
      builder: (pContext, pConstraints) {
        final vSize = pConstraints.biggest;

        return GestureDetector(
          onPanStart: (pDetails) => _start(pDetails, vSize),
          onPanUpdate: (pDetails) => _update(pDetails, vSize),
          onPanEnd: (_) => _dragging = null,
          child: AnimatedBuilder(
            animation: _drawing,
            builder: (_, _) => CustomPaint(
              size: vSize,
              painter: _AtticPainter(
                geometry: _geometry(vSize),
                progress: _drawing.value,
                ink: vInk,
                tape: Color.lerp(vColors.tape, Colors.orange, 0.2)!,
                handle: Theme.of(context).colorScheme.primary,
                style: TextStyle(fontFamily: handFont, fontSize: 18, color: vInk),
                carrezLabel: vText.atticCarrezLine,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mise à l'échelle de la coupe dans le cadre du croquis, partagée par le dessin et le doigt.
class _AtticGeometry {
  _AtticGeometry({
    required this.size,
    required this.section,
    required this.widthMm,
    required this.kneeMm,
    required this.twoPitches,
  }) {
    final vTop = section.topMm.clamp(1, 1 << 30);
    scale = math.min((size.width - left - 16) / math.max(1, widthMm), (floorY - 14) / vTop);
  }

  final Size size;
  final AtticSection section;
  final int widthMm;
  final int kneeMm;
  final bool twoPitches;
  late final double scale;

  // Marges pour les cotes
  static const left = 46.0;
  double get floorY => size.height - 34;

  Offset at(double pXmm, double pYmm) => Offset(left + pXmm * scale, floorY - pYmm * scale);

  double get run => twoPitches ? widthMm / 2 : widthMm.toDouble();
  double get slopedRun => (widthMm - section.flatWidthMm) / (twoPitches ? 2 : 1);

  Offset get kneeHandle => at(0, kneeMm.toDouble());
  Offset get topHandle => at(twoPitches ? widthMm / 2 : slopedRun, section.topMm.toDouble());

  List<Offset> get outline => [
    at(0, 0),
    at(0, kneeMm.toDouble()),
    at(slopedRun, section.topMm.toDouble()),
    if (twoPitches) ...[
      at(widthMm - slopedRun, section.topMm.toDouble()),
      at(widthMm.toDouble(), kneeMm.toDouble()),
      at(widthMm.toDouble(), 0),
    ] else ...[
      at(run, section.topMm.toDouble()),
      at(run, 0),
    ],
    at(0, 0),
  ];
}

class _AtticPainter extends CustomPainter {
  _AtticPainter({
    required this.geometry,
    required this.progress,
    required this.ink,
    required this.tape,
    required this.handle,
    required this.style,
    required this.carrezLabel,
  });

  final _AtticGeometry geometry;
  final double progress;
  final Color ink;
  final Color tape;
  final Color handle;
  final TextStyle style;
  final String carrezLabel;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    final vGeometry = geometry;
    final vSection = vGeometry.section;
    if (vGeometry.widthMm <= 0) {
      return;
    }
    final vFloorY = vGeometry.floorY;
    const vLeft = _AtticGeometry.left;

    // Papier millimétré à l'échelle du dessin : un carreau pour 50 cm
    final vGrid = Paint()
      ..color = ink.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    final vStep = math.max(8.0, 500 * vGeometry.scale);
    for (var vX = vLeft; vX <= pSize.width; vX += vStep) {
      pCanvas.drawLine(Offset(vX, 0), Offset(vX, vFloorY), vGrid);
    }
    for (var vY = vFloorY; vY >= 0; vY -= vStep) {
      pCanvas.drawLine(Offset(vLeft, vY), Offset(pSize.width, vY), vGrid);
    }

    // Le trait se dessine d'abord, le reste apparaît ensuite
    final vTrace = (progress / 0.7).clamp(0.0, 1.0);
    final vReveal = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);

    if (vSection.usableWidthMm > 0 && vReveal > 0) {
      final vStart = vSection.lowStripMm.toDouble();
      final vEnd = vStart + vSection.usableWidthMm;
      pCanvas.drawRect(
        Rect.fromPoints(vGeometry.at(vStart, 0), vGeometry.at(vEnd, carrezHeightMm.toDouble())),
        Paint()..color = tape.withValues(alpha: 0.3 * vReveal),
      );
    }

    final vPencil = Paint()
      ..color = ink
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final vOutline = vGeometry.outline;
    var vLength = 0.0;
    for (var vIndex = 0; vIndex < vOutline.length - 1; vIndex++) {
      vLength += (vOutline[vIndex + 1] - vOutline[vIndex]).distance;
    }
    var vLeftToDraw = vLength * vTrace;
    for (var vIndex = 0; vIndex < vOutline.length - 1 && vLeftToDraw > 0; vIndex++) {
      final vFrom = vOutline[vIndex];
      final vSegment = vOutline[vIndex + 1] - vFrom;
      final vPart = math.min(1.0, vLeftToDraw / math.max(1e-6, vSegment.distance));
      pencilLine(pCanvas, vFrom, vFrom + vSegment * vPart, vPencil);
      vLeftToDraw -= vSegment.distance;
    }
    if (vReveal == 0) {
      return;
    }

    final vRevealStyle = style.copyWith(color: style.color!.withValues(alpha: vReveal));
    final vDash = Paint()
      ..color = ink.withValues(alpha: 0.6 * vReveal)
      ..strokeWidth = 1;
    final vRight = vGeometry.at(vGeometry.widthMm.toDouble(), 0).dx;
    if (vSection.topMm > carrezHeightMm) {
      final vCarrezY = vGeometry.at(0, carrezHeightMm.toDouble()).dy;
      for (var vX = vLeft; vX < vRight; vX += 10) {
        pCanvas.drawLine(Offset(vX, vCarrezY), Offset(vX + 5, vCarrezY), vDash);
      }
      sketchLabel(pCanvas, carrezLabel, Offset(vRight - 16, vCarrezY - 12), vRevealStyle);
    }

    final vMeasure = Paint()
      ..color = ink.withValues(alpha: 0.85 * vReveal)
      ..strokeWidth = 1;
    String vCm(int pMm) => formatCentimetres(pMm);
    dimensionLine(
      pCanvas,
      vGeometry.at(0, 0) + const Offset(0, 16),
      vGeometry.at(vGeometry.widthMm.toDouble(), 0) + const Offset(0, 16),
      vCm(vGeometry.widthMm),
      vMeasure,
      vRevealStyle,
      pLabelShift: 12,
    );
    if (vGeometry.kneeMm > 0) {
      dimensionLine(
        pCanvas,
        vGeometry.at(0, 0) + const Offset(-18, 0),
        vGeometry.at(0, vGeometry.kneeMm.toDouble()) + const Offset(-18, 0),
        vCm(vGeometry.kneeMm),
        vMeasure,
        vRevealStyle,
        pLabelShift: -16,
      );
    }
    final vMiddle = vGeometry.twoPitches
        ? vGeometry.widthMm / 2
        : vGeometry.run - (vGeometry.run - vGeometry.slopedRun) / 2;
    dimensionLine(
      pCanvas,
      vGeometry.at(vMiddle, 0),
      vGeometry.at(vMiddle, vSection.topMm.toDouble()),
      vCm(vSection.topMm),
      vMeasure,
      vRevealStyle,
      pLabelShift: 26,
    );

    // Poignées à attraper au doigt
    final vHandle = Paint()..color = handle.withValues(alpha: vReveal);
    final vRing = Paint()
      ..color = handle.withValues(alpha: 0.3 * vReveal)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    for (final vPoint in [vGeometry.kneeHandle, vGeometry.topHandle]) {
      pCanvas
        ..drawCircle(vPoint, 7, vHandle)
        ..drawCircle(vPoint, 13, vRing);
    }
  }

  @override
  bool shouldRepaint(_AtticPainter pOld) =>
      pOld.progress != progress ||
      pOld.geometry.section != geometry.section ||
      pOld.geometry.widthMm != geometry.widthMm ||
      pOld.geometry.kneeMm != geometry.kneeMm ||
      pOld.geometry.twoPitches != geometry.twoPitches ||
      pOld.geometry.size != geometry.size ||
      pOld.ink != ink;
}
