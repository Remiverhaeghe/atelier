import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/room.dart';
import '../logic/slope.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Plafond rampant : interrupteur, puis le mur bas, la jambette et la largeur de la pente.
class SlopeEditor extends StatelessWidget {
  const SlopeEditor({super.key, required this.room, required this.onChanged});

  final Room room;
  final ValueChanged<Room> onChanged;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vSlope = room.slope;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.roofing_outlined),
          title: Text(vText.slopeSwitch),
          value: vSlope != null,
          onChanged: (pOn) => onChanged(
            pOn
                ? room.copyWith(
                    slope: Slope(
                      wallIndex: 0,
                      lowMm: (room.ceilingHeightMm * 0.4).round(),
                      runMm: 2000,
                    ),
                  )
                : room.copyWith(clearSlope: true),
          ),
        ),
        if (vSlope != null) ...[
          DropdownButtonFormField<int>(
            initialValue: vSlope.wallIndex.clamp(0, room.walls.length - 1),
            decoration: InputDecoration(labelText: vText.slopeWall),
            items: [
              for (var vIndex = 0; vIndex < room.walls.length; vIndex++)
                DropdownMenuItem(value: vIndex, child: Text(vText.wallTitle(vIndex + 1))),
            ],
            onChanged: (pIndex) => onChanged(
              room.copyWith(
                slope: Slope(wallIndex: pIndex!, lowMm: vSlope.lowMm, runMm: vSlope.runMm),
              ),
            ),
          ),
          NumberField<int>(
            label: vText.slopeLow,
            initial: formatCentimetres(vSlope.lowMm),
            parse: parseCentimetres,
            onValue: (pValue) => onChanged(
              room.copyWith(
                slope: Slope(wallIndex: vSlope.wallIndex, lowMm: pValue, runMm: vSlope.runMm),
              ),
            ),
          ),
          NumberField<int>(
            label: vText.slopeRun,
            initial: formatCentimetres(vSlope.runMm),
            parse: parseCentimetres,
            onValue: (pValue) => onChanged(
              room.copyWith(
                slope: Slope(wallIndex: vSlope.wallIndex, lowMm: vSlope.lowMm, runMm: pValue),
              ),
            ),
          ),
          if (activeSlope(room) == null)
            IconLine(AtelierIcons.warning, vText.slopeInvalid)
          else
            IconLine(
              Icons.accessibility_new,
              vText.slopeStanding(formatSquareMetres(standingFloorMm2(room) / 1e6)),
            ),
        ],
      ],
    );
  }
}
