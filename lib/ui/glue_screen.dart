import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/glues.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Colles et serrage : la colle selon ce qu'on assemble, ses temps, et les serre-joints.
class GlueScreen extends StatefulWidget {
  const GlueScreen({super.key});

  @override
  State<GlueScreen> createState() => _GlueScreenState();
}

class _GlueScreenState extends State<GlueScreen> {
  GlueUse _use = GlueUse.indoorFurniture;
  int _lengthMm = 800;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vClamps = clampsFor(_lengthMm);

    return Scaffold(
      appBar: AppBar(title: Text(vText.glueTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(vText.glueUseQuestion, style: vTheme.textTheme.titleSmall),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final vUse in GlueUse.values)
                ChoiceChip(
                  label: Text(glueUseName(vText, vUse)),
                  selected: _use == vUse,
                  onSelected: (_) => setState(() => _use = vUse),
                ),
            ],
          ),
          for (final vGlue in gluesFor(_use))
            Card(
              margin: const EdgeInsets.only(top: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(glueName(vText, vGlue), style: vTheme.textTheme.titleMedium),
                    Text(glueText(vText, vGlue), style: vTheme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    IconLine(Icons.timer_outlined, vText.glueOpen(vGlue.openMinutes)),
                    IconLine(
                      Icons.compress,
                      vGlue.clampMinutes == 0
                          ? vText.glueNoClamp
                          : vText.glueClamp(vGlue.clampMinutes, vClamps),
                    ),
                    IconLine(Icons.hourglass_bottom, vText.glueCure(vGlue.cureHours)),
                    if (vGlue.waterproof) IconLine(Icons.water_drop_outlined, vText.glueWaterproof),
                    if (vGlue.gapFilling) IconLine(Icons.format_color_fill, vText.glueGapFilling),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          NumberField(
            label: vText.glueLength,
            initial: formatCentimetres(_lengthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _lengthMm = pValue),
          ),
          const SizedBox(height: 8),
          IconLine(Icons.lightbulb_outline, vText.glueTip),
          Text(vText.glueHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

String glueUseName(AppLocalizations pText, GlueUse pUse) => switch (pUse) {
  GlueUse.indoorFurniture => pText.glueUseFurniture,
  GlueUse.outdoorWood => pText.glueUseOutdoor,
  GlueUse.laminate => pText.glueUseLaminate,
  GlueUse.repair => pText.glueUseRepair,
  GlueUse.heavyFixing => pText.glueUseFixing,
};

String glueName(AppLocalizations pText, Glue pGlue) => switch (pGlue) {
  Glue.vinyl => pText.glueVinyl,
  Glue.vinylD3 => pText.glueVinylD3,
  Glue.polyurethane => pText.gluePolyurethane,
  Glue.contact => pText.glueContact,
  Glue.epoxy => pText.glueEpoxy,
  Glue.construction => pText.glueConstruction,
};

String glueText(AppLocalizations pText, Glue pGlue) => switch (pGlue) {
  Glue.vinyl => pText.glueVinylText,
  Glue.vinylD3 => pText.glueVinylD3Text,
  Glue.polyurethane => pText.gluePolyurethaneText,
  Glue.contact => pText.glueContactText,
  Glue.epoxy => pText.glueEpoxyText,
  Glue.construction => pText.glueConstructionText,
};
