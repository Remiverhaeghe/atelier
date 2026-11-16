import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/paint.dart';
import '../logic/room.dart';
import '../logic/shopping.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'shopping_texts.dart';
import 'theme.dart';

/// Peinture de la pièce : surfaces, litres, pots les moins chers et fournitures.
class PaintView extends StatelessWidget {
  const PaintView({
    super.key,
    required this.room,
    required this.onChanged,
    this.prices = const {},
  });

  final Room room;
  final ValueChanged<Room> onChanged;

  /// Prix saisis dans les courses, pour choisir les pots les moins chers.
  final Map<String, double> prices;

  void _update(PaintSettings pSettings) => onChanged(room.copyWith(paint: pSettings));

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vSettings = room.paint;
    if (room.walls.length < 3) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(vText.paintNeedsRoom)),
      );
    }
    Widget vSwitch(String pLabel, bool pValue, ValueChanged<bool> pOnChanged) =>
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(pLabel),
          value: pValue,
          onChanged: pOnChanged,
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _PaintResults(room: room, prices: prices),
        const SizedBox(height: 16),
        NumberField(
          label: vText.ceilingHeight,
          initial: formatCentimetres(room.ceilingHeightMm),
          parse: parseCentimetres,
          onValue: (pValue) => onChanged(room.copyWith(ceilingHeightMm: pValue)),
        ),
        const SizedBox(height: 12),
        Text(vText.paintWhat, style: vTheme.textTheme.titleMedium),
        vSwitch(vText.paintWallsSwitch, vSettings.walls, (pValue) {
          _update(vSettings.copyWith(walls: pValue));
        }),
        vSwitch(vText.paintCeilingSwitch, vSettings.ceiling, (pValue) {
          _update(vSettings.copyWith(ceiling: pValue));
        }),
        vSwitch(vText.paintWoodworkSwitch, vSettings.woodwork, (pValue) {
          _update(vSettings.copyWith(woodwork: pValue));
        }),
        vSwitch(vText.paintPrimerSwitch, vSettings.primer, (pValue) {
          _update(vSettings.copyWith(primer: pValue));
        }),
        NumberField(
          label: vText.paintCoats,
          initial: '${vSettings.coats}',
          parse: parseWhole,
          onValue: (pValue) => _update(vSettings.copyWith(coats: pValue)),
        ),
        NumberField(
          label: vText.paintCoverage,
          initial: formatDecimal(vSettings.coverageM2PerL),
          parse: parseDecimal,
          onValue: (pValue) => _update(vSettings.copyWith(coverageM2PerL: pValue)),
        ),
        if (vSettings.woodwork) ...[
          NumberField(
            label: vText.paintWoodworkCoats,
            initial: '${vSettings.woodworkCoats}',
            parse: parseWhole,
            onValue: (pValue) => _update(vSettings.copyWith(woodworkCoats: pValue)),
          ),
          NumberField(
            label: vText.paintWoodworkCoverage,
            initial: formatDecimal(vSettings.woodworkCoverageM2PerL),
            parse: parseDecimal,
            onValue: (pValue) => _update(vSettings.copyWith(woodworkCoverageM2PerL: pValue)),
          ),
        ],
        if (vSettings.primer)
          NumberField(
            label: vText.paintPrimerCoverage,
            initial: formatDecimal(vSettings.primerCoverageM2PerL),
            parse: parseDecimal,
            onValue: (pValue) => _update(vSettings.copyWith(primerCoverageM2PerL: pValue)),
          ),
        NumberField(
          label: vText.paintExtra,
          initial: '${vSettings.extraPercent}',
          parse: parseWhole,
          onValue: (pValue) => _update(vSettings.copyWith(extraPercent: pValue)),
        ),
      ],
    );
  }
}

class _PaintResults extends StatelessWidget {
  const _PaintResults({required this.room, required this.prices});

  final Room room;
  final Map<String, double> prices;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vAreas = paintAreas(room);
    final vLitres = paintLitres(room, room.paint);
    final vQuantities = roomQuantities(room, prices);
    final vSupplies = paintSupplies(room, room.paint);
    String vPots(PaintProduct pProduct) => [
      for (final vSize in potSizes[pProduct]!)
        if ((vQuantities[potItem(pProduct, vSize)] ?? 0) > 0)
          vText.potCount(vQuantities[potItem(pProduct, vSize)]!, formatDecimal(vSize)),
    ].join(' + ');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.resultsTitle, style: vTheme.textTheme.titleMedium),
            BigFigure(vText.paintArea(formatDecimal(_round(vAreas.wallsM2)))),
            if (room.paint.ceiling)
              IconLine(Icons.crop_free, vText.paintCeilingArea(formatDecimal(_round(vAreas.ceilingM2)))),
            if (room.paint.woodwork)
              IconLine(
                Icons.door_front_door_outlined,
                vText.paintWoodworkArea(formatDecimal(_round(vAreas.woodworkM2))),
              ),
            if (vLitres.isEmpty) Text(vText.paintNothing),
            for (final vEntry in vLitres.entries)
              IconLine(
                Icons.format_paint_outlined,
                vText.paintLitresLine(
                  paintProductLabel(vText, vEntry.key),
                  formatDecimal(_round(vEntry.value)),
                  vPots(vEntry.key),
                ),
              ),
            if (vLitres.isNotEmpty) ...[
              IconLine(
                Icons.handyman_outlined,
                vText.paintSupplies(vSupplies.rollers, vSupplies.dropCloths, vSupplies.tapeRolls),
              ),
              const SizedBox(height: 4),
              Text(vText.paintPotsHint, style: vTheme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

/// Une décimale suffit pour des m² et des litres.
double _round(double pValue) => (pValue * 10).round() / 10;
