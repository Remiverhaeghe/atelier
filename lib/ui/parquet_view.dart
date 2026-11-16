import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/parquet.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'theme.dart';

/// Nom affiché d'un type de parquet.
String parquetLabel(AppLocalizations pText, ParquetType pType) => switch (pType) {
  ParquetType.floating => pText.parquetFloating,
  ParquetType.glued => pText.parquetGlued,
  ParquetType.nailed => pText.parquetNailed,
  ParquetType.herringbone => pText.parquetHerringbone,
};

/// Réglages du parquet de la pièce et quantités à acheter.
class ParquetView extends StatelessWidget {
  const ParquetView({super.key, required this.room, required this.onChanged});

  final Room room;
  final ValueChanged<Room> onChanged;

  void _update(ParquetSettings pSettings) => onChanged(room.copyWith(parquet: pSettings));

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vSettings = room.parquet;
    if (room.walls.length < 3) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(vText.parquetNeedsRoom)),
      );
    }
    final vDefaults = vSettings.defaults;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _ParquetResults(room: room),
        const SizedBox(height: 16),
        DropdownButtonFormField<ParquetType>(
          initialValue: vSettings.type,
          decoration: InputDecoration(
            labelText: vText.parquetType,
            helperText: vText.parquetDefaultsHint,
            helperMaxLines: 3,
          ),
          items: [
            for (final vType in ParquetType.values)
              DropdownMenuItem(value: vType, child: Text(parquetLabel(vText, vType))),
          ],
          onChanged: (pType) {
            if (pType != null && pType != vSettings.type) {
              _update(ParquetSettings.forType(pType, pBase: vSettings));
            }
          },
        ),
        DropdownButtonFormField<int>(
          initialValue: vSettings.layingWallIndex.clamp(0, room.walls.length - 1),
          decoration: InputDecoration(labelText: vText.layingWall),
          items: [
            for (var vIndex = 0; vIndex < room.walls.length; vIndex++)
              DropdownMenuItem(value: vIndex, child: Text(vText.wallTitle(vIndex + 1))),
          ],
          onChanged: (pIndex) => _update(vSettings.copyWith(layingWallIndex: pIndex)),
        ),
        NumberField(
          key: ValueKey('plankLength-${vSettings.type}'),
          label: vText.plankLength,
          initial: formatCentimetres(vSettings.plankLengthMm),
          parse: parseCentimetres,
          onValue: (pValue) => _update(vSettings.copyWith(plankLengthMm: pValue)),
        ),
        NumberField(
          key: ValueKey('plankWidth-${vSettings.type}'),
          label: vText.plankWidth,
          initial: formatCentimetres(vSettings.plankWidthMm),
          parse: parseCentimetres,
          onValue: (pValue) => _update(vSettings.copyWith(plankWidthMm: pValue)),
        ),
        NumberField(
          key: ValueKey('packArea-${vSettings.type}'),
          label: vText.packArea,
          initial: formatDecimal(vSettings.packAreaM2),
          parse: parseDecimal,
          onValue: (pValue) => _update(vSettings.copyWith(packAreaM2: pValue)),
        ),
        NumberField(
          key: ValueKey('gap-${vSettings.type}'),
          label: vText.expansionGap,
          initial: '${vSettings.expansionGapMm}',
          parse: parseWhole,
          onValue: (pValue) => _update(vSettings.copyWith(expansionGapMm: pValue)),
        ),
        NumberField(
          key: ValueKey('waste-${vSettings.type}'),
          label: vText.wastePercent,
          initial: '${vSettings.wastePercent}',
          parse: parseWhole,
          onValue: (pValue) => _update(vSettings.copyWith(wastePercent: pValue)),
        ),
        if (vSettings.type != ParquetType.herringbone)
          NumberField(
            key: ValueKey('joint-${vSettings.type}'),
            label: vText.minJointOffset,
            initial: formatCentimetres(vSettings.minJointOffsetMm),
            parse: parseCentimetres,
            onValue: (pValue) => _update(vSettings.copyWith(minJointOffsetMm: pValue)),
          ),
        if (vDefaults.needsUnderlay)
          NumberField(
            key: ValueKey('underlay-${vSettings.type}'),
            label: vText.underlayRollArea,
            initial: formatDecimal(vSettings.underlayRollAreaM2),
            parse: parseDecimal,
            onValue: (pValue) => _update(vSettings.copyWith(underlayRollAreaM2: pValue)),
          ),
        if (vDefaults.needsGlue)
          NumberField(
            key: ValueKey('glue-${vSettings.type}'),
            label: vText.glueCoverage,
            initial: formatDecimal(vSettings.glueCoverageM2),
            parse: parseDecimal,
            onValue: (pValue) => _update(vSettings.copyWith(glueCoverageM2: pValue)),
          ),
        if (vDefaults.needsNails) ...[
          NumberField(
            key: ValueKey('nails-${vSettings.type}'),
            label: vText.nailsPerM2,
            initial: '${vSettings.nailsPerM2}',
            parse: parseWhole,
            onValue: (pValue) => _update(vSettings.copyWith(nailsPerM2: pValue)),
          ),
          NumberField(
            key: ValueKey('box-${vSettings.type}'),
            label: vText.nailsPerBox,
            initial: '${vSettings.nailsPerBox}',
            parse: parseWhole,
            onValue: (pValue) => _update(vSettings.copyWith(nailsPerBox: pValue)),
          ),
        ],
      ],
    );
  }
}

class _ParquetResults extends StatelessWidget {
  const _ParquetResults({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vEstimate = estimateParquet(room, room.parquet);
    final vRows = vEstimate.rows;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.resultsTitle, style: vTheme.textTheme.titleMedium),
            const SizedBox(height: 8),
            BigFigure(vText.resultPacks(vEstimate.packs)),
            IconLine(
              AtelierIcons.area,
              vText.resultArea(
                formatSquareMetres(vEstimate.floorAreaM2),
                formatSquareMetres(vEstimate.areaWithWasteM2),
              ),
            ),
            if (room.parquet.type == ParquetType.herringbone)
              IconLine(
                AtelierIcons.planks,
                vText.resultLeftRight(vEstimate.leftPlanks, vEstimate.rightPlanks),
              )
            else
              IconLine(AtelierIcons.planks, vText.resultPlanks(vEstimate.planks)),
            if (vEstimate.underlayRolls > 0)
              IconLine(AtelierIcons.underlay, vText.resultUnderlay(vEstimate.underlayRolls)),
            if (vEstimate.glueBuckets > 0)
              IconLine(AtelierIcons.glue, vText.resultGlue(vEstimate.glueBuckets)),
            if (vEstimate.nailBoxes > 0)
              IconLine(AtelierIcons.nails, vText.resultNails(vEstimate.nailBoxes)),
            const Divider(height: 24),
            Text(vText.rowsTitle, style: vTheme.textTheme.titleSmall),
            if (vRows == null)
              Text(vText.rowsHerringbone)
            else ...[
              IconLine(
                AtelierIcons.rows,
                vText.rowsSummary(
                  vRows.rowCount,
                  formatCentimetres(vRows.firstRowWidthMm),
                  formatCentimetres(vRows.lastRowWidthMm),
                ),
              ),
              if (vRows.balanced) Text(vText.rowsBalanced),
            ],
          ],
        ),
      ),
    );
  }
}

/// Champ numérique qui ne transmet que les valeurs valides.
class NumberField<T> extends StatefulWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.initial,
    required this.parse,
    required this.onValue,
  });

  final String label;
  final String initial;
  final T? Function(String) parse;
  final ValueChanged<T> onValue;

  @override
  State<NumberField<T>> createState() => _NumberFieldState<T>();
}

class _NumberFieldState<T> extends State<NumberField<T>> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String pText) {
    final vValue = widget.parse(pText);
    setState(() => _error = vValue == null ? AppLocalizations.of(context).invalidNumber : null);
    if (vValue != null) {
      widget.onValue(vValue);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: widget.label, errorText: _error),
      onChanged: _changed,
    ),
  );
}
