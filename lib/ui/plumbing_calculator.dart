import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/plumbing.dart';
import '../logic/units.dart';
import 'theme.dart';

String fixtureLabel(AppLocalizations pText, Fixture pFixture) => switch (pFixture) {
  Fixture.washbasin => pText.fixtureWashbasin,
  Fixture.shower => pText.fixtureShower,
  Fixture.bathtub => pText.fixtureBathtub,
  Fixture.sink => pText.fixtureSink,
  Fixture.washingMachine => pText.fixtureWashingMachine,
  Fixture.dishwasher => pText.fixtureDishwasher,
  Fixture.toilet => pText.fixtureToilet,
};

IconData fixtureIcon(Fixture pFixture) => switch (pFixture) {
  Fixture.washbasin => Icons.wash_outlined,
  Fixture.shower => Icons.shower_outlined,
  Fixture.bathtub => Icons.bathtub_outlined,
  Fixture.sink => Icons.countertops_outlined,
  Fixture.washingMachine => Icons.local_laundry_service_outlined,
  Fixture.dishwasher => Icons.kitchen_outlined,
  Fixture.toilet => Icons.wc_outlined,
};

/// Plomberie : appareils et longueurs, tuyaux par diamètre, alimentation, pente à respecter.
class PlumbingCalculator extends StatefulWidget {
  const PlumbingCalculator({super.key});

  @override
  State<PlumbingCalculator> createState() => _PlumbingCalculatorState();
}

class _PlumbingCalculatorState extends State<PlumbingCalculator> {
  final _runs = <FixtureRun>[];

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vNeeds = plumbingNeeds(_runs);

    return Scaffold(
      appBar: AppBar(title: Text(vText.plumbingTitle)),
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
                  Text(vText.resultsTitle, style: vTheme.textTheme.titleMedium),
                  if (_runs.isEmpty) Text(vText.plumbingEmpty),
                  for (final vEntry in vNeeds.drainMetresByDiameter.entries)
                    IconLine(Icons.plumbing, vText.drainLine(vEntry.value, vEntry.key)),
                  if (_runs.isNotEmpty) ...[
                    IconLine(Icons.water_drop_outlined, vText.supplyLine(vNeeds.supplyMetres)),
                    IconLine(Icons.turn_right, vText.fittingsLine(vNeeds.elbows, vNeeds.fittings)),
                  ],
                  const SizedBox(height: 4),
                  Text(vText.plumbingHint, style: vTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var vIndex = 0; vIndex < _runs.length; vIndex++)
            Card(
              child: ListTile(
                leading: Icon(fixtureIcon(_runs[vIndex].fixture), color: vTheme.colorScheme.primary),
                title: Text(fixtureLabel(vText, _runs[vIndex].fixture)),
                subtitle: Text(
                  vText.fixtureLine(
                    drainDiameterMm(_runs[vIndex].fixture),
                    formatDecimal(_runs[vIndex].runMetres),
                    formatCentimetres(drainDrop(_runs[vIndex].runMetres).minMm),
                    formatCentimetres(drainDrop(_runs[vIndex].runMetres).maxMm),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: vText.runShorter,
                      icon: const Icon(Icons.remove),
                      onPressed: _runs[vIndex].runMetres <= 0.5
                          ? null
                          : () => setState(
                              () => _runs[vIndex] = (
                                fixture: _runs[vIndex].fixture,
                                runMetres: _runs[vIndex].runMetres - 0.5,
                              ),
                            ),
                    ),
                    IconButton(
                      tooltip: vText.runLonger,
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(
                        () => _runs[vIndex] = (
                          fixture: _runs[vIndex].fixture,
                          runMetres: _runs[vIndex].runMetres + 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: vText.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() => _runs.removeAt(vIndex)),
                    ),
                  ],
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            children: [
              for (final vFixture in Fixture.values)
                ActionChip(
                  avatar: Icon(fixtureIcon(vFixture), size: 18),
                  label: Text(fixtureLabel(vText, vFixture)),
                  onPressed: () => setState(() => _runs.add((fixture: vFixture, runMetres: 2))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
