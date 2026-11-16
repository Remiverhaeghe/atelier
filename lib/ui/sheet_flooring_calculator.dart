import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/geometry.dart';
import '../logic/room.dart';
import '../logic/sheet_flooring.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'room_source.dart';
import 'theme.dart';

/// Sol souple ou moquette en rouleau : lés, longueur à commander, joints et colle.
class SheetFlooringCalculator extends StatefulWidget {
  const SheetFlooringCalculator({super.key, this.rooms = const []});

  final List<Room> rooms;

  @override
  State<SheetFlooringCalculator> createState() => _SheetFlooringCalculatorState();
}

class _SheetFlooringCalculatorState extends State<SheetFlooringCalculator> {
  Room? _room;
  int _length = 4000;
  int _width = 3000;
  int _roll = 4000;
  int _repeat = 0;
  int _source = 0;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planSheet(_length, _width, _roll, pRepeatMm: _repeat);
    final vFloor = _room == null ? _length * _width / 1e6 : floorAreaM2(_room!);

    return Scaffold(
      appBar: AppBar(title: Text(vText.sheetTitle)),
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
                  BigFigure(vText.sheetOrder(formatCentimetres(vPlan.totalMm))),
                  IconLine(
                    Icons.view_week_outlined,
                    vText.sheetStrips(vPlan.strips, formatCentimetres(vPlan.stripMm)),
                  ),
                  IconLine(
                    Icons.swap_horiz,
                    vPlan.alongLength ? vText.sheetAlongLength : vText.sheetAlongWidth,
                  ),
                  if (vPlan.seams > 0)
                    IconLine(Icons.compare_arrows, vText.sheetSeams(vPlan.seams)),
                  IconLine(
                    Icons.format_color_fill_outlined,
                    vText.sheetGlue(formatDecimal(sheetGlueKg(vFloor))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          RoomSourcePicker(
            rooms: widget.rooms,
            value: _room?.id,
            onChanged: (pRoom) => setState(() {
              _room = pRoom;
              if (pRoom != null) {
                final vBox = roomBox(pRoom);
                _length = vBox.lengthMm;
                _width = vBox.widthMm;
              }
              _source++;
            }),
          ),
          NumberField<int>(
            key: ValueKey('length-$_source'),
            label: vText.sheetLength,
            initial: '$_length',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _length = pValue),
          ),
          NumberField<int>(
            key: ValueKey('width-$_source'),
            label: vText.sheetWidth,
            initial: '$_width',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _width = pValue),
          ),
          const SizedBox(height: 8),
          Text(vText.sheetRoll),
          SegmentedButton<int>(
            segments: [
              for (final vRoll in rollWidthsMm)
                ButtonSegment(value: vRoll, label: Text('${vRoll ~/ 1000} m')),
            ],
            selected: {_roll},
            onSelectionChanged: (pRoll) => setState(() => _roll = pRoll.single),
          ),
          NumberField<int>(
            label: vText.sheetRepeat,
            initial: '$_repeat',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _repeat = pValue),
          ),
          const SizedBox(height: 12),
          Text(vText.sheetHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
