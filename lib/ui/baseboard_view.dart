import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/bar_cutting.dart';
import '../logic/baseboard.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'dialogs.dart';
import 'parquet_view.dart';
import 'room_plan.dart';
import 'theme.dart';
import 'bars_diagram.dart';
import 'cut_diagram.dart';

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
      pStock: [for (final vPiece in vPieces) vPiece.stockMm(vSettings.thicknessMm)],
    );
    final vTotal = vPieces.fold<int>(0, (pSum, pPiece) => pSum + pPiece.lengthMm);
    final vDone = _room.cutPieces.where((pIndex) => pIndex < vPieces.length).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Card(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vText.resultsTitle, style: vTheme.textTheme.titleMedium),
                BigFigure(vText.bars(vBars.bars.length)),
                IconLine(
                  AtelierIcons.length,
                  vText.baseboardSummary(vPieces.length, formatDecimal(vTotal / 1000)),
                ),
                if (vBars.tooLong.isNotEmpty)
                  IconLine(
                    AtelierIcons.warning,
                    vText.tooLongPieces(vBars.tooLong.length),
                    color: vTheme.colorScheme.error,
                  ),
                if (vSettings.fixing == BaseboardFixing.glued)
                  IconLine(AtelierIcons.cartridges, vText.cartridges(vNeeds.cartridges))
                else
                  IconLine(AtelierIcons.nails, vText.fixingPoints(vNeeds.points)),
              ],
            ),
          ),
        ),
        _NextCut(
          pieces: vPieces,
          done: _room.cutPieces,
          onCut: (pIndex) {
            setState(() => _highlight = vPieces[pIndex].wallNumber - 1);
            _toggle(pIndex, true);
          },
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
                label: vText.baseboardThickness,
                initial: '${vSettings.thicknessMm}',
                parse: parseWhole,
                onValue: (pValue) => _update(vSettings.copyWith(thicknessMm: pValue)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(vText.fewestBars),
                subtitle: Text(vText.fewestBarsHelp),
                value: vSettings.fewestBars,
                onChanged: (pOn) => _update(vSettings.copyWith(fewestBars: pOn)),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: BarsDiagram(
            plan: vBars,
            labels: [for (final vPiece in vPieces) formatCentimetres(vPiece.lengthMm)],
          ),
        ),
        for (var vBar = 0; vBar < vBars.bars.length; vBar++)
          ListTile(
            dense: true,
            title: Text(
              vText.barLine(
                vBar + 1,
                [
                  for (final vIndex in vBars.bars[vBar].pieceIndexes)
                    formatCentimetres(vPieces[vIndex].lengthMm),
                ].join(' + '),
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
          subtitle: Text('${vText.baseboardHelp}\n${vText.cutDiagramHelp}'),
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    vText.pieceCuts(
                      cutLabel(vText, vPieces[vIndex].startCut),
                      cutLabel(vText, vPieces[vIndex].endCut),
                    ),
                    if (vBars.barOf(vIndex) != null) vText.pieceInBar(vBars.barOf(vIndex)!),
                  ].join('\n'),
                ),
                const SizedBox(height: 6),
                CutDiagram(piece: vPieces[vIndex]),
              ],
            ),
          ),
      ],
    );
  }
}

/// La seule pièce à couper maintenant : longueur, deux coupes, dessin et un bouton.
class _NextCut extends StatelessWidget {
  const _NextCut({required this.pieces, required this.done, required this.onCut});

  final List<BaseboardPiece> pieces;
  final List<int> done;
  final ValueChanged<int> onCut;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vNext = [
      for (var vIndex = 0; vIndex < pieces.length; vIndex++) vIndex,
    ].where((pIndex) => !done.contains(pIndex));

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: vNext.isEmpty
            ? IconLine(Icons.check_circle_outline, vText.allCutDone)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vText.nextCutTitle, style: vTheme.textTheme.titleMedium),
                  BigFigure('${formatCentimetres(pieces[vNext.first].lengthMm)} ${vText.unitCm}'),
                  Text(
                    vText.pieceCuts(
                      cutLabel(vText, pieces[vNext.first].startCut),
                      cutLabel(vText, pieces[vNext.first].endCut),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CutDiagram(piece: pieces[vNext.first]),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => onCut(vNext.first),
                    icon: const Icon(Icons.content_cut),
                    label: Text(vText.nextCutDone),
                  ),
                ],
              ),
      ),
    );
  }
}
