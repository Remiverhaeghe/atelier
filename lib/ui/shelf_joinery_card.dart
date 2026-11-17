import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/extra_items.dart';
import '../logic/shelf.dart';
import '../logic/shelf_joinery.dart';
import '../logic/units.dart';
import 'drill_template_pdf.dart';
import 'shelf_calculator.dart';
import 'shopping_target.dart';
import 'theme.dart';

String shelfLoadLabel(AppLocalizations pText, ShelfLoad pLoad) => switch (pLoad) {
  ShelfLoad.light => pText.shelfLoadLight,
  ShelfLoad.books => pText.shelfLoadBooks,
  ShelfLoad.heavy => pText.shelfLoadHeavy,
};

/// Choix de la charge, entre les champs d'une étagère ou d'une tablette murale.
class ShelfLoadField extends StatelessWidget {
  const ShelfLoadField({super.key, required this.load, required this.onChanged});

  final ShelfLoad load;
  final ValueChanged<ShelfLoad> onChanged;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return DropdownButtonFormField<ShelfLoad>(
      initialValue: load,
      decoration: InputDecoration(labelText: vText.shelfLoad),
      items: [
        for (final vLoad in ShelfLoad.values)
          DropdownMenuItem(value: vLoad, child: Text(shelfLoadLabel(vText, vLoad))),
      ],
      onChanged: (pLoad) => onChanged(pLoad ?? load),
    );
  }
}

/// Assemblage et solidité d'une étagère : épaisseur selon la charge, tablettes, mur, fond.
class ShelfJoineryCard extends StatelessWidget {
  const ShelfJoineryCard({
    super.key,
    required this.design,
    required this.load,
    required this.adjustable,
  });

  final ShelfDesign design;
  final ShelfLoad load;
  final bool adjustable;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vInner = design.widthMm - 2 * design.thicknessMm;
    final vThickness = adviseThickness(design.material, vInner, load);
    final vJoint = adviseJoint(design, pAdjustable: adjustable);
    final vStability = adviseStability(design);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.joineryTitle, style: vTheme.textTheme.titleMedium),
            if (vThickness.middleUpright)
              IconLine(
                Icons.warning_amber,
                vText.joineryMiddleUpright(
                  vThickness.thicknessMm,
                  formatCentimetres(vThickness.spanMm),
                ),
                color: vTheme.colorScheme.error,
              )
            else
              IconLine(
                Icons.straighten,
                vText.joineryThickness(vThickness.thicknessMm),
                color: vThickness.thicknessMm > design.thicknessMm
                    ? vTheme.colorScheme.error
                    : null,
              ),
            ...switch (vJoint.joint) {
              ShelfJoint.dowels => [
                IconLine(
                  Icons.hardware_outlined,
                  vText.joineryDowels(vJoint.perEnd, vJoint.diameterMm, vJoint.lengthMm),
                ),
                IconLine(
                  Icons.build_outlined,
                  vText.joineryDowelsDrill(
                    vJoint.holeInSideMm,
                    vJoint.holeInShelfMm,
                    vJoint.edgeMarginMm,
                  ),
                ),
              ],
              ShelfJoint.confirmatScrews => [
                IconLine(Icons.hardware_outlined, vText.joineryConfirmat(vJoint.perEnd)),
                IconLine(Icons.build_outlined, vText.joineryConfirmatDrill(vJoint.holeInShelfMm)),
              ],
              ShelfJoint.shelfPins => [
                IconLine(Icons.hardware_outlined, vText.joineryPins(vJoint.edgeMarginMm)),
              ],
            },
            if (vStability.fixToWall) IconLine(Icons.vertical_align_top, vText.joineryFixToWall),
            if (vStability.brace) IconLine(Icons.change_history, vText.joineryBrace),
            const SizedBox(height: 8),
            AddToShoppingButton(items: () => _shopping(vText, vJoint)),
            OutlinedButton.icon(
              icon: const Icon(Icons.print_outlined),
              label: Text(vText.drillTemplateButton),
              onPressed: () => Printing.layoutPdf(
                name: vText.drillTemplateTitle,
                onLayout: (_) => buildDrillTemplatePdf(vText, design, vJoint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ExtraItem> _shopping(AppLocalizations pText, JointAdvice pJoint) {
    final vPlan = planShelf(design);
    final vShelves = design.shelves < 2 ? 2 : design.shelves;
    final rItems = [
      ExtraItem(
        name: pText.extraShelfBoards(
          shelfMaterialLabel(pText, design.material),
          design.thicknessMm,
        ),
        quantity: vPlan.boards,
      ),
      ExtraItem(
        name: switch (pJoint.joint) {
          ShelfJoint.dowels => pText.extraDowels(pJoint.diameterMm, pJoint.lengthMm),
          ShelfJoint.confirmatScrews => pText.extraConfirmat,
          ShelfJoint.shelfPins => pText.extraPins,
        },
        quantity: vShelves * 2 * pJoint.perEnd,
      ),
    ];

    return rItems;
  }
}
