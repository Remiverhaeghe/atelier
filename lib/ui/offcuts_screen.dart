import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/offcuts.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';
import '../state/worksites_controller.dart';
import 'theme.dart';

String offcutMaterialLabel(AppLocalizations pText, OffcutMaterial pMaterial) => switch (pMaterial) {
  OffcutMaterial.plank => pText.offcutPlank,
  OffcutMaterial.baseboard => pText.offcutBaseboard,
};

/// Chutes du chantier : on les note, l'appli dit où chacune peut resservir.
class OffcutsScreen extends StatelessWidget {
  const OffcutsScreen({super.key, required this.controller, required this.worksiteId});

  final WorksitesController controller;
  final String worksiteId;

  Future<void> _add(BuildContext pContext, Worksite pWorksite) async {
    final vOffcut = await showDialog<Offcut>(
      context: pContext,
      builder: (_) => const _OffcutDialog(),
    );
    if (vOffcut != null) {
      controller.updateWorksite(pWorksite.copyWith(offcuts: [...pWorksite.offcuts, vOffcut]));
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
        if (vWorksite == null) {
          return const Scaffold();
        }
        final vUses = offcutUses(vWorksite);

        return Scaffold(
          appBar: AppBar(title: Text(vText.offcutsTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _add(pContext, vWorksite),
            icon: const Icon(Icons.add),
            label: Text(vText.offcutAdd),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (vWorksite.offcuts.isEmpty)
                Padding(padding: const EdgeInsets.all(20), child: Text(vText.offcutsEmpty)),
              for (final vOffcut in vWorksite.offcuts)
                ListTile(
                  leading: Icon(
                    vOffcut.material == OffcutMaterial.plank
                        ? AtelierIcons.planks
                        : AtelierIcons.baseboard,
                  ),
                  title: Text('${formatCentimetres(vOffcut.lengthMm)} cm'),
                  subtitle: Text(offcutMaterialLabel(vText, vOffcut.material)),
                  trailing: IconButton(
                    tooltip: vText.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => controller.updateWorksite(
                      vWorksite.copyWith(
                        offcuts: [
                          for (final vOther in vWorksite.offcuts)
                            if (vOther.id != vOffcut.id) vOther,
                        ],
                      ),
                    ),
                  ),
                ),
              if (vUses.isNotEmpty) ...[
                ListTile(title: Text(vText.offcutsUsesTitle, style: vTheme.textTheme.titleMedium)),
                for (final vUse in vUses)
                  ListTile(
                    leading: const Icon(Icons.recycling),
                    title: Text(
                      vText.offcutUse(
                        formatCentimetres(vUse.offcut.lengthMm),
                        formatCentimetres(vUse.lengthMm),
                      ),
                    ),
                    subtitle: Text(
                      vUse.offcut.material == OffcutMaterial.plank
                          ? vText.offcutUseRow(vUse.roomName, vUse.place)
                          : vText.offcutUseWall(vUse.roomName, vUse.place),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OffcutDialog extends StatefulWidget {
  const _OffcutDialog();

  @override
  State<_OffcutDialog> createState() => _OffcutDialogState();
}

class _OffcutDialogState extends State<_OffcutDialog> {
  final _length = TextEditingController();
  OffcutMaterial _material = OffcutMaterial.plank;
  String? _error;

  @override
  void dispose() {
    _length.dispose();
    super.dispose();
  }

  void _submit() {
    final vLength = parseCentimetres(_length.text);
    if (vLength == null || vLength == 0) {
      setState(() => _error = AppLocalizations.of(context).invalidLength);
      return;
    }
    Navigator.pop(
      context,
      Offcut(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        material: _material,
        lengthMm: vLength,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(vText.offcutAdd),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<OffcutMaterial>(
            segments: [
              for (final vMaterial in OffcutMaterial.values)
                ButtonSegment(value: vMaterial, label: Text(offcutMaterialLabel(vText, vMaterial))),
            ],
            selected: {_material},
            onSelectionChanged: (pSelection) => setState(() => _material = pSelection.single),
          ),
          TextField(
            controller: _length,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: vText.wallLength,
              suffixText: vText.unitCm,
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(onPressed: _submit, child: Text(vText.save)),
      ],
    );
  }
}
