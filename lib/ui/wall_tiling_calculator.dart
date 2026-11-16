import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/room.dart';
import '../logic/room_surfaces.dart';
import '../logic/tiling.dart';
import '../logic/units.dart';
import '../logic/wall_tiling.dart';
import 'parquet_view.dart';
import 'room_source.dart';
import 'theme.dart';

/// Faïence et crédence : pan de mur, ouverture, prises, profilés et silicone.
class WallTilingCalculator extends StatefulWidget {
  const WallTilingCalculator({super.key, this.rooms = const []});

  final List<Room> rooms;

  @override
  State<WallTilingCalculator> createState() => _WallTilingCalculatorState();
}

class _WallTilingCalculatorState extends State<WallTilingCalculator> {
  var _wall = const WallTiling();
  Room? _room;
  int _wallIndex = 0;

  /// Change quand un mur remplit les champs, pour qu'ils se redessinent avec ses cotes.
  int _source = 0;

  /// Le mur choisi donne la largeur du pan ; sa hauteur sous plafond si on ne fait pas une
  /// crédence, ainsi que sa fenêtre ou sa porte la plus large.
  void _fromWall() {
    final vRoom = _room;
    final vPanel = vRoom == null ? null : wallPanel(vRoom, _wallIndex);
    if (vRoom == null || vPanel == null) {
      return;
    }
    final vOpenings = [...vRoom.walls[_wallIndex].openings]
      ..sort((pA, pB) => pB.widthMm.compareTo(pA.widthMm));
    final vOpening = vOpenings.firstOrNull;
    _source++;
    _wall = _wall.copyWith(
      design: _wall.design.copyWith(
        lengthMm: vPanel.widthMm,
        widthMm: _wall.onWorktop ? _wall.design.widthMm : vPanel.heightMm,
      ),
      cutOutWidthMm: vOpening?.widthMm ?? 0,
      cutOutHeightMm: vOpening == null
          ? 0
          : (vOpening.heightMm ?? defaultOpeningHeightMm(vOpening.kind)),
    );
  }

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
          RoomSourcePicker(
            rooms: widget.rooms,
            value: _room?.id,
            onChanged: (pRoom) => setState(() {
              _room = pRoom;
              _wallIndex = 0;
              _fromWall();
            }),
          ),
          if (_room != null)
            DropdownButtonFormField<int>(
              key: ValueKey('mur-${_room!.id}'),
              initialValue: _wallIndex,
              decoration: InputDecoration(labelText: vText.roomSourceWall),
              items: [
                for (var vIndex = 0; vIndex < _room!.walls.length; vIndex++)
                  DropdownMenuItem(value: vIndex, child: Text(vText.wallTitle(vIndex + 1))),
              ],
              onChanged: (pIndex) => setState(() {
                _wallIndex = pIndex!;
                _fromWall();
              }),
            ),
          NumberField<int>(
            key: ValueKey('largeur-$_source'),
            label: vText.wallTileWidth,
            initial: formatCentimetres(vDesign.lengthMm),
            parse: parseCentimetres,
            onValue: (pValue) => vDesignSet(vDesign.copyWith(lengthMm: pValue)),
          ),
          NumberField<int>(
            key: ValueKey('hauteur-$_source'),
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
            key: ValueKey('ouverture-$_source'),
            label: vText.wallTileCutOutWidth,
            initial: _wall.cutOutWidthMm == 0 ? '' : formatCentimetres(_wall.cutOutWidthMm),
            parse: parseCentimetres,
            onValue: (pValue) => vSet(_wall.copyWith(cutOutWidthMm: pValue)),
          ),
          NumberField<int>(
            key: ValueKey('ouverture-h-$_source'),
            label: vText.wallTileCutOutHeight,
            initial: _wall.cutOutHeightMm == 0 ? '' : formatCentimetres(_wall.cutOutHeightMm),
            parse: parseCentimetres,
            onValue: (pValue) => vSet(_wall.copyWith(cutOutHeightMm: pValue)),
          ),
          const SizedBox(height: 8),
          Text(vText.wallTileExposed, style: vTheme.textTheme.labelLarge),
          const SizedBox(height: 4),
          SegmentedButton<int>(
            segments: [
              for (final vSides in [0, 1, 2]) ButtonSegment(value: vSides, label: Text('$vSides')),
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
