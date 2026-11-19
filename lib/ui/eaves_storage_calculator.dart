import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/eaves_storage.dart';
import '../logic/extra_items.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'shopping_target.dart';
import 'sketch3d.dart';
import 'theme.dart';

/// Placard sous rampant : façade, modules, portes et bacs sur roulettes.
class EavesStorageCalculator extends StatefulWidget {
  const EavesStorageCalculator({super.key});

  @override
  State<EavesStorageCalculator> createState() => _EavesStorageCalculatorState();
}

class _EavesStorageCalculatorState extends State<EavesStorageCalculator> {
  int _kneeMm = 600;
  int _slopeDeg = 45;
  int _lengthMm = 2400;
  int _frontMm = 1200;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planEavesStorage(
      pKneeWallMm: _kneeMm,
      pSlopeDeg: _slopeDeg.toDouble(),
      pLengthMm: _lengthMm,
      pFrontMm: _frontMm,
    );
    String vCm(int pMm) => formatCentimetres(pMm);

    return Scaffold(
      appBar: AppBar(title: Text(vText.eavesTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (vPlan == null)
            IconLine(Icons.warning_amber, vText.eavesNone, color: vTheme.colorScheme.error)
          else ...[
            AspectRatio(
              aspectRatio: 1.4,
              child: EavesSketch(plan: vPlan, kneeMm: _kneeMm, frontMm: _frontMm),
            ),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BigFigure(vText.eavesDepth(vCm(vPlan.depthMm))),
                    IconLine(Icons.inventory_2_outlined, vText.eavesLitres(vPlan.litres)),
                    IconLine(
                      Icons.view_week_outlined,
                      vText.eavesModules(vPlan.modules, vCm(vPlan.moduleMm)),
                    ),
                    IconLine(
                      Icons.content_cut,
                      vText.eavesSides(vPlan.sides, vCm(_kneeMm), vCm(_frontMm), _slopeDeg),
                    ),
                    IconLine(
                      Icons.door_front_door_outlined,
                      vText.eavesDoors(
                        vPlan.modules,
                        vCm(vPlan.moduleMm),
                        vCm(vPlan.doorHeightMm),
                        vPlan.hingesPerDoor,
                      ),
                    ),
                    IconLine(
                      Icons.shopping_basket_outlined,
                      vText.eavesBins(
                        vPlan.modules,
                        vCm(vPlan.binWidthMm),
                        vCm(vPlan.binDepthMm),
                        vCm(vPlan.binHeightMm),
                      ),
                    ),
                    if (vPlan.shelf case final vShelf?)
                      IconLine(
                        Icons.table_rows_outlined,
                        vText.eavesShelf(vCm(vShelf.heightMm), vCm(vShelf.depthMm)),
                      ),
                    IconLine(Icons.dashboard_outlined, vText.eavesPanels(vPlan.panels)),
                    AddToShoppingButton(
                      items: () => [
                        ExtraItem(name: vText.eavesPanelItem, quantity: vPlan.panels),
                        ExtraItem(
                          name: vText.eavesHingeItem,
                          quantity: vPlan.modules * vPlan.hingesPerDoor,
                        ),
                        ExtraItem(name: vText.eavesCasterItem, quantity: vPlan.modules * 4),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          NumberField(
            label: vText.eavesKnee,
            initial: vCm(_kneeMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _kneeMm = pValue),
          ),
          NumberField(
            label: vText.slopeAngle,
            initial: '$_slopeDeg',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _slopeDeg = pValue.clamp(5, 85)),
          ),
          NumberField(
            label: vText.eavesLength,
            initial: vCm(_lengthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _lengthMm = pValue),
          ),
          NumberField(
            label: vText.eavesFront,
            initial: vCm(_frontMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _frontMm = pValue),
          ),
          const SizedBox(height: 12),
          IconLine(Icons.lightbulb_outline, vText.eavesTip),
          Text(vText.eavesHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Le placard en relief : mur de genou, rampant, montants coupés, une porte ouverte sur un bac.
class EavesSketch extends StatelessWidget {
  const EavesSketch({super.key, required this.plan, required this.kneeMm, required this.frontMm});

  final EavesPlan plan;
  final int kneeMm;
  final int frontMm;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vDepth = plan.depthMm.toDouble();
    final vKnee = kneeMm.toDouble();
    final vFront = frontMm.toDouble();
    // Deux modules suffisent pour comprendre ; le rampant dépasse un peu la façade
    final vWidth = plan.moduleMm * 2.0;
    final vRise = (vFront - vKnee) / vDepth;
    final vRoofEnd = vDepth * 1.3;

    return Sketch3D(
      parts: [
        Prism.box(-60, 0, 0, vWidth, 0, vKnee, role: PartRole.board),
        Prism(
          [
            (0, vKnee),
            (vRoofEnd, vKnee + vRoofEnd * vRise),
            (vRoofEnd, vKnee + vRoofEnd * vRise + 40),
            (0, vKnee + 40),
          ],
          0,
          vWidth,
          role: PartRole.ghost,
        ),
        for (final vY in [0.0, plan.moduleMm.toDouble(), vWidth - 19])
          Prism([(0, 0), (vDepth, 0), (vDepth, vFront), (0, vKnee)], vY, vY + 19),
        Prism.box(
          binBackGapMm.toDouble(),
          vDepth,
          binSideGapMm.toDouble(),
          plan.binWidthMm.toDouble(),
          0,
          plan.binHeightMm.toDouble(),
          role: PartRole.highlight,
        ),
        Prism.box(
          vDepth,
          vDepth + 19,
          plan.moduleMm.toDouble(),
          vWidth,
          eavesPlinthMm.toDouble(),
          vFront,
          role: PartRole.board,
        ),
      ],
      callouts: [
        (
          at: (x: -30.0, y: 0.0, z: vKnee / 2),
          text: vText.eavesKneeLabel,
          shift: const Offset(-40, 0),
        ),
        (
          at: (x: vRoofEnd * 0.8, y: vWidth, z: vKnee + vRoofEnd * 0.8 * vRise + 40),
          text: vText.eavesSlopeLabel,
          shift: const Offset(30, -30),
        ),
        (
          at: (x: vDepth * 0.6, y: 0.0, z: plan.binHeightMm / 2),
          text: vText.eavesBinLabel,
          shift: const Offset(-20, 50),
        ),
        (
          at: (x: vDepth + 19, y: vWidth, z: (vFront + eavesPlinthMm) / 2),
          text: vText.eavesDoorLabel,
          shift: const Offset(40, 20),
        ),
      ],
    );
  }
}
