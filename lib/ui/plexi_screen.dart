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
                    IconLine(Icons.thermostat_outlined, vText.plexiThermal),
                    IconLine(Icons.info_outline, vText.roofHint),
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vSize.rooms.join(', ')),
                      _RoofMatch(widthMm: vSize.widthMm, heightMm: vSize.heightMm),
                    ],
                  ),
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

/// Fenêtre de toit du commerce la plus proche, et la reprise du chevêtre qu'elle demande.
class _RoofMatch extends StatelessWidget {
  const _RoofMatch({required this.widthMm, required this.heightMm});

  final int widthMm;
  final int heightMm;

  String _change(AppLocalizations pText, int pMm, bool pWidth) {
    if (pMm.abs() < 5) {
      return pWidth ? pText.roofKeepWidth : pText.roofKeepHeight;
    }
    final vCm = formatCentimetres(pMm.abs());
    final rText = pWidth
        ? (pMm > 0 ? pText.roofWiden(vCm) : pText.roofNarrow(vCm))
        : (pMm > 0 ? pText.roofLengthen(vCm) : pText.roofShorten(vCm));

    return rText;
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vMatch = nearestRoofWindow(widthMm, heightMm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconLine(
          Icons.window_outlined,
          vText.roofNearest(formatCentimetres(vMatch.widthMm), formatCentimetres(vMatch.heightMm)),
        ),
        Text('${_change(vText, vMatch.widenMm, true)}, ${_change(vText, vMatch.heightenMm, false)}'),
      ],
    );
  }
}
