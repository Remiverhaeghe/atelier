import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/units.dart';
import '../logic/window_frame.dart';
import '../state/worksites_controller.dart';
import 'frame_calculator.dart';
import 'theme.dart';

/// Plexis de toiture à remplacer : surface totale et tailles, avec le cadre à fabriquer.
class PlexiScreen extends StatelessWidget {
  const PlexiScreen({super.key, required this.controller, required this.worksiteId});

  final WorksitesController controller;
  final String worksiteId;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vRooms = controller.worksite(worksiteId)?.rooms ?? const [];
    final vSizes = plexiSizes(vRooms);

    return Scaffold(
      appBar: AppBar(title: Text(vText.plexiTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (vSizes.isEmpty)
            Padding(padding: const EdgeInsets.all(8), child: Text(vText.plexiEmpty))
          else ...[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vText.plexiTotal, style: vTheme.textTheme.titleMedium),
                    BigFigure('${formatSquareMetres(plexiAreaM2(vRooms))} m²'),
                    IconLine(
                      Icons.thermostat_outlined,
                      vText.plexiThermal,
                    ),
                  ],
                ),
              ),
            ),
            for (final vSize in vSizes)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.roofing_outlined),
                  title: Text(
                    vText.plexiSize(
                      vSize.count,
                      formatCentimetres(vSize.widthMm),
                      formatCentimetres(vSize.heightMm),
                    ),
                  ),
                  subtitle: Text(vSize.rooms.join(', ')),
                  trailing: const Icon(Icons.carpenter_outlined),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          FrameCalculator(widthMm: vSize.widthMm, heightMm: vSize.heightMm),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
