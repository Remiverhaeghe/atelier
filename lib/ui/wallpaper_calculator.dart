import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import '../logic/wallpaper.dart';
import 'parquet_view.dart';
import 'room_source.dart';
import 'theme.dart';

/// Papier peint : rouleaux selon la longueur de murs, la hauteur et le raccord du motif.
class WallpaperCalculator extends StatefulWidget {
  const WallpaperCalculator({super.key, this.rooms = const []});

  final List<Room> rooms;

  @override
  State<WallpaperCalculator> createState() => _WallpaperCalculatorState();
}

class _WallpaperCalculatorState extends State<WallpaperCalculator> {
  Room? _room;
  int _length = 14000;
  int _height = 2500;
  int _repeat = 0;
  int _source = 0;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planWallpaper(_length, _height, pRepeatMm: _repeat);

    return Scaffold(
      appBar: AppBar(title: Text(vText.wallpaperTitle)),
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
                  BigFigure(vText.wallpaperRolls(vPlan.rolls)),
                  IconLine(
                    Icons.view_week_outlined,
                    vText.wallpaperStrips(vPlan.strips, formatCentimetres(vPlan.stripMm)),
                  ),
                  IconLine(
                    Icons.content_cut,
                    vPlan.stripsPerRoll == 0
                        ? vText.wallpaperTooHigh
                        : vText.wallpaperPerRoll(vPlan.stripsPerRoll),
                  ),
                  IconLine(Icons.format_color_fill_outlined, vText.wallpaperGlue(vPlan.gluePacks)),
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
                _length = wallpaperLengthMm(pRoom);
                _height = pRoom.ceilingHeightMm;
              }
              _source++;
            }),
          ),
          NumberField<int>(
            key: ValueKey('length-$_source'),
            label: vText.wallpaperLength,
            initial: '$_length',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _length = pValue),
          ),
          NumberField<int>(
            key: ValueKey('height-$_source'),
            label: vText.wallpaperHeight,
            initial: '$_height',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _height = pValue),
          ),
          NumberField<int>(
            label: vText.wallpaperRepeat,
            initial: '$_repeat',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _repeat = pValue),
          ),
          const SizedBox(height: 12),
          Text(vText.wallpaperHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
