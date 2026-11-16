import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/tiling.dart';
import '../logic/units.dart';
import '../logic/wall_tiling.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Faïence et crédence : pan de mur, ouverture, prises, profilés et silicone.
class WallTilingCalculator extends StatefulWidget {
  const WallTilingCalculator({super.key});

  @override
  State<WallTilingCalculator> createState() => _WallTilingCalculatorState();
}

class _WallTilingCalculatorState extends State<WallTilingCalculator> {
  var _wall = const WallTiling();

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vNeeds = wallTilingNeeds(_wall);
    final vDesign = _wall.design;
    void vSet(WallTiling pWall) => setState(() => _wall = pWall);
    void vDesignSet(TilingDesign pDesign) => vSet(_wall.copyWith(design: pDesign));
    final vRow = vNeeds.tiling.alongWidth;
    final vTopCut = vDesign.widthMm - vRow.fullTiles * (vDesign.tileWidthMm + vDesign.jointMm);

    return Scaffold(
      appBar: AppBar(title: Text(vText.wallTileTitle)),
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
                  BigFigure(vText.tilingBoxes(vNeeds.boxes)),
                  Text(vText.tilingTiles(vNeeds.tiles, formatSquareMetres(vNeeds.netAreaM2))),
                  IconLine(
                    Icons.table_rows_outlined,
                    vTopCut <= 0
                        ? vText.wallTileRowsExact(vRow.fullTiles)
                        : vText.wallTileRows(vRow.fullTiles, formatCentimetres(vTopCut)),
                  ),
                  IconLine(Icons.format_paint_outlined, vText.tilingGlue(vNeeds.glueKg)),
                  IconLine(Icons.grid_on, vText.tilingJoint(formatDecimal(vNeeds.jointKg))),
                  if (vNeeds.holes > 0)
                    IconLine(Icons.power_outlined, vText.wallTileHoles(vNeeds.holes, holeSawMm)),
                  if (vNeeds.profileMm > 0)
                    IconLine(
                      Icons.border_outer,
                      vText.wallTileProfile(formatCentimetres(vNeeds.profileMm)),
                    ),
                  if (vNeeds.siliconeMm > 0)
                    IconLine(
                      Icons.water_drop_outlined,
                      vText.wallTileSilicone(formatCentimetres(vNeeds.siliconeMm)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          NumberField<int>(
            label: vText.wallTileWidth,
            initial: formatCentimetres(vDesign.lengthMm),
            parse: parseCentimetres,
            onValue: (pValue) => vDesignSet(vDesign.copyWith(lengthMm: pValue)),
          ),
          NumberField<int>(
            label: vText.wallTileHeight,
            initial: formatCentimetres(vDesign.widthMm),
            parse: parseCentimetres,
            onValue: (pValue) => vDesignSet(vDesign.copyWith(widthMm: pValue)),
          ),
          NumberField<int>(
            label: vText.tileLength,
            initial: formatCentimetres(vDesign.tileLengthMm),
            parse: parseCentimetres,
            onValue: (pValue) => vDesignSet(vDesign.copyWith(tileLengthMm: pValue)),
          ),
          NumberField<int>(
            label: vText.wallTileTileHeight,
            initial: formatCentimetres(vDesign.tileWidthMm),
            parse: parseCentimetres,
            onValue: (pValue) => vDesignSet(vDesign.copyWith(tileWidthMm: pValue)),
          ),
          NumberField<double>(
            label: vText.tilingBoxArea,
            initial: formatDecimal(vDesign.boxM2),
            parse: parseDecimal,
            onValue: (pValue) => vDesignSet(vDesign.copyWith(boxM2: pValue)),
          ),
          NumberField<int>(
            label: vText.wallTileSockets,
            initial: '${_wall.sockets}',
            parse: parseWhole,
            onValue: (pValue) => vSet(_wall.copyWith(sockets: pValue)),
          ),
          NumberField<int>(
            label: vText.wallTileCutOutWidth,
            initial: '',
            parse: parseCentimetres,
            onValue: (pValue) => vSet(_wall.copyWith(cutOutWidthMm: pValue)),
          ),
          NumberField<int>(
            label: vText.wallTileCutOutHeight,
            initial: '',
            parse: parseCentimetres,
            onValue: (pValue) => vSet(_wall.copyWith(cutOutHeightMm: pValue)),
          ),
          const SizedBox(height: 8),
          Text(vText.wallTileExposed, style: vTheme.textTheme.labelLarge),
          const SizedBox(height: 4),
          SegmentedButton<int>(
            segments: [
              for (final vSides in [0, 1, 2])
                ButtonSegment(value: vSides, label: Text('$vSides')),
            ],
            selected: {_wall.exposedSides},
            onSelectionChanged: (pChoice) => vSet(_wall.copyWith(exposedSides: pChoice.single)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.wallTileTop),
            value: _wall.topExposed,
            onChanged: (pValue) => vSet(_wall.copyWith(topExposed: pValue)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.wallTileWorktop),
            value: _wall.onWorktop,
            onChanged: (pValue) => vSet(_wall.copyWith(onWorktop: pValue)),
          ),
          IconLine(Icons.lightbulb_outline, vText.wallTileHint),
        ],
      ),
    );
  }
}
