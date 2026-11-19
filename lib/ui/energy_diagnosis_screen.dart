import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/heat_loss.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'renovation_screen.dart';
import 'sketch3d.dart';
import 'theme.dart';

String envelopePartLabel(AppLocalizations pText, EnvelopePart pPart) => switch (pPart) {
  EnvelopePart.roof => pText.energyRoof,
  EnvelopePart.walls => pText.energyWalls,
  EnvelopePart.windows => pText.energyWindows,
  EnvelopePart.floor => pText.energyFloor,
  EnvelopePart.air => pText.energyAir,
};

/// État d'une paroi, du pire (0) au meilleur (3), en mots de tous les jours.
String envelopeStateLabel(AppLocalizations pText, EnvelopePart pPart, int pState) =>
    switch (pPart) {
      EnvelopePart.roof => [
        pText.energyRoof0,
        pText.energyRoof1,
        pText.energyRoof2,
        pText.energyRoof3,
      ],
      EnvelopePart.walls => [
        pText.energyWalls0,
        pText.energyWalls1,
        pText.energyWalls2,
        pText.energyWalls3,
      ],
      EnvelopePart.windows => [
        pText.energyWindows0,
        pText.energyWindows1,
        pText.energyWindows2,
        pText.energyWindows3,
      ],
      EnvelopePart.floor => [
        pText.energyFloor0,
        pText.energyFloor1,
        pText.energyFloor2,
        pText.energyFloor3,
      ],
      EnvelopePart.air => [pText.energyAir0, pText.energyAir1, pText.energyAir2, pText.energyAir3],
    }[pState.clamp(0, 3)];

/// Pourcentage entier, pour afficher une part.
String percentOf(double pShare) => '${(pShare * 100).round()}';

/// Montant arrondi à la centaine : un coût indicatif n'a pas besoin de plus.
String roughEuros(int pEuros) => '${(pEuros / 100).round() * 100}';

/// Diagnostic thermique simple : pertes par paroi, travaux les plus rentables, aides à vérifier.
class EnergyDiagnosisScreen extends StatefulWidget {
  const EnergyDiagnosisScreen({super.key, this.rooms = const []});

  /// Pièces du chantier : elles donnent sol, plafond, fenêtres et volume.
  final List<Room> rooms;

  @override
  State<EnergyDiagnosisScreen> createState() => _EnergyDiagnosisScreenState();
}

class _EnergyDiagnosisScreenState extends State<EnergyDiagnosisScreen> {
  late Envelope _envelope = envelopeFromRooms(widget.rooms);

  void _set(Envelope pEnvelope) => setState(() => _envelope = pEnvelope);

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vLosses = heatLosses(_envelope);
    final vWorks = bestWorks(_envelope);
    final vTotalKwh = yearlyKwh(totalLossWK(_envelope));
    NumberField<double> vArea(String pLabel, double pValue, Envelope Function(double) pSet) =>
        NumberField<double>(
          label: pLabel,
          initial: formatDecimal(pValue),
          parse: parseDecimal,
          onValue: (pNew) => _set(pSet(pNew)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(vText.energyTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AspectRatio(aspectRatio: 1.5, child: HouseLossSketch(losses: vLosses)),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vText.energyLossesTitle, style: vTheme.textTheme.titleMedium),
                  BigFigure(vText.energyTotal('${(vTotalKwh / 100).round() * 100}')),
                  for (final vLoss in vLosses)
                    IconLine(
                      Icons.thermostat_outlined,
                      vText.energyPartLoss(
                        envelopePartLabel(vText, vLoss.part),
                        percentOf(vLoss.share),
                        '${vLoss.lossWK.round()}',
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vText.energyWorksTitle, style: vTheme.textTheme.titleMedium),
                  if (vWorks.isEmpty) Text(vText.energyNoWork),
                  for (final (vIndex, vWork) in vWorks.indexed)
                    IconLine(
                      Icons.trending_down,
                      vText.energyWork(
                        vIndex + 1,
                        envelopePartLabel(vText, vWork.part),
                        envelopeStateLabel(vText, vWork.part, vWork.toState),
                        percentOf(vWork.savedShare),
                        roughEuros(vWork.cost),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(vText.energyCostHint, style: vTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          IconLine(Icons.account_balance_outlined, vText.energyAids),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => RenovationScreen(envelope: _envelope)),
            ),
            icon: const Icon(Icons.stairs_outlined),
            label: Text(vText.renovTitle),
          ),
          const SizedBox(height: 12),
          Text(vText.energyHouse, style: vTheme.textTheme.titleMedium),
          if (widget.rooms.isNotEmpty)
            Text(vText.energyFromRooms, style: vTheme.textTheme.bodySmall),
          vArea(
            vText.energyRoofArea,
            _envelope.roofM2,
            (pValue) => _envelope.copyWith(roofM2: pValue),
          ),
          vArea(
            vText.energyWallsArea,
            _envelope.wallsM2,
            (pValue) => _envelope.copyWith(wallsM2: pValue),
          ),
          vArea(
            vText.energyWindowsArea,
            _envelope.windowsM2,
            (pValue) => _envelope.copyWith(windowsM2: pValue),
          ),
          vArea(
            vText.energyFloorArea,
            _envelope.floorM2,
            (pValue) => _envelope.copyWith(floorM2: pValue),
          ),
          vArea(
            vText.energyVolume,
            _envelope.volumeM3,
            (pValue) => _envelope.copyWith(volumeM3: pValue),
          ),
          for (final vPart in EnvelopePart.values)
            DropdownButtonFormField<int>(
              key: ValueKey('etat-${vPart.name}'),
              initialValue: _envelope.stateOf(vPart),
              isExpanded: true,
              decoration: InputDecoration(labelText: envelopePartLabel(vText, vPart)),
              items: [
                for (var vState = 0; vState < 4; vState++)
                  DropdownMenuItem(
                    value: vState,
                    child: Text(envelopeStateLabel(vText, vPart, vState)),
                  ),
              ],
              onChanged: (pState) => _set(_envelope.withState(vPart, pState!)),
            ),
          const SizedBox(height: 12),
          Text(vText.energyHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// La maison en relief : murs, toit, fenêtre et plancher, la paroi qui perd le plus surlignée,
/// chacune avec sa part des pertes.
class HouseLossSketch extends StatelessWidget {
  const HouseLossSketch({super.key, required this.losses});

  final List<PartLoss> losses;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vWorst = losses.isEmpty ? null : losses.first.part;
    PartRole vRole(EnvelopePart pPart, PartRole pNormal) =>
        pPart == vWorst ? PartRole.highlight : pNormal;
    String vLabel(EnvelopePart pPart) {
      final vShare = losses.where((pLoss) => pLoss.part == pPart).firstOrNull?.share ?? 0;

      return vText.energySketchLabel(envelopePartLabel(vText, pPart), percentOf(vShare));
    }

    // Maison de 8 × 6 m, murs de 2,5 m, toit à deux pans de 2 m de haut
    const vWidth = 8000.0;
    const vDepth = 6000.0;
    const vWall = 2500.0;
    const vRidge = 2000.0;

    return Sketch3D(
      parts: [
        Prism.box(0, vWidth, 0, vDepth, -250, 0, role: vRole(EnvelopePart.floor, PartRole.board)),
        Prism.box(0, vWidth, 0, vDepth, 0, vWall, role: vRole(EnvelopePart.walls, PartRole.ghost)),
        Prism.box(2500, 4300, -10, 0, 900, 2100, role: vRole(EnvelopePart.windows, PartRole.glass)),
        Prism(
          [
            (0, vWall),
            (vWidth / 2, vWall + vRidge),
            (vWidth, vWall),
            (vWidth, vWall + 150),
            (vWidth / 2, vWall + vRidge + 150),
            (0, vWall + 150),
          ],
          0,
          vDepth,
          role: vRole(EnvelopePart.roof, PartRole.wood),
        ),
      ],
      callouts: [
        (
          at: (x: vWidth * 0.25, y: 0.0, z: vWall + vRidge / 2),
          text: vLabel(EnvelopePart.roof),
          shift: const Offset(-60, -50),
        ),
        (
          at: (x: 1000.0, y: 0.0, z: vWall / 2),
          text: vLabel(EnvelopePart.walls),
          shift: const Offset(-70, 10),
        ),
        (
          at: (x: 3400.0, y: 0.0, z: 1500.0),
          text: vLabel(EnvelopePart.windows),
          shift: const Offset(-40, 80),
        ),
        (
          at: (x: vWidth, y: vDepth / 2, z: -125.0),
          text: vLabel(EnvelopePart.floor),
          shift: const Offset(60, 20),
        ),
        (
          at: (x: vWidth, y: vDepth, z: vWall / 2),
          text: vLabel(EnvelopePart.air),
          shift: const Offset(40, -20),
        ),
      ],
    );
  }
}
