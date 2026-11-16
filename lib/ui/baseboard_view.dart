import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/bar_cutting.dart';
import '../logic/baseboard.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'dialogs.dart';
import 'parquet_view.dart';
import 'room_plan.dart';

/// Texte d'une coupe de bout de plinthe.
String cutLabel(AppLocalizations pText, EndCut pCut) => switch (pCut.kind) {
  EndCutKind.square => pText.cutSquare,
  EndCutKind.insideMiter => pText.cutInside(formatAngle(pCut.sawAngleDeg)),
  EndCutKind.outsideMiter => pText.cutOutside(formatAngle(pCut.sawAngleDeg)),
  EndCutKind.scarf => pText.cutScarf,
};

String fixingLabel(AppLocalizations pText, BaseboardFixing pFixing) => switch (pFixing) {
  BaseboardFixing.glued => pText.fixingGlued,
  BaseboardFixing.nailed => pText.fixingNailed,
  BaseboardFixing.clips => pText.fixingClips,
};

String _offcutLabel(AppLocalizations pText, int pOffcutMm) => pOffcutMm == 0
    ? pText.barNoOffcut
    : pOffcutMm >= reusableOffcutMm
    ? pText.barOffcutReusable(formatCentimetres(pOffcutMm))
    : pText.barOffcut(formatCentimetres(pOffcutMm));

/// Plinthes de la pièce : réglages, fournitures et liste des coupes à cocher.
class BaseboardView extends StatefulWidget {
  const BaseboardView({super.key, required this.room, required this.onChanged});

  final Room room;
  final ValueChanged<Room> onChanged;

  @override
  State<BaseboardView> createState() => _BaseboardViewState();
}

class _BaseboardViewState extends State<BaseboardView> {
  /// Mur du morceau touché, surligné sur le plan.
  int? _highlight;

  Room get _room => widget.room;

  void _update(BaseboardSettings pSettings) =>
      widget.onChanged(_room.copyWith(baseboard: pSettings, cutPieces: const []));

  void _toggle(int pIndex, bool pCut) {
    final vCut = {..._room.cutPieces};
    pCut ? vCut.add(pIndex) : vCut.remove(pIndex);
    widget.onChanged(_room.copyWith(cutPieces: vCut.toList()..sort()));
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    if (_room.walls.isEmpty) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(vText.baseboardNeedsWalls)),
      );
    }
    final vSettings = _room.baseboard;
    final vPieces = baseboardPieces(_room, vSettings);
    final vNeeds = fixingNeeds(vPieces, vSettings);
    final vBars = planBars(
      [for (final vPiece in vPieces) vPiece.lengthMm],
      vSettings.barLengthMm,
      vSettings.kerfMm,
    );
    final vTotal = vPieces.fold<int>(0, (pSum, pPiece) => pSum + pPiece.lengthMm);
    final vDone = _room.cutPieces.where((pIndex) => pIndex < vPieces.length).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vText.resultsTitle, style: vTheme.textTheme.titleMedium),
                Text(vText.bars(vBars.bars.length), style: vTheme.textTheme.headlineSmall),
                Text(vText.baseboardSummary(vPieces.length, formatDecimal(vTotal / 1000))),
                if (vBars.tooLong.isNotEmpty)
                  Text(
                    vText.tooLongPieces(vBars.tooLong.length),
                    style: TextStyle(color: vTheme.colorScheme.error),
                  ),
                if (vSettings.fixing == BaseboardFixing.glued)
                  Text(vText.cartridges(vNeeds.cartridges))
                else
                  Text(vText.fixingPoints(vNeeds.points)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              DropdownButtonFormField<BaseboardFixing>(
                initialValue: vSettings.fixing,
                decoration: InputDecoration(labelText: vText.fixing),
                items: [
                  for (final vFixing in BaseboardFixing.values)
                    DropdownMenuItem(value: vFixing, child: Text(fixingLabel(vText, vFixing))),
                ],
                onChanged: (pFixing) => _update(vSettings.copyWith(fixing: pFixing)),
              ),
              NumberField(
                label: vText.barLength,
                initial: formatCentimetres(vSettings.barLengthMm),
                parse: parseCentimetres,
                onValue: (pValue) => _update(vSettings.copyWith(barLengthMm: pValue)),
              ),
              NumberField(
                label: vText.kerf,
                initial: '${vSettings.kerfMm}',
                parse: parseWhole,
                onValue: (pValue) => _update(vSettings.copyWith(kerfMm: pValue)),
              ),
              if (vSettings.fixing == BaseboardFixing.glued)
                NumberField(
                  key: const ValueKey('glue'),
                  label: vText.glueMetres,
                  initial: formatDecimal(vSettings.glueMetresPerCartridge),
                  parse: parseDecimal,
                  onValue: (pValue) => _update(vSettings.copyWith(glueMetresPerCartridge: pValue)),
                )
              else
                NumberField(
                  key: const ValueKey('spacing'),
                  label: vText.fixingSpacing,
                  initial: formatCentimetres(vSettings.fixingSpacingMm),
                  parse: parseCentimetres,
                  onValue: (pValue) => _update(vSettings.copyWith(fixingSpacingMm: pValue)),
                ),
            ],
          ),
        ),
        ListTile(title: Text(vText.barsTitle, style: vTheme.textTheme.titleMedium)),
        for (var vBar = 0; vBar < vBars.bars.length; vBar++)
          ListTile(
            dense: true,
            title: Text(
              vText.barLine(
                vBar + 1,
                vBars.bars[vBar].pieceLengths.map(formatCentimetres).join(' + '),
              ),
            ),
            subtitle: Text(_offcutLabel(vText, vBars.bars[vBar].offcutMm(vBars.kerfMm))),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: RoomPlan(room: _room, highlightWall: _highlight),
        ),
        ListTile(
          title: Text(vText.cutProgress(vDone, vPieces.length)),
          subtitle: Text(vText.baseboardHelp),
        ),
        for (var vIndex = 0; vIndex < vPieces.length; vIndex++)
          CheckboxListTile(
            value: _room.cutPieces.contains(vIndex),
            onChanged: (pValue) {
              setState(() => _highlight = vPieces[vIndex].wallNumber - 1);
              _toggle(vIndex, pValue ?? false);
            },
            title: Text(
              vText.pieceTitle(
                vPieces[vIndex].wallNumber,
                formatCentimetres(vPieces[vIndex].lengthMm),
              ),
            ),
            subtitle: Text(
              [
                vText.pieceCuts(
                  cutLabel(vText, vPieces[vIndex].startCut),
                  cutLabel(vText, vPieces[vIndex].endCut),
                ),
                if (vBars.barOf(vIndex) != null) vText.pieceInBar(vBars.barOf(vIndex)!),
              ].join('\n'),
            ),
          ),
      ],
    );
  }
}
