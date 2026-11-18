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

  Future<void> _measure() async {
    final vAngle = await measureAngle(context);
    if (vAngle != null && mounted) {
      setState(() => _slopeDeg = vAngle.round().clamp(1, 89));
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
                    ),
                  ),
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
            label: vText.atticKnee,
            initial: vCm(_kneeMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _kneeMm = pValue),
          ),
          Row(
            children: [
              Expanded(
                child: NumberField(
                  // Nouvelle clé après une mesure : le champ reprend la valeur mesurée
                  key: ValueKey(_slopeDeg),
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

/// Croquis coté de la coupe, à l'échelle, tracé au crayon sur le carnet.
class AtticSketch extends StatelessWidget {
  const AtticSketch({
    super.key,
    required this.section,
    required this.widthMm,
    required this.kneeMm,
    required this.twoPitches,
  });

  final AtticSection section;
  final int widthMm;
  final int kneeMm;
  final bool twoPitches;

  @override
  Widget build(BuildContext context) {
    final vColors = AtelierColors.of(context);
    final vText = AppLocalizations.of(context);

    return CustomPaint(
      painter: _AtticPainter(
        section: section,
        widthMm: widthMm,
        kneeMm: kneeMm,
        twoPitches: twoPitches,
        ink: vColors.ink,
        tape: Color.lerp(vColors.tape, Colors.orange, 0.2)!,
        style: Theme.of(
          context,
        ).textTheme.labelMedium!.copyWith(color: vColors.ink, fontStyle: FontStyle.italic),
        carrezLabel: vText.atticCarrezLine,
      ),
    );
  }
}

class _AtticPainter extends CustomPainter {
  _AtticPainter({
    required this.section,
    required this.widthMm,
    required this.kneeMm,
    required this.twoPitches,
    required this.ink,
    required this.tape,
    required this.style,
    required this.carrezLabel,
  });

  final AtticSection section;
  final int widthMm;
  final int kneeMm;
  final bool twoPitches;
  final Color ink;
  final Color tape;
  final TextStyle style;
  final String carrezLabel;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    if (widthMm <= 0) {
      return;
    }
    // Marges pour les cotes, puis une seule échelle pour la largeur et la hauteur
    const vLeft = 46.0;
    const vBottom = 34.0;
    const vTopMargin = 14.0;
    final vScale = [
      (pSize.width - vLeft - 16) / widthMm,
      (pSize.height - vBottom - vTopMargin) / section.topMm.clamp(1, 1 << 30),
    ].reduce((pA, pB) => pA < pB ? pA : pB);
    final vFloorY = pSize.height - vBottom;
    Offset vAt(double pXmm, double pYmm) => Offset(vLeft + pXmm * vScale, vFloorY - pYmm * vScale);

    // Papier millimétré à l'échelle du dessin : un carreau pour 50 cm
    final vGrid = Paint()
      ..color = ink.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    final vStep = 500 * vScale;
    for (var vX = vLeft; vX <= pSize.width; vX += vStep) {
      pCanvas.drawLine(Offset(vX, 0), Offset(vX, vFloorY), vGrid);
    }
    for (var vY = vFloorY; vY >= 0; vY -= vStep) {
      pCanvas.drawLine(Offset(vLeft, vY), Offset(pSize.width, vY), vGrid);
    }

    final vRun = twoPitches ? widthMm / 2 : widthMm.toDouble();
    final vSlopedRun = (widthMm - section.flatWidthMm) / (twoPitches ? 2 : 1);
    final vOutline = <Offset>[
      vAt(0, 0),
      vAt(0, kneeMm.toDouble()),
      vAt(vSlopedRun, section.topMm.toDouble()),
      if (twoPitches) ...[
        vAt(widthMm - vSlopedRun, section.topMm.toDouble()),
        vAt(widthMm.toDouble(), kneeMm.toDouble()),
        vAt(widthMm.toDouble(), 0),
      ] else ...[
        vAt(vRun, section.topMm.toDouble()),
        vAt(vRun, 0),
      ],
    ];

    // Zone où l'on tient debout, surlignée comme au feutre
    if (section.usableWidthMm > 0) {
      final vStart = section.lowStripMm.toDouble();
      final vEnd = vStart + section.usableWidthMm;
      pCanvas.drawRect(
        Rect.fromPoints(vAt(vStart, 0), vAt(vEnd, carrezHeightMm.toDouble())),
        Paint()..color = tape.withValues(alpha: 0.28),
      );
    }

    final vPencil = Paint()
      ..color = ink
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var vIndex = 0; vIndex < vOutline.length - 1; vIndex++) {
      pencilLine(pCanvas, vOutline[vIndex], vOutline[vIndex + 1], vPencil);
    }
    pencilLine(pCanvas, vOutline.last, vOutline.first, vPencil);

    // Ligne des 1,80 m en tirets
    final vDash = Paint()
      ..color = ink.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    final vCarrezY = vAt(0, carrezHeightMm.toDouble()).dy;
    if (section.topMm > carrezHeightMm) {
      for (var vX = vLeft; vX < vAt(vRun * (twoPitches ? 2 : 1), 0).dx; vX += 10) {
        pCanvas.drawLine(Offset(vX, vCarrezY), Offset(vX + 5, vCarrezY), vDash);
      }
      // Au bout de la ligne, à droite, loin de la cote de hauteur
      final vLabelAt = vAt(widthMm.toDouble(), carrezHeightMm.toDouble()) + const Offset(-16, -10);
      sketchLabel(pCanvas, carrezLabel, vLabelAt, style);
    }

    final vMeasure = Paint()
      ..color = ink.withValues(alpha: 0.85)
      ..strokeWidth = 1;
    String vCm(int pMm) => formatCentimetres(pMm);
    dimensionLine(
      pCanvas,
      vAt(0, 0) + const Offset(0, 16),
      vAt(widthMm.toDouble(), 0) + const Offset(0, 16),
      vCm(widthMm),
      vMeasure,
      style,
      pLabelShift: 11,
    );
    if (kneeMm > 0) {
      dimensionLine(
        pCanvas,
        vAt(0, 0) + const Offset(-18, 0),
        vAt(0, kneeMm.toDouble()) + const Offset(-18, 0),
        vCm(kneeMm),
        vMeasure,
        style,
        pLabelShift: -16,
      );
    }
    final vMiddle = twoPitches ? widthMm / 2 : vRun - (vRun - vSlopedRun) / 2;
    dimensionLine(
      pCanvas,
      vAt(vMiddle, 0),
      vAt(vMiddle, section.topMm.toDouble()),
      vCm(section.topMm),
      vMeasure,
      style,
      pLabelShift: 24,
    );
  }

  @override
  bool shouldRepaint(_AtticPainter pOld) =>
      pOld.section != section ||
      pOld.widthMm != widthMm ||
      pOld.kneeMm != kneeMm ||
      pOld.twoPitches != twoPitches ||
      pOld.ink != ink;
}
