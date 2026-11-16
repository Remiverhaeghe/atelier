import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/goals.dart';
import '../logic/moisture.dart';
import '../logic/units.dart';
import '../state/worksites_controller.dart';
import 'theme.dart';

String moistureMaterialLabel(AppLocalizations pText, MoistureMaterial pMaterial) =>
    switch (pMaterial) {
      MoistureMaterial.cementScreed => pText.moistureCement,
      MoistureMaterial.anhydriteScreed => pText.moistureAnhydrite,
      MoistureMaterial.wood => pText.moistureWood,
    };

/// Humidité avant la pose : un verdict par support, puis les relevés.
class MoistureScreen extends StatelessWidget {
  const MoistureScreen({super.key, required this.controller, required this.worksiteId, this.today});

  final WorksitesController controller;
  final String worksiteId;

  /// Jour des nouveaux relevés ; aujourd'hui si absent, fixé dans les tests.
  final DateTime? today;

  Future<void> _add(BuildContext pContext) async {
    final vWorksite = controller.worksite(worksiteId);
    if (vWorksite == null) {
      return;
    }
    final vReading = await showDialog<MoistureReading>(
      context: pContext,
      builder: (_) => _ReadingDialog(day: goalDate(today ?? DateTime.now())),
    );
    if (vReading != null) {
      await controller.updateWorksite(
        vWorksite.copyWith(moisture: [...vWorksite.moisture, vReading]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (pContext, _) {
        final vWorksite = controller.worksite(worksiteId);
        final vReadings = vWorksite?.moisture ?? const <MoistureReading>[];

        return Scaffold(
          appBar: AppBar(title: Text(vText.moistureTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _add(pContext),
            icon: const Icon(Icons.add),
            label: Text(vText.moistureAdd),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (vReadings.isEmpty) Text(vText.moistureEmpty),
              for (final vMaterial in MoistureMaterial.values)
                if (moistureVerdict([
                      for (final vReading in vReadings)
                        if (vReading.material == vMaterial) vReading,
                    ])
                    case final vVerdict?)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        vVerdict.state == MoistureState.ready
                            ? Icons.check_circle
                            : Icons.water_drop_outlined,
                        color: vVerdict.state == MoistureState.ready
                            ? vTheme.colorScheme.primary
                            : vTheme.colorScheme.error,
                      ),
                      title: Text(moistureMaterialLabel(vText, vMaterial)),
                      subtitle: Text(switch (vVerdict.state) {
                        MoistureState.ready => vText.moistureReady(formatDecimal(vVerdict.last)),
                        MoistureState.tooDry => vText.moistureTooDry(formatDecimal(vVerdict.last)),
                        MoistureState.tooWet =>
                          vVerdict.daysLeft == null
                              ? vText.moistureTooWet(
                                  formatDecimal(vVerdict.last),
                                  formatDecimal(vMaterial.maxPercent),
                                )
                              : vText.moistureDays(vVerdict.daysLeft!),
                      }),
                    ),
                  ),
              for (final vReading in [...vReadings]..sort((pA, pB) => pB.day.compareTo(pA.day)))
                ListTile(
                  dense: true,
                  title: Text(
                    '${vReading.day} : ${formatDecimal(vReading.percent)} %, '
                    '${moistureMaterialLabel(vText, vReading.material)}',
                  ),
                  trailing: IconButton(
                    tooltip: vText.delete,
                    icon: const Icon(Icons.close),
                    onPressed: () => controller.updateWorksite(
                      vWorksite!.copyWith(
                        moisture: [
                          for (final vOther in vReadings)
                            if (vOther.id != vReading.id) vOther,
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              IconLine(Icons.info_outline, vText.moistureHint),
            ],
          ),
        );
      },
    );
  }
}

class _ReadingDialog extends StatefulWidget {
  const _ReadingDialog({required this.day});

  final String day;

  @override
  State<_ReadingDialog> createState() => _ReadingDialogState();
}

class _ReadingDialogState extends State<_ReadingDialog> {
  MoistureMaterial _material = MoistureMaterial.cementScreed;
  final _value = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(vText.moistureAdd),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<MoistureMaterial>(
            initialValue: _material,
            items: [
              for (final vMaterial in MoistureMaterial.values)
                DropdownMenuItem(
                  value: vMaterial,
                  child: Text(moistureMaterialLabel(vText, vMaterial)),
                ),
            ],
            onChanged: (pMaterial) => setState(() => _material = pMaterial!),
          ),
          TextField(
            controller: _value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: vText.moistureValue),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(
          onPressed: () {
            final vPercent = parseDecimal(_value.text);
            if (vPercent == null) {
              return;
            }
            Navigator.pop(
              context,
              MoistureReading(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                material: _material,
                day: widget.day,
                percent: vPercent,
              ),
            );
          },
          child: Text(vText.save),
        ),
      ],
    );
  }
}
