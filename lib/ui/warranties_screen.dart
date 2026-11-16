import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/goals.dart';
import '../logic/units.dart';
import '../logic/warranties.dart';
import '../state/worksites_controller.dart';
import 'theme.dart';

String warrantyKindLabel(AppLocalizations pText, WarrantyKind pKind) => switch (pKind) {
  WarrantyKind.conformity => pText.warrantyConformity,
  WarrantyKind.completion => pText.warrantyCompletion,
  WarrantyKind.biennial => pText.warrantyBiennial,
  WarrantyKind.decennial => pText.warrantyDecennial,
  WarrantyKind.custom => pText.warrantyCustom,
};

/// Garanties : jusqu'à quand, et celles qui finissent bientôt en tête.
class WarrantiesScreen extends StatelessWidget {
  const WarrantiesScreen({
    super.key,
    required this.controller,
    required this.worksiteId,
    this.today,
  });

  final WorksitesController controller;
  final String worksiteId;

  /// Jour de référence ; aujourd'hui si absent, fixé dans les tests.
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vToday = today ?? DateTime.now();

    return ListenableBuilder(
      listenable: controller,
      builder: (pContext, _) {
        final vWorksite = controller.worksite(worksiteId);
        final vItems = sortedWarranties(vWorksite?.warranties ?? const []);

        return Scaffold(
          appBar: AppBar(title: Text(vText.warrantyTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final vNew = await showDialog<Warranty>(
                context: pContext,
                builder: (_) => _WarrantyDialog(id: controller.newId(), day: goalDate(vToday)),
              );
              final vCurrent = controller.worksite(worksiteId);
              if (vNew != null && vCurrent != null) {
                await controller.updateWorksite(
                  vCurrent.copyWith(warranties: [...vCurrent.warranties, vNew]),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: Text(vText.warrantyAdd),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
            children: [
              if (vItems.isEmpty)
                Padding(padding: const EdgeInsets.all(8), child: Text(vText.warrantyEmpty)),
              for (final vItem in vItems)
                Card(
                  child: ListTile(
                    leading: Icon(
                      switch (warrantyState(vItem, vToday)) {
                        WarrantyState.running => Icons.verified_outlined,
                        WarrantyState.endingSoon => AtelierIcons.warning,
                        WarrantyState.ended => Icons.history,
                      },
                      color: warrantyState(vItem, vToday) == WarrantyState.endingSoon
                          ? vTheme.colorScheme.error
                          : null,
                    ),
                    title: Text(vItem.label),
                    subtitle: Text(
                      [
                        warrantyKindLabel(vText, vItem.kind),
                        if (warrantyState(vItem, vToday) == WarrantyState.ended)
                          vText.warrantyEnded(goalDate(vItem.end))
                        else
                          vText.warrantyUntil(goalDate(vItem.end)),
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: vText.delete,
                      icon: const Icon(Icons.close),
                      onPressed: () => controller.updateWorksite(
                        vWorksite!.copyWith(
                          warranties: [
                            for (final vOther in vWorksite.warranties)
                              if (vOther.id != vItem.id) vOther,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              IconLine(Icons.info_outline, vText.warrantyHint),
            ],
          ),
        );
      },
    );
  }
}

class _WarrantyDialog extends StatefulWidget {
  const _WarrantyDialog({required this.id, required this.day});

  final String id;
  final String day;

  @override
  State<_WarrantyDialog> createState() => _WarrantyDialogState();
}

class _WarrantyDialogState extends State<_WarrantyDialog> {
  final _label = TextEditingController();
  late final _start = TextEditingController(text: widget.day);
  final _months = TextEditingController(text: '12');
  WarrantyKind _kind = WarrantyKind.conformity;

  @override
  void dispose() {
    _label.dispose();
    _start.dispose();
    _months.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(vText.warrantyAdd),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _label,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: vText.warrantyLabel),
            ),
            DropdownButtonFormField<WarrantyKind>(
              initialValue: _kind,
              isExpanded: true,
              items: [
                for (final vKind in WarrantyKind.values)
                  DropdownMenuItem(value: vKind, child: Text(warrantyKindLabel(vText, vKind))),
              ],
              onChanged: (pKind) => setState(() => _kind = pKind!),
            ),
            TextField(
              controller: _start,
              decoration: InputDecoration(labelText: vText.warrantyStart),
            ),
            if (_kind == WarrantyKind.custom)
              TextField(
                controller: _months,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: vText.warrantyMonths),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(
          onPressed: () {
            if (_label.text.trim().isEmpty || DateTime.tryParse(_start.text.trim()) == null) {
              return;
            }
            Navigator.pop(
              context,
              Warranty(
                id: widget.id,
                label: _label.text.trim(),
                kind: _kind,
                start: _start.text.trim(),
                months: _kind == WarrantyKind.custom ? (parseWhole(_months.text) ?? 0) : 0,
              ),
            );
          },
          child: Text(vText.save),
        ),
      ],
    );
  }
}
