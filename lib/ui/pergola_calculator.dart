import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/extra_items.dart';
import '../logic/pergola.dart';
import '../logic/units.dart';
import '../logic/wood_species.dart';
import 'parquet_view.dart';
import 'shopping_target.dart';
import 'theme.dart';
import 'wood_species_card.dart';
import 'plan_unit.dart';
import 'room_measure_picker.dart' show lengthText;

String pergolaCoverLabel(AppLocalizations pText, PergolaCover pCover) => switch (pCover) {
  PergolaCover.open => pText.pergolaCoverOpen,
  PergolaCover.polycarbonate => pText.pergolaCoverPolycarbonate,
  PergolaCover.steelSheet => pText.pergolaCoverSteel,
  PergolaCover.tiles => pText.pergolaCoverTiles,
};

/// Pergola ou auvent : chevrons, poutres, poteaux et plots, selon la neige et la couverture.
class PergolaCalculator extends StatefulWidget {
  const PergolaCalculator({super.key});

  @override
  State<PergolaCalculator> createState() => _PergolaCalculatorState();
}

class _PergolaCalculatorState extends State<PergolaCalculator> {
  var _pergola = const Pergola();

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vUnit = PlanUnit.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planPergola(_pergola);
    final vRafter = vPlan.rafter;
    final vBeam = vPlan.beam;
    final vPostSide = vPlan.postSideMm;
    void vSet(Pergola pPergola) => setState(() => _pergola = pPergola);

    return Scaffold(
      appBar: AppBar(title: Text(vText.pergolaTitle)),
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
                  IconLine(
                    vRafter == null ? Icons.warning_amber : Icons.view_week_outlined,
                    vRafter == null
                        ? vText.pergolaRafterTooLong
                        : vText.pergolaRafters(
                            vPlan.rafters,
                            vRafter.widthMm,
                            vRafter.heightMm,
                            lengthText(vText, _pergola.rafterSpacingMm, vUnit),
                          ),
                    color: vRafter == null ? vTheme.colorScheme.error : null,
                  ),
                  IconLine(
                    Icons.straighten,
                    vBeam == null
                        ? vText.mezzanineBeamTooLong
                        : vText.mezzanineBeams(vPlan.beams, vBeam.widthMm, vBeam.heightMm),
                  ),
                  IconLine(
                    Icons.vertical_align_bottom,
                    vPostSide == null
                        ? vText.mezzaninePostTooSlender
                        : vText.pergolaPosts(
                            vPlan.postsPerBeam * vPlan.beams,
                            vPostSide,
                            lengthText(vText, vPlan.postSpacingMm, vUnit),
                          ),
                  ),
                  IconLine(Icons.foundation, vText.pergolaFootings(vPlan.concreteLitres)),
                  IconLine(
                    Icons.ac_unit,
                    vText.pergolaSnow(
                      (_pergola.snowKnPerM2 * 100).round(),
                      (_pergola.deadKnPerM2 * 100).round(),
                    ),
                  ),
                  Text(vText.pergolaWarning, style: vTheme.textTheme.bodySmall),
                  AddToShoppingButton(
                    items: () => [
                      if (vRafter != null)
                        ExtraItem(
                          name: vText.extraBeam(
                            vRafter.widthMm,
                            vRafter.heightMm,
                            formatCentimetres(_pergola.depthMm),
                          ),
                          quantity: vPlan.rafters,
                        ),
                      if (vBeam != null)
                        ExtraItem(
                          name: vText.extraBeam(
                            vBeam.widthMm,
                            vBeam.heightMm,
                            formatCentimetres(_pergola.lengthMm),
                          ),
                          quantity: vPlan.beams,
                        ),
                      if (vPostSide != null)
                        ExtraItem(
                          name: vText.extraBeam(
                            vPostSide,
                            vPostSide,
                            formatCentimetres(_pergola.postHeightMm),
                          ),
                          quantity: vPlan.postsPerBeam * vPlan.beams,
                        ),
                      ExtraItem(
                        name: vText.extraPostBases,
                        quantity: vPlan.postsPerBeam * vPlan.beams,
                      ),
                      ExtraItem(
                        name: vText.extraConcreteBags,
                        quantity: (vPlan.concreteLitres / 16).ceil(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const WoodSpeciesCard(useClass: UseClass.outdoor),
          DropdownButtonFormField<PergolaCover>(
            initialValue: _pergola.cover,
            decoration: InputDecoration(labelText: vText.pergolaCover),
            items: [
              for (final vCover in PergolaCover.values)
                DropdownMenuItem(value: vCover, child: Text(pergolaCoverLabel(vText, vCover))),
            ],
            onChanged: (pCover) => vSet(_pergola.copyWith(cover: pCover)),
          ),
          DropdownButtonFormField<SnowRegion>(
            initialValue: _pergola.region,
            decoration: InputDecoration(labelText: vText.pergolaRegion),
            items: [
              for (final vRegion in SnowRegion.values)
                DropdownMenuItem(
                  value: vRegion,
                  child: Text(
                    vText.pergolaRegionLabel(
                      vRegion.name.toUpperCase(),
                      (vRegion.groundKnPerM2 * 100).round(),
                    ),
                  ),
                ),
            ],
            onChanged: (pRegion) => vSet(_pergola.copyWith(region: pRegion)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.pergolaAgainstWall),
            value: _pergola.againstWall,
            onChanged: (pValue) => vSet(_pergola.copyWith(againstWall: pValue)),
          ),
          for (final (vLabel, vValue, vApply) in [
            (
              vText.pergolaLength,
              _pergola.lengthMm,
              (int pValue) => _pergola.copyWith(lengthMm: pValue),
            ),
            (
              vText.pergolaDepth,
              _pergola.depthMm,
              (int pValue) => _pergola.copyWith(depthMm: pValue),
            ),
            (
              vText.mezzaninePostHeight,
              _pergola.postHeightMm,
              (int pValue) => _pergola.copyWith(postHeightMm: pValue),
            ),
          ])
            NumberField(
              label: vLabel,
              initial: formatCentimetres(vValue),
              parse: parseCentimetres,
              onValue: (pValue) => vSet(vApply(pValue)),
            ),
        ],
      ),
    );
  }
}
