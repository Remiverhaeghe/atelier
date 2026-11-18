import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/glossary.dart';
import '../logic/units.dart';
import '../logic/wood_window.dart';
import '../logic/wood_species.dart';
import 'glossary_view.dart';
import 'notebook.dart';
import 'parquet_view.dart';
import 'sketch3d.dart';
import 'theme.dart';
import 'wood_species_card.dart';

/// Châssis fixe en bois pour remplacer un plexi : débit, assemblages, vitrage à commander.
class WoodWindowCalculator extends StatefulWidget {
  const WoodWindowCalculator({super.key});

  @override
  State<WoodWindowCalculator> createState() => _WoodWindowCalculatorState();
}

class _WoodWindowCalculatorState extends State<WoodWindowCalculator> {
  var _widthMm = 800;
  var _heightMm = 1000;
  var _frameWidthMm = 58;
  var _frameDepthMm = 70;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    String vCm(int pMm) => formatCentimetres(pMm);
    final vW = _frameWidthMm;
    final vD = _frameDepthMm;
    final vWindow = planWoodWindow(
      pWidthMm: _widthMm,
      pHeightMm: _heightMm,
      pFrameWidthMm: _frameWidthMm,
      pFrameDepthMm: _frameDepthMm,
    );

    return Scaffold(
      appBar: AppBar(title: Text(vText.woodWindowTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: WoodWindowSketch(
                      window: vWindow,
                      frameWidthMm: _frameWidthMm,
                      frameDepthMm: _frameDepthMm,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BigFigure(
                    vText.woodWindowGlass(vCm(vWindow.glassWidthMm), vCm(vWindow.glassHeightMm)),
                  ),
                  IconLine(
                    Icons.scale_outlined,
                    vText.woodWindowGlassWeight(formatDecimal(vWindow.glassKg.roundToDouble())),
                  ),
                  IconLine(
                    Icons.carpenter_outlined,
                    vText.woodWindowStiles(vCm(vWindow.stileLengthMm), vW, vD),
                  ),
                  IconLine(Icons.carpenter, vText.woodWindowRails(vCm(vWindow.railLengthMm))),
                  IconLine(
                    Icons.join_inner,
                    vText.woodWindowTenon(vWindow.tenonLengthMm, vWindow.tenonThicknessMm),
                  ),
                  IconLine(
                    Icons.straighten,
                    vText.woodWindowRebate(rebateDepthMm, vWindow.rebateWidthMm),
                  ),
                  IconLine(Icons.horizontal_rule, vText.woodWindowBead(vCm(vWindow.beadLengthMm))),
                  if (vWindow.frameTooThin)
                    IconLine(
                      Icons.warning_amber,
                      vText.woodWindowTooThin(minLipMm),
                      color: vTheme.colorScheme.error,
                    ),
                ],
              ),
            ),
          ),
          const TermsRow([
            Term.frame,
            Term.stile,
            Term.rail,
            Term.tenon,
            Term.mortise,
            Term.rebate,
            Term.glazingBead,
            Term.setting,
          ]),
          WhyCard(
            title: vText.whyTitle,
            steps: [
              vText.woodWindowWhyOuter(
                fittingGapMm,
                vCm(vWindow.outerWidthMm),
                vCm(vWindow.outerHeightMm),
              ),
              vText.woodWindowWhyTenon(_frameDepthMm, _frameWidthMm),
              vText.woodWindowWhyGlass(rebateDepthMm, glassClearanceMm),
              vText.woodWindowWhyRebate(glassThicknessMm, glazingSealMm, beadThicknessMm),
            ],
          ),
          const WoodSpeciesCard(useClass: UseClass.outdoor),
          Text(vText.woodWindowSteps, style: vTheme.textTheme.bodySmall),
          NumberField(
            label: vText.woodWindowWidth,
            initial: vCm(_widthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _widthMm = pValue),
          ),
          NumberField(
            label: vText.woodWindowHeight,
            initial: vCm(_heightMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _heightMm = pValue),
          ),
          NumberField(
            label: vText.woodWindowFrameWidth,
            initial: '$_frameWidthMm',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _frameWidthMm = pValue),
          ),
          NumberField(
            label: vText.woodWindowFrameDepth,
            initial: '$_frameDepthMm',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _frameDepthMm = pValue),
          ),
        ],
      ),
    );
  }
}

/// Le châssis en relief, à l'échelle : montants pleine hauteur, traverses entre eux, vitrage
/// posé au milieu de l'épaisseur, cotes de largeur, de hauteur et d'épaisseur.
class WoodWindowSketch extends StatelessWidget {
  const WoodWindowSketch({
    super.key,
    required this.window,
    required this.frameWidthMm,
    required this.frameDepthMm,
  });

  final WoodWindow window;
  final int frameWidthMm;
  final int frameDepthMm;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vWidth = window.outerWidthMm.toDouble();
    final vHeight = window.outerHeightMm.toDouble();
    final vBar = frameWidthMm.toDouble();
    final vDepth = frameDepthMm.toDouble();
    if (vWidth <= 2 * vBar || vHeight <= 2 * vBar) {
      return const SizedBox.shrink();
    }
    // Épaisseur dessinée plus forte que nature pour qu'on la voie, plafonnée à un quart
    final vShown = (vDepth * 2.5).clamp(vDepth, vWidth / 4);

    return Sketch3D(
      parts: [
        Prism.box(0, vBar, 0, vShown, 0, vHeight),
        Prism.box(vWidth - vBar, vWidth, 0, vShown, 0, vHeight),
        Prism.box(vBar, vWidth - vBar, 0, vShown, 0, vBar),
        Prism.box(vBar, vWidth - vBar, 0, vShown, vHeight - vBar, vHeight),
        Prism.box(
          vBar,
          vWidth - vBar,
          vShown * 0.45,
          vShown * 0.55,
          vBar,
          vHeight - vBar,
          role: PartRole.glass,
        ),
      ],
      callouts: [
        (
          at: (x: vWidth / 2, y: 0, z: 0),
          text: vText.sketchCm(formatCentimetres(window.outerWidthMm)),
          shift: const Offset(0, 26),
        ),
        (
          at: (x: 0, y: 0, z: vHeight / 2),
          text: vText.sketchCm(formatCentimetres(window.outerHeightMm)),
          shift: const Offset(-36, 0),
        ),
        (
          at: (x: vWidth, y: vShown / 2, z: vHeight),
          text: vText.sketchDepth(frameDepthMm),
          shift: const Offset(20, -24),
        ),
      ],
    );
  }
}
